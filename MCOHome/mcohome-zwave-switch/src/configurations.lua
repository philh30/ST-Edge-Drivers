-- Copyright 2022 SmartThings
-- Modified 2022 philh30 - MCOHome devices
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

--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })

local devices = {
  MCOHOME_2_LEGACY = {
    MATCHING_MATRIX = {
      mfrs = 0x015F,
      product_types = 0x3121,
      product_ids = 0x1302
    },
    ASSOCIATION = {
      {grouping_identifier = 3}
    }
  },
  MCOHOME_4_LEGACY = {
    MATCHING_MATRIX = {
      mfrs = 0x015F,
      product_types = 0x3141,
      product_ids = 0x1302
    },
    ASSOCIATION = {
      {grouping_identifier = 5}
    }
  },
  MCOHOME_4 = {
    MATCHING_MATRIX = {
      mfrs = 0x015F,
      product_types = 0x3141,
      product_ids = 0x5102
    },
    ASSOCIATION = {
      {grouping_identifier = 1}
    },
    CONFIGURATION = {
      {parameter_number = 8, size = 1, configuration_value = 1},
    }
  },
}

local configurations = {}

configurations.initial_configuration = function(driver, device)
  local configuration = configurations.get_device_configuration(device)
  if configuration ~= nil then
    for _, value in ipairs(configuration) do
      device:send(Configuration:Set(value))
    end
  end
  local association = configurations.get_device_association(device)
  if association ~= nil then
    for _, value in ipairs(association) do
      local _node_ids = value.node_ids or {driver.environment_info.hub_zwave_id}
      device:send(Association:Set({grouping_identifier = value.grouping_identifier, node_ids = _node_ids}))
      device:send(Association:Get({grouping_identifier = value.grouping_identifier}))
    end
  end
end

configurations.get_device_configuration = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.CONFIGURATION
    end
  end
  return nil
end

configurations.get_device_association = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.ASSOCIATION
    end
  end
  return nil
end

return configurations