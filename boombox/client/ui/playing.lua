local shellAdditions = require("/Boombox.utils.shell")
local player = {
    isPlaying = false,
    file = ""
}
player.__index = player
player.__call = function(self, screen, log, functions)
    player.log = log

    player.shuffle = screen:addButton("ui_player_shuffle")
        :setSize(10, 4)
        :setPosition(1, "{parent.height - 3}")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            functions.queue.toggleShuffle()
        end)

    local shuffle_orig_render = player.shuffle.render
    function player.shuffle:render()
        shuffle_orig_render(self)
        self:textFg(1, 2, " Shuffle:", self.get("foreground"))
        self:textFg(1, 3, " " .. functions.queue.shuffleStatus(), self.get("foreground"))
    end

    player.repeat_track = screen:addButton("ui_player_repeat")
        :setSize(10, 4)
        :setPosition("{parent.width - self.width + 1}", "{parent.height - 3}")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            functions.queue.toggleRepeat()
            -- player.repeat_track:setText("Repeat:\n" .. functions.queue.repeatStatus())
        end)

    local repeat_orig_render = player.repeat_track.render
    function player.repeat_track:render()
        repeat_orig_render(self)
        self:textFg(1, 2, " Repeat:", self.get("foreground"))
        -- self:textFg(1, 3, " " .. functions.queue.repeatStatus(), self.get("foreground"))
        self:textFg(1, 3, " WIP...", self.get("foreground"))
    end

    player.play = screen:addButton("ui_player_play")
        :setSize(10, 1)
        :setPosition("{parent.width / 2 - self.width / 2 + 1}", "{parent.height - 2}")
        :setText(self:Playing())
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            self.isPlaying = not self.isPlaying
            player.play:setText(self:Playing())
            os.queueEvent("speaker_play_state", self.isPlaying)
        end)

    player.previous = screen:addButton("ui_player_previous")
        :setSize(10, 1)
        :setPosition("{parent.width / 2 - self.width}", "{parent.height}")
        :setText("Previous")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            self.file = functions.queue.previous()
            os.queueEvent("speaker_play_now", self.file)
        end)

    player.next = screen:addButton("ui_player_next")
        :setSize(10, 1)
        :setPosition("{parent.width / 2 + 1 + 1}", "{parent.height}")
        :setText("Next")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            self.file = functions.queue.next()
            os.queueEvent("speaker_play_now", self.file)
        end)

    player.progress = screen:addProgressBar("ui_player_progress")
        :setSize("{parent.width + 1}", 1)
        :setPosition(1, "{parent.height - 5}")
        :setProgress(0)
        :setShowPercentage(true)
        :listenEvent("speaker_progress", true)

    function player.progress:handleEvent(event, data)
        if event == "speaker_progress" then
            player.progress:setProgress(data)
        end
    end

    player.seek5 = screen:addButton("ui_player_seek5")
        :setSize(5, 1)
        :setPosition("{ui_player_play.x + ui_player_play.width + 1}", "{ui_player_play.y}")
        :setText("+05s")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            os.queueEvent("speaker_seek", 5)
        end)

    player.seek10 = screen:addButton("ui_player_seek10")
        :setSize(5, 1)
        :setPosition("{ui_player_play.x + ui_player_play.width + 1 + ui_player_seek5.width + 1}", "{ui_player_play.y}")
        :setText("+10s")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            os.queueEvent("speaker_seek", 10)
        end)

    player.seekN5 = screen:addButton("ui_player_seekN5")
        :setSize(5, 1)
        :setPosition("{ui_player_play.x - self.width - 1}", "{ui_player_play.y}")
        :setText("-05s")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            os.queueEvent("speaker_seek", -5)
        end)

    player.seekN10 = screen:addButton("ui_player_seekN10")
        :setSize(5, 1)
        :setPosition("{ui_player_play.x - self.width - 1 - ui_player_seekN5.width - 1}", "{ui_player_play.y}")
        :setText("-10s")
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            os.queueEvent("speaker_seek", -10)
        end)

    player.visualizer = screen:addProgram()
        :setSize("{parent.width}", "{parent.height - (parent.height - ui_player_progress.y) - 2}")
        :execute("/Boombox/audio/waveform.lua")

    player.player = multishell.launch(shellAdditions.createShellEnv("rom/programs"), "rom/programs/shell.lua", "Boombox/audio.lua")
    multishell.setTitle(player.player, "Boombox Player")
end

function player:Playing()
    if not self.isPlaying then return "Play" end
    return "Pause"
end

return function()
    return setmetatable({}, player)
end
