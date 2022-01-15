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

local function delay_send(device,commands,delay)
    local function send_loop()
        log.trace('~~~~~ Send ' .. ((#commands == 1) and '' or ('with delay: ' .. #commands .. ' commands to send')) .. '~~~~~')
        device:send(commands[1])
        table.remove(commands,1)
        if #commands > 0 then
            device.thread:call_with_delay(delay, send_loop)
        else
            log.trace('~~~~~ All commands sent ~~~~~')
        end
    end
    send_loop()
end

return delay_send