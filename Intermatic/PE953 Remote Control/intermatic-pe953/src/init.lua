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

local caps = require "st.capabilities"
--- @type st.zwave.defaults
local defaults = require "st.zwave.defaults"
--- @type st.zwave.Driver
local ZwaveDriver = require "st.zwave.driver"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version = 1 })
local firmware = caps["platinummassive43262.firmwareVersion"]

local function added_handler(self, device)
  device:send(Version:Get({}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device,command)
  device:send(Version:Get({}))
end

--- Version:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Version.Report
local function version_handler(driver,device,command)
    device:emit_event(firmware.version({ value = command.args.application_version .. '.' .. command.args.application_sub_version }))
end


local driver_template = {
  supported_capabilities = {
    firmware,
    caps.refresh,
  },
  zwave_handlers = {
    [cc.VERSION] = {
      [Version.REPORT] = version_handler
    },
  },
  lifecycle_handlers = {
    added = added_handler,
  },
  capability_handlers = {
    [caps.refresh.ID] = {
      [caps.refresh.commands.refresh.NAME] = refresh_handler
    },
  },
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
--- @type st.zwave.Driver
local pe953 = ZwaveDriver("pe953_remote_control", driver_template)
pe953:run()
