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
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local clusters = require "st.zigbee.zcl.clusters"
local ElectricalMeasurement = clusters.ElectricalMeasurement
local SimpleMetering = clusters.SimpleMetering
local Level = clusters.Level
local OnOff = clusters.OnOff
local constants = require "st.zigbee.constants"
local log = require "log"
local utils = require "st.utils"
local delay_send = require "delay_send"

--- @param driver ZigbeeDriver The current driver running containing necessary context for execution
--- @param device st.zigbee.Device The device this message was received from containing identifying information
local function get_multiplier_divisor(driver,device)
  -- Additional one time configuration
  if device:supports_capability(capabilities.energyMeter) or device:supports_capability(capabilities.powerMeter) then
    -- Divisor and multipler for EnergyMeter
    device:send(ElectricalMeasurement.attributes.ACPowerDivisor:read(device))
    device:send(ElectricalMeasurement.attributes.ACPowerMultiplier:read(device))
    -- Divisor and multipler for PowerMeter
    device:send(SimpleMetering.attributes.Divisor:read(device))
    device:send(SimpleMetering.attributes.Multiplier:read(device))
  end
end

--- @param driver ZigbeeDriver The current driver running containing necessary context for execution
--- @param device st.zigbee.Device The device this message was received from containing identifying information
local function do_configure(driver, device)
  device:refresh()
  device:configure()
  get_multiplier_divisor(driver,device)
end

local function init(driver,device)
  get_multiplier_divisor(driver,device)
end

--- @param driver ZigbeeDriver The current driver running containing necessary context for execution
--- @param device st.zigbee.Device The device this message was received from containing identifying information
--- @param args table The capability command table
local function info_changed(driver, device, args)
  if device.preferences['defaultLevel'] then
    local dim_raw = device.preferences['defaultLevel']
    local max_level = device.preferences['maxLevel'] or 254
    local min_level = device.preferences['minLevel'] or 0
    min_level = (min_level < max_level) and min_level or 0
    dim_raw = (dim_raw == 0) and 255 or math.floor(min_level+dim_raw*(max_level-min_level)/100)
    device:send(Level.attributes.OnLevel:write(device,dim_raw))
    device:send(Level.attributes.OnLevel:read(device))
  end
  device:refresh()
end

local function raw_to_level(device,raw)
  local max_level = device.preferences['maxLevel'] or 254
  local min_level = device.preferences['minLevel'] or 0
  min_level = (min_level < max_level) and min_level or 0
  local level = (raw==0) and 0 or math.floor(min_level+raw*(max_level-min_level)/100)
  return level
end

--- This will send the move to level with on off command to the level control cluster
---
--- @param driver ZigbeeDriver The current driver running containing necessary context for execution
--- @param device st.zigbee.Device The device this message was received from containing identifying information
--- @param command table The capability command table
local function set_level(driver, device, command)
  local curr_level = device:get_latest_state(command.component,capabilities.switchLevel.ID,capabilities.switchLevel.level.NAME)
  local curr_state = device:get_latest_state(command.component,capabilities.switch.ID,capabilities.switch.switch.NAME)
  local raw = command.args.level
  local level = raw_to_level(device,raw)
  local rate = command.args.rate or device.preferences['levelChangeTime'] or 0xFFFF
  local scaleRate = device.preferences['levelChangeScaling'] == '1'
  local startAtZero = device.preferences['startLevel'] == '0'
  local cmd = {}
  if startAtZero and (curr_state == 'off') then
    table.insert(cmd,Level.server.commands.MoveToLevel(device, 1, 0))
    curr_level = 0
  end
  if scaleRate then
    local change = curr_level and math.abs(curr_level - raw) or 100
    rate = (rate == 0xFFFF) and 0xFFFF or math.floor(rate*change/100)
  end
  table.insert(cmd,Level.server.commands.MoveToLevelWithOnOff(device, level, rate))
  if curr_state == 'off' then
    table.insert(cmd,clusters.OnOff.server.commands.On(device))
  end
  delay_send(device,cmd,0.5)
end

--- This converts the Uint8 value from 0-254 to SwitchLevel.level(0-100)
---
--- @param driver Driver The current driver running containing necessary context for execution
--- @param device st.zigbee.Device The device this message was received from containing identifying information
--- @param value st.zigbee.data_types.Uint8 the value of the current level attribute of the level control cluster
--- @param zb_rx st.zigbee.ZigbeeMessageRx the full message this report came in
local function level_attr_handler(driver, device, value, zb_rx)
  local max_level = device.preferences['maxLevel'] or 254
  local min_level = device.preferences['minLevel'] or 0
  min_level = (min_level < max_level) and min_level or 0
  local level = math.floor(((utils.clamp_value(value.value,min_level,max_level)-min_level)/(max_level-min_level)* 100) + 0.5)
  device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capabilities.switchLevel.level(level))
end

--- Fix for an error in the default handler for InstantaneousDemand attribute on SimpleMetering cluster
---
--- @param driver ZigbeeDriver The current driver running containing necessary context for execution
--- @param device st.zigbee.Device The device this message was received from containing identifying information
--- @param value st.zigbee.data_types.Int24 the value of the instantaneous demand
--- @param zb_rx st.zigbee.ZigbeeMessageRx the full message this report came in
local function instantaneous_demand_handler(driver, device, value, zb_rx)
  local raw_value = value.value
  --- demand = demand received * Multipler/Divisor
  local multiplier = device:get_field(constants.SIMPLE_METERING_MULTIPLIER_KEY) or 1
  local divisor = device:get_field(constants.SIMPLE_METERING_DIVISOR_KEY) or 1
  raw_value = raw_value * multiplier/divisor*1000
  device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capabilities.powerMeter.power({value = raw_value, unit = "W" }))
end

---- Driver template config
local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.powerMeter,
    capabilities.energyMeter,
    capabilities.refresh
  },
  lifecycle_handlers = {
    doConfigure = do_configure,
    infoChanged = info_changed,
    init = init,
  },
  zigbee_handlers = {
    attr = {
      [Level.ID] = {
        [Level.attributes.CurrentLevel.ID] = level_attr_handler
      },
      [SimpleMetering.ID] = {
        [SimpleMetering.attributes.InstantaneousDemand.ID] = instantaneous_demand_handler,
      }
    }
  },
  capability_handlers = {
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = set_level,
    },
  },
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ge_switch = ZigbeeDriver("ge-zigbee-switch", driver_template)
ge_switch:run()