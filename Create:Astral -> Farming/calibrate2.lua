local move = require("lib.move")
local log = require("lib.log")
local calibrate_functions = require("calibrate_functions")
local calibrate = {
    farm_lookup = {
        ["minecraft:cocoa_beans"] = "minecraft:jungle_log"
    },
    farm_functions = {
        ["minecraft:jungle_log"] = calibrate_functions.jungle_log
    },
    facing = nil
}

local function mergeTables(tableA, tableB)
    for i=1, #tableB do
        tableA[#tableA + 1] = tableB[i]
    end
    return tableA
end

local function addRadius(position, radius)
    local x, y, z = position.x, position.y, position.z
    local positions = {}
    for dx = -radius, radius do
        for dz = -radius, radius do
            local new_pos = Vector(x + dx, y, z + dz)
            positions[#positions + 1] = new_pos
        end
    end
    return positions
end

---Calibrate the turtle to the farm.
---@param type calibrate.farm_lookup.key The minecraft block identifier of the item that you want to harvest.
---@param radius number How many blocks the turtle will check for around the last block for more farm lands. Default of 5, limit of 10.
function calibrate.farm(type, radius)
    radius = radius or 5
    radius = math.min(radius, 10)

    local positions = {}
    local yetSearched = {}
    log.info("Calibrating farm for " .. type .. "(radius " .. radius .. ")")
    local farm_block = calibrate.farm_lookup[type]
    -- Assumption: Nothing is weird and we farm from above.
    local current_pos = move.localgps()
    yetSearched[0] = Vector(current_pos.x, current_pos.y, current_pos.z)
    yetSearched = mergeTables(yetSearched, addRadius(current_pos, radius))

    log.info("Starting search")

    while #yetSearched > 0 do
        local pos = table.remove(yetSearched, 1)
        log.info("Checking position " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)

        local block, info = turtle.inspectDown()

        if block then
            if info.name == block then
                log.info("Found farm block at " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
                local farm_positions = calibrate.farm_functions[farm_block](pos)
                positions = mergeTables(positions, farm_positions)
                yetSearched = mergeTables(yetSearched, addRadius(pos, radius))
            end
        end
    end

    return positions
end

return calibrate
