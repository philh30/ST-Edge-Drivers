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

local capabilities = require "st.capabilities"
local cc = require "st.zwave.CommandClass"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local log = require "log"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({version=1,strict=true})
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({version=1,strict=true})
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({version=4})

--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({version=1})
-- 
local call_parent_handler = require "call_parent"

local HOMESEER_MOTION_FLS100_FINGERPRINTS = {
  {mfr = 0x000C, prod = 0x0201, model = 0x000B},  -- FLS-100+
  {mfr = 0x000C, prod = 0x0201, model = 0x000C},  -- FLS-100+ G2 (2020 model)
}

-- Note:
-- The device can be configured where it doesn't send discrete NOTIFICATION - MOTION events
-- for actual motion sensor (PIR) events.
-- Instead, it sends SENSOR_BINARY messages for MOTION that mirror the state of the switch.
-- I believe this is when the lux trigger is not set to 0 (which is needed for "smart home mode")
-- We also saw that after a reboot (maybe after changing that setting) it started sending
-- Notification messages correctly.

-- FLS100 (G1)
-- Z-Wave P2 values can be set to make the sensor behave in different ways. The default value is 50.
-- Value 0 = decouples the motion sensor from the load. Motion will be sensed and that's 
--           reported to the controller. However, the light won't be turned on.
-- Values 30-200 = sets the LUX threshold for motion-activated operation. 
--     If set to "50", motion will turn on lights when the LUX level is 50 or less.
-- Value 255 = Light is always turned on with motion regardless of LUX value.
--
-- The FLS100 (non G2) seems to have an issue when paired with S2.   
-- When setup in the "smart sensor" type config and paired with S2, motion
-- reports aren't received by ST.    The thought is that the device isn't 
-- sending NOTIFICATION RESULT as security wrapped, and the hub is just
-- discarding them.
-- Pairing without S2 seems to work fine in testing.
-- 
-- Parameter 4 (Send Basic Report) is not listed on the alliance site, but is 
-- documetned in the manual.
-- Its not referenced in the DTH version of this driver.
-- So it MAY cause issues.

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true 
local function can_handle_homeseer_motion(opts, driver, device, ...)
  for _, fingerprint in ipairs(HOMESEER_MOTION_FLS100_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end


local function do_init(self,device, event, args)

  -- Call the topmost 'init' lifecycle hander to do any default work
  call_parent_handler(self.lifecycle_handlers.init, self, device, event, args)

  -- Add any debugging needed on driver restart here
end

local function do_configure(self,device, event, args)

  -- Call the topmost 'doConfigure' lifecycle hander to do any default work
  call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, event, args)
end


--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Basic.Report
local function basic_report(self, device, cmd)
  -- The FLS100+ sends a BASIC report for the --motion sensor--, not the switch.
  -- Because we're primarily a switch device driver, our default handlers for BASIC REPORT
  -- are mapping to switch capabilities, not the motion sensor.
  -- We'll override the logic for basic report to send motion sensor events.
  if (cmd.args.value ~= 0) then
    device:emit_event_for_endpoint(cmd.src_channel, capabilities.motionSensor.motion.active())
  else
    device:emit_event_for_endpoint(cmd.src_channel, capabilities.motionSensor.motion.inactive())
  end
end

-- Ignore processing these messages
local function ignore_handler(self, device, cmd)
  device.log.trace("ignoring message")
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device)
  -- Call the default refresh handling in the parent
  device:default_refresh()

  -- event = MOTION_DETECTION 

  -- The default motion sensor capability handlers use SENSOR_BINARY requests
  -- instead of Notification.   So request a notification here.
  device:send(Notification:Get({v1_alarm_type = 0, notification_type = Notification.notification_type.HOME_SECURITY, event = 0x08}))
end

local homeseer_motion = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.REPORT] = basic_report,
    },
  },
  supported_capabilities = {
    capabilities.switch,
    capabilities.motionSensor,
    capabilities.refresh,
    capabilities.illuminanceMeasurement,
    capabilities.temperatureMeasurement,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
  },
  lifecycle_handlers = {
    init        = do_init,
    doConfigure = do_configure,
  },
  NAME = "homeseer fls100",
  can_handle = can_handle_homeseer_motion,
}

return homeseer_motion