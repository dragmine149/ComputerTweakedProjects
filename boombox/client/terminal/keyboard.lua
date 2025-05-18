if not fs.isDir("/tmp") then fs.makeDir("/tmp") end
-- shell.exit()

local file = fs.open("/tmp/input.txt", "w")
if not file then error("Failed to open file") end

local expect = require("cc.expect")
local args = { ... }

-- print(textutils.serialise(args))
print(args[1])
print(args[2])
print(args[3])

expect.expect(1, args[1], "string") -- Title
expect.expect(2, args[2], "string", "nil") -- default text
expect.expect(3, args[3], "boolean", "nil") -- multiline support

local title = args[1]
local defaultText = args[2] or ""
local multiline = args[3] or false

file.writeLine(defaultText)
file.writeLine("")
file.writeLine("-- Any lines starting in a lua comment ('--') will be ignored")
file.writeLine("-- Please enter your input at the start of the file")
file.writeLine("--")
file.writeLine("-- " .. title)
file.writeLine("--")
local multilineSupport = multiline and "enabled" or "disabled"
local multilineExplanation = multiline and "all lines will be read" or "only the first line will be read"
file.writeLine("-- Multiline support is " .. multilineSupport .. " meaning")
file.writeLine("-- " .. multilineExplanation)
file.writeLine("-- This is a temporary file and will be deleted")
file.writeLine("-- after the interface has been exited.")
file.writeLine("--")
file.writeLine("-- NOTE: PLEASE SAVE BEFORE EXITING OTHERWISE YOUR")
file.writeLine("-- INPUT WILL BE LOST")
file.writeLine("--")
file.writeLine("")

file.close()

shell.run("edit", "/tmp/input.txt")

file = fs.open("/tmp/input.txt", "r")
if not file then error("Failed to open file (how??)") end

local data = file.readAll()

file.close()
local function stripComments(str)
    local lines = {}
    for line in str:gmatch("[^\r\n]+") do
        if not line:match("^%s*%-%-") then
            table.insert(lines, line)
        end
    end
    return table.concat(lines, "\n")
end

data = stripComments(data)

if not multiline then
    data = data:gsub("\r\n", "\n")
end

shell.run("rm", "/tmp/input.txt")
shell.run("rm", "/tmp")

os.queueEvent("terminal_input", data)
