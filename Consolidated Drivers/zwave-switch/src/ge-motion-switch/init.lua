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
local capdefs = require('ge-motion-switch.capabilitydefs')
local config_handlers = require "ge-motion-switch.config_handlers"

local TimeoutDuration = capdefs.TimeoutDuration.capability
local OperationMode = capdefs.OperationMode.capability
local MotionSensitivity = capdefs.MotionSensitivity.capability
local LightSensing = capdefs.LightSensing.capability
local DefaultLevel = capdefs.DefaultLevel.capability

local GE_MOTION_SWITCH_FINGERPRINTS = {
  {mfr = 0x0063, prod = 0x494D, model = 0x3031},
  {mfr = 0x0063, prod = 0x494D, model = 0x3032},
  {mfr = 0x0063, prod = 0x494D, model = 0x3033},
  {mfr = 0x0063, prod = 0x494D, model = 0x3034},
}

--- Determine whether the passed device is a 3-speed fan
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true if the device is an 3-speed fan, else false
local function can_handle_ge_motion(opts, driver, device, ...)
  for _, fingerprint in ipairs(GE_MOTION_SWITCH_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
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
    [17]  = { handler = 'defaultLevel' },
  }
  if param_map[param] then
    config_handlers[param_map[param].handler](device,command.args.configuration_value)
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Basic.Report
local function basic_report(driver,device,cmd)
  local event
  if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
    event = capabilities.switch.switch.off()
  else
    event = capabilities.switch.switch.on()
  end
  device:emit_event_for_endpoint(cmd.src_channel, event)
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
  device:send(Notification:Get({v1_alarm_type = 0, notification_type = 0xFF, event = 0x00}))
  device:send(Configuration:Get({parameter_number = 1}))
  device:send(Configuration:Get({parameter_number = 3}))
  device:send(Configuration:Get({parameter_number = 13}))
  device:send(Configuration:Get({parameter_number = 14}))
  if device:supports_capability_by_id(DefaultLevel.ID) then
    device:send(Configuration:Get({parameter_number = 17}))
  end
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

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function defaultlevel_handler(driver,device,command)
  local config_value = (command.args.defaultLevel == 100) and 99 or command.args.defaultLevel
  device:send(Configuration:Set({parameter_number = 17, size = 1, configuration_value = config_value}))
  device:send(Configuration:Get({parameter_number = 17}))
end

local ge_motion = {
  zwave_handlers = {
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = configuration_report,
    },
    [cc.BASIC] = {
      [Basic.REPORT] = basic_report,
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
    DefaultLevel,
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
    [DefaultLevel.ID] = {
      [DefaultLevel.commands.setDefaultLevel.NAME] = defaultlevel_handler,
    },
  },
  NAME = "ge zwave motion switch",
  can_handle = can_handle_ge_motion,
}

return ge_motion