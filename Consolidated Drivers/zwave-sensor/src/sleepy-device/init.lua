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

--
-- Support subdriver for zwave sleepy devices.
-- 

local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local cc = require "st.zwave.CommandClass"
local call_parent_handler = require "call_parent"


local function can_handle_sleepy_device(opts, driver, device, ...)
    return device:is_cc_supported(cc.WAKE_UP)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification(sleepy-device)")

  -- If we've not yet configured the device, execute it now.  This can be if we switched drivers.
  if device:get_field("device_configured") ~= true then
    device.log.debug("Configuration of device pending.")
    call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, "doConfigure")
    -- device.thread:queue_event(self.lifecycle_dispatcher.dispatch, self.lifecycle_dispatcher, self, device, "doConfigure")
  end
end

local sleepy_device = {
    NAME = "Sleepy Device",
    zwave_handlers = {
        [cc.WAKE_UP] = {
            [WakeUp.NOTIFICATION] = wakeup_notification,
        },
    },
    can_handle = can_handle_sleepy_device,
}

return sleepy_device