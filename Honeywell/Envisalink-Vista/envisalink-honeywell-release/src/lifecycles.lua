-- Author: philh30
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local log = require('log')

-- Fallback for lifecycles not handled by sub-drivers

local lifecycle_handler = {}

function lifecycle_handler.init(driver, device)
  log.debug(device.id .. ": " .. device.device_network_id .. " : " .. device.model .. " > INITIALIZING GENERIC")
end

function lifecycle_handler.added(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > ADDED GENERIC")
  device:online()
end

function lifecycle_handler.driverSwitched(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > DRIVER SWITCHED GENERIC")
end

function lifecycle_handler.infoChanged(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > INFO CHANGED GENERIC")
end

function lifecycle_handler.doConfigure(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > DO CONFIGURE GENERIC")
end

function lifecycle_handler.removed(_, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > REMOVED GENERIC")
end

return lifecycle_handler
