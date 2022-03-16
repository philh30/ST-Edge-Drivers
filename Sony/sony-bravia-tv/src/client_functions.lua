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

local caps = require("st.capabilities")
local log = require("log")
local socket = require("cosock.socket")
local disco = require("disco")
local config = require("config")
local simple_ip_map = require("simple_ip_map")

local client_functions = {}

--- Parse message and emit appropriate events
---
--- @param device st.Device
local function parse(device,rcv)
    local cmd
    local map_decode = simple_ip_map()

    if DEVICE_MAP[device.device_network_id].response then
        device.thread:cancel_timer(DEVICE_MAP[device.device_network_id].response)
        DEVICE_MAP[device.device_network_id].response = nil
    end
    if rcv:sub(1,2) == '*S' then
        if #rcv < 23 then
            log.error('Incomplete message received')
        else
            local msg_type = string.sub(rcv,3,3)
            local msg_cmd = string.sub(rcv,4,7)
            local msg_param = string.sub(rcv,8,23)
            if map_decode[msg_cmd] then
                local component = map_decode[msg_cmd].comp
                local capability = map_decode[msg_cmd].cap
                local attribute = map_decode[msg_cmd].attr
                local val = map_decode[msg_cmd].values[msg_param] or tonumber(msg_param)
                if msg_cmd == 'CHNN' and tonumber(msg_param) then val = val .. '' end
                if msg_type == 'A' and DEVICE_MAP[device.device_network_id][attribute] and (os.difftime(os.time(),DEVICE_MAP[device.device_network_id][attribute]) <= 2) then
                    log.trace(string.format('%s Ignoring command acknowledgment: %s second(s) elapsed since %s command sent.',device.device_network_id,os.difftime(os.time(),DEVICE_MAP[device.device_network_id][attribute]),attribute)) 
                elseif msg_type == 'A' and msg_cmd == 'CHNN' and msg_param == 'FFFFFFFFFFFFFFFF' then
                    device:emit_component_event(device.profile.components[component],caps[capability][attribute]({value = ''}))
                elseif msg_type == 'A' and msg_cmd == 'INPT' and msg_param == 'FFFFFFFFFFFFFFFF' then
                    device:emit_component_event(device.profile.components[component],caps[capability][attribute]({value = 'APP'}))
                elseif msg_param == 'FFFFFFFFFFFFFFFF' then
                    log.trace(string.format('%s Failed to update attribute %s',device.device_network_id,attribute))
                elseif device:component_exists(component) and msg_cmd ~= 'IRCC' then
                    device:emit_component_event(device.profile.components[component],caps[capability][attribute]({value = val}))
                end
            end
        end
    end
end

--- Initial parse of incoming, find device
---
--- @param driver Driver
function client_functions.msghandler(driver, sock)
    local recvbuf
    local recverr

    recvbuf, recverr = sock:receive('*l')
    local ip = sock:getpeername()
    local device_list = driver:get_devices()
    local device
    for _, dev in pairs(device_list) do
        if DEVICE_MAP[dev.device_network_id].ip == ip then
            device = dev
        end
    end
    if recverr ~= nil then
        log.debug (string.format('Receive status = %s', recverr))
    end

    if (recverr ~= 'timeout') and recvbuf then
        log.trace(string.format('%s RX < %s',device.device_network_id,recvbuf))
        parse(device,recvbuf)
    elseif (recverr ~= 'timeout') and (recverr ~= nil) then
        log.error (string.format('Socket Receive Error occured: %s', recverr))
        if recverr == 'closed' then
            log.warn('Closing socket')
            sock:close()
            if device and device.device_network_id then
                log.warn(string.format('%s has disconnected',device.device_network_id))
                if DEVICE_MAP[device.device_network_id] then DEVICE_MAP[device.device_network_id].sock = nil end
            end
        end
    end
end

--- @param driver Driver
--- @param device st.Device
function client_functions.connect(driver, device, ip, port)

    local listen_ip = "0.0.0.0"
    local listen_port = 0

    log.trace(string.format('%s CONNECTING TO %s:%s',device.device_network_id,ip,port))
    local client = assert(socket.tcp(), string.format("Create socket %s",device.device_network_id))
    client:settimeout(2)
    assert(client:bind(listen_ip, listen_port), string.format("Bind socket %s",device.device_network_id))
    local ret, msg = client:connect(ip,port)

    if ret == nil then
        log.error (string.format('%s CONNECTION TO %s:%s FAILED',device.device_network_id,ip,port))
        device:offline()
        client:close()
        return nil
    else
        client:settimeout(0)
        DEVICE_MAP[device.device_network_id] = DEVICE_MAP[device.device_network_id] or {}
        DEVICE_MAP[device.device_network_id].sock = client
        driver:register_channel_handler(client, client_functions.msghandler, string.format("%s",device.device_network_id))
        log.debug(string.format('%s CONNECTED TO %s:%s',device.device_network_id,ip,port))
        device:online()
        local old_ip = device:get_field('IP')
        if ip ~= old_ip then device:set_field('IP',ip,{persist = true}) end
        DEVICE_MAP[device.device_network_id].ip = ip
        driver:inject_capability_command(device,{component="main",capability="refresh",command="refresh",args={}})
        return client
    end
end

--- @param driver Driver
--- @param device st.Device
function client_functions.check_connection(driver,device)
    local old_ip = device:get_field('IP')
    local success = false
    if not (DEVICE_MAP[device.device_network_id] or {}).sock then
        if old_ip then
            success = client_functions.connect(driver,device,old_ip,config.PORT)
            if success then
                return success
            end
        end
        local devices = driver:get_devices()
        local devices_found = disco.find_device()
        for _, dev in ipairs(devices) do
            local matched = false
            for _, fnd in ipairs(devices_found) do
                if dev.device_network_id == fnd.id then
                    log.info(string.format('DEVICE %s FOUND AT %s:%s',dev.device_network_id,fnd.ip,fnd.port))
                    if not DEVICE_MAP[dev.device_network_id] then DEVICE_MAP[dev.device_network_id] = {} end
                    DEVICE_MAP[dev.device_network_id].ip = fnd.ip
                    if fnd.ip ~= old_ip then device:set_field('IP',fnd.ip,{persist = true}) end
                    matched = true
                    break
                end
            end
            if not matched then
                log.info(string.format('DEVICE %s NOT FOUND',dev.device_network_id))
            end
        end
    else
        device:online()
    end
    if ((DEVICE_MAP or {})[device.device_network_id] or {}).ip and not DEVICE_MAP[device.device_network_id].sock then
        success = client_functions.connect(driver,device,DEVICE_MAP[device.device_network_id].ip,config.PORT)
        if success then
            return success
        end
    elseif not ((DEVICE_MAP or {})[device.device_network_id] or {}).ip then
        log.error(string.format("%s CANNOT CONNECT. CHECK CONNECTION AND REFRESH",device.device_network_id))
        device:offline()
    end
end

--- @param driver Driver
--- @param device st.Device
function client_functions.refresh_connection(driver,device)
    local function reconnect()
        client_functions.check_connection(driver,device)
    end
    if (DEVICE_MAP[device.device_network_id] or {}).sock then
        log.trace(string.format('%s DISCONNECTING - CONNECTION REFRESH',device.device_network_id))
        device:offline()
        driver:unregister_channel_handler(string.format("%s",device.device_network_id))
        DEVICE_MAP[device.device_network_id].sock:close()
        DEVICE_MAP[device.device_network_id].sock = nil
    end
    device.thread:call_with_delay(2, reconnect)
end

return client_functions