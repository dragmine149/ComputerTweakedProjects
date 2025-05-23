local switch = require("/Boombox.utils.switch")
local log = require("/Boombox.utils.log")

local file = {}

---Request a server with retry support.
---@param url string The server to ping.
---@param headers any
---@param binary any
---@return string|nil
local function request(url, headers, binary)
    local valid, reason = http.checkURL(url)
    if not valid then
        log.error("Invalid url: " .. reason)
        os.queueEvent("boombox_download_error", reason)
        return
    end
    log.info("Requesting " .. url)
    local response, message, failed

    file.retry = 2
    if file.retryEnabled then file.retry = 0 end

    -- log.info(response)
    log.info("retry: " .. tostring(file.retry))
    while not response and file.retry < 3 do
        log.debug("Requesting: " .. url)
        -- log.info(response)
        log.info("retry: " .. tostring(file.retry) .. ", enabled: " .. tostring(file.retryEnabled))

        response, message, failed = http.get(url, headers, binary)
        log.info("Http fetched! " .. tostring(response ~= nil))
        if response then
            local data = response.readAll()
            response.close()
            os.sleep(2)
            log.info("Returning data")
            -- log.info('Received: '.. tostring(data))
            return data
        end

        if message then
            log.error(message)
        end

        if failed then
            local failedData = failed.readAll()
            failed.close()
            log.info('Failed: ' .. tostring(failedData))
        end

        file.retry = file.retry + 1
        os.queueEvent("boombox_retry", file.retry)
        os.sleep(2) -- take a short 2 second nap.
    end
    log.info("Completed while loop.")

    -- return response
end

function file.new()
    file.__path = ""
    file.storage = ""
    file.__data = {}
    file.__info = {}
    file.retry = 0
    file.retryEnabled = false

    file:listen()
end

function file:getInfo()
    if self.__yt then
        log.info("retry: " .. tostring(file.retry) .. ", enabled: " .. tostring(file.retryEnabled))

        local response = request("https://ytdlp.online/stream?command=--get-title%20--skip-download%20--xff%20us%20" .. self.__path)
        log.info(response)
        if not response then
            log.error("Error in response stream!")
            os.queueEvent("boombox_download_error", self.__path)
            return
        end
        file.__info.title = response:match("\n.-\n(data: (.+))")local title = nil
        for line in response:gmatch("[^\r\n]+") do
            if line:match("^data:") then
                if title then
                    title = line:match("^data:%s*(.-)$")
                    break
                else
                    title = true
                end
            end
        end
        file.__info.title = title
        os.queueEvent("boombox_download_info", file.__info.title)
        return
    end
    -- assume title is in the file name.
    local file_name = self.__path:match("([^/]+)%.");
    file.__info.title = file_name

    os.queueEvent("boombox_download_info", file.__info.title)
end

function file:download()
    log.info(tostring(file.storage))
    log.info(tostring(file.__info.title))

    local path = self.__path
    if self.__yt then
        path = "https://boombox-server.dragmine149.workers.dev/?video=" .. self.__path
    end

    log.info("Attempting to download: " .. path)
    local data = request(path, {}, true)
    log.info("Received some data...")
    if not data then
        log.info("Failed to download")
        os.queueEvent("boombox_download_error", path)
        return
    end


    log.info("Downloaded, now storing... (" .. file.storage .. "/" .. file.__info.title .. ".dfpwm)")
    local handler, error = fs.open(file.storage .. "/" .. file.__info.title .. ".dfpwm", "wb")
    if not handler then
        log.info("Failed to open file: " .. tostring(error))
        os.queueEvent("boombox_download_error", error)
        return
    end
    log.info("Writing to file...")
    handler.write(data)
    handler.flush()
    handler.close()

    os.queueEvent("boombox_download_complete")
end

function file:listen()
    local ListenSwitch = switch()
        :case("file", function(data)
            self.__path = data[2]
            self.__yt = self.__path:match("http[s]?://[w]?[w]?[w]?%.?youtube%.com/watch%?v=") or self.__path:match("http[s]?://youtu%.be/")
        end)
        :case("retry", function(data)
            -- log.info(textutils.serialise(data))
            self.retryEnabled = data[2]
        end)
        :case("info", function()
            self:getInfo()
        end)
        :case("download", function()
            self:download()
        end)
        :case("storage", function(data)
            -- log.info(data[2].item)
            self.storage = data[2].item
        end)
        :case("terminate", function()
            log.warn("Preventing termination")
        end)
        :case("http_check", function (url, success, reason)
            if not success then
                log.error(url .. " provided " .. reason)
            end
        end)
        :default(function()
            -- os.queueEvent("boombox_download_error", "unknown event")
        end)

    while true do
        local data = {os.pullEventRaw("boombox_request")}
        table.remove(data, 1)
        log.info('Received data')
        log.info(textutils.serialise(data))

        ListenSwitch(data[1], data)
    end
end


file.new()
