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
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 3 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local call_parent_handler = require "call_parent"
local battery = require "battery"


local RING_FINGERPRINTS = {
  { manufacturerId = 0x0346, productType = 0x0201, productId = 0x0301 }, -- Ring contact sensor v2
}

--- Determine whether the passed device is RING_FINGERPRINTS
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true if the device proper, else false
local function can_handle_ring_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(RING_FINGERPRINTS) do
    if device:id_match(fingerprint.manufacturerId, fingerprint.productType, fingerprint.productId) then
      return true
    end
  end
  return false
end

--- Handler for notification report command class
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification.Report
local function notification_report_handler(self, device, cmd)
  local home_security_notification_events_map = {
    [Notification.event.home_security.INTRUSION] = {
      active = capabilities.contactSensor.contact.open(),
      inactive = capabilities.contactSensor.contact.closed()
    },
    [Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED] = {
      active = capabilities.tamperAlert.tamper.detected(),
      inactive = capabilities.tamperAlert.tamper.clear(),
    },
    -- To do: Should this be a separate custom capability?
    [Notification.event.home_security.MAGNETIC_FIELD_INTERFERENCE_DETECTED] = {
      active = capabilities.tamperAlert.tamper.detected(),
      inactive = capabilities.tamperAlert.tamper.clear(),
    },
  }

  local event
  if cmd.args.notification_type == Notification.notification_type.HOME_SECURITY then
    if cmd.args.event == Notification.event.home_security.STATE_IDLE then
      event = home_security_notification_events_map[string.byte(cmd.args.event_parameter)].inactive
    else
      event = home_security_notification_events_map[cmd.args.event].active
    end
  elseif cmd.args.notification_type == Notification.notification_type.SYSTEM and cmd.args.event == Notification.event.system.HEARTBEAT then
    event = capabilities.button.button.pushed()
    event.state_change = true
  end
  if (event ~= nil) then
    device:emit_event(event)
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification()")

  -- Check the contact sensor if it's currently tripped
  if device:get_latest_state('main',capabilities.contactSensor.ID,'contact','open') == 'open' then
    device:send(Notification:Get({notification_type=Notification.notification_type.HOME_SECURITY,event=Notification.event.home_security.INTRUSION}))
  end

  -- We may need to request a battery update while we're woken up
  if battery.getBatteryUpdate(self, device) then
    -- Request a battery update now
    device:send(Battery:Get({}))
  end
end

local ring_contact_sensor = {
  zwave_handlers = {
    [cc.WAKE_UP] = {
        [WakeUp.NOTIFICATION] = wakeup_notification,
    },
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = notification_report_handler
    },
  },
  NAME = "Ring Contact Sensor 2",
  can_handle = can_handle_ring_sensor
}

return ring_contact_sensor
