local shellAdditions = require("/Boombox.utils.shell")
local options = {}
options.__index = options

function options.__call(self, screen, log, functions)
    options.log = log
    options.functions = functions
    self.tab = multishell.getFocus()
    self.delete = false

    options.file = screen:addLabel("ui_options_file")
        :setSize("{parent.width}", 1)
        :setAutoSize(false)

    options.size = screen:addLabel("ui_options_size")
        :setSize("{parent.width}", 1)
        :setAutoSize(false)
        :setPosition(1, "{ui_options_file.y + 1}")

    options.rename = screen:addButton("ui_options_rename")
        :setText("Rename")
        :setSize(8, 3)
        :onClick(function()
            if multishell.getTitle(self.tab) == 'edit' then
                -- we are already editing something. No need to edit TWO things
                return
            end

            self.tab = multishell.launch(shellAdditions.createShellEnv("rom/programs"), "rom/programs/shell.lua", "Boombox/terminal/keyboard.lua",
                "\"Please replace the old name of the file with the new name\"", "\""..options.current.."\""
            )
            options.log.info("Launching options editor. Tab id: " .. self.tab)
            shell.switchTab(self.tab)
        end)
        :setPosition(1, "{ui_options_size.y + 2}")
        -- :listenEvent("terminal_input", true)
        :setColor("{self.clicked and colors.white or colors.black}", "{self.clicked and colors.gray or colors.lightGray}")

    ---comment
    ---@param event string
    ---@param data string
    function options.rename:handleEvent(event, data)
        if event == "terminal_input" then
            if not data:match("%.dfpwm$") then
                data = data .. ".dfpwm"
            end

            fs.move(options.current, data)
            options.current = data
            options.file:setText("Current file: " .. data)
            self.tab = multishell.getFocus()
        end
    end

    options.delete = screen:addButton("ui_options_delete")
        :setText("Delete")
        :setSize(8, 3)
        :onClick(function()
            if not self.delete then
               self.delete = true
               options.timer:start()
               options.delete:setText("confirm?")
               return
            end
            fs.delete(options.current)
            options.leave()
        end)
        :setPosition("{ui_options_rename.width + 2}", "{ui_options_rename.y}")
        :setColor("{self.clicked and colors.white or colors.black}", "{self.clicked and colors.gray or colors.lightGray}")

    options.timer = screen:addTimer("ui_options_delete_timer")
        :setInterval(2)
        :setAction(function()
            self.delete = false
            options.delete:setText("Delete")
        end)

    options.back = screen:addButton()
        :setText("Back")
        :setSize(6, 3)
        :onClick(function() options.leave() end)
        :setPosition("{ui_options_delete.x + ui_options_delete.width + 1}", "{ui_options_delete.y}")
        :setColor("{self.clicked and colors.white or colors.black}", "{self.clicked and colors.gray or colors.lightGray}")
end

function options.view(file)
    options.current = file
    options.file:setText("Current file: " .. file)
    options.size:setText("Size on disk: " .. options.functions.formatBytes(fs.getSize(file)))
    options.rename:listenEvent("terminal_input", true)
end
function options.leave()
    options.rename:listenEvent("terminal_input", false)
    options.functions.files()
end

return function()
	return setmetatable({}, options)
end
