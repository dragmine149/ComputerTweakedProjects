local calibrate = require("calibrate")
local move = require("lib.move")
local cocoa = {
    positions = {}
}

function cocoa.init()
    cocoa.positions = calibrate.positions("cocoa")
end

local function turn(dir)
    if dir == -1 then
        turtle.turnLeft()
    else
        turtle.turnRight()
    end
end

-- Assumption: We are in a corner, in front in cocoa and left/right is also cocoa.
function cocoa.setupCorner()
    -- Dir: Left/right of the cocoa. -1 = left, 1 = right.
    if move.block("minecraft:cocoa_beans") == nil then
        error("No cocoa beans found. Can't farm cocoa")
    end

    print("Finding cocoa beans...")

    local dir = 1 -- default to block on right.
    turtle.turnLeft()
    local block, info = turtle.inspect()
    -- if block on left, store -1 else 1 (default)
    if block then dir = -1 end
    turtle.turnRight()

    print("Found cocoa beans!")

    print("Getting tree height")
    local height = move.blockVertical("minecraft:cocoa_beans", 5)
    if height == nil then
        error("No cocoa beans found. Can't farm cocoa")
    end

    print("Tree height:", height)

    print("Storing tree")

    cocoa.positions[#cocoa.positions + 1] = {
        x = info.x,
        y = info.y,
        z = info.z,
        dir = dir,
        height = height
    }
end


function cocoa.setupTree()
    print("Setting up tree")
    cocoa.setupCorner()
    print("Corner 1 completed, moving to corner 2")
    turtle.dig()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.turnRight()
    turtle.place()
    turn(cocoa.positions[#cocoa.positions].dir * -1)
    turtle.dig()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.turnRight()
    turtle.place()
    turn(cocoa.positions[#cocoa.positions].dir * -1)
    print("Starting corner 2")
    cocoa.setupCorner()
    print("Tree completed")
end
