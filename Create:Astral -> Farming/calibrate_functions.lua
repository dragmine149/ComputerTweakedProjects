local log = require("log")
local move = require("move")
local calibrate_functions = {}

function calibrate_functions.jungle_log(position)
    log.info("Calibrating jungle log at position: " .. position)
    move.face(move.ROTATION.NORTH)
    local corners = {
        ["1"] = {
            pos = {
                x = position.x + 1,
                y = position.y,
                z = position.z + 1
            },
            move = {
                x = 1,
                z = 1
            }
        },
        ["2"] = {
            pos = {
                x = position.x + 1,
                y = position.y,
                z = position.z - 1
            },
            move = {
                x = 1,
                z = -1
            }
        },
        ["3"] = {
            pos = {
                x = position.x - 1,
                y = position.y,
                z = position.z + 1
            },
            move = {
                x = -1,
                z = 1
            }
        },
        ["4"] = {
            pos = {
                x = position.x - 1,
                y = position.y,
                z = position.z - 1
            },
            move = {
                x = -1,
                z = -1
            }
        }
    }
    local corner_info = {}
    local chosen = {}

    for i = 1, #corners do
        log.info("Calibrating corner " .. i .. " at position: " .. corners[i].pos.x .. ", " .. corners[i].pos.y .. ", " .. corners[i].pos.z)
        local corner = corners[i]
        move.move(corner.move.x, corner.move.z)

        corner_info[i] = 0
        turtle.down()

        log.info("Calibrating corner depth")
        local s, e = true, nil
        -- Confirm the depth of the tree.
        while s do
            s, e = turtle.down()
            corner_info[i] = corner_info[i] + 1
        end

        log.info("Corner depth calibrated at " .. corner_info[i])
        for i = 1, corner_info[i] do
            turtle.up()
        end

        move.move(corner.move.x * -1, corner.move.z * -1)
    end

    log.info("Trunk corner calibration finished. Processing")

    -- Prefer corners where the maximum depth is possible.
    -- Prefer opposite corners (1, 3) (2, 4)
    -- Prefer corners where least wasted time is possible.

    local maxDepth = math.max(corner_info[1], corner_info[2], corner_info[3], corner_info[4])
    if maxDepth == corner_info[1] and maxDepth == corner_info[3] then
        chosen[#chosen+1] = {
            pos = corners[1],
            depth = maxDepth
        }
        chosen[#chosen+1] = {
            pos = corners[3],
            depth = maxDepth
        }
        return chosen
    elseif maxDepth == corner_info[2] or maxDepth == corner_info[4] then
        chosen[#chosen+1] = {
            pos = corners[2],
            depth = maxDepth
        }
        chosen[#chosen+1] = {
            pos = corners[4],
            depth = maxDepth
        }
        return chosen
    end

    chosen[#chosen+1] = {
        pos = corners[1],
        depth = maxDepth
    }
    chosen[#chosen+1] = {
        pos = corners[2],
        depth = maxDepth
    }
    chosen[#chosen+1] = {
        pos = corners[3],
        depth = maxDepth
    }
    chosen[#chosen+1] = {
        pos = corners[4],
        depth = maxDepth
    }
    return chosen
end

return calibrate_functions
