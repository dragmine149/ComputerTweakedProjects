local STATE = {
  NONE = 0,
  FUEL = 1,
  OUT = 2,
  FARM = 3,
  DONE = 4
}

local calibrate = {
  fuel_pos = {},
  out_pos = {},
  farm_pos = {},
  farm_init_pos = {},
  state = STATE.NONE,
  pos = {
    x = nil,
    y = nil,
    z = nil
  },
  confirm_count = 0,
}

local function quick_save()
  local file = fs.open("/Farming/calibration.txt", "w+")
  -- assume we already dealt with this problem
  if file == nil then return nil end
  file.write(textutils.encodeJSON(calibrate))
  file.close()
  return true
end

---Gets the gps positions. Handles debugging as well.
---@return nil|{x:integer, y:integer, z:integer} coords The current xyz coordinates of the turtle.
local function get_pos()
  print("Getting current pos")
  local x, y, z = gps.locate()

  if x == nil then
    print("Somehow the gps failed to locate me. Please try again.")
    return nil
  end

  return { x, y, z }
end

---Stores a position of the requested type.
---@param type string The name to show to the user.
---@param var_name string The internal name.
---@return nil|integer code error or success codes.
local function calibrate_pos(type, var_name)
  print("Starting calibration for " .. type)

  if calibrate.pos.x == nil then
    local c_pos = get_pos()
    if c_pos == nil then return end
    calibrate.pos = c_pos

    if quick_save() == nil then return nil end
    print("Position temp saved. Please destroy, replace and restart me where you intend to give me " .. type)
    return 1
  end

  local c_pos = get_pos()
  if c_pos == nil then return end
  if c_pos == calibrate.pos and calibrate.confirm_count == 0 then
    print("Position unchanged. Are you sure you want this location? If so just restart me.")
    calibrate.confirm_count = calibrate.confirm_count + 1

    return 2
  end

  print("Saving current position (" .. textutils.serialize(c_pos) .. ") as " .. type .. " position")

  calibrate[var_name] = c_pos
  if quick_save() == nil then return nil end
  return 3
end


local function calibrate_farm()
  if calibrate_pos("Farm", "farm_init_pos") ~= 3 then return end

  print("Starting calibration of farmland. Please wait...")
end


---Checks if we have the data for a position
---@param data {fuel_pos: {x:integer, y:integer, z:integer} | nil, out_pos: {x:integer, y:integer, z:integer} | nil, state: integer} The data to check against
---@param var_name string The name of the element in the data to check
---@param return_state integer the return type to return
---@return integer
local function check_for_pos(data, var_name, return_state)
  -- we are in the middle of calibrating this state.
  if calibrate.state == return_state or data.state == return_state then
    return return_state
  end

  -- we have data on it, hence no need to do anything
  if calibrate[var_name] ~= nil then
    return STATE.NONE
  end
  -- we can load data on it.
  if data[var_name] ~= nil then
    calibrate[var_name] = data[var_name]
    return STATE.NONE
  end
  -- ok, need to do something.
  return return_state
end


---Checks if the gps system is setup because otherwise this would not work at all.
---@return boolean State Is the gps system setup or not?
local function check_gps()
  if gps.locate() == nil then
    print("Failed to get location. Turtle can't do anything. Please make sure the gps locator is built!")
    return false
  end
  return true
end


local function calibrate_pos_wrapper(data, var_name, display_name, state)
  calibrate.state = check_for_pos(data, var_name, state)
  if calibrate.state == state then
    if calibrate_pos(display_name, var_name) ~= 3 then return nil end
    calibrate.pos.x = nil
    calibrate.pos.y = nil
    calibrate.pos.z = nil
    if quick_save() == nil then return nil end
  end
  return true
end

---Starts the calibration process.
---@param redo boolean Redo the calibration process from scratch.
---@return nil|boolean state nil: there was an error. boolean: Everything went fine.
function calibrate.start(redo)
  print("------------------------------------------")
  if calibrate.state == STATE.DONE and redo ~= true then
    print("Calibration already done.")
    return true
  end

  calibrate.state = STATE.NONE

  print("Starting calibration...")
  if check_gps() == false then return nil end

  -- update the startup file to automatically continue calibration.
  local startup_file = fs.open("startup.lua", "w")
  if startup_file == nil then
    print("Failed to open startup file. Please try again and make sure we can write to `startup.lua`")
    return nil
  end
  startup_file.writeLine("local calibrate = require('Farming.calibrate')")
  startup_file.writeLine("calibrate.start()")
  startup_file.close()

  local file = fs.open("/Farming/calibration.txt", "r")
  if file == nil then
    print("Failed to open calibration file. Please try again and make sure we can write to `/Farming/calibration.txt`")
    return nil
  end

  local data = file.readAll()
  file.close()
  local decodeData = textutils.decodeJSON(data)
  if decodeData == nil then
    print("Failed to decode calibration data. File is corrupt, regenerating file.")
    decodeData = {}
  end

  calibrate.state = decodeData.state;
  if calibrate.state == nil then
    calibrate.state = STATE.NONE
  end

  if calibrate_pos_wrapper(decodeData, "fuel_pos", "Fuel", STATE.FUEL) == nil then return nil end
  if calibrate_pos_wrapper(decodeData, "out_pos", "Output", STATE.FUEL) == nil then return nil end

  calibrate.state = STATE.DONE
  if quick_save() == nil then return nil end

  print("Finished calibration!")
  print("------------------------------------------")

  startup_file = fs.open("startup.lua", "w")
  if startup_file == nil then return nil end
  startup_file.write("")
  startup_file.close()

  return true
end


return calibrate
