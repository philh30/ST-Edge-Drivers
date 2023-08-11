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
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.Battery
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 2 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local call_parent_handler = require "call_parent"
local battery = require "battery"

local ZOOZ_FINGERPRINTS = {
  { manufacturerId = 0x027A, productType = 0x7000, productId = 0xE001 }, -- Zooz ZSE41
}

--- Determine whether the passed device is zooz_4_in_1_sensor
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true if the device proper, else false
local function can_handle_zooz_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZOOZ_FINGERPRINTS) do
    if device:id_match(fingerprint.manufacturerId, fingerprint.productType, fingerprint.productId) then
      return true
    end
  end
  return false
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification()")

  -- Check the contact sensor if it's currently open
  if device:get_latest_state('main',capabilities.contactSensor.ID,'contact','open') == 'open' then
    device:send(SensorBinary:Get({sensor_type = SensorBinary.sensor_type.DOOR_WINDOW}))
  end

  -- We may need to request a battery update while we're woken up
  if battery.getBatteryUpdate(self, device) then
    -- Request a battery update now
    device:send(Battery:Get({}))
  end
end

local zooz_sensor = {
  zwave_handlers = {
    [cc.WAKE_UP] = {
        [WakeUp.NOTIFICATION] = wakeup_notification,
    },
  },
  NAME = "zooz zse41 sensor",
  can_handle = can_handle_zooz_sensor
}

return zooz_sensor
