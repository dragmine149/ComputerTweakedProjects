local communicate = require("Astral -> Farming/communicate")
local calibrate = require("Create:Astral -> Farming.calibrate")
local farm = {
    seed = "minecraft:wheat_seeds"
}

function farm.start()

end

function farm.farm()
    local exists, details = turtle.inspectDown()
    if not exists then
        turtle.down()
        local grassexists, details = turtle.inspectDown()
        if not grassexists then farm.home() end
        if details.tags.type == "minecraft:grass_block" then
            turtle.placeDown()
        end
    end
end

function farm.home()
    -- navigate back to home.
end
