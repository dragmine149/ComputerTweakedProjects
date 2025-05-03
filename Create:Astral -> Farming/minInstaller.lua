print("Installing minimum requirements for farming. Please wait...")

fs.makeDir("Farming")

print("Installing switch module")
shell.run("pastebin", "get", "FjGiw8NL")

print("Installing main installer module")
shell.run("wget")

print("Finished installing minimum requirements. Cleaning up")
fs.delete("minInstaller.lua")

print("Clean up complete. Running main installer")
shell.run("Farming/Installer.lua")
