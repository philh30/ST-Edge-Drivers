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
local utilities = require('utilities')
local capabilitydefs = require('capabilitydefs')
local socket = require "cosock.socket"
local evlClient = require "envisalink"
local events = require "evthandler"
local capabilities    = require('st.capabilities')

local command_handler = {}

local evlFunctions = {
  disarm      = 'disarm_partition',
  armAway     = 'arm_away_partition',
  armStay     = 'arm_stay_partition',
  armInstant  = 'arm_instant_partition',
  armNight    = 'arm_night_partition',
  armMax      = 'arm_max_partition',
  chime       = 'chime_partition',
  bypass      = 'bypass_zone_partition',
  triggerOne  = 'trigger_one_partition',
  triggerTwo  = 'trigger_two_partition',
}

----------------
-- Switch command
function command_handler.on_off(driver, device, command)
  local on_off = command.command
  local dev_id = device.device_network_id:match('envisalink|s|(.+)|%d+')
  local partition = device.device_network_id:match('envisalink|s|.+|(%d+)')
  log.warn (string.format('Switch flipped (%s) %s Partition %d',on_off,dev_id,partition))
  if (evlFunctions[dev_id] and (dev_id == 'triggerOne' or dev_id == 'triggerTwo')) then
    evlClient[evlFunctions[dev_id] .. '_' .. on_off](driver,conf.alarmcode,partition)
    device:emit_event(capabilities.switch.switch({value = on_off}))
  elseif (on_off == 'on' and evlFunctions[dev_id]) or dev_id == 'chime' then
    evlClient[evlFunctions[dev_id]](driver,conf.alarmcode,partition)
  end
end

----------------
-- Refresh triggered by a zone
function command_handler.refresh_zone(driver,device)
  local partition = device.preferences.partition
  last_event[partition] = nil
  local partition_id = 'envisalink|p|' .. partition
  local device_list = driver:get_devices()
  for _, dev in ipairs(device_list) do
    if dev.device_network_id == partition_id then
      if dev.state_cache.main[capabilitydefs.alarmMode.name].alarmMode.value == "ready" then
        if not (dev.state_cache.main.bypassable.bypassStatus.value == 'bypassed' and device.state_cache.main.bypassable.bypassStatus.value == 'bypassed') then
          events.zone_handler[device.model](driver,device,{state = 'closed'})
        end
      end
      device:emit_event(capabilities.tamperAlert.tamper.clear())
      device:emit_event(capabilities.battery.battery({value = 100}))
      break
    end
  end
end

----------------
-- Refresh triggered by a zone
function command_handler.refresh_partition(driver,device)
  local partition_num = device.device_network_id:match('envisalink|p|(.+)')
  log.warn('Refresh partition ' .. partition_num)
  last_event[partition_num] = nil
  local device_list = driver:get_devices()
  if device.state_cache.main[capabilitydefs.alarmMode.name].alarmMode.value == "ready" then
    local bypass_partition = device.state_cache.main.bypassable.bypassStatus.value == 'bypassed'
    for _, dev in ipairs(device_list) do
      if dev.preferences.partition == partition_num then
        if not (bypass_partition and dev.state_cache.main.bypassable.bypassStatus.value == 'bypassed') then
          events.zone_handler[device.model](driver,device,{['state'] = 'closed'})
          log.debug(string.format('Clearing zone: %s', dev.device_network_id))
        end
      end
    end
  end
end



------------------------
-- Send EVL Command
function command_handler.send_evl_command(driver,args)
  if evlFunctions[args.command] then
    if args.command == 'bypass' then
      evlClient[evlFunctions[args.command]](driver,conf.alarmcode,args.partition,args.zone)
    else
      evlClient[evlFunctions[args.command]](driver,conf.alarmcode,args.partition)
    end
  end
end


-----------------------------------------------
----------------------------------------------
-- EVL Functions
function command_handler.connect_to_envisalink(driver,device)

  local client = evlClient.connect(driver)

  if not client then
  
    log.warn ('Retrying to connect to Envisalink')
  
    local retries = 2
  
    repeat
      socket.sleep(5)
      client = evlClient.connect(driver)
      retries = retries - 1
    until retries == 0
  end
    
  if client then  
    log.info ('Found and connected to Envisalink device')
    
    -- make sure we got logged in
    
    local retries = 2
    repeat 
      log.debug ('Waiting for login...')
      socket.sleep(3)
      retries = retries - 1
    until evlClient.is_loggedin(driver) or (retries == 0)
    
    if evlClient.is_loggedin(driver) then
      utilities.set_online(driver,'online')
      return true
      
    else
      evlClient.disconnect(driver)
      log.error ('Failed to log into EnvisaLink')
    end
    
  else
    log.error ('Failed to connect to Envisalink')
  end

  return false

end

return command_handler
