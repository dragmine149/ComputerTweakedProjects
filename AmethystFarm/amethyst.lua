-- print(turtle.inspectUp())
-- local b, d = turtle.inspectUp()
-- print(textutils.serialise(d))


-- print(textutils.serialise(peripheral.getNames()))
-- turtle.drop()

local function findAndDrop()
    local direction = peripheral.getNames()[1]
    if direction == "top" then turtle.dropUp() end
    if direction == "bottom" then turtle.dropDown() end
    if direction == "front" then turtle.drop() end
    if direction == "left" then
        turtle.turnLeft()
        turtle.drop()
        turtle.turnRight()
    end
    if direction == "right" then
        turtle.turnRight()
        turtle.drop()
        turtle.turnLeft()
    end
    if direction == "back" then
        turtle.turnRight()
        turtle.turnRight()
        turtle.drop()
        turtle.turnLeft()
        turtle.turnLeft()
    end
end


local function valid_block(inspect_function)
    local block, data = inspect_function()
    if not block then return false end
    if data.name ~= "minecraft:amethyst_cluster" then return false end
    return true
end

while true do
    print("Checking...")
    if valid_block(turtle.inspectUp) then turtle.digUp() end
    if valid_block(turtle.inspectDown) then turtle.digDown() end

    for _ = 1, 4 do
        if valid_block(turtle.inspect) then
            turtle.dig()
        end
        turtle.turnLeft()
    end

    findAndDrop()
    print("Sleeping")
    os.sleep(60) -- don't need it to check THAT often.
end
