-- Copyright 2022 philh30
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
local evt = require('evthandler')
local socket = require "cosock.socket"

local models_supported = {
  'Honeywell Contact Sensor Wireless',
  'Honeywell Motion Sensor Wireless',
  'Honeywell Carbon Monoxide Sensor Wireless',
  'Honeywell Smoke Sensor Wireless',
  'Honeywell Leak Sensor Wireless',
  'Honeywell Glass Sensor Wireless',
  'Honeywell Contact Sensor Wired',
  'Honeywell Motion Sensor Wired',
  'Honeywell Carbon Monoxide Sensor Wired',
  'Honeywell Smoke Sensor Wired',
  'Honeywell Leak Sensor Wired',
  'Honeywell Glass Sensor Wired',
}

local capabilityInits = {
  ['Wireless'] = {
    capabilities.bypassable.bypassStatus.ready(),
    capabilities.tamperAlert.tamper.clear(),
    capabilities.battery.battery({value = 100}),
  },
  ['Wired'] = {
    capabilities.bypassable.bypassStatus.ready(),
    capabilities.tamperAlert.tamper.clear(),
  },
  ['Contact'] = {
    capabilities[capabilitydefs.contactZone.name].contactZone.closed(),
    capabilities.contactSensor.contact.closed(),
  },
  ['Motion'] = {
    capabilities[capabilitydefs.motionZone.name].motionZone.inactive(),
    capabilities.motionSensor.motion.inactive(),
  },
  ['Carbon Monoxide'] = {
    capabilities[capabilitydefs.carbonMonoxideZone.name].carbonMonoxideZone.clear(),
    capabilities.carbonMonoxideDetector.carbonMonoxide.clear(),
    capabilities.smokeDetector.smoke.clear()
  },
  ['Smoke'] = {
    capabilities[capabilitydefs.smokeZone.name].smokeZone.clear(),
    capabilities.smokeDetector.smoke.clear()
  },
  ['Leak'] = {
    capabilities[capabilitydefs.leakZone.name].leakZone.dry(),
    capabilities.waterSensor.water.dry()
  },
  ['Glass'] = {
    capabilities[capabilitydefs.glassBreakZone.name].glassBreakZone.noSound(),
    capabilities.soundDetection.soundDetected.noSound(),
    capabilities.contactSensor.contact.closed(),
  },
}

local function can_handle_sensors(opts, driver, device, ...)
  for _, model in pairs(models_supported) do
    if device.model == model then
      return true
    end
  end
  return false
end

local function added_handler(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > ADDED ZONE")
  local wired_wireless = device.model:match('Wire.+')
  local type = device.model:match('Honeywell (.+) Sensor')
  for _, event in pairs(capabilityInits[wired_wireless]) do
    device:emit_event(event)
  end
  for _, event in pairs(capabilityInits[type]) do
    device:emit_event(event)
  end
  device:online()
end

local function init_handler(driver,device)
  log.debug(device.id .. ": " .. device.device_network_id .. " : " .. device.model .. " > INITIALIZING ZONE")
end

local function refresh_handler(driver, device, command)
  log.info(device.id .. ": " .. device.device_network_id .. " > REFRESH")
  commands.refresh_zone(driver,device)
end

-------------------
-- bypass function
local function bypass_handler(driver, device, cmd)
  log.info('Bypass function called')
  local args = {}
  args.zone = device.device_network_id:match('envisalink|z|(%d+)')
  args.command = cmd.command
  args.partition = device.preferences.partition
  commands.send_evl_command(driver,args)
end

local function infoChanged_handler(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > INFO CHANGED ZONE")
  local new_model = evt.device_types[device.preferences.zoneType][device.preferences.wiredWireless].model
  if device.model ~= new_model then
    log.warn (string.format('Changing %s device type from %s to %s',device.device_network_id,device.model,new_model))
    local create_device_msg = {
      profile = evt.device_types[device.preferences.zoneType][device.preferences.wiredWireless].profile,
      manufacturer = 'Honeywell/Ademco',
      model = new_model,
      vendor_provided_label = 'Honeywell Vista ' .. evt.device_types[device.preferences.zoneType].vendor_label,
    }
    assert (device:try_update_metadata(create_device_msg), "Failed to change device")
    log.warn (string.format('Attempted to change to %s, now %s',new_model,device.model))
    
    socket.sleep(1)
    
    local wired_wireless = new_model:match('Wire.+')
    local type = new_model:match('Honeywell (.+) Sensor')
    for _, event in pairs(capabilityInits[wired_wireless]) do
      device:emit_event(event)
    end
    for _, event in pairs(capabilityInits[type]) do
      device:emit_event(event)
    end
  end
end

---------------------------------------
-- Zone Sub-Driver
local zone_driver = {
  NAME = "Zone",
  lifecycle_handlers = {
    added = added_handler,
    init = init_handler,
    infoChanged = infoChanged_handler,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
          [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
        },
    [capabilities[capabilitydefs.bypass.name].ID] = {
          [capabilities[capabilitydefs.bypass.name].commands.bypass.NAME] = bypass_handler,
    }
  },
  can_handle = can_handle_sensors,
}

return zone_driver