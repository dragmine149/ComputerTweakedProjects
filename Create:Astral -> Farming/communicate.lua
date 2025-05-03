local communicate = {}
---@type ccTweaked.peripheral.Modem
communicate.modem = nil

CHANNEL_SETUP = 65432
---Sets up this module ready for machine communication
function communicate.init()
  print("Initialising communication module")

  -- got to setup the peripheral
  communicate.modem = peripheral.find("modem", function(name, modem)
    return modem.isWireless()
  end)
  if not communicate.modem then
    error("No wireless modem found")
  end

  -- and then the channels
  local send_channel, reply_channel = communicate.get_channels()
  communicate.send_channel = send_channel
  communicate.reply_channel = reply_channel
  communicate.modem.open(communicate.reply_channel)
end

---Gets the channels this machine uses to communicate with the main machine.
---@return integer send_channel The channel to send the data
---@return integer reply_channel The channel to receive replies
function communicate.get_channels()
  print("Getting channels")

  -- check if we have the channels saved from a previous sync.
  local file = fs.open("Farming/channels.txt", "r")
  if file then
    local message = textutils.unserialize(file.readAll())
    file.close()
    return message.send_channel, message.reply_channel
  end

  -- if not, send a request for channels
  communicate.modem.transmit(CHANNEL_SETUP, CHANNEL_SETUP, {
    message = "channels",
    id = os.getComputerID(),
    label = os.getComputerLabel()
  })
  local event, side, channel, replyChannel, message, distance
  repeat
    event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
  until channel == CHANNEL_SETUP

  -- store the channels for future use
  file = fs.open("Farming/channels.txt", "w")
  if not file then
    print("Failed to open file, can't save channels. Will require channel resync upon restart")
  else
    file.write(textutils.serialize(message))
    file.close()
  end

  -- return them.
  return message.send_channel, message.reply_channel
end


---Send a message to the main system. Doesn't listen for responses as those aren't needed. We trust.
---@param message any The message to send.
function communicate.send_message(message)
  print("Sending message: " .. message)
  communicate.modem.transmit(communicate.send_channel, communicate.reply_channel, message)
end

return communicate
