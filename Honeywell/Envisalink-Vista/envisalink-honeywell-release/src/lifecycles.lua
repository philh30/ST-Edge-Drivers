local log = require('log')

-- Fallback for lifecycles not handled by sub-drivers

local lifecycle_handler = {}

function lifecycle_handler.init(driver, device)
  log.debug(device.id .. ": " .. device.device_network_id .. " : " .. device.model .. " > INITIALIZING")
end

function lifecycle_handler.added(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > ADDED")
  device:online()
end

function lifecycle_handler.driverSwitched(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > DRIVER SWITCHED")
end

function lifecycle_handler.infoChanged(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > INFO CHANGED")
end

function lifecycle_handler.doConfigure(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > DO CONFIGURE")
end

function lifecycle_handler.removed(_, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > REMOVED")
end

return lifecycle_handler
