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
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version = 1 })
local zw = require "st.zwave"
local log = require "log"
local firmware = caps["platinummassive43262.firmwareVersion"]
local delay_send = require "delay_send"

local last_button = 6
local last_time = 0

--- @param device st.zwave.Device
local function set_scenes(device)
  -- 0x21 0x33 = ControllerReplication:TransferScene; Payload = Sequence # / Scene # / Hub Node ID / Level of BasicSet sent
  -- To enable reporting to the hub, set each scene to send the scene # as the BasicSet value.
  -- There is no way to differentiate which scene sends an 'off' command as all scenes send 0 in the BasicSet for 'off'.
  local hubnode = device.driver.environment_info.hub_zwave_id
  local cmds = {}
  local cmd = {}
  for i=1,5,1 do
    cmd = zw.Command(0x21, 0x33, string.char(i) .. string.char(i) .. string.char(hubnode) .. string.char(i))
    cmd.err = nil
    table.insert(cmds,cmd)
  end
  return cmds
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added_handler(driver, device)
  device:emit_event(caps.button.numberOfButtons({ value = 1 }))
  device:emit_event(caps.button.supportedButtonValues({ value = {'up','up_2x','up_3x','up_4x','up_5x','down'} }))
end

-- Name is limited to 10 characters - upper case letters, numbers, or space.
local function check_name(str)
  str = str:upper()
  local new_str = ''
  local bytes = {str:byte(1,#str)}
  local max = #bytes
  max = (max > 10) and 10 or max
  for i=1,max,1 do
    local c = bytes[i]
    if (c==32) or (c>=48 and c<=57) or (c>=65 and c<=90) then
      new_str = new_str .. string.char(c)
    end
  end
  return new_str
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function infoChanged_handler(driver, device, event, args)
  local cmds = {}
  if device.preferences.setScene then
    cmds = set_scenes(device)
  end
  for scene = 1,5,1 do
    local id = 'scene' .. scene .. 'Name'
    local new_name = device.preferences[id]
    if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~=  new_name) then
      new_name = string.char(scene) .. string.char(scene) .. check_name(new_name)
      local cmd = zw.Command(0x21, 0x34, new_name)
      cmd.err = nil
      table.insert(cmds,cmd)
    end
  end
  if #cmds > 0 then delay_send(device,cmds,1) end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device,command)
  device:send(Version:Get({}))
  device:emit_event(caps.button.numberOfButtons({ value = 1 }))
  device:emit_event(caps.button.supportedButtonValues({ value = {'up','up_2x','up_3x','up_4x','up_5x','down'} }))
end

--- Version:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Version.Report
local function version_handler(driver,device,command)
    device:emit_event(firmware.version({ value = command.args.application_version .. '.' .. command.args.application_sub_version }))
end

local button_map = {
  [0] = 'down',
  [1] = 'up',
  [2] = 'up_2x',
  [3] = 'up_3x',
  [4] = 'up_4x',
  [5] = 'up_5x',
}

--- Basic:Set handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Basic.Set
local function basic_set(driver,device,command)
  local val = command.args.value
  local curr_time = os.time()
  local elapsed_sec = os.difftime(curr_time,last_time)
  last_time = curr_time
  log.trace(string.format("Time elapsed: %s; Minimum delay: %s; This button: %s; Last button: %s",elapsed_sec,device.preferences.buttonDelay,val,last_button))
  if (val ~= last_button) or (elapsed_sec > device.preferences.buttonDelay) then
    local evt = caps.button.button({value = button_map[val]})
    evt.state_change = true
    device:emit_event(evt)
  end
  last_button = val
end

local driver_template = {
  supported_capabilities = {
    firmware,
    caps.refresh,
  },
  zwave_handlers = {
    [cc.VERSION] = {
      [Version.REPORT] = version_handler,
    },
    [cc.BASIC] = {
      [Basic.SET] = basic_set,
    }
  },
  lifecycle_handlers = {
    added = added_handler,
    infoChanged = infoChanged_handler,
  },
  capability_handlers = {
    [caps.refresh.ID] = {
      [caps.refresh.commands.refresh.NAME] = refresh_handler,
    },
  },
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
--- @type st.zwave.Driver
local pe953 = ZwaveDriver("pe953_remote_control", driver_template)
pe953:run()
