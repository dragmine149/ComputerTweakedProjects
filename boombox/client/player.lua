local expect = {}

local native_select, native_type = select, type

function expect.get_type_names(...)
    local types = table.pack(...)
    for i = types.n, 1, -1 do
        if types[i] == "nil" then table.remove(types, i) end
    end

    if #types <= 1 then
        return tostring(...)
    else
        return table.concat(types, ", ", 1, #types - 1) .. " or " .. types[#types]
    end
end


function expect.get_display_type(value, t)
    -- Lua is somewhat inconsistent in whether it obeys __name just for values which
    -- have a per-instance metatable (so tables/userdata) or for everything. We follow
    -- Cobalt and only read the metatable for tables/userdata.
    if t ~= "table" and t ~= "userdata" then return t end

    local metatable = debug.getmetatable(value)
    if not metatable then return t end

    local name = rawget(metatable, "__name")
    if type(name) == "string" then return name else return t end
end

--- Expect an argument to have a specific type.
--
-- @tparam number index The 1-based argument index.
-- @param value The argument's value.
-- @tparam string ... The allowed types of the argument.
-- @return The given `value`.
-- @throws If the value is not one of the allowed types.
function expect.expect(index, value, ...)
    local t = native_type(value)
    for i = 1, native_select("#", ...) do
        if t == native_select(i, ...) then return value end
    end

    -- If we can determine the function name with a high level of confidence, try to include it.
    local name
    local ok, info = pcall(debug.getinfo, 3, "nS")
    if ok and info.name and info.name ~= "" and info.what ~= "C" then name = info.name end

    t = expect.get_display_type(value, t)

    local type_names = expect.get_type_names(...)
    if name then
        error(("bad argument #%d to '%s' (%s expected, got %s)"):format(index, name, type_names, t), 3)
    else
        error(("bad argument #%d (%s expected, got %s)"):format(index, type_names, t), 3)
    end
end

local decoder = {
    char = string.char,
    byte = string.byte,
    floor = math.floor,
    band = bit32.band,
    rshift = bit32.arshift,

}
decoder.PREC = 10
decoder.PREC_POW = 2 ^ decoder.PREC
decoder.PREC_POW_HALF = 2 ^ (decoder.PREC - 1)
decoder.STRENGTH_MIN = 2 ^ (decoder.PREC - 8 + 1)

function decoder.make_predictor()
    local charge, strength, previous_bit = 0, 0, false

    return function(current_bit)
        local target = current_bit and 127 or -128

        local next_charge = charge + decoder.floor((strength * (target - charge) + decoder.PREC_POW_HALF) / decoder.PREC_POW)
        if next_charge == charge and next_charge ~= target then
            next_charge = next_charge + (current_bit and 1 or -1)
        end

        local z = current_bit == previous_bit and decoder.PREC_POW - 1 or 0
        local next_strength = strength
        if next_strength ~= z then next_strength = next_strength + (current_bit == previous_bit and 1 or -1) end
        if next_strength < decoder.STRENGTH_MIN then next_strength = decoder.STRENGTH_MIN end

        charge, strength, previous_bit = next_charge, next_strength, current_bit
        return charge
    end
end

--[[- Create a new decoder for converting DFPWM into PCM audio data.

The returned decoder is itself a function. This function accepts a string and returns a table of amplitudes, each value
between -128 and 127.

> [Reusing decoders][!WARNING]
> Decoders have lots of internal state which tracks the state of the current stream. If you reuse an decoder for
> multiple streams, or use different decoders for the same stream, the resulting audio may not sound correct.

@treturn function(dfpwm: string):{ number... } The encoder function
@see decode A helper function for decoding an entire file of audio at once.

@usage Reads "data/example.dfpwm" in blocks of 16KiB (the speaker can accept a maximum of 128×1024 samples), decodes
them and then plays them through the speaker.

```lua {data-peripheral=speaker}
local dfpwm = require "cc.audio.dfpwm"
local speaker = peripheral.find("speaker")

local decoder = dfpwm.make_decoder()
for input in io.lines("data/example.dfpwm", 16 * 1024) do
  local decoded = decoder(input)
  while not speaker.playAudio(decoded) do
    os.pullEvent("speaker_audio_empty")
  end
end
```
]]
function decoder.make_decoder()
    local predictor = decoder.make_predictor()
    local low_pass_charge = 0
    local previous_charge, previous_bit = 0, false

    return function (input, output)
        expect.expect(1, input, "string")

        local output, output_n = {}, 0
        for i = 1, #input do
            local input_byte = decoder.byte(input, i)
            for _ = 1, 8 do
                local current_bit = decoder.band(input_byte, 1) ~= 0
                local charge = predictor(current_bit)

                local antijerk = charge
                if current_bit ~= previous_bit then
                    antijerk = decoder.floor((charge + previous_charge + 1) / 2)
                end

                previous_charge, previous_bit = charge, current_bit

                low_pass_charge = low_pass_charge + decoder.floor(((antijerk - low_pass_charge) * 140 + 0x80) / 256)

                output_n = output_n + 1
                output[output_n] = low_pass_charge

                input_byte = decoder.rshift(input_byte, 1)
            end
        end

        return output
    end
end

local player = {}

---@type ccTweaked.peripheral.Speaker
player.speaker = peripheral.wrap("top")
print(player.speaker)

local function disk(id)
    if id < 2 then return "disk" end
    return "disk" .. id
end

function player.decode(file)
    local data = fs.open(file, "rb")
    if not data then return false end
    return data
end
function player.playDecoded(handle, volume)
    local player_decoder = decoder.make_decoder()
    while true do
        -- local event = os.pullEventRaw("terminate")
        -- print(event)
        -- if event == "terminate" then break end

        local chunk = handle.read(1 * 1024)
        if not chunk then break end

        local buffer = player_decoder(chunk)
        local empty = false
        while not player.speaker.playAudio(buffer, volume) and not empty do
            local event = os.pullEventRaw()
            print(event)
            if event == "stop_sound" then return end
            empty = event == "speaker_audio_empty"

            -- os.pullEvent("speaker_audio_empty")
        end
    end
end

function player.playSound(file, volume)
    print("Playing sound from file "..file)
    local handler = player.decode(file)
    if not handler then return end
    player.playDecoded(handler, volume)
    handler.close()
end

local args = {...}
local file = args[1]
local volume = tonumber(args[2]) or 1.0
print("e")
shell.exit()
player.playSound(file, volume)
