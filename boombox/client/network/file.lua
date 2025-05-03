local args = {...}
local switch = require("/Boombox.utils.switch")

local file = {}

local function request(url, headers, binary)
    local response

    if file.__autoRetry.enabled then
        file.__autoRetry[url] = file.__autoRetry[url] or 2
    end

    while not response and file.__autoRetry[url] < 3 do
        print("Requesting: " .. url)
        response = http.get(url, headers, binary)
        if response then
            local data = response.readAll()
            response.close()
            return data
        end

        file.__autoRetry[url] = file.__autoRetry[url] + 1
    end
end

function file.new()
    file.__path = ""
    file.__data = {}
    file.__info = {}
    file.__autoRetry = {
        enabled = false
    }
    file.__yt = file.__path:match("http[s]?://[w]?[w]?[w]?%.?youtube%.com/watch%?v=") or file.__path:match("http[s]?://youtu%.be/")

    file:listen()
end

function file:getInfo()
    if self.__yt then
       local response = request("https://ytdlp.online/stream?command=--get-title --skip-download " .. self.__path)
       if not response then
           os.queueEvent("boombox_download_error", self.__path)
           return
       end
       file.__info.title = response:match("\n.-\n(data: (.+))")
    end
    -- assume title is in the file name.
    local file_name = self.__path:match("([^/]+)%.");
    file.__info.title = file_name

    os.queueEvent("boombox_download_info", file.__info)
end

function file:download()
    local path = self.__path
    if self.__yt then
        path = "https://boombox-server.dragmine149.workers.dev/?video=" .. self.__path
    end

    local data = request(path, {}, true)
    if not data then
        os.queueEvent("boombox_download_error", path)
        return
    end
    file.__data = data
    os.queueEvent("boombox_download_complete", file.__data)
end

function file:listen()
    local data = {os.pullEvent("boombox_request")}
    local ListenSwitch = switch()
        :case("file", function()
            self.__path = data[2]
        end)
        :case("auto", function()
            self.__autoRetry.enabled = data[2]
        end)
        :case("info", function()
            self:getInfo()
        end)
        :case("download", function()
            self:download()
        end)
        :default(function()
            os.queueEvent("boombox_download_error", "unknown event")
        end)

    ListenSwitch(data[1])
end


file.new()
