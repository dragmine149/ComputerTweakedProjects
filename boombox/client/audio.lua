local pretty = require("cc.pretty")
local switch = require("utils.switch")
local log = require("utils.log")
local dfpwm = require("cc.audio.dfpwm")
local aukit = require("AUKit")

local audio = {
    buffer = "",
    bufferOffset = 1,
    speakers = {},
    empty = 0,
    playing = false
}
audio.__index = audio

-- local function playAll(data)
--     log.info(textutils.serialise(data))
--     local audioData = dfpwm.decode(data)

--     local cor = {}
--     log.info("Speakers: ")
--     log.info(pretty.pretty(audio.speakers))
--     for _, speaker in pairs(audio.speakers) do
--         log.info("Speaker: " .. tostring(speaker))
--         table.insert(cor, function ()
--             while not speaker.playAudio(audioData) do
--                 os.pullEvent("speaker_audio_empty")
--             end
--             audio.empty = audio.empty + 1
--         end)
--     end

--     return cor
-- end

-- function audio:emptyBuffer()
--     if #self.speakers == 0 then
--         log.error("No speakers found")
--         os.queueEvent("speaker_error", "No speakers found")
--         return
--     end

--     log.info("Emptied buffer")
--     -- self.empty = self.empty + 1
--     if self.empty <= #self.speakers and not self.playing then return end

--     log.info("Playing next set of data")
--     parallel.waitForAll(table.unpack(playAll(self.buffer[self.bufferOffset])))
--     self.empty = 0
--     self.bufferOffset = self.bufferOffset + 1
--     log.info("Buffer offset: " .. self.bufferOffset)
--     log.info("Progress: " .. self.bufferOffset / #self.buffer)
--     os.queueEvent("speaker_progress", self.bufferOffset / #self.buffer)
-- end

function audio:AUKit()
    local iterator, length = aukit.stream.dfpwm(self.buffer)
    aukit.play(
        iterator,
        function(pos)
            self.progress = pos / length
            os.queueEvent("speaker_progress", self.progress)
        end,
        settings.get("volume", 1),
        peripheral.find("speaker")
    )
end

function audio:playNow(file)
    self.buffer = ""
    self.bufferOffset = 1

    log.info("Loading song data from", file)
    local songData = fs.open(file, "rb")
    if not songData then os.queueEvent("speaker_error", "File not found") return end
    self.buffer = songData.readAll()

    -- local byteSize = settings.get("byteSize", 2)
    -- local byte = "not nil"
    -- while byte ~= nil do
    --     byte = songData.read(byteSize * 1024)
    --     if byte then
    --         table.insert(self.buffer, byte)
    --     end
    -- end

    -- log.info(textutils.serialize(self.buffer))

    songData.close()
end

function audio:playState(state)
    log.info("Playing state: " .. tostring(state))
    self.playing = state
    if state then
        self.empty = #self.speakers
        -- audio:emptyBuffer()
        audio:AUKit()
    end
end

function audio:seek(progress)
    log.info("Seeking to: " .. tostring(progress))
    local percent = 0.01 * #self.buffer
    local change = percent * progress
    log.info("Change: " .. tostring(change))
    log.info("Buffer offset before: " .. tostring(self.bufferOffset))
    self.bufferOffset = math.floor(self.bufferOffset + change)
    log.info("Buffer offset after: " .. tostring(self.bufferOffset))
end

function audio:events()
    while true do
        local event, data = os.pullEventRaw()
        local eventSwitch = switch()
            -- :case("speaker_audio_empty", function()
            --     log.info("Buffer is empty")
            --     self:emptyBuffer()
            -- end)
            :case("speaker_play_now", function(file)
                log.info("Playing now: " .. file)
                self:playNow(file)
                self:playState(true)
            end)
            :case("speaker_play_state", function(state)
                log.info("Playing state: " .. tostring(state))
                self:playState(state)
            end)
            :case("speaker_seek", function(progress)
                log.info("Seeking to: " .. tostring(progress))
                self:seek(progress)
            end)
            :case("peripheral", function()
                log.info("Peripheral detected")
                self.speakers[#self.speakers + 1] = peripheral.wrap(data)
            end)
            :case("peripheral_detach", function()
                log.info("Peripheral detached")
                -- table.remove(self.speakers, peripheral.wrap(data))
            end)
            :case("terminate", function()
                log.warn("Preventing termination")
            end)
            :default(function() end)

        eventSwitch(event, data)
    end
end

for _, speaker in pairs({ peripheral.find("speaker") }) do
    audio.speakers[#audio.speakers + 1] = speaker
end
audio:events()
