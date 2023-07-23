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
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
--- @type st.utils
local utils = require "st.utils"
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
local parent = require('call_parent')

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

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function init(driver, device, event, args)
  local supported_buttons = device:get_latest_state('main','button','supportedButtonValues')
  if not supported_buttons then
    -- setup for button capability
    -- only necessary due to adding button after initial driver release
    device:emit_event(capabilities.button.supportedButtonValues({ value = {'up','down'} }, { visibility = { displayed = false } }))
    device:emit_event(capabilities.button.numberOfButtons({ value = 1 }, { visibility = { displayed = false } }))
    local hubnode = device.driver.environment_info.hub_zwave_id or 1
    device:send(Association:Set({grouping_identifier = 3, node_ids = {hubnode}}))
    device:send(Association:Get({grouping_identifier = 3}))
  end
  -- Call the topmost 'init' lifecycle hander to do any default work
  parent(driver.lifecycle_handlers.init, driver, device, event, args)
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
--- @param cmd st.zwave.CommandClass.Basic.Set
local function basic_set(driver,device,cmd)
  local evt = (cmd.args.value == 0) and capabilities.button.button.down() or capabilities.button.button.up()
  evt.state_change = true
  device:emit_event(evt)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Basic.Report
local function basic_report(driver,device,cmd)
  local event
  local value = nil
  if cmd.args.target_value ~= nil then
    value = cmd.args.target_value
    if cmd.args.target_value == SwitchBinary.value.OFF_DISABLE then
      event = capabilities.switch.switch.off()
    else
      event = capabilities.switch.switch.on()
    end
  else
    value = cmd.args.value
    if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
      event = capabilities.switch.switch.off()
    else
      event = capabilities.switch.switch.on()
    end
  end
  device:emit_event_for_endpoint(cmd.src_channel, event)
  event = nil
  if value ~= nil and value > 0 then
    if value == 99 or value == 0xFF then
      value = 100
    end
    event = capabilities.switchLevel.level(value)
  end

  if event ~= nil then
    device:emit_event_for_endpoint(cmd.src_channel, event)
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

local function get_delay(device,dimmingDuration,distance)
  local delay = constants.MIN_DIMMING_GET_STATUS_DELAY -- delay in seconds
  if (device.preferences or {}).dimStepsZwave and (device.preferences or {}).dimTimeZwave and dimmingDuration == 'default' and not ((device.preferences or {}).dimRate == '0' and distance < 99) then
    local steps = math.ceil(distance/device.preferences.dimStepsZwave)
    local sec_per_step = device.preferences.dimTimeZwave/100
    delay = math.max(steps * sec_per_step + constants.DEFAULT_POST_DIMMING_DELAY, delay)
  elseif dimmingDuration ~= 'default' then
    delay = math.max(dimmingDuration + constants.DEFAULT_POST_DIMMING_DELAY, delay)
  end
  return delay
end

local function get_distance(device,command)
  local level = utils.round(command.args.level)
  level = utils.clamp_value(level, 1, 99)
  local current_level = device:get_latest_state(command.component,'switchLevel','level')
  local current_switch = device:get_latest_state(command.component,'switch','switch')
  local distance = 100
  if current_switch == 'off' then
    distance = level
  elseif current_level then
    current_level = utils.clamp_value(current_level,1,99)
    distance = math.abs(current_level - level)
  end
  return level, distance
end

local function switch_set_helper(driver, device, value, command)
  local set = Basic:Set({ value = value })
  local get
  local delay = constants.DEFAULT_GET_STATUS_DELAY
  if device:is_cc_supported(cc.SWITCH_BINARY) then
    get = SwitchBinary:Get({})
  elseif device:is_cc_supported(cc.SWITCH_MULTILEVEL) then
    local dimmingDuration = command.args.rate or 'default'
    delay = get_delay(device,dimmingDuration,99)
    get = SwitchMultilevel:Get({})
  else
    get = Basic:Get({})
  end
  device:send_to_component(set, command.component)
  local query_device = function()
    device:send_to_component(get, command.component)
  end
  device.thread:call_with_delay(delay, query_device)
end

local function on_handler(driver, device, command)
  switch_set_helper(driver, device, SwitchBinary.value.ON_ENABLE, command)
end

local function off_handler(driver, device, command)
  switch_set_helper(driver, device, SwitchBinary.value.OFF_DISABLE, command)
end

local function switch_level_handler(driver, device, command)
  local set
  local get
  local level, distance = get_distance(device,command)
  local dimmingDuration = command.args.rate or 'default' -- dimming duration in seconds
  local delay = get_delay(device,dimmingDuration,distance) -- delay in seconds
  if device:is_cc_supported(cc.SWITCH_MULTILEVEL) then
    get = SwitchMultilevel:Get({})
    if dimmingDuration == "default" then
      set = Basic:Set({ value=level })
    else
      set = SwitchMultilevel:Set({ value=level, duration=dimmingDuration })
    end
  elseif device:is_cc_supported(cc.BASIC) then
    get = Basic:Get({})
    set = Basic:Set({ value=level})
  end
  device:send_to_component(set, command.component)
  local query_level = function()
    device:send_to_component(get, command.component)
  end
  device.thread:call_with_delay(delay, query_level)
end

local ge_motion = {
  zwave_handlers = {
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = configuration_report,
    },
    [cc.BASIC] = {
      [Basic.REPORT] = basic_report,
      [Basic.SET] = basic_set,
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
  lifecycle_handlers = {
    init = init,
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
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_handler,
      [capabilities.switch.commands.off.NAME] = off_handler,
    },
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = switch_level_handler,
    },
  },
  NAME = "ge zwave motion switch",
  can_handle = can_handle_ge_motion,
}

return ge_motion