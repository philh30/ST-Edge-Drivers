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

local socket = require "cosock.socket"
local commands = require('commands')
local log = require('log')
local capabilities = require('st.capabilities')
local utilities = require('utilities')
local capdefs = require('capabilitydefs')
local evlClient = require('envisalink')
local events = require "evthandler"


local function initconfigEVL(device)

  local ip
  local port
  local addr_is_valid = false
      
  ip, port = utilities.validate_address(device.preferences.lanAddressEVL)
  if ip ~= nil then
    conf.ip = ip
    conf.port = port
    addr_is_valid = true
  else
    log.warn ('Invalid EVL LAN address')
  end
      
  conf.alarmcode = device.preferences.alarmCodeEVL
  conf.password = device.preferences.passwordEVL
  conf.zoneclosedelay = tonumber(device.preferences.zoneCloseDelay)
  conf.wiredzonemax = tonumber(device.preferences.wiredZoneMax)

  if conf.alarmcode ~= nil then
    if string.len(device.preferences.alarmCodeEVL) ~= 4 then
      log.warn('Invalid alarmcode (not 4 digits')
    end
  else
    log.warn('Invalid alarmcode (not a number)')
  end
  
  log.info (string.format('Using config prefs: %s:%d, alarmcode: %d', conf.ip, conf.port, conf.alarmcode))
  return(addr_is_valid)

end

---------------------------------------
-- Init Lifecycle Handler
local function init_handler(driver, device)
  log.debug(device.id .. ": " .. device.device_network_id .. " : " .. device.model .. " > INITIALIZING PRIMARY PARTITION")

  socket.sleep(5)

  initialized = true

  log.warn('Starting up connection')
  if initconfigEVL(device) then
    if not evlClient.is_loggedin(driver) then
      if not evlClient.is_connected(driver) then
        if not commands.connect_to_envisalink(driver,device) then
          evlClient.reconnect(driver)
        end
      end
    end
  end

  log.debug ('Initialization Success!')
end

---------------------------------------
-- InfoChanged Lifecycle Handler
local function add_zones(driver,zoneType,zoneString)
  if #zoneString > 0 then
    log.debug (string.format('Add %s Zones: %s', zoneType, zoneString))
    local zoneTable = utilities.splitString(zoneString,',')
    for _, zone in ipairs(zoneTable) do
      events.add_zone(driver,zoneType,zone,nil)
    end
  end
end

local function infoChanged_handler(driver,device, event, args)
  log.info(device.id .. ": " .. device.device_network_id .. " > INFO CHANGED PRIMARY PARTITION")

  local changed = false
  local connection_changed = false
  
  conf.zoneclosedelay = tonumber(device.preferences.zoneCloseDelay)
  conf.wiredzonemax = tonumber(device.preferences.wiredZoneMax)

  if args.old_st_store.preferences.lanAddressEVL ~= device.preferences.lanAddressEVL then
    changed = true
    connection_changed = true
  end
  if  (args.old_st_store.preferences.passwordEVL ~= device.preferences.passwordEVL) or (args.old_st_store.preferences.alarmCodeEVL ~= device.preferences.alarmCodeEVL) then
    changed = true
  end

  if changed then
    local valid_addr = initconfigEVL(device)
  
    -- Determine if need to (re) connect
  
    if connection_changed and valid_addr then
    
      log.info ('Renewing connection to Envisalink')

      if timers.reconnect then
        driver:cancel_timer(timers.reconnect)
      end
      if timers.waitlogin then
        driver:cancel_timer(timers.waitlogin)
      end
      timers.reconnect = nil
      socket.sleep(.1)
      timers.waitlogin = nil
        
      if evlClient.is_connected(driver) then
        evlClient.disconnect(driver)
      end
      
      if not commands.connect_to_envisalink(driver,device) then
        evlClient.reconnect(driver)
      end
    end
  end
  
  if device.preferences.addZones then
    add_zones(driver,'Contact',device.preferences.contactZones)
    add_zones(driver,'Motion',device.preferences.motionZones)
    add_zones(driver,'Carbon Monoxide',device.preferences.coZones)
    add_zones(driver,'Smoke',device.preferences.smokeZones)
    add_zones(driver,'Leak',device.preferences.leakZones)
    add_zones(driver,'Glass',device.preferences.glassZones)
  end
  if device.preferences.addSwitches or device.preferences.addPartition or device.preferences.addTriggers then
    local device_list = driver:get_devices()
    local found = {
      ['disarm']      = false,
      ['armAway']     = false,
      ['armStay']     = false,
      ['armInstant']  = false,
      ['armMax']      = false,
      ['armNight']    = false,
      ['chime']       = false,
      ['triggerOne']    = false,
      ['triggerTwo']    = false,
    }
    for _, dev in ipairs(device_list) do
      local dev_id = dev.device_network_id:match('envisalink|s|(.+)|1')
      if dev_id then found[dev_id] = true end
    end
    if device.preferences.addSwitches then
      if not found['disarm'] then events.createDevice(driver,'switch','Switch','disarm|1',nil) end
      if not found['armAway'] then events.createDevice(driver,'switch','Switch','armAway|1',nil) end
      if not found['armStay'] then events.createDevice(driver,'switch','Switch','armStay|1',nil) end
      if (not found['armInstant']) and device.preferences.armInstantSupported then events.createDevice(driver,'switch','Switch','armInstant|1',nil) end
      if (not found['armMax']) and device.preferences.armMaxSupported then events.createDevice(driver,'switch','Switch','armMax|1',nil) end
      if (not found['armNight']) and device.preferences.armNightSupported then events.createDevice(driver,'switch','Switch','armNight|1',nil) end
    end
    if device.preferences.addPartition then
      local part_found = false
      for _, dev in ipairs(device_list) do
        if dev.device_network_id:match('envisalink|p|2') then
          part_found = true
          break
        end
      end
      if not part_found then
        events.createDevice(driver,'partition', 'Partition', 2, nil)
      end
    end
    if device.preferences.addTriggers then
      if not found['triggerOne'] then events.createDevice(driver,'switch','Switch','triggerOne|1',nil) end
      if not found['triggerTwo'] then events.createDevice(driver,'switch','Switch','triggerTwo|1',nil) end
    end
  end
  local supported_modes = {'disarm','armAway','armStay'}
  if device.preferences.armInstantSupported then
    table.insert(supported_modes,'armInstant')
  end
  if device.preferences.armMaxSupported then
    table.insert(supported_modes,'armMax')
  end
  if device.preferences.armNightSupported then
    table.insert(supported_modes,'armNight')
  end
  device:emit_event(capabilities[capdefs.alarmMode.name].supportedAlarmModes({value = supported_modes}))
end

local function removed_handler(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > REMOVED PRIMARY PARTITION")
  initialized = false
end

---------------------------------------
-- Primary Partition Sub-Driver
local primary_partition_driver = {
  NAME = "Primary Partition",
  lifecycle_handlers = {
    init = init_handler,
    infoChanged = infoChanged_handler,
    removed = removed_handler,
    deleted = removed_handler,
  },
  capability_handlers = {},
  can_handle = function(opts, driver, device, ...)
    return device.model == "Honeywell Primary Partition"
  end
}

return primary_partition_driver