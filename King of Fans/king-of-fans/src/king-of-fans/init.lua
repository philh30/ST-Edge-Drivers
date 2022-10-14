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

local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local FanControl = clusters.FanControl
local Level = clusters.Level
local OnOff = clusters.OnOff

local KOF_FINGERPRINTS = {
  { mfr = "King Of Fans,  Inc.", model = "HDC52EastwindFan" },
}

local is_kof = function(opts, driver, device)
  for _, fingerprint in ipairs(KOF_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

local levels_for_4_speed = {
  [0] = 0,
  [1] = 25,
  [2] = 50,
  [3] = 75,
  [4] = 100,
}

local function level_to_speed(level)
  local speed = 0
  for spd, lvl in ipairs(levels_for_4_speed) do
    if (level >= lvl) and (spd > speed) then
      speed = spd
    end
  end
  return speed
end

-- CAPABILITY HANDLERS

local function on_handler(driver, device, command)
  if command.component == 'light' then
    device:send(OnOff.server.commands.On(device))
  else
    local speed = tonumber(device.preferences.defaultFanOn) or 1
    device:send(FanControl.attributes.FanMode:write(device,speed))
  end
end

local function off_handler(driver, device, command)
  if command.component == 'light' then
    device:send(OnOff.server.commands.Off(device))
  else
    device:send(FanControl.attributes.FanMode:write(device,FanControl.attributes.FanMode.OFF))
  end
end

local function switch_level_handler(driver, device, command)
  if command.component == 'light' then
    local level = math.floor(command.args.level/100.0 * 254)
    device:send(Level.server.commands.MoveToLevelWithOnOff(device, level, command.args.rate or 0xFFFF))
  else
    local speed = level_to_speed(command.args.level)
    if speed then
      device:send(FanControl.attributes.FanMode:write(device,speed))
    end
  end
end

local function fan_speed_handler(driver, device, command)
  device:send(FanControl.attributes.FanMode:write(device,command.args.speed))
end

-- ZIGBEE HANDLERS

local function zb_fan_control_handler(driver, device, value, zb_rx)
  if value.value < 5 then
    device:emit_event(capabilities.fanSpeed.fanSpeed(value.value))
  end
  local attr = capabilities.switch.switch
  device:emit_component_event(device.profile.components.main,value.value > 0 and attr.on() or attr.off())
  device:emit_component_event(device.profile.components.main,capabilities.switchLevel.level(levels_for_4_speed[value.value]))
end

local function zb_level_handler(driver, device, value, zb_rx)
  device:emit_component_event(device.profile.components.light,capabilities.switchLevel.level(math.floor((value.value / 254.0 * 100) + 0.5)))
end

local function zb_onoff_handler(driver, device, value, zb_rx)
  local attr = capabilities.switch.switch
  device:emit_component_event(device.profile.components.light,value.value and attr.on() or attr.off())
end

local king_of_fans = {
  NAME = "King of Fans",
  zigbee_handlers = {
    attr = {
      [FanControl.ID] = {
        [FanControl.attributes.FanMode.ID] = zb_fan_control_handler
      },
      [Level.ID] = {
        [Level.attributes.CurrentLevel.ID] = zb_level_handler
      },
      [OnOff.ID] = {
        [OnOff.attributes.OnOff.ID] = zb_onoff_handler
      }
    }
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_handler,
      [capabilities.switch.commands.off.NAME] = off_handler,
    },
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = switch_level_handler
    },
    [capabilities.fanSpeed.ID] = {
      [capabilities.fanSpeed.commands.setFanSpeed.NAME] = fan_speed_handler
    }
  },
  can_handle = is_kof
}

return king_of_fans