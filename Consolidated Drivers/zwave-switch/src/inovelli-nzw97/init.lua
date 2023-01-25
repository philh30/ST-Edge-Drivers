-- Author: csstup
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
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version = 2 })

local log = require "log"

-- NZW97 Notes:
-- Associations require firmware 1.02 or later to work correctly, even though the 
-- device reports the class.

local INOVELLI_2_CHANNEL_SMART_PLUG_FINGERPRINTS = {
  --{mfr = 0x015D, prod = 0x0221, model = 0x251C}, -- Show Home Outlet
  --{mfr = 0x0312, prod = 0x0221, model = 0x251C}, -- Inovelli Outlet
  --{mfr = 0x0312, prod = 0xB221, model = 0x251C}, -- Inovelli Outlet
  --{mfr = 0x0312, prod = 0x0221, model = 0x611C}, -- Inovelli Outlet
  --{mfr = 0x015D, prod = 0x0221, model = 0x611C}, -- Inovelli Outlet
  --{mfr = 0x015D, prod = 0x6100, model = 0x6100}, -- Inovelli Outlet
    {mfr = 0x0312, prod = 0x6100, model = 0x6100}, -- Inovelli NZW97 Outdoor Dual Outlet
  --{mfr = 0x015D, prod = 0x2500, model = 0x2500}, -- Inovelli Outlet
}

local function can_handle_inovelli_2_channel_smart_plug(opts, driver, device, ...)
  for _, fingerprint in ipairs(INOVELLI_2_CHANNEL_SMART_PLUG_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function supports_associations(driver, device)
  local fw_major = (((device.st_store or {}).zwave_version or {}).firmware or {}).major
  local fw_minor = (((device.st_store or {}).zwave_version or {}).firmware or {}).minor
  if fw_major and fw_minor then
    if fw_major >= 1 and fw_minor >= 2 then
      -- firmware 1.02 or later required for correct association support
      return true
    end
  end
  return false
end


-- Update the state of the "main" switch.
-- If either child is on, then main is on.
-- If both children are off, then main is off.
local function handle_main_switch_event(device, value)
  if value == SwitchBinary.value.ON_ENABLE then
    device:emit_event(capabilities.switch.switch.on())
  else
    if device:get_latest_state("switch1", capabilities.switch.ID, capabilities.switch.switch.NAME) == "on" or
        device:get_latest_state("switch2", capabilities.switch.ID, capabilities.switch.switch.NAME) == "on" then
      device:emit_event(capabilities.switch.switch.on())
    else
      device:emit_event(capabilities.switch.switch.off())
    end
  end
end

-- Get the status of the two child switches.
local function query_switch_status(device)
  device:send_to_component(SwitchBinary:Get({}), "switch1")
  device:send_to_component(SwitchBinary:Get({}), "switch2")
end

-- Handle a basic set from a associated another device
local function basic_set_handler(driver, device, cmd)
  local value = cmd.args.target_value and cmd.args.target_value or cmd.args.value
  local event = value == SwitchBinary.value.OFF_DISABLE and capabilities.switch.switch.off() or capabilities.switch.switch.on()

  device:emit_event_for_endpoint(cmd.src_channel, event)

  query_switch_status(device)
end

local function basic_and_switch_binary_report_handler(driver, device, cmd)
  device.log.trace("basic_and_switch_binary_report_handler: cmd.src_channel" .. cmd.src_channel)
  local value = cmd.args.target_value and cmd.args.target_value or cmd.args.value

  if cmd.src_channel == 0 then
    -- src_channel 0 from the device is just a reflection of channel 1 (switch 1).
    -- Just ignore it.
  else
    -- For other channels, update that endpoint.
    local event = value == SwitchBinary.value.OFF_DISABLE and capabilities.switch.switch.off() or capabilities.switch.switch.on()
    device:emit_event_for_endpoint(cmd.src_channel, event)
    -- And sync the "main" state based on the state of the two child switches.
    handle_main_switch_event(device, value)
  end
end

local function set_switch_value(driver, device, value, command)
  if command.component == "main" then
    -- For main, if we request "endpoint 0", the device only changes endpoint 1 (switch1).
    -- So instead control both child endpoints.
    device:send_to_component(SwitchBinary:Set({target_value = value, duration = 0}), "switch1")
    device:send_to_component(SwitchBinary:Set({target_value = value, duration = 0}), "switch2")
  else
    --Set individual switch value
    device:send_to_component(SwitchBinary:Set({target_value = value, duration = 0}), command.component)
  end
end

local function switch_set_helper(value)
  return function(driver, device, command) return set_switch_value(driver, device, value, command) end
end

local inovelli_2_channel_smart_plug = {
  NAME = "Inovelli 2 channel smart plug",
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.REPORT] = basic_and_switch_binary_report_handler,
      [Basic.SET] = basic_set_handler
    },
    [cc.SWITCH_BINARY] = {
      [SwitchBinary.REPORT] = basic_and_switch_binary_report_handler
    }
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME]  = switch_set_helper(SwitchBinary.value.ON_ENABLE),
      [capabilities.switch.commands.off.NAME] = switch_set_helper(SwitchBinary.value.OFF_DISABLE)
    }
  },
  lifecycle_handlers = {
    -- added          = device_added,
  },
  can_handle = can_handle_inovelli_2_channel_smart_plug,
}

return inovelli_2_channel_smart_plug
