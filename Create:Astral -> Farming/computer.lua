-- local basalt = require("basalt")
local basalt = require("Basalt2.src.main")
---@class Computer
---@field turtles table
---@field modem ccTweaked.peripheral.Modem
local computer = {
    turtles = {},
}

function computer.init()
    print("Hello... Hello Computer.")

    -- got to setup the peripheral
    computer.modem = peripheral.find("modem", function(name, modem)
      return modem.isWireless()
    end)
    if not computer.modem then
      error("No wireless modem found")
    end

    -- Check for required dirs
    if fs.exists("/Farming/") then fs.makeDir("/Farming/") end
    if fs.exists("/Farming/turtles.txt") then
      -- if by chance, we already have a database of turtles then import them.
      local turtleList = fs.open("/Farming/turtles.txt", "r")
      if turtleList then
        local turtleData = turtleList.readAll()
        turtleList.close()
        if turtleData then
          computer.turtles = textutils.unserialize(turtleData)
        end
      end
    end

end

function computer.listener()
  --- process events
  while true do
      local e, p1, p2, p3, p4, p5 = os.pullEvent()
      if e == "modem_message" and p2 == CHANNEL_SETUP then
          local channels = computer.addTurtle(p4)
          computer.modem.transmit(p2, p3, channels)
      end
  end
end

--- @param message {message: string, id: number, label: string} Message data from turtle
function computer.addTurtle(message)
  if message.message == "channels" then
    if computer.turtles[message.id] then
      return computer.turtles[message.id]
    end

    computer.turtles[message.id] = {
        label = message.label,
        send_channel = 10000 + #computer.turtles,
        reply_channel = 10000 + #computer.turtles,
    }

    local turtleList = fs.open("/Farming/turtles.txt", "w")
    if turtleList then
        turtleList.writeLine(textutils.serialize(computer.turtles))
        turtleList.close()
    end

    return computer.turtles[message.id]
  end
end

function computer.ui()
    local menu = basalt.getMainFrame()

    local title = menu:addLabel()
    title:setPosition(5, 5)
    title:setText("Farming Computer")

    local turtles = menu:addFrame()
    turtles:setPosition(5, 50)
    turtles:setSize(20, 10)
    turtles:setBackground(colors.gray)

    local turtleList = menu:addList()
    for id, turtle in pairs(computer.turtles) do
        turtleList:addItem(id)
    end

end
