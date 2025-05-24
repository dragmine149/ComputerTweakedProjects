local switch = require("/Boombox.utils.switch")
local queue = {
    queue = {},
    shuffled_queue = {},
    random_history = {},
    position = 1,
    confirm = {
        item = "",
        time = 0,
    }
}
queue.__index = queue
queue.__call = function(self, screen, log)
    queue.log = log

    queue.list = screen:addList("ui_queue_list")
        :setPosition(1, 2)
        :setSize("{parent.width - 1}", "{parent.height - 5}")
        :onSelect(function ()
            queue.play_now:setBackground("{self.clicked and colors.gray or colors.lightGray}")
        end)

    queue.scroll = screen:addScrollbar("ui_queue_scroll")
        :setPosition("{ui_queue_list.width + 1}", 2)
        :setSize(1, "{ui_queue_list.height}")
        :setZ(10)
        :attach(queue.list, {
            property = "offset",
            min = 0,
            max = function () return #queue.list.get("items") end
        })

    queue.remove = screen:addButton("ui_queue_remove")
        :setPosition(0, "{parent.height - 2}")
        :setText(" Remove from queue")
        :setSize(20, 3)
        :onClick(function ()
            local item = queue.list:getSelectedItem()
            queue.log.info("Removing item (" .. item.item .. ") from queue")
            for i, v in ipairs(self.queue) do
                queue.log.info("Scanning item (" .. v .. ")")
                if v == item.item then
                    table.remove(self.queue, i)
                    queue:update()
                    break
                end
            end
        end)
        :setBackground("{self.clicked and colors.gray or colors.lightGray}")

    queue.play_now = screen:addButton("ui_queue_play_now")
        :setText(" Play now")
        :setPosition("{parent.width - 9}", "{parent.height - 2}")
        :setSize(10, 3)
        :onClick(function (playself)
            if playself:getBackground() == colors.gray then return end
            local item = queue.list:getSelectedItem()
            queue.log.info(textutils.serialise(item))
            os.queueEvent("speaker_play_now", item.item)
        end)
        :setBackground(colors.gray)
end
---@enum ShuffleType
queue.SHUFFLE_TYPE = {
    NONE = 1,
    RANDOM = 2,
    NO_REPEAT = 3
}

function queue.shuffleStatus()
    local shuffle = settings.get("shuffle", queue.SHUFFLE_TYPE.NONE)
    local shuffleSwitch = switch()
        :case(queue.SHUFFLE_TYPE.NONE, function()
            return "None"
        end)
        :case(queue.SHUFFLE_TYPE.RANDOM, function()
            return "Random"
        end)
        :case(queue.SHUFFLE_TYPE.NO_REPEAT, function()
            return "No Repeat"
        end)
        :default(function()
            return "Unknown"
        end)

    return shuffleSwitch(shuffle)
end

function queue:toggleShuffle()
    local shuffle = settings.get("shuffle", queue.SHUFFLE_TYPE.NONE)
    if shuffle == queue.SHUFFLE_TYPE.NONE then
        settings.set("shuffle", queue.SHUFFLE_TYPE.RANDOM)
    elseif shuffle == queue.SHUFFLE_TYPE.RANDOM then
        settings.set("shuffle", queue.SHUFFLE_TYPE.NO_REPEAT)
    elseif shuffle == queue.SHUFFLE_TYPE.NO_REPEAT then
        settings.set("shuffle", queue.SHUFFLE_TYPE.NONE)
    end
end

local function copy(obj)
    local new = {}
    for k,v in pairs(obj)do
        new[k] = v
    end
    return new
end

function queue:next()
    local shuffle = settings.get("shuffle", queue.SHUFFLE_TYPE.NONE)
    local shuffleSwitch = switch()
        :case(queue.SHUFFLE_TYPE.NONE, function()
            self.position = self.position + 1
            return self.queue[self.position]
        end)
        :case(queue.SHUFFLE_TYPE.RANDOM, function()
            self.position = math.random(#self.queue)
            self.random_history[#self.random_history + 1] = self.position
            return self.queue[self.position]
        end)
        :case(queue.SHUFFLE_TYPE.NO_REPEAT, function()
            if #self.shuffled_queue == # self.queue then self.shuffled_queue = {} end
            local pos = 0
            while pos < 0 do
                pos = math.random(#self.queue)
                for _, v in ipairs(self.shuffled_queue) do
                    if v == pos then pos = 0 end
                end
                if pos > 0 then
                    self.shuffled_queue[#self.shuffled_queue + 1] = pos
                    return self.queue[pos]
                end
            end
        end)
    return shuffleSwitch(shuffle)
end

function queue:previous()
    local shuffle = settings.get("shuffle", queue.SHUFFLE_TYPE.NONE)
    local shuffleSwitch = switch()
        :case(queue.SHUFFLE_TYPE.NONE, function()
            self.position = self.position - 1
            return self.queue[self.position]
        end)
        :case(queue.SHUFFLE_TYPE.RANDOM, function()
            self.position = table.remove(self.random_history)
            return self.queue[self.position]
        end)
        :case(queue.SHUFFLE_TYPE.NO_REPEAT, function()
            return self.queue[table.remove(self.shuffled_queue)]
        end)
    return shuffleSwitch(shuffle)
end

function queue.enqueue(self, item)
    queue.log.info("Added " .. item .. " to queue")
    table.insert(self.queue, item)
    os.queueEvent("speaker_play_empty", item)
end

function queue:update()
    queue.log.info("Updating UI queue")
    queue.list:clear()
    queue.play_now:setBackground(colors.gray)
    queue.log.info(textutils.serialize(self.queue))
    for _, item in ipairs(self.queue) do
        queue.log.info("Adding " .. tostring(item) .. "to ui queue")
        local selected = item == self.queue[self.position]
        queue.list:addItem({
            text = item,
            item = item,
            selected = selected
        })
        if selected then
            queue.play_now:setBackground("{self.clicked and colors.gray or colors.lightGray}")
        end
    end
    queue.scroll:setValue(0)
        :setMin(0)
        :setMax(#queue.list:getItems())
        :updateAttachedElement()
end

return function()
    return setmetatable({}, queue)
end
