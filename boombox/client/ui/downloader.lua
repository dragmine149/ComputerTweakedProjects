local shellAdditions = require("/Boombox.utils.shell")
local downloader = {}
downloader.__index = downloader

function downloader.__call(self, screen, log, functions)
    downloader.log = log
    downloader.screen = screen
    screen:setVisible(false)

    downloader.title = screen:addLabel("ui_downloader_title")
        :setAutoSize(false)
        :setText("Download a file remotely")
        :setSize("{parent.width}", 1)

    downloader.description = screen:addLabel("ui_downloader_description")
        :setAutoSize(false)
        :setText([[Click the button below and then follow the instructions on the computer.
Please don't worry. The music will continue playing even with the computer awaiting input.]])
        :setSize(57, 3)
        :setPosition(1, "{ui_downloader_title.height + 1}")

    downloader.input = screen:addButton("ui_downloader_input")
        :setSize("{parent.width}", 1)
        :setPosition(0, downloader.description.height + downloader.title.height)
        :setText("Enter URL")
        :setColor("{self.clicked and colors.white or colors.black}", "{self.clicked and colors.gray or colors.lightGray}")
        :onClick(function()
            local defaultText = "\nhttps://example.com/file.dfpwm"
            if downloader.input:getText() ~= "Enter URL" and downloader.input:getText() ~= defaultText then
                defaultText = downloader.input:getText()
            end

            self.tab = multishell.launch(shellAdditions.createShellEnv("rom/programs"), "rom/programs/shell.lua", "Boombox/terminal/keyboard.lua",
                "\"" .. "Please enter the URL of the file you wish to\n-- download. The URL must point to a 'dfpwm' file.\n-- Due to advanced technology, we can now also\n-- download directly from youtube videos. This is an exception to the 'dfpwm' rule" .. "\""
            )
            downloader.log.info("Launching downloader editor. Tab id: " .. self.tab)
            shell.switchTab(self.tab)
        end)
        :listenEvent("terminal_input", true)
        :listenEvent("boombox_download_error", true)
        :listenEvent("boombox_download_info", true)

    downloader.info = screen:addLabel("ui_downloader_info")
        :setSize("{parent.width}", 3)
        :setPosition(1, "{ui_downloader_input.y + ui_downloader_input.height + 1}")
        :setText("")


    function downloader.input:handleEvent(event, data)
        -- downloader.log.info("EventReceived: " .. event .. " Data: " .. pretty.pretty(data))
        if event == "terminal_input" then
            downloader.input:setText(data)
            os.queueEvent("boombox_request", "file", data)
            os.queueEvent("boombox_request", "info")
            self.tab = 1 -- switch back to our tab.
            shell.switchTab(self.tab)
        end

        if event == "boombox_download_error" or event == "boombox_download_info" then
            downloader.info:setText(data)

            if not string.find(data, "youtube:") then
                downloader.button:setColor("{self.clicked and colors.white or colors.black}", "{self.clicked and colors.gray or colors.lightGray}")
            end
        end
    end

    downloader.button = screen:addButton("ui_downloader_button")
        :setText("Download")
        :setSize("{parent.width}", 1)
        :setPosition(1, "{ui_downloader_info.y + ui_downloader_info.height + 1}")
        :setColor("{colors.gray}", "{colors.black}")

    downloader.retry = screen:addCheckbox("ui_downloader_retry")
        :setText("Auto retry?: [ ] (0/1)")
        :setCheckedText("Auto retry?: [x] (0/3)")
        :setSize("{parent.width}", 1)
        :setPosition(1, "{ui_downloader_button.y + ui_downloader_button.height + 1}")
        :onClick(function()
            os.queueEvent("boombox_request", "retry", not downloader.retry:getChecked())
        end)
        :listenEvent("boombox_retry")
        :listenEvent("boombox_request")

    function downloader.retry:handleEvent(event, data)
        if event == "boombox_retry" then
            downloader.retry:setText("Auto retry?: [ ] (" .. data .. "/1)")
            downloader.retry:setCheckedText("Auto retry?: [x] (" .. data .. "/3)")
        end
        if event == "boombox_request" then
            if data == "info" then
                downloader.retry
                    :setText("Auto retry?: [ ] (0/1)")
                    :setCheckedText("Auto retry?: [x] (0/3)")
            end
        end
    end

    downloader.network = multishell.launch(shellAdditions.createShellEnv("rom/programs"), "rom/programs/shell.lua", "Boombox/network/file.lua")
    multishell.setTitle(downloader.network, "Boombox Downloader")
end


function downloader.download()
    downloader.log.info("Downloading file...")
    downloader.screen:setVisible(true)
end


return function()
	return setmetatable({}, downloader)
end
