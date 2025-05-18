local function downloadFile(filename, url)
    local res = http.get(url)
    if not res then error("Error downloading file from " .. url) end
    local data = res.readAll()
    res.close()
    local file = fs.open(filename, "w")
    if not file then error("Can't write to file " .. filename .. "...") end
    file.write(data)
    file.close()
end

print("Downloading basalt (UI Manager)")
print()
if fs.exists("/Boombox/basalt.lua") then fs.delete("/Boombox/basalt.lua") end
shell.run("wget", "run", "https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua", "-r", "/Boombox/basalt.lua")

print("Downloading AUKit")
print()
if fs.exists("/Boombox/AUKit.lua") then fs.delete("/Boombox/AUKit.lua") end
downloadFile("/Boombox/AUKit.lua", "https://github.com/MCJack123/AUKit/releases/download/1.9.1/aukit.min.lua")

print("Downloading BetterBetterBlittle")
print()
if fs.exists("/Boombox/utils/betterbetterblittle.lua") then fs.delete("/Boombox/utils/betterbetterblittle.lua") end
downloadFile("/Boombox/utils/betterbetterblittle.lua",
    "https://raw.githubusercontent.com/Xella37/Pine3D/bf70ce8dfd293c5cfc795183cf1ba8a6d230be73/betterblittle.lua")

print("Downloading Boombox...")
