local welcome = {}
welcome.__index = welcome

---comment
---@param notices string
---@param message string
---@return string message
local function addNote(notices, message)
    if notices:len() == 0 then
        notices = message
    else
        notices = notices .. "\n\n\n" .. message
    end
    return notices
end

welcome.__call = function(self, screen, log)
    local text = [[Welcome to Boombox!

A program made to be able to download music, queue music and play music just like a normal music player would. With the added benefit of playing on all speakers at once.

With an amazing UI powered by Basalt, you can easily navigate through your music collection and control your music playback.
]]

    local notices = ""
    local external = { peripheral.find("drive") }
    local files = fs.list(".")
    local driveMounted = false
    for _, file in pairs(files) do
        if file:sub(1, 4) == 'disk' then
            driveMounted = true
            break
        end
    end

    if #external == 0 or not driveMounted then
        notices = addNote(notices, "Note: No floppy disks where found, although it is still possible to use the internal storage, you will be limited. It is recomened to have at least one drive.")
    else
        local space = fs.getCapacity("disk/")
        -- if space < 1024 * 1024 then
        if space < 1000 * 1000 * 10 then
            notices = addNote(notices, "\n\n\nNote: The disk is too small to store music, it is recomened to have at least 10MB of storage per disk.")
        end
    end

    log.debug(tostring(term.current().setTextScale))
    if not term.current().setTextScale then
        notices = addNote(notices, "Note: This is running on a computer. It is recomeneded to use a monitor instead.")
    end

    screen:addLabel("welcome_description")
        :setAutoSize(false)
        :setSize("{parent.width}", "{parent.height - 5}")
        :setPosition(1, 1)
        :setForeground(colors.black)
        :setText(text)

    screen:addLabel("welcome_notice")
        :setAutoSize(false)
        :setSize("{parent.width}", 5)
        :setPosition(1, "{welcome_description.height}")
        :setForeground(colors.red)
        :setText(notices)

    return self
end

function welcome:name() return "Welcome" end

return function()
	return setmetatable({}, welcome)
end
