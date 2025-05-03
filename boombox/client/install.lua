print("Downloading basalt (UI Manager)")
print()
if fs.exists("/Boombox/basalt.lua") then fs.delete("/Boombox/basalt.lua") end
shell.run("wget", "run", "https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua", "-r")
fs.move("/basalt.lua", "/Boombox/basalt.lua")

print("Downloading AUKit")
print()
if fs.exists("/Boombox/AUKit.lua") then fs.delete("/Boombox/AUKit.lua") end
shell.run("wget", "https://github.com/MCJack123/AUKit/releases/download/1.9.1/aukit.min.lua", "/Boombox/AUKit.lua")

print("Downloading Boombox...")
