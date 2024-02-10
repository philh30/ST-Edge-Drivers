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
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({version=1,strict=true})
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({version=3})
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2,strict=true})
local preferencesMap = require "preferences"
local update_preferences = require "update_preferences"
local splitAssocString = require "split_assoc_string"
local call_parent_handler = require "call_parent"

local GE_SWITCH_FINGERPRINTS = {
  {mfr = 0x0063, prod = 0x4450, model = 0x3030},
  {mfr = 0x0063, prod = 0x4944, model = 0x3031},
  {mfr = 0x0063, prod = 0x4944, model = 0x3032},
  {mfr = 0x0063, prod = 0x4944, model = 0x3033},
  {mfr = 0x0063, prod = 0x4944, model = 0x3034},
  {mfr = 0x0063, prod = 0x4944, model = 0x3035},
  {mfr = 0x0063, prod = 0x4944, model = 0x3036},
  {mfr = 0x0063, prod = 0x4944, model = 0x3037},
  {mfr = 0x0063, prod = 0x4944, model = 0x3038},
  {mfr = 0x0063, prod = 0x4944, model = 0x3039},
  {mfr = 0x0063, prod = 0x4944, model = 0x3130},
  {mfr = 0x0063, prod = 0x4944, model = 0x3131},
  {mfr = 0x0063, prod = 0x4944, model = 0x3233},
  {mfr = 0x0063, prod = 0x4944, model = 0x3235},
  {mfr = 0x0063, prod = 0x4944, model = 0x3237},
  {mfr = 0x0063, prod = 0x4944, model = 0x3333},
  {mfr = 0x0063, prod = 0x4944, model = 0x3334},
  {mfr = 0x0063, prod = 0x4944, model = 0x3337},
  {mfr = 0x0063, prod = 0x4944, model = 0x3339},
  {mfr = 0x0063, prod = 0x4952, model = 0x3031},
  {mfr = 0x0063, prod = 0x4952, model = 0x3032},
  {mfr = 0x0063, prod = 0x4952, model = 0x3033},
  {mfr = 0x0063, prod = 0x4952, model = 0x3034},
  {mfr = 0x0063, prod = 0x4952, model = 0x3035},
  {mfr = 0x0063, prod = 0x4952, model = 0x3036},
  {mfr = 0x0063, prod = 0x4952, model = 0x3037},
  {mfr = 0x0063, prod = 0x4952, model = 0x3038},
  {mfr = 0x0063, prod = 0x4952, model = 0x3130},
  {mfr = 0x0063, prod = 0x4952, model = 0x3133},
  {mfr = 0x0063, prod = 0x4952, model = 0x3134},
  {mfr = 0x0063, prod = 0x4952, model = 0x3135},
  {mfr = 0x0063, prod = 0x4952, model = 0x3136},
  {mfr = 0x0063, prod = 0x4952, model = 0x3137},
  {mfr = 0x0063, prod = 0x4952, model = 0x3139},
  {mfr = 0x0063, prod = 0x4952, model = 0x3231},
  {mfr = 0x0063, prod = 0x4952, model = 0x3233},
  {mfr = 0x0063, prod = 0x4952, model = 0x3234},
  {mfr = 0x0063, prod = 0x4952, model = 0x3235},
  {mfr = 0x0063, prod = 0x4952, model = 0x3237},
  {mfr = 0x0063, prod = 0x4952, model = 0x3238},
  {mfr = 0x0063, prod = 0x4F44, model = 0x3032},
  {mfr = 0x0063, prod = 0x4F50, model = 0x3031},
  {mfr = 0x0063, prod = 0x4F50, model = 0x3032},
  {mfr = 0x0063, prod = 0x4F50, model = 0x3034},
  {mfr = 0x0063, prod = 0x5044, model = 0x3031},
  {mfr = 0x0063, prod = 0x5044, model = 0x3033},
  {mfr = 0x0063, prod = 0x5044, model = 0x3038},
  {mfr = 0x0063, prod = 0x5044, model = 0x3130},
  {mfr = 0x0063, prod = 0x5044, model = 0x3132},
  {mfr = 0x0063, prod = 0x5052, model = 0x3031},
  {mfr = 0x0063, prod = 0x5052, model = 0x3033},
  {mfr = 0x0063, prod = 0x5052, model = 0x3038},
  {mfr = 0x0063, prod = 0x5052, model = 0x3130},
  {mfr = 0x0063, prod = 0x5052, model = 0x3132},  -- 28177 GE Plug In Dual
  {mfr = 0x0063, prod = 0x5252, model = 0x3530},
  {mfr = 0x0063, prod = 0x5257, model = 0x3533},
  {mfr = 0x0039, prod = 0x4944, model = 0x3038},
  {mfr = 0x0039, prod = 0x4944, model = 0x3130},
  {mfr = 0x0039, prod = 0x4944, model = 0x3131},
  {mfr = 0x0039, prod = 0x4944, model = 0x3235},
  {mfr = 0x0039, prod = 0x4944, model = 0x3237},
  {mfr = 0x0039, prod = 0x4952, model = 0x3036},
  {mfr = 0x0039, prod = 0x4952, model = 0x3037},
  {mfr = 0x0039, prod = 0x4952, model = 0x3133},
  {mfr = 0x0039, prod = 0x4952, model = 0x3135},
  {mfr = 0x0039, prod = 0x4952, model = 0x3137},
  {mfr = 0x0039, prod = 0x4F50, model = 0x3032},
  {mfr = 0x0039, prod = 0x4F50, model = 0x3034},
  {mfr = 0x0039, prod = 0x5044, model = 0x3033},
  {mfr = 0x0039, prod = 0x5044, model = 0x3038},
  {mfr = 0x0039, prod = 0x5052, model = 0x3033},
  {mfr = 0x0039, prod = 0x5052, model = 0x3038},
}

--- Determine whether the passed device is a 3-speed fan
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true if the device is an 3-speed fan, else false
local function can_handle_ge_switch(opts, driver, device, ...)
  for _, fingerprint in ipairs(GE_SWITCH_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
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

 -- Handle zwave plus lifeline associations
 if device:is_cc_supported(cc.ZWAVEPLUS_INFO) and device:is_cc_supported(cc.ASSOCIATION)  then
  device.log.debug("Adding to lifeline")
  -- Add us to lifeline
  device:send(Association:Set({grouping_identifier = 1, node_ids ={driver.environment_info.hub_zwave_id}}))
  device:send(Association:Get({grouping_identifier = 1}))
end

end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added(driver, device, event, args)
    -- Call the topmost 'added' lifecycle hander to do any default work
  call_parent_handler(driver.lifecycle_handlers.added, driver, device, event, args)
  update_preferences(driver, device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function basic_set(driver, device, cmd)
  local evt = capabilities.button.button.pushed_2x()
  evt.state_change = true
  device:emit_event(evt)
  evt = (cmd.args.value == 0) and capabilities.button.button.down_2x() or capabilities.button.button.up_2x()
  evt.state_change = true
  device:emit_event(evt)
end

local map_key_attribute_to_capability = {
  [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = '',
  [CentralScene.key_attributes.KEY_RELEASED] = '_released', -- released doesn't exist on button capability, so don't emit this event
  [CentralScene.key_attributes.KEY_HELD_DOWN] = '_hold',
  [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = '_2x',
  [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = '_3x',
  [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = '_4x',
  [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = '_5x',
}

--- Generates and send button capability event
---
--- @param device st.zwave.Device
--- @param capability_attribute function generates capability event
--- @param  button_number number
local function send_button_capability_event(device, capability_attribute, button_number, cmd)
  local additional_fields = {
    state_change = true
  }
  local event
  if capability_attribute ~= nil then
    event = capability_attribute(additional_fields)
  end

  if event ~= nil then
    device:emit_event_for_endpoint(cmd.src_channel, event)
  end
end

--- Handler for scene notification command class reports
---
--- Shall emit appropriate capabilities.button event ( `pushed`, `held` etc.)
--- based on command's key_attributes
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.CentralScene.Notification
---           expected command arguments:
---           args={key_attributes="KEY_PRESSED_1_TIME",
---                 scene_number=0, sequence_number=0, slow_refresh=false}
local function central_scene_notification_handler(self, device, cmd)
  local button_number = 1
  if ( cmd.args.scene_number ~= nil and cmd.args.scene_number ~= 0 ) then
    button_number = cmd.args.scene_number
  end
  local suffix = map_key_attribute_to_capability[cmd.args.key_attributes]
  local button_key = ((button_number == 1) and 'up' or 'down') .. suffix
  local generic_push = (suffix == '_hold') and ('held') or ('pushed' .. suffix)
  if cmd.args.key_attributes ~= CentralScene.key_attributes.KEY_RELEASED then
    send_button_capability_event(device,capabilities.button.button[generic_push],button_number,cmd)
    send_button_capability_event(device,capabilities.button.button[button_key],button_number,cmd)
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Basic.Report
local function basic_report(driver,device,cmd)
  local event
  if cmd.args.target_value ~= nil then
    -- Target value is our best inidicator of eventual state.
    -- If we see this, it should be considered authoritative.
    if cmd.args.target_value == SwitchBinary.value.OFF_DISABLE then
      event = capabilities.switch.switch.off()
    else
      event = capabilities.switch.switch.on()
    end
  else
    if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
      event = capabilities.switch.switch.off()
    else
      event = capabilities.switch.switch.on()
    end
  end
  device:emit_event_for_endpoint(cmd.src_channel, event)
end

local ge_switch = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.SET] = basic_set,
      [Basic.REPORT] = basic_report,
    },
    [cc.CENTRAL_SCENE] = {
      [CentralScene.NOTIFICATION] = central_scene_notification_handler,
    },
  },
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.fanSpeed,
    capabilities.refresh,
    capabilities.button,
    capabilities.energyMeter,
    capabilities.powerMeter,
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = added,
  },
  sub_drivers = {
    require("zwave-fan-3-speed"),
    require("ge-switch-dual"),
  },
  NAME = "ge zwave",
  can_handle = can_handle_ge_switch,
}

return ge_switch