local dir = package.path
local path = fs.combine(dir, "init.lua")

---@type ccTweaked.peripheral.Monitor
local monitor = peripheral.find("monitor")
if monitor then
    print("Found monitor and displaying on monitor")
    term.redirect(monitor)
end

print("Loading UI")
local ui = require("/Boombox.ui")

ui.init()
ui.render()
