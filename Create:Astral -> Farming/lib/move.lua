local move = {}
---@enum move.ROTATION
move.ROTATION = {
    NORTH = 0,
    EAST = 1,
    SOUTH = 2,
    WEST = 3
}

---@class GPS_Position
---@field x number
---@field y number
---@field z number

---@return GPS_Position
function move.localgps()
    local pos = gps.locate(2, true)
    if not pos then
        error("GPS not available")
    end
    return {x = pos[1], y = pos[2], z = pos[3]}
end

---Get the direction the turtle is currently facing.
---@return move.ROTATION rotation
function move.facing()
    ---Internal function for getting the direction based on movement maths.
    ---@param dx number
    ---@param dz number
    ---@return move.ROTATION rotation
    local function translate_dxz(dx, dz)
       if dx == 1 then
           return move.ROTATION.WEST
       elseif dx == -1 then
           return move.ROTATION.EAST
       elseif dz == 1 then
           return move.ROTATION.SOUTH
       elseif dz == -1 then
           return move.ROTATION.NORTH
       end
       return move.ROTATION.NORTH
    end

    -- Do a dance.
    local cur_pos = move.localgps()
    local new_pos = nil
    local a, s, _ = 0, false, nil
    while not s and a < 3 do
        s, _ = turtle.forward()
        if s then
            new_pos = move.localgps()
            turtle.back()
            local dx, dz = new_pos.x - cur_pos.x, new_pos.z - cur_pos.z
            return translate_dxz(dx, dz)
        end
        a = a + 1
        turtle.turnLeft()
    end
    -- assume by default, we face north.
    return move.ROTATION.NORTH
end

---Rotate the turtle so that it is facing the desired ROTATION
---@param direction move.ROTATION The direction to rotate to.
function move.face(direction)
    if direction == move.ROTATION.NORTH then
        turtle.turnLeft()
    elseif direction == move.ROTATION.SOUTH then
        turtle.turnRight()
    elseif direction == move.ROTATION.EAST then
        turtle.turnRight()
        turtle.turnRight()
    elseif direction == move.ROTATION.WEST then
        turtle.turnLeft()
        turtle.turnLeft()
    end
end

function move.move(x, y)
    -- assumption: It's clear.
    for _ = 1, x do if x > 0 then turtle.forward() else turtle.back() end end
    if y > 0 then turtle.turnLeft() else turtle.turnRight() end
    for _ = 1, y do turtle.forward() end
    if y < 0 then turtle.turnLeft() else turtle.turnRight() end
end


function move.pos(end_pos)
    local pos = gps.locate()

    local dx = end_pos.x - pos.x
    local dy = end_pos.y - pos.y
    local dz = end_pos.z - pos.z

end


---Checks around itself to find a block.
---@param target_block string The block to find (as per the return of turtle.inspect().name)
---@return nil|ccTweaked.turtle.inspectInfo block The block information if found.
function move.block(target_block)
    local _, info, found
    local turn = 0
    while not found and turn < 3 do
        _, info = turtle.inspect()
        if info.name == target_block then
            found = true
            break
        end
        turtle.turnRight()
        turn = turn + 1
    end

    if found then
        return info
    end

    error("Block not found")
    return nil
end

function move.blockVertical(target_block, limit)
    limit = limit or 5
    local _, info, notfound
    local height = 0
    while not notfound and height < limit do
        _, info = turtle.inspectUp()
        if info.name ~= target_block then
            notfound = true
            break
        end
        turtle.up()
        height = height + 1
    end

    for i = 1, height do
        turtle.down()
    end

    return height
end

return move
