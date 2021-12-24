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
--- @type st.zwave.CommandClass.SceneActivation
local SceneActivation = (require "st.zwave.CommandClass.SceneActivation")({version=1,strict=true})
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({version=1,strict=true})
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function update_preferences(driver, device, args)
  local preferences = preferencesMap.get_device_parameters(device)
  for id, value in pairs(device.preferences) do
    if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and preferences and preferences[id]) then
      if preferences[id].type == 'config' then
        local new_parameter_value = preferencesMap.to_numeric_value(device.preferences[id])
        device:send(Configuration:Set({parameter_number = preferences[id].parameter_number, size = preferences[id].size, configuration_value = new_parameter_value}))
      elseif preferences[id].type == 'assoc' then
        local group = preferences[id].group
        local maxnodes = preferences[id].maxnodes
        local addhub = preferences[id].addhub
        local nodes = splitAssocString(value,',',maxnodes,addhub)
        device:send(Association:Remove({grouping_identifier = group, node_ids = {}}))
        if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {1}})) end --add hub to group 3 for double click reporting
        if #nodes > 0 then
          device:send(Association:Set({grouping_identifier = group, node_ids = nodes}))
        end
        device:send(Association:Get({grouping_identifier = group}))
      end
    end
  end
  if device:supports_capability_by_id(capabilities.button.ID) then
    local buttons = preferencesMap.get_buttons(device)
    if buttons and buttons.count then device:emit_event(capabilities.button.numberOfButtons({ value = buttons.count })) end
    if buttons and buttons.values then device:emit_event(capabilities.button.supportedButtonValues({ value = buttons.values })) end
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
  local generic_push = 'pushed' .. suffix
  if cmd.args.key_attributes ~= CentralScene.key_attributes.KEY_RELEASED then
    send_button_capability_event(device,capabilities.button.button[generic_push],button_number,cmd)
    send_button_capability_event(device,capabilities.button.button[button_key],button_number,cmd)
  end
end

local driver_template = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.SET] = basic_set,
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
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = added,
  },
  NAME = "ge zwave",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ge_switch = ZwaveDriver("ge-zwave-switch", driver_template)
ge_switch:run()