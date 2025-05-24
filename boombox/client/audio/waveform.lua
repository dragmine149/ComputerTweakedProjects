-- Modified version of https://gist.github.com/MichielP1807/9536445bd5773915a58594869049d2ed
-- from https://pinestore.cc/projects/99/waveflow-visualizer

local log = require("/Boombox.utils.log")
-- BetterBetterBlittle (takes color spaces into account when picking colors)
local betterblittle = require("/Boombox.utils.betterbetterblittle")
local switch = require("/Boombox.utils.switch")
local waveform = {}
waveform.__index = waveform

local LAST_COLOR = 2 ^ 15
waveform.gradients = {
    {0xf3ee5e, 0xe6ca58, 0xd9a653, 0xcc824e, 0xbf5d48, 0xb14242, 0x9f3b3b, 0x8e3535, 0x7d2f2f, 0x6c2828, 0x5a2222, 0x491c1c, 0x371515, 0x260e0e, 0x140808, 0x040101},
    {0x54d2f3, 0x5eb3e8, 0x6995de, 0x7275d3, 0x7d56c8, 0x813fbc, 0x7439a9, 0x673296, 0x5a2c84, 0x4e2772, 0x41205f, 0x351a4d, 0x28143b, 0x1b0d28, 0x0f0716, 0x020103},
    {0xf45256, 0xec4f6c, 0xe34c82, 0xdc4a98, 0xd448ae, 0xc844b8, 0xb43da5, 0xa13693, 0x8d3082, 0x79296f, 0x66235e, 0x521c4c, 0x3e1539, 0x2b0f28, 0x180816, 0x040103},
    {0x79f256, 0x6de66c, 0x61d983, 0x55cd98, 0x4ac0af, 0x40b2b9, 0x39a0a7, 0x338f95, 0x2c7d82, 0x276c70, 0x205a5e, 0x1a4a4c, 0x14383a, 0x0e2628, 0x071415, 0x010304}
}
waveform.gradientI = 1


-- each sample is an integer between -128 and 127
local samplerate = 48 -- 48 samples per ms (48kHz)

local buffers = {}
-- local MAX_BUFFERS = 3 -- maximum number of buffers to keep in memory
local bufferI = 0

local newestBufferEndTime = 0 -- in ms, aka nextBufferStartTime
-- local oldPeripheralCall = peripheral.call
-- function peripheral.call(name, method, ...)
--     if method == "playAudio" then
--         if not oldPeripheralCall(name, method, ...) then return false end

--         if not only_use_speaker or only_use_speaker == name then
--             local newBuffer = ({...})[1]
--             local volume = ({...})[2]

--             local bufferDuration = #newBuffer / samplerate
--             local time = os.epoch("utc")
--             if time - newestBufferEndTime > 10 then
--                 newestBufferEndTime = time + bufferDuration
--                 buffers = {}
--             else
--                 newestBufferEndTime = newestBufferEndTime + bufferDuration
--             end

--             bufferI = bufferI % MAX_BUFFERS + 1
--             buffers[bufferI] = newBuffer
--         end

--         return true -- success
--     else
--         return oldPeripheralCall(name, method, ...)
--     end
-- end

local SCREEN_WIDTH, SCREEN_HEIGHT = term.getSize()
local FB_WIDTH, FB_HEIGHT = SCREEN_WIDTH * 2, SCREEN_HEIGHT * 3
local window = window.create(term.current(), 1, 1, SCREEN_WIDTH, SCREEN_HEIGHT)
local frameBuffer = {}

local function setColors()
    local gradient = waveform.gradients[waveform.gradientI]
    for i = 1, #gradient do
        window.setPaletteColor(2 ^ (i - 1), gradient[i])
    end
end
setColors()

local function userInput()
    while true do
        local event, which, x, y = os.pullEventRaw()
        if event == "mouse_click" then
            waveform.gradientI = waveform.gradientI % #waveform.gradients + 1
            setColors()
        elseif event == "terminate" then
            peripheral.call = oldPeripheralCall
            return
        end
    end
end

function waveform.gameLoop()
    local lastTime = os.epoch("utc")
    local lastI = -1
    local max, min, floor, random = math.max, math.min, math.floor, math.random

    while true do
        local time = os.epoch("utc")
        local dt = time - lastTime

        if dt >= 10 then -- limit to 100 fps
            lastTime = time

            local buffer, sampleIndex = {}, 1
            local sampleOffset = floor((newestBufferEndTime - time) * samplerate)
            -- log.info(sampleOffset, newestBufferEndTime, time)
            if sampleOffset >= 0 then
                buffer = buffers[bufferI] or {}
                sampleIndex = #buffer - sampleOffset
                if sampleIndex < 0 then
                    buffer = buffers[(bufferI - 2)] or {}
                    sampleIndex = sampleIndex + #buffer
                end
            end

            local fadeFactor = random() < dt / 20 and 2 or 1
            local fadeFactor2 = random() < dt / 50 and 2 or 1
            for y = 1, FB_HEIGHT do
                local row = frameBuffer[y] or {}
                for x = 1, FB_WIDTH do
                    local color = row[x] or LAST_COLOR
                    row[x] = max(min((color) * (color > 128 and fadeFactor2 or fadeFactor), LAST_COLOR), 2)
                end
                frameBuffer[y] = row
            end

            local scale = 4
            for x = 1, FB_WIDTH do
                local sample = 0
                if sampleOffset >= 0 then
                    sample = buffer[sampleIndex - scale * (x - 1)]
                    if not sample then
                        buffer = buffers[bufferI] or {}
                        sample = buffer[sampleIndex + x] or 0
                    end
                end
                local y = floor((sample + 128) / 256 * (FB_HEIGHT - 2) + 1)
                if y > 0 and y < FB_HEIGHT then
                    local row = frameBuffer[y]
                    row[FB_WIDTH - x + 1] = 1
                    frameBuffer[y] = row
                end
            end

            betterblittle.drawBuffer(frameBuffer, window)
            bufferI = bufferI + 1

            -- window.setTextColor(2)
            -- window.setCursorPos(1, 1)
            -- window.write("" .. sampleOffset .. " " .. sampleIndex)

            -- window.setVisible(true)
            -- window.setVisible(false)
        end

        os.queueEvent("gameLoop")
        os.pullEventRaw("gameLoop")
    end
end

function waveform.buffer()
    log.info("Waiting...")
    while true do
        local event, data = os.pullEventRaw()
        local waveSwitch = switch()
            :case("speaker_progress", function (edata)
                newestBufferEndTime = os.epoch("utc") + (edata * 1000)
            end)
            :case("speaker_visualizer", function(edata)
                log.info("Received data!")
                log.info(type(edata))
                buffers = edata
            end)
            :default(function() end)

        waveSwitch(event, data)
    end
end
-- print("Waiting...")

parallel.waitForAny(waveform.gameLoop, waveform.buffer, userInput)
