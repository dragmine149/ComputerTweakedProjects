local folders = {
    selected_item = false
}
folders.__index = folders

folders.__call = function(self, screen, log, functions)
    folders.log = log

    folders.list = screen:addList("ui_folders_list")
        :setPosition(1, 2)
        :setSize("{parent.width - 1}", "{parent.height - 5}")

    screen:addButton("ui_folders_refresh")
        :setPosition("{parent.width - self.width + 1}", 1)
        :setText("refresh")
        :setColor("{self.clicked and colors.white or colors.black}", "{self.clicked and colors.gray or colors.lightGray}")
        :setSize(9, 1)
        :onClick(function() folders:refresh() end)

    folders.dropdown = screen:addDropdown("ui_folders_dropdown")
        :setPosition("{ui_folders_refresh.x - self.width}", 1)
        :setZ(10)
        :setSize(15, 1)
        :onSelect(function(dropSelf, index, item)
            log.info("Selected: " .. tonumber(index) .. " : " .. tostring(item))
            self:populate(item.item)
        end)
        :setColor(colors.white, colors.gray)
        :setDropdownHeight(10)

    folders.scroll = screen:addScrollbar("ui_folders_scroll")
        :setSize(1, "{ui_folders_list.height}")
        :setPosition("{ui_folders_list.width + 1}", 2)
        :setZ(10)
        :attach(folders.list, {
            property = "offset",
            min = 0,
            max = function()
                return #folders.list.get("items")
            end
        })

    screen:addLabel("ui_folders_label")
        :setText("Folder: ")
        :setPosition("{ui_folders_dropdown.x - self.width}", 1)

    folders.download = screen:addButton("ui_folders_download")
        :setText(" Download file")
        :setSize(16, 3)
        :setPosition(0, "{parent.height - 2}")
        :onClick(function()
            folders.log.info("Downloading file...")
            functions.download()
        end)
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")

    folders.queue_all = screen:addButton("ui_folders_queue_all")
        :setText("Add All to Queue")
        :setSize(18, 1)
        :setPosition("{parent.width - self.width + 1}", "{parent.height}")
        :onClick(function()
            folders.log.info("Add All to Queue button clicked")
            folders.log.info("Adding all items to queue")
            -- basalt.LOGGER.info(textutils.serialize(ui.playlist.get("items")))

            for _, item in ipairs(folders.list:getItems()) do
                functions.enqueue(item.item)
            end

            -- for _, item in ipairs(ui.playlist.get("items")) do
            --     basalt.LOGGER.info("Added " .. item.text .. " to queue")
            --     audio.enqueue(item.item)
            -- end
            -- ui.UpdateStatus("Added folder (" .. dropdown:getSelectedItems()[1].text .. ") to Queue")
        end)
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")

        folders.queue = screen:addButton("ui_folders_queue")
            :setText("Add to Queue")
            -- :setPosition("{ui_folders_queue_all.x - self.width - 1}", "{parent.height - 2}")
            :setPosition("{parent.width - self.width + 1}", "{parent.height - 2}")
            :setSize(18, 1)
            :onClick(function()
                if not folders.selected_item then return end
                folders.log.info("Add to Queue button clicked")
                functions.enqueue(folders.list:getSelectedItem().item)
                -- local selected = ui.playlist:getSelectedItem()
                -- if selected == nil then
                --     basalt.LOGGER.error("No item selected")
                --     return
                -- end
                -- basalt.LOGGER.info("Added " .. selected.item .. " to queue")
                -- audio.enqueue(selected.item)
                -- ui.UpdateStatus("Added file (" .. selected.item .. ") to Queue")
            end)
            :setBackground(colors.gray)


    -- UI options can come later, for now we'll just have to get them to use the command line.
    -- folders.options = {}

    -- folders.options.button = screen:addButton("ui_folders_options_btn")
    --     :setText("Options")
    --     :setSize(9, 3)
    --     :setPosition("{parent.width - self.width + 1}", "{parent.height - 2}")
    --     :setBackground("{self.clicked and colors.gray or colors.lightGray}")
    --     :onClick(function()
    --         folders.log.info("Options button clicked")
    --     end)

    -- folders.options.ui = screen:addLabel("ui_folder_options_ui")
    --     :setText("")
    --     :setAutoSize(false)
    --     :setSize("{parent.width / 2}", "{parent.height / 2}")
    --     :setPosition("{(parent.width / 2) - (self.width / 2)}", 1)
    --     :setBackgroundEnabled(true)
    --     :setBackground(colors.lightBlue)
    --     :setZ(100)

    -- folders.options.title = screen:addLabel("ui_folder_options_title")
    --     :setText("Test Options")
    --     :setPosition("{ui_folder_options_ui.x + ui_folder_options_ui.width / 2 - self.width / 2}", 1)
    --     -- :setSize(7, 1)
    --     :setBackground(colors.black)

    self:refresh()
end

---Returns information about the drives on the network.
---@return table The drive information, containing the mount path, disk label and peripheral path.
local function getMounts()
    -- we can't do a normal `.find` filter as that would elimante the peripheral wrap path which could be important later.
    local peripherals = peripheral.getNames()
    local mounts = {}

    for _, name in ipairs(peripherals) do
        local driveType = peripheral.getType(name)
        ---@type ccTweaked.peripheral.Drive
        if driveType == "drive" then -- everything else is not our business.
            local drive = peripheral.wrap(name)
            if drive and drive.hasData() then
                folders.log.info(drive.getMountPath())
                mounts[drive.getMountPath()] = {
                    network = name,
                    label = drive.getDiskLabel() or drive.getMountPath()
                }
            end
        end
    end

    return mounts
end

---Update the dropdown ui to include new changes to the file system if any has happened. (This includes new drives being added and removed from the network)
function folders:refresh()
    local previousSelected = folders.dropdown:getSelectedItem()

    folders.__mounts = getMounts()
    folders.dropdown:clear()

    ---Returns the state of the provided file.
    ---@param folder string
    ---@param file string
    ---@return integer result (0 = file, 1 = audio, 2 = dir)
    local function check_for_audio(folder, file)
        if file:match("[^/]*.dfpwm$") then return 1 end -- ignore files which are not .dfpwm files ("what is this file?")
        if not fs.isDir(fs.combine(folder, file)) then return 0 end -- ignore files which are not directories
        return 2
    end

    ---Process the folder and its contents to see if we should add it to the ui or not.
    ---@param item string
    local function process_item(item)
        if not fs.isDir(item) then return end -- files are useless here.
        if item == 'rom' then return end -- this is read only stuff
        if item == 'boombox' then return end -- hey. don't touch our stuff.

        local files = fs.list(item)
        local hasAudio = false
        while #files > 0 and not hasAudio do
            -- folders.log.info(textutils.serialise(files))

            local subfile = files[1]
            table.remove(files, 1)

            local result = check_for_audio(item, subfile)
            if result == 1 then
                hasAudio = true
            elseif result == 2 then
                table.insert(files, fs.combine(item, subfile))
            end

        end

        if not hasAudio then return end -- No audio files, so not worth it to show it.

        local text = item
        local mounted = folders.__mounts[item]
        if mounted then
            folders.log.info("Mounted drive: " .. tostring(mounted.label) .. " at " .. item)
            text = mounted.label .. ' (' .. item .. ')' -- by default, include both label and folder
            if mounted.label == item then text = item end -- but remove the label (and just show the folder) if they turn out to be the same.
        end

        local selected = #folders.dropdown.get("items") == 0
        if previousSelected then
            folders.log.debug("previousSelected.item: '" .. tostring(previousSelected.item) .. "' Using that instead.")
            selected = previousSelected.item == item
        end

        folders.dropdown:addItem({ text = text, item = item, selected = selected })
        if selected then
            folders:populate(item)
        end
    end

    local root = fs.list('.')
    for _, item in ipairs(root) do
        process_item(item)
    end
end

function folders:updateButtons()
    folders.queue:setBackground("{self.clicked and colors.gray or colors.lightGray}")
    folders.selected_item = true
end

---Populate the ui with different files that are playable in that folder.
---@param folder string The folder (fs) to load.
function folders:populate(folder)
    local files = fs.list(folder)
    ---comment
    ---@param file string
    local function processFile(file)
        folders.log.info("Processing file: '" .. fs.combine(folder, file) .. "'. Dir: " .. tostring(fs.isDir(file)))
        if fs.isDir(fs.combine(folder, file)) then
            -- process the directories.
            local subfolder = fs.combine(folder, file)
            local subfiles = fs.list(subfolder)
            folders.log.info("Populating folder: '" .. subfolder .. "' files: " .. #subfiles)
            folders.log.info(textutils.serialize(subfiles))
            for _, subfile in pairs(subfiles) do
                folders.log.info("Adding '" .. fs.combine(file, subfile) .. "' to the table")
                table.insert(files, fs.combine(file, subfile))
            end
            return
        end
        if not file:match("[^/]*.dfpwm$") then return end -- ignore files which are not .dfpwm files ("what is this file?")

        folders.log.info("Adding " .. fs.combine(folder, file))
        folders.list:addItem({
            text = file, item = fs.combine(folder, file), callback = function()
                folders.log.info("Clicked file: " .. file)
                folders:updateButtons()
            end
        })
    end

    folders.list:clear()
    folders.queue:setBackground(colors.gray)
    folders.selected_item = false

    folders.log.info("Populating folder: '" .. folder .. "' files: " .. #files)

    while #files > 0 do
        processFile(files[1])
        table.remove(files, 1)
    end

    folders.scroll:setValue(0)
        :setMin(0)
        :setMax(#folders.list.get("items"))
        :updateAttachedElement()
end


function folders:option_ui()

end

return function()
	return setmetatable({}, folders)
end
