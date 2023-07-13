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

local log             = require('log')
local capabilities    = require('st.capabilities')
local capabilitydefs  = require('capabilitydefs')

local event_handler = {}

local switch_modes = {
  ready         = 'disarm',
  notready      = 'disarm',
  arming        = 'none',
  armedstay     = 'armStay',
  armedaway     = 'armAway',
  armedinstant  = 'armInstant',
  armedmax      = 'armMax',
  alarmcleared  = 'none',
  alarm         = 'no change',
}

event_handler.device_types = {
  contact = {
    wired         = { profile = 'contact-sensor-wired',           model = 'Honeywell Contact Sensor Wired'    },
    wireless      = { profile = 'contact-sensor-wireless',        model = 'Honeywell Contact Sensor Wireless' },
    vendor_label  = 'Contact'
  },
  motion = {
    wired         = { profile = 'motion-sensor-wired',            model = 'Honeywell Motion Sensor Wired'     },
    wireless      = { profile = 'motion-sensor-wireless',         model = 'Honeywell Motion Sensor Wireless'  },
    vendor_label  = 'Motion'
  },
  glass = {
    wired         = { profile = 'glass-sensor-wired',             model = 'Honeywell Glass Sensor Wired'      },
    wireless      = { profile = 'glass-sensor-wireless',          model = 'Honeywell Glass Sensor Wireless'   },
    vendor_label  = 'Glass Break'
  },
  leak = {
    wired         = { profile = 'leak-sensor-wired',              model = 'Honeywell Leak Sensor Wired'       },
    wireless      = { profile = 'leak-sensor-wireless',           model = 'Honeywell Leak Sensor Wireless'    },
    vendor_label  = 'Leak'
  },
  carbonmonoxide = {
    wired         = { profile = 'carbonmonoxide-sensor-wired',    model = 'Honeywell Carbon Monoxide Sensor Wired'      },
    wireless      = { profile = 'carbonmonoxide-sensor-wireless', model = 'Honeywell Carbon Monoxide Sensor Wireless'   },
    vendor_label  = 'Carbon Monoxide'
  },
  smoke = {
    wired         = { profile = 'smoke-sensor-wired',             model = 'Honeywell Smoke Sensor Wired'      },
    wireless      = { profile = 'smoke-sensor-wireless',          model = 'Honeywell Smoke Sensor Wireless'   },
    vendor_label  = 'Smoke'
  },
}

local device_profiles = {
  ['Primary Partition'] = 'primaryPartition',
  ['Partition']         = 'partition',
  ['Contact']           = 'contact-sensor',
  ['Motion']            = 'motion-sensor',
  ['Carbon Monoxide']   = 'carbonmonoxide-sensor',
  ['Smoke']             = 'smoke-sensor',
  ['Leak']              = 'leak-sensor',
  ['Glass']             = 'glass-sensor',
  ['Switch']            = 'switch'
}

----------------
-- Zone Handlers
local translate_state = {
  contact               = { open = 'open',           closed = 'closed',    bypassed = 'closed'  },
  contact_bypass        = { open = 'open',           closed = 'closed',    bypassed = 'bypassed'},
  motion                = { open = 'active',         closed = 'inactive',  bypassed = 'inactive'},
  motion_bypass         = { open = 'active',         closed = 'inactive',  bypassed = 'bypassed'},
  bypassable            = { open = 'notReady',       closed = 'ready',     bypassed = 'bypassed'},
  carbonmonoxide        = { open = 'detected',       closed = 'clear',     bypassed = 'clear'   },
  carbonmonoxide_bypass = { open = 'detected',       closed = 'clear',     bypassed = 'bypassed'},
  smoke                 = { open = 'detected',       closed = 'clear',     bypassed = 'clear'   },
  smoke_bypass          = { open = 'detected',       closed = 'clear',     bypassed = 'bypassed'},
  glass                 = { open = 'glassBreaking',  closed = 'noSound',   bypassed = 'noSound' },
  glass_bypass          = { open = 'glassBreaking',  closed = 'noSound',   bypassed = 'bypassed'},
  leak                  = { open = 'wet',            closed = 'dry',       bypassed = 'dry'     },
  leak_bypass           = { open = 'wet',            closed = 'dry',       bypassed = 'bypassed'},
  security_system       = { alarm = nil, alarmcleared = nil, arming = nil, armedaway = 'armedAway', armedstay = 'armedStay', armedinstant = 'armedStay', armedmax = 'armedAway', ready = 'disarmed', notready = 'disarmed' }
}

local function update_zone_contact(driver,device,body)
  device:emit_event(capabilities[capabilitydefs.contactZone.name].contactZone({value = translate_state.contact_bypass[body.state]}))
  device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.contactSensor.contact({value = translate_state.contact[body.state]},{visibility = {displayed = false}}))
end

local function update_zone_motion(driver,device,body)
  device:emit_event(capabilities[capabilitydefs.motionZone.name].motionZone({value = translate_state.motion_bypass[body.state]}))
  device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.motionSensor.motion({value = translate_state.motion[body.state]},{visibility = {displayed = false}}))
end

local function update_zone_carbonmonoxide(driver,device,body)
  device:emit_event(capabilities[capabilitydefs.carbonMonoxideZone.name].carbonMonoxideZone({value = translate_state.carbonmonoxide_bypass[body.state]}))
  device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.carbonMonoxideDetector.carbonMonoxide({value = translate_state.carbonmonoxide[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.smokeDetector.smoke({value = translate_state.smoke[body.state]},{visibility = {displayed = false}}))
end

local function update_zone_smoke(driver,device,body)
  device:emit_event(capabilities[capabilitydefs.smokeZone.name].smokeZone({value = translate_state.smoke_bypass[body.state]}))
  device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.smokeDetector.smoke({value = translate_state.smoke[body.state]},{visibility = {displayed = false}}))
end

local function update_zone_leak(driver,device,body)
  device:emit_event(capabilities[capabilitydefs.leakZone.name].leakZone({value = translate_state.leak_bypass[body.state]}))
  device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.waterSensor.water({value = translate_state.leak[body.state]},{visibility = {displayed = false}}))
end
  
local function update_zone_glass(driver,device,body)
  device:emit_event(capabilities[capabilitydefs.glassBreakZone.name].glassBreakZone({value = translate_state.glass_bypass[body.state]}))
  device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.contactSensor.contact({value = translate_state.contact[body.state]},{visibility = {displayed = false}}))
  device:emit_event(capabilities.soundDetection.soundDetected({value = translate_state.glass[body.state]},{visibility = {displayed = false}}))
end

local function update_tamper(driver,device,body)
  device:emit_event(capabilities.tamperAlert.tamper({value = body.tamper}))
end

local function update_battery(driver,device,body)
  device:emit_event(capabilities.battery.battery({value = body.battery}))
end

local function update_switch(driver,device,body)
  local command = device.device_network_id:match('envisalink|s|(.+)|'.. body.partition)
  if switch_modes[body.state] ~= 'no change' and command ~= 'triggerOne' and command ~= 'triggerTwo' then
    if command == switch_modes[body.state] then
      device:emit_event(capabilities.switch.switch.on())
    else
      device:emit_event(capabilities.switch.switch.off())
    end
  end
end

event_handler.zone_handler = {
  ['Honeywell Contact Sensor Wireless']         = update_zone_contact,
  ['Honeywell Motion Sensor Wireless']          = update_zone_motion,
  ['Honeywell Carbon Monoxide Sensor Wireless'] = update_zone_carbonmonoxide,
  ['Honeywell Smoke Sensor Wireless']           = update_zone_smoke,
  ['Honeywell Leak Sensor Wireless']            = update_zone_leak,
  ['Honeywell Glass Sensor Wireless']           = update_zone_glass,
  ['Honeywell Contact Sensor Wired']            = update_zone_contact,
  ['Honeywell Motion Sensor Wired']             = update_zone_motion,
  ['Honeywell Carbon Monoxide Sensor Wired']    = update_zone_carbonmonoxide,
  ['Honeywell Smoke Sensor Wired']              = update_zone_smoke,
  ['Honeywell Leak Sensor Wired']               = update_zone_leak,
  ['Honeywell Glass Sensor Wired']              = update_zone_glass,
}

local function update_partition(driver,device,body)
  local partition = device.device_network_id:match('envisalink|p|(.+)')
  device:emit_event(capabilities[capabilitydefs.statusMessage.name].statusMessage({value = body.alpha}))
  if translate_state.security_system[body.state] then
    device:emit_event(capabilities.securitySystem.securitySystemStatus({value = translate_state.security_system[body.state]},{visibility = {displayed = false}}))
  end
  device:emit_event(capabilities[capabilitydefs.alarmMode.name].alarmMode({value = body.state}))
  device:emit_event(capabilities.chime.chime({value = body.chime}))
  device:emit_event(capabilities.powerSource.powerSource({value = body.power}))
  if body.battery then device:emit_event(capabilities.battery.battery({value = body.battery})) end
  if (body.bypass ~= 'bypassed') and (device.state_cache.main.bypassable.bypassStatus.value == "bypassed") then
    device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.bypass]},{visibility = {displayed = false}}))
    local zone_body = {state = 'closed'}
    local device_list = driver:get_devices()
    for _, dev in ipairs(device_list) do
      if dev.device_network_id:match('envisalink|z|.+') then
        if tonumber(dev.preferences.partition) == tonumber(partition) then
          if dev.state_cache.main.bypassable.bypassStatus.value == 'bypassed' then
            event_handler.zone_handler[dev.model](driver,dev,zone_body)
          end
        end
      end
    end
  else
    device:emit_event(capabilities.bypassable.bypassStatus({value = translate_state.bypassable[body.bypass]},{visibility = {displayed = false}}))
  end
end

event_handler.zone_handler['Honeywell Primary Partition'] = update_partition
event_handler.zone_handler['Honeywell Partition']         = update_partition

function event_handler.clear_partition(driver,partition_num)
  log.debug('Clearing partition ' .. partition_num)
  local kill_timers = {}
  for zone_type, the_timer in pairs(zone_timers[partition_num]) do
      local the_zone = zone_type:match('(%d+)|.+')
      local the_type = zone_type:match('%d+|(.+)')
      log.debug(string.format('  Clearing zone: %s - %s', the_zone, the_type))
      local the_zone_response = {
          type      = 'zone',
          partition = partition_num,
          zone      = the_zone
      }
      if the_type == 'state' then
          the_zone_response.state = 'closed'
      elseif the_type == 'tamper' then
          the_zone_response.tamper = 'clear'
      elseif the_type == 'battery' then
          the_zone_response.battery = 100
      end
      event_handler.stnp_notification_handler(driver,the_zone_response)
      table.insert(kill_timers,zone_type)
  end
  for _,zone_type in pairs(kill_timers) do
      log.debug (string.format('Removing %s from zone_timers', zone_type))
      zone_timers[partition_num][zone_type] = nil
  end
end

function event_handler.stnp_notification_handler(driver, body)
  local device_list = driver:get_devices()
  for _, device in ipairs(device_list) do
    if body.type == 'partition' then
      if device.device_network_id == 'envisalink|p|' .. body.partition then
        if (device.state_cache.main[capabilitydefs.alarmMode.name].alarmMode.value ~= 'ready') and (body.state == 'ready') then event_handler.clear_partition(driver,body.partition) end
        event_handler.zone_handler[device.model](driver,device,body)
      end
      if device.device_network_id:find('envisalink|s|.+|'.. body.partition) then
        update_switch(driver,device,body)
      end
    end
    if body.type == 'zone' then
      if device.device_network_id == 'envisalink|z|' .. body.zone then
        if body.state then
          event_handler.zone_handler[device.model](driver,device,body)
        elseif body.tamper then
          update_tamper(driver,device,body)
        elseif body.battery then
          update_battery(driver,device,body)
        end
        break
      end
    end
  end
end

------------------------
-- Create device
function event_handler.add_zone(driver,zoneType,zone,zoneLabel)
  if tonumber(zone) and tonumber(zone)>0 and tonumber(zone)<=128 then
    local exists = false
    local device_list = driver:get_devices()
    for _, dev in ipairs(device_list) do
      if dev.device_network_id == 'envisalink|z|' .. zone then
        exists = true
        break
      end
    end
    if not exists then
      log.debug (string.format("Trying to add %s Zone %s",zoneType,zone))
      event_handler.createDevice(driver, 'zone', zoneType, zone, zoneLabel)
    else
      log.debug (string.format("Zone %s already exists", zone))
    end
  else
    log.error('Non-numeric or out of range zone provided: ' .. zone)
  end
end

function event_handler.createDevice(driver, dev_type, dev_profile, dev_id, dev_label)
  -- dev_type = partition/zone/switch
  -- dev_profile = Primary Partition/Partition/Contact/Motion/Carbon Monoxide/Smoke/Leak/Glass Break/Switch/Momentary
  -- dev_id = 1/2/3/4/armStay/armAway/disarm/armInstant

  local id = 'envisalink' .. ((dev_type == 'partition' and '|p|') or (dev_type == 'zone' and '|z|') or '|s|') .. dev_id
  dev_label = dev_label or ('HW ' .. dev_profile .. ' ' .. dev_id)
  local dev_wired = ''
  local dev_model = 'Honeywell ' .. dev_profile .. ((dev_type == 'zone' and ' Sensor') or '')

  if dev_type == 'zone' then
    dev_wired = (tonumber(dev_id) > conf.wiredzonemax) and '-wireless' or '-wired'
    dev_model = dev_model .. ((tonumber(dev_id) > conf.wiredzonemax) and ' Wireless' or ' Wired')
  end
  

  local create_device_msg = {
                              type = "LAN",
                              device_network_id = id,
                              label = dev_label,
                              profile = device_profiles[dev_profile] .. dev_wired,
                              manufacturer = 'Honeywell/Ademco',
                              model = dev_model,
                              vendor_provided_label = 'Honeywell Vista ' .. dev_profile,
                            }
                        
  log.info(string.format("Creating %s device: %s %s (%s)", dev_type, dev_profile, dev_id, id))
  assert (driver:try_create_device(create_device_msg), "failed to create panel device")
end

return event_handler