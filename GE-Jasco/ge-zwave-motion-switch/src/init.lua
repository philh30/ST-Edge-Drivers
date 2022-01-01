-- Author: philh30
--
-- Copyright 2021 SmartThings
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
local cc = require "st.zwave.CommandClass"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local log = require "log"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({version=1,strict=true})
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2,strict=true})
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4,strict=true})
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({version=2})
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({version=3})
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"
local capdefs = require('capabilitydefs')
local config_handlers = require "config_handlers"

capabilities[capdefs.TimeoutDuration.name] = capdefs.TimeoutDuration.capability
local TimeoutDuration = capabilities[capdefs.TimeoutDuration.name]

capabilities[capdefs.OperationMode.name] = capdefs.OperationMode.capability
local OperationMode = capabilities[capdefs.OperationMode.name]

capabilities[capdefs.MotionSensitivity.name] = capdefs.MotionSensitivity.capability
local MotionSensitivity = capabilities[capdefs.MotionSensitivity.name]

capabilities[capdefs.LightSensing.name] = capdefs.LightSensing.capability
local LightSensing = capabilities[capdefs.LightSensing.name]


--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function update_preferences(driver, device, args)
  local preferences = preferencesMap.get_device_parameters(device)
  for id, value in pairs(device.preferences) do
    if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and preferences and preferences[id]) then
      if preferences[id].type == 'config' then
        local new_parameter_value = preferencesMap.to_numeric_value(device.preferences[id])
        device:send(Configuration:Set({parameter_number = preferences[id].parameter_number, size = preferences[id].size, configuration_value = new_parameter_value}))
        device:send(Configuration:Get({parameter_number = preferences[id].parameter_number}))
      elseif preferences[id].type == 'assoc' then
        local group = preferences[id].group
        local maxnodes = preferences[id].maxnodes
        local addhub = preferences[id].addhub
        local nodes = splitAssocString(value,',',maxnodes,addhub)
        local hubnode = device.driver.environment_info.hub_zwave_id
        device:send(Association:Remove({grouping_identifier = group, node_ids = {}}))
        if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {hubnode}})) end --add hub to group 3 for double click reporting
        if #nodes > 0 then
          device:send(Association:Set({grouping_identifier = group, node_ids = nodes}))
        end
        device:send(Association:Get({grouping_identifier = group}))
      end
    end
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function info_changed(driver, device, event, args)
  update_preferences(driver, device, args)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  device:refresh()
  update_preferences(driver, device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added(driver, device)
  device:refresh()
  update_preferences(driver, device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Configuration.Report
local function configuration_report(driver,device,command)
  local param = command.args.parameter_number
  local param_map = {
    [1]   = { handler = 'timeoutDuration' },
    [3]   = { handler = 'operationMode' },
    [13]  = { handler = 'motionSensitivity' },
    [14]  = { handler = 'lightSensing' },
  }
  if param_map[param] then
    config_handlers[param_map[param].handler](device,command.args.configuration_value)
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device)
  if device:supports_capability_by_id(capabilities.switchLevel.ID) and device:is_cc_supported(cc.SWITCH_MULTILEVEL) then
    device:send(SwitchMultilevel:Get({}))
  elseif device:supports_capability_by_id(capabilities.switch.ID) and device:is_cc_supported(cc.SWITCH_BINARY) then
    device:send(SwitchBinary:Get({}))
  elseif device:supports_capability_by_id(capabilities.switch.ID) and device:is_cc_supported(cc.BASIC) then
    device:send(Basic:Get({}))
  end
  --device:send(SensorBinary:Get({sensor_type = SensorBinary.sensor_type.MOTION}))
  device:send(Notification:Get({v1_alarm_type = 0, notification_type = 0xFF, event = 0x00}))
  device:send(Configuration:Get({parameter_number = 1}))
  device:send(Configuration:Get({parameter_number = 3}))
  device:send(Configuration:Get({parameter_number = 13}))
  device:send(Configuration:Get({parameter_number = 14}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function timeoutduration_handler(driver,device,command)
  local map = {
    ["5s"] = 0,
    ["1m"] = 1,
    ["5m"] = 5,
    ["15m"] = 15,
    ["30m"] = 30,
  }
  device:send(Configuration:Set({parameter_number = 1, size = 1, configuration_value = map[command.args.timeoutDuration]}))
  device:send(Configuration:Get({parameter_number = 1}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function operationmode_handler(driver,device,command)
  local map = {
    manual = 1,
    vacancy = 2,
    occupancy = 3,
  }
  device:send(Configuration:Set({parameter_number = 3, size = 1, configuration_value = map[command.args.operationMode]}))
  device:send(Configuration:Get({parameter_number = 3}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function motionsensitivity_handler(driver,device,command)
  local map = {
    high = 1,
    medium = 2,
    low = 3,
  }
  device:send(Configuration:Set({parameter_number = 13, size = 1, configuration_value = map[command.args.motionSensitivity]}))
  device:send(Configuration:Get({parameter_number = 13}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function lightsensing_handler(driver,device,command)
  device:send(Configuration:Set({parameter_number = 14, size = 1, configuration_value = (command.args.value == 'off' or command.args.value == 'Off') and 0 or 1}))
  device:send(Configuration:Get({parameter_number = 14}))
end

local driver_template = {
  zwave_handlers = {
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = configuration_report,
    },
  },
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.refresh,
    capabilities.motionSensor,
    TimeoutDuration,
    OperationMode,
    MotionSensitivity,
    LightSensing,
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = added,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
    [TimeoutDuration.ID] = {
      [TimeoutDuration.commands.setTimeoutDuration.NAME] = timeoutduration_handler,
    },
    [OperationMode.ID] = {
      [OperationMode.commands.setOperationMode.NAME] = operationmode_handler,
    },
    [MotionSensitivity.ID] = {
      [MotionSensitivity.commands.setMotionSensitivity.NAME] = motionsensitivity_handler,
    },
    [LightSensing.ID] = {
      [LightSensing.commands.setLightSensing.NAME] = lightsensing_handler,
    },
  },
  NAME = "ge zwave",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ge_motion_switch = ZwaveDriver("ge-zwave-motion-switch", driver_template)
ge_motion_switch:run()