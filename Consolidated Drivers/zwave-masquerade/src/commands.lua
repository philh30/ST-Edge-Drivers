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

local log = require "log"
--- @type st.zwave.CommandClass
local cc  = require "st.zwave.CommandClass"
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({version=1})
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2})
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4})

local function send_command(device,cmd)
    if device.preferences.invertStatus then cmd = math.abs(cmd-1) end
    local value = cmd == 1 and SwitchBinary.value.ON_ENABLE or SwitchBinary.value.OFF_DISABLE
    local get
    local delay = constants.DEFAULT_GET_STATUS_DELAY
    if device:is_cc_supported(cc.SWITCH_BINARY) then
        device:send(SwitchBinary:Set({value = value}))
        get = SwitchBinary:Get({})
    elseif device:is_cc_supported(cc.SWITCH_MULTILEVEL) then
        device:send(SwitchMultilevel:Set({value = value}))
        get = SwitchMultilevel:Get({})
    else
        device:send(Basic:Set({value = value}))
        get = Basic:Get({})
    end
    local follow_up_poll = function()
        device:send(get)
    end
    device.thread:call_with_delay(delay, follow_up_poll)
end

local handlers = {}

function handlers.on(driver, device, command)
    send_command(device,1)
end

function handlers.off(driver, device, command)
    send_command(device,0)
end

function handlers.alarm(driver, device, command)
    if command.command == device.preferences.alarm1 then
        send_command(device,0)
    elseif command.command == device.preferences.alarm2 then
        send_command(device,1)
    else
        device:refresh()
    end
end

function handlers.shadeLevel(driver, device, command)
    if command.args.shadeLevel == 0 then
        send_command(device,0)
    else
        send_command(device,1)
    end
end

return handlers