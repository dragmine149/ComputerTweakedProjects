local args = { ... }

local Switch = require("lib.switch")

local function install()
    print("Installing Astral Farming...")

    local installer = Switch()
    :case("turtle", function ()
      print("Installing turtle farming...")
      end)

    :case("main", function ()
      print("Installing main farming...")

      shell.run("wget", "run", "https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua", "-r")

      end)

    installer(args[1])
end

install()
