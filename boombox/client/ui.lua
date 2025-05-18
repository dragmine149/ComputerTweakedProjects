local basalt = require("basalt")
-- local audio = require("audio")

local ui_modules = {
    welcome = require("ui.welcome")(),
    folders = require("ui.folders")(),
    playing = require("ui.playing")(),
    -- settings = require("ui.settings")(),
    queue = require("ui.queue")(),
    downloader = require("ui.downloader")()
}

local ui = {
    screens = {
        tabs = {},
        count = 0
    },
    current_tab = {
        name = "welcome",
        id = 1,
        transition = false
    },
    playlist_controls = {}
}

local function ui_change_tab(tab, id)
    if ui.current_tab.transition then return end
    basalt.LOGGER.info("Switch to tab: " .. tostring(tab))
    ui.screens.tabs[ui.current_tab.name]:setColor(colors.black, colors.lightGray)
    local old_tab = ui.current_tab.id
    ui.current_tab = {
        name = tab,
        id = id
    }
    ui.screens.tabs[ui.current_tab.name]:setColor(colors.white, colors.gray)
    if old_tab ~= id then
        ui.switchScreen(id)
    end
end

function ui.new_tab(tab_name, previous_name, tab_id, callback)
    local tab = ui.frame:addButton(tab_name)
        :setIgnoreOffset(true)
        :setText(tab_name:gsub("^%l", string.upper))
        :setSize(#tab_name + 2, 1)
        :setColor(colors.black, colors.lightGray)
        :setY(2)
        :onClick(function(self)
            ui_change_tab(self.name, tab_id)
            if callback then callback(self) end
        end)

    if previous_name then
        tab:setX("{" .. previous_name .. ".x + " .. previous_name .. ".width}")
    else
        tab:setX(2)
    end

    return tab
end


function ui:Status()
    ui.status = ui.frame:addLabel()
        :setAutoSize(false)
        :setSize(50, 3)
        :setPosition(1, "{parent.height - 1}")
        :setForeground(colors.black)
        :setText("Status: Chilling out to the beats of electronic noise.")
        :setIgnoreOffset(true)
end

function ui.UpdateStatus(text)
    basalt.LOGGER.info("Updating status to: " .. text)
    ui.status:setText("Status: " .. text)
end


function ui.init()
    basalt.LOGGER.setEnabled(true)
    basalt.LOGGER.setLogToFile(true)
    ui.frame = basalt.getMainFrame()

    basalt.LOGGER.info("Initializing UI")

    ui.restart = ui.frame:addButton()
        :setText("Restart")
        :setPosition("{parent.x + parent.width - 10}", "{parent.y + parent.height - 2}")
        :setIgnoreOffset(true)
        :onClick(function() os.reboot() end)

    ui.frame:addLabel()
        :setText("Boombox")
        :setPosition("{parent.width / 2 - self.width / 2}", 1)
        :setIgnoreOffset(true)

    ui_modules.welcome(ui.create_Screen(1), basalt.LOGGER)
    ui_modules.folders(ui.create_Screen(2), basalt.LOGGER, {
        enqueue = function(file)
            ui_modules.queue:enqueue(file)
        end,
        download = function()
            ui.current_tab.name = "Downloader"
            ui.current_tab.id = 101
            ui.switchScreen(101)
            ui_modules.downloader:download()
        end
    })
    ui_modules.playing(ui.create_Screen(3), basalt.LOGGER, {
        queue = {
            toggleShuffle = function()
                return ui_modules.queue:toggleShuffle()
            end,
            shuffleStatus = function()
                return ui_modules.queue:shuffleStatus()
            end,
            next = function()
                return ui_modules.queue:next()
            end,
            previous = function()
                return ui_modules.queue:previous()
            end
        }
    })
    ui_modules.queue(ui.create_Screen(4), basalt.LOGGER)
    ui_modules.downloader(ui.create_Screen(101), basalt.LOGGER)

    ui.screens.tabs = {
        welcome = ui.new_tab("welcome", nil, 1),
        files = ui.new_tab("files", "welcome", 2),
        playing = ui.new_tab("playing", "files", 3),
        queue = ui.new_tab("queue", "playing", 4, function() ui_modules.queue:update() end),
        settings = ui.new_tab("settings", "queue", 5)
    }
    ui.screens.tabs.welcome:setColor(colors.white, colors.gray)

    ui_change_tab("files", 2)
    -- ui_change_tab("playing", 3)
    -- ui_change_tab("queue", 4)
end

function ui.create_Screen(index)
    local screen = ui.frame:addFrame()
        :setSize("{parent.width - 2}", "{parent.height - 6}")
        :setColor(colors.black, colors.white)

    screen:setPosition(function()
        return (ui.frame:getWidth() * (index - 1)) + 2
    end, 4)

    ui.screens[index] = screen
    ui.screens.count = index
    return screen
end

function ui.switchScreen(tab_index)
    ui.current_tab.transition = true
    basalt.LOGGER.info("Switching tabs... (" .. tab_index .. ")")
    ui.frame:animate()
        :moveOffset((tab_index - 1) * ui.frame:getWidth(), 0, 0.5)
        :start()
        :onComplete(function()
            ui.current_tab.transition = false
        end)
end

function ui.render()
    basalt.LOGGER.info("Rendering UI...")
    basalt.run()
end


return ui
