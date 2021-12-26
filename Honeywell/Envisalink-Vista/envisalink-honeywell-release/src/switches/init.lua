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

local capabilities = require('st.capabilities')
local log = require('log')
local commands = require('commands')
local capabilitydefs = require('capabilitydefs')

local models_supported = {
  'Honeywell Switch',
}

local function can_handle_sensors(opts, driver, device, ...)
  for _, model in ipairs(models_supported) do
    if device.model == model then
      return true
    end
  end
  return false
end

local function added_handler(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > ADDED ZONE")
  device:emit_event(capabilities.switch.switch.off())
  device:online()
end

local function init_handler(driver,device)
  log.debug(device.id .. ": " .. device.device_network_id .. " : " .. device.model .. " > INITIALIZING")
  local dev_id = device.device_network_id:match('envisalink|s|(.+)|%d+')
  local partition = device.device_network_id:match('envisalink|s|.+|(%d+)')
end

---------------------------------------
-- Switch Sub-Driver
local switch_driver = {
  NAME = "Switch",
  lifecycle_handlers = {
    added = added_handler,
    init = init_handler,
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
          [capabilities.switch.commands.on.NAME] = commands.on_off,
          [capabilities.switch.commands.off.NAME] = commands.on_off,
        },
  },
  can_handle = can_handle_sensors,
}

return switch_driver