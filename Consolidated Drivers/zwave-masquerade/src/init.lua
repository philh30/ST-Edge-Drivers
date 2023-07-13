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

local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.Driver
local ZwaveDriver = require "st.zwave.driver"
--- @type st.zwave.defaults
local defaults = require "st.zwave.defaults"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({version=1,strict=true})
--- @type st.zwave.CommandClass.Battery
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2,strict=true})
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4,strict=true})
--- @type st.zwave.CommandClass.SensorAlarm
local SensorAlarm = (require "st.zwave.CommandClass.SensorAlarm")({version=1})
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({version=2})
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version=3 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 2 })
local log = require "log"
local cap_map = require "cap_map"
local zwave_handlers = require "zw_handlers"
local commands = require "commands"

--- Refresh command
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver, device)
  if device:is_cc_supported(cc.SWITCH_MULTILEVEL) then
    device:send(SwitchMultilevel:Get({}))
  elseif device:is_cc_supported(cc.SWITCH_BINARY) then
    device:send(SwitchBinary:Get({}))
  elseif device:is_cc_supported(cc.BASIC) then
    device:send(Basic:Get({}))
  end
  if device:is_cc_supported(cc.SENSOR_BINARY) then
    device:send(SensorBinary:Get({}))
  end
  if device:is_cc_supported(cc.BATTERY) then
    device:send(Battery:Get({}))
  end
end

--- Handle preference changes
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function info_changed(driver, device, event, args)
  if args.old_st_store.preferences.chooseProfile ~= device.preferences.chooseProfile then
    local create_device_msg = {
      profile = device.preferences.chooseProfile .. (device:is_cc_supported(cc.BATTERY) and '-battery' or ''),
    }
    assert (device:try_update_metadata(create_device_msg), "Failed to change device")
    log.warn('Changed to new profile. App restart required.')
    local function init_delay()
      local initial_events_map = cap_map(device)
      for id, event in pairs(initial_events_map) do
        if device:supports_capability_by_id(id) then
          device:emit_event(event[0])
        end
        if event.init then device:emit_event(event.init) end
      end
    end
    device.thread:call_with_delay(5,init_delay,'reset_caps')
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added_handler(driver, device)
  local initial_events_map = cap_map(device)
  for id, event in pairs(initial_events_map) do
    if device:supports_capability_by_id(id) then
      device:emit_event(event[0])
      if event.init then device:emit_event(event.init) end
    end
  end
end

local driver_template = {
  supported_capabilities = {
    capabilities.battery,
  },
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.REPORT] = zwave_handlers.report,
      [Basic.SET] = zwave_handlers.basic_set_handler,
    },
    [cc.SWITCH_BINARY] = {
      [SwitchBinary.REPORT] = zwave_handlers.report,
    },
    [cc.SWITCH_MULTILEVEL] = {
      [SwitchMultilevel.REPORT] = zwave_handlers.report,
    },
    [cc.SENSOR_BINARY] = {
      [SensorBinary.REPORT] = zwave_handlers.sensor_binary_report_handler,
    },
    [cc.SENSOR_ALARM] = {
      [SensorAlarm.REPORT] = zwave_handlers.sensor_alarm_report_handler,
    },
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = zwave_handlers.notification_handler,
    },
  },
  capability_handlers = {
    [capabilities.alarm.ID] = {
      [capabilities.alarm.commands.off.NAME] = commands.alarm,
      [capabilities.alarm.commands.siren.NAME] = commands.alarm,
      [capabilities.alarm.commands.strobe.NAME] = commands.alarm,
      [capabilities.alarm.commands.both.NAME] = commands.alarm,
    },
    [capabilities.lock.ID] = {
      [capabilities.lock.commands.unlock.NAME] = commands.on,
      [capabilities.lock.commands.lock.NAME] = commands.off,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = commands.on,
      [capabilities.switch.commands.off.NAME] = commands.off,
    },
    [capabilities.windowShade.ID] = {
      [capabilities.windowShade.commands.open.NAME] = commands.on,
      [capabilities.windowShade.commands.close.NAME] = commands.off,
    },
    [capabilities.windowShadeLevel.ID] = {
      [capabilities.windowShadeLevel.commands.setShadeLevel.NAME] = commands.shadeLevel,
    },
    [capabilities.valve.ID] = {
      [capabilities.valve.commands.open.NAME] = commands.on,
      [capabilities.valve.commands.close.NAME] = commands.off,
    },
  },
  lifecycle_handlers = {
    added = added_handler,
    infoChanged = info_changed,
    doConfigure = do_configure
  },
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
--- @type st.zwave.Driver
local sensor = ZwaveDriver("zwave_masquerade", driver_template)
sensor:run()
