-- Copyright 2021 SmartThings
--
-- Edited by philh30 to use as library instead of subdriver
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

local log = require "log"
local fan_speed_helper = (require "zwave_fan_helpers")

local zwave_fan_3_speed = {}

local function map_fan_3_speed_to_switch_level (speed)
  if speed == fan_speed_helper.fan_speed.OFF then
    return fan_speed_helper.levels_for_inovelli_3_speed.OFF -- off
  elseif speed == fan_speed_helper.fan_speed.LOW then
    return fan_speed_helper.levels_for_inovelli_3_speed.LOW -- low
  elseif speed == fan_speed_helper.fan_speed.MEDIUM then
    return fan_speed_helper.levels_for_inovelli_3_speed.MEDIUM -- medium
  elseif speed == fan_speed_helper.fan_speed.HIGH or speed == fan_speed_helper.fan_speed.MAX then
    return fan_speed_helper.levels_for_inovelli_3_speed.HIGH -- high and max
  else
    log.error (string.format("3 speed fan driver: invalid speed: %d", speed))
  end
end

local function map_switch_level_to_fan_3_speed (level)
  if (level == fan_speed_helper.levels_for_inovelli_3_speed.OFF) then
    return fan_speed_helper.fan_speed.OFF
  elseif (fan_speed_helper.levels_for_inovelli_3_speed.OFF < level and level <= fan_speed_helper.levels_for_inovelli_3_speed.LOW) then
    return fan_speed_helper.fan_speed.LOW
  elseif (fan_speed_helper.levels_for_inovelli_3_speed.LOW < level and level <= fan_speed_helper.levels_for_inovelli_3_speed.MEDIUM) then
    return fan_speed_helper.fan_speed.MEDIUM
  elseif (fan_speed_helper.levels_for_inovelli_3_speed.MEDIUM < level and level <= fan_speed_helper.levels_for_inovelli_3_speed.MAX) then
    return fan_speed_helper.fan_speed.HIGH
  else
    log.error (string.format("3 speed fan driver: invalid level: %d", level))
  end
end

--- Issue a level-set command to the specified device.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table ST level capability command
function zwave_fan_3_speed.fan_speed_set(driver, device, command)
  fan_speed_helper.capability_handlers.fan_speed_set(driver, device, command, map_fan_3_speed_to_switch_level)
end

--- Convert `SwitchMultilevel` level {0 - 99}
--- into `FanSpeed` speed { 0, 1, 2, 3, 4}
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SwitchMultilevel.Report
function zwave_fan_3_speed.fan_multilevel_report(driver, device, cmd)
  fan_speed_helper.zwave_handlers.fan_multilevel_report(driver, device, cmd, map_switch_level_to_fan_3_speed)
end

return zwave_fan_3_speed
