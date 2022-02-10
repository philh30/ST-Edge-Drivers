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

local to_send_queue = {}
local timers = {}

--- @param device st.zwave.Device
local function throttle_send(device)
    local function throttle_loop()
        if #to_send_queue[device.id] > 0 then
            log.trace (string.format('~~~~~ THROTTLE: %s commands to send ~~~~~',#to_send_queue[device.id]))
            local to_send = table.remove(to_send_queue[device.id],1)
            local msg = to_send.msg
            local delay = to_send.delay or 1
            device:send(msg)
            timers[device.id] = device.thread:call_with_delay(delay, throttle_loop)
        else
            log.trace('~~~~~ THROTTLE: No more commands to send ~~~~~')
            device.thread:cancel_timer(timers[device.id])
            timers[device.id] = nil
        end
    end

	if timers[device.id] then
		log.trace ('~~~~~ THROTTLE: Message queued ~~~~~')
	else
		timers[device.id] = device.thread:call_with_delay(0, throttle_loop)
	end
end

--- @param device st.zwave.Device
local function send_command(device,commands)
	if not (to_send_queue[device.id]) then to_send_queue[device.id] = {} end
    for _,cmd in pairs(commands) do
        cmd.delay = cmd.delay or (device.preferences.zwDelay and device.preferences.zwDelay / 1000) or 1
        table.insert(to_send_queue[device.id],cmd)
    end
    throttle_send(device)
end

return send_command