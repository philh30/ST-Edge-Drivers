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

local CC = require "st.zwave.CommandClass"
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local capabilities = require "st.capabilities"

local ZWAVE_TEMP_LEAK_SENSOR_FINGERPRINTS = {
  { -- Homeseer HS-LS100+ Temperature Shock and Leak Sensor
    mfr   = 0x000C,
    prod  = 0x0201,
    model = 0x000A
  }
}

-- If needed, update our device profile.
local function update_device_profile(self, device)
  local hasTemp = device:supports_capability_by_id(capabilities.temperatureMeasurement.ID)
  -- we may need to change profiles
  if tonumber(device.preferences["tempReportInterval"]) > 0 then
    -- temperature reporting is enabled
    if not hasTemp then
      device:try_update_metadata({profile = "homeseer-leak-temp"})
    end
  else
    -- temperature reporting is disabled
    if hasTemp then
      device:try_update_metadata({profile = "homeseer-leak"})
    end
  end
end

local function can_handle_zwave_temp_leak_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_TEMP_LEAK_SENSOR_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function call_parent_handler(handlers, self, device, event, args)
  if type(handlers) == "function" then
    handlers = { handlers }  -- wrap as table
  end
  for _, func in ipairs( handlers or {} ) do
      func(self, device, event, args)
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function hsl_init(self, device, event, args)
  -- We may need to update our profile
  update_device_profile(self, device)

  -- Call the topmost 'init' lifecycle hander to do any default work
  call_parent_handler(self.lifecycle_handlers.init, self, device, event, args)
end

local function basic_set(driver, device, cmd)
  device.log.trace("basic_set() ignored")
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function hsl_doConfigure(self, device, event, args)
  -- Call the topmost 'doConfigure' lifecycle hander to do the default work first
  call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, event, args)

  -- Send the default refresh commands for the capabilities of this device
  -- This includes SENSOR_BINARY GET and BATTERY GET.
  device:default_refresh()
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function hsl_infoChanged(self, device, event, args)
  -- We may need to update our device profile
  update_device_profile(self, device)

  -- Call the topmost 'infoChanged' lifecycle hander to do any default work
  call_parent_handler(self.lifecycle_handlers.infoChanged, self, device, event, args)
end

local homeseer_leak = {
  zwave_handlers = {
    [CC.BASIC] = {
      [Basic.SET] = basic_set,
    },
  },
  lifecycle_handlers = {
    init        = hsl_init,
    -- added =
    doConfigure = hsl_doConfigure,
    infoChanged = hsl_infoChanged,
  },
  NAME = "homeseer ls100+ leak sensor",
  can_handle = can_handle_zwave_temp_leak_sensor,
}

return homeseer_leak