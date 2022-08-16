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
--- @type st.zwave.defaults
local defaults = require "st.zwave.defaults"
--- @type st.zwave.Driver
local ZwaveDriver = require "st.zwave.driver"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
local preferencesMap = require "preferences"
local splitAssocString = require "split_assoc_string"

--- Map component to end_points(channels)
---
--- @param device st.zwave.Device
--- @param component_id string ID
--- @return table dst_channels destination channels e.g. {2} for Z-Wave channel 2 or {} for unencapsulated
local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("switch(%d)")
  return { ep_num and tonumber(ep_num) } 
end

--- Map end_point(channel) to Z-Wave endpoint 9 channel)
---
--- @param device st.zwave.Device
--- @param ep number the endpoint(Z-Wave channel) ID to find the component for
--- @return string the component ID the endpoint matches to
local function endpoint_to_component(device, ep)
  local switch_comp = string.format("switch%d", ep)
  if device.profile.components[switch_comp] ~= nil then
    return switch_comp
  else
    return "main"
  end
end

--- Initialize device
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local device_init = function(self, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
end

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
        if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {hubnode}})) end
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

local function device_added(driver, device)
  device:refresh()
end

-------------------------------------------------------------------------------------------
-- Register message handlers and run driver
-------------------------------------------------------------------------------------------
local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.colorControl,
    capabilities.colorTemperature,
    capabilities.colorMode,
    capabilities.powerMeter,
    capabilities.energyMeter,
    capabilities.button,
    capabilities.refresh,
  },
  capability_handlers = {
--[[
      [capabilities.refresh.ID] = {
          [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
        },
--]]
  },
  sub_drivers = {
    require("inovelli-lzw45")
  },
  lifecycle_handlers = {
    init = device_init,
    infoChanged = info_changed,
    added = device_added
  }
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
--- @type st.zwave.Driver
local switch = ZwaveDriver("zwave_switch", driver_template)
switch:run()
