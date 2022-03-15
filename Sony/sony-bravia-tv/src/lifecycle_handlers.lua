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

local client_functions = require("client_functions")
local get_app_list = require("app_list")
local emit_source_list = require("source_list")
local command_handlers = require("command_handlers")
local log = require("log")

local function keep_alive(driver,device)
    local function poll()
        log.trace(string.format('%s POLLING TO KEEP CONNECTION ALIVE',device.device_network_id))
        client_functions.check_connection(driver,device)
        command_handlers.send_cmd(driver,device,{component='main',capability='switch'},'switch','query')
    end
    if not (DEVICE_MAP[device.device_network_id] or {}).alive then
        if not DEVICE_MAP[device.device_network_id] then DEVICE_MAP[device.device_network_id] = {} end
        DEVICE_MAP[device.device_network_id].alive = device.thread:call_on_schedule(30*60, poll) -- Query power every 30 minutes
    end
end

--- @param driver Driver
--- @param device st.Device
local function init(driver,device,command)
    client_functions.check_connection(driver,device)
    if (DEVICE_MAP[device.device_network_id] or {}).ip then
        get_app_list(driver,device)
    end
    emit_source_list(device)
    keep_alive(driver,device)
end
  
  --- @param driver Driver
  --- @param device st.Device
local function removed(driver,device)
    log.trace(string.format("%s REMOVED",device.device_network_id))
    if DEVICE_MAP[device.device_network_id] then
        if DEVICE_MAP[device.device_network_id].alive then
            device.thread:cancel_time(DEVICE_MAP[device.device_network_id].alive)
            DEVICE_MAP[device.device_network_id].alive = nil
        end
        DEVICE_MAP[device.device_network_id].sock:close()
        DEVICE_MAP[device.device_network_id] = nil
    end
end
  
  --- @param driver Driver
  --- @param device st.Device
local function updated(driver,device)
    log.trace(string.format("%s UPDATED",device.device_network_id))
    emit_source_list(device)
end

return {
    init = init,
    removed = removed,
    infoChanged = updated,
}