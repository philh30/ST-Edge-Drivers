-- Copyright 2021 SmartThings
-- Modified by philh30 to handle z-wave association
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
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
--- @type st.zwave.CommandClass.MultiChannelAssociation
local MultiChannelAssociation = (require "st.zwave.CommandClass.MultiChannelAssociation")({ version=4 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"


--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function update_preferences(driver, device, args)
  local preferences = preferencesMap.get_device_parameters(device)
  local supports_multi = device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION)
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
        local nodes,multi_nodes,multi = splitAssocString(value,',',maxnodes,addhub,supports_multi)
        local hubnode = device.driver.environment_info.hub_zwave_id
        if supports_multi then
          device:send(MultiChannelAssociation:Remove({grouping_identifier = group, node_ids = {}, multi_channel_nodes = {}}))
        else
          device:send(Association:Remove({grouping_identifier = group, node_ids = {}}))
        end
        if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {hubnode}})) end
        if (#multi_nodes + #nodes) > 0 then
          if multi then
            device:send(MultiChannelAssociation:Set({grouping_identifier = group, node_ids = nodes, multi_channel_nodes = multi_nodes}))
          else
            device:send(Association:Set({grouping_identifier = group, node_ids = nodes}))
          end
        end
        if multi then
          device:send(MultiChannelAssociation:Get({grouping_identifier = group}))
        else
          device:send(Association:Get({grouping_identifier = group}))
        end
      end
    end
  end
  if device:supports_capability_by_id(capabilities.button.ID) then
    local buttons = preferencesMap.get_buttons(device)
    if buttons and buttons.count then device:emit_event(capabilities.button.numberOfButtons({ value = buttons.count })) end
    if buttons and buttons.values then device:emit_event(capabilities.button.supportedButtonValues({ value = buttons.values })) end
  end
end

return update_preferences