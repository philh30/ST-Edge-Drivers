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
local eiscp_map = require("eiscp_map")

local client_functions = {}

--- Parse ISCP message and emit appropriate events
---
--- @param device st.Device
local function parse_eiscp(device,rcv)
    local payload = {rcv:byte(1,#rcv)}
    local str = ''
    local cmd
    local sub_cmd
    local eiscp_decode = eiscp_map()

    if DEVICE_MAP[device.device_network_id].response then
        device.thread:cancel_timer(DEVICE_MAP[device.device_network_id].response)
        DEVICE_MAP[device.device_network_id].response = nil
    end

    str = table.concat(payload,' ')
    log.trace(string.format('%s RX < %s',device.device_network_id,str))
    if rcv:sub(1,4) == 'ISCP' then
        if #rcv <= 16 then
            log.error('Incomplete header row')
        else
            local len = #rcv
            local header_len = string.byte(rcv,8)
            local data_len = string.byte(rcv,12)
            if len ~= header_len + data_len then
            log.error(string.format('Length is %s, expected is %s',len,header_len + data_len))
            else
            local header = rcv:sub(1,header_len)
            local data = rcv:sub(header_len+1,len)
            if (string.byte(data,data_len) == 10) or (string.byte(data,data_len) == 13) then
                data_len = data_len-1
                if (string.byte(data,data_len) == 10) or (string.byte(data,data_len) == 13) then
                data_len = data_len-1
                end
            end
            if (string.byte(data,data_len) ~= 26) then
                log.error('No EOF detected')
            else
                data_len = data_len-1
                cmd = string.sub(data,3,5)
                sub_cmd = string.sub(data,6,data_len)
                log.debug(string.format('%s RX < %s%s',device.device_network_id,cmd,sub_cmd))
                if eiscp_decode[cmd] then
                    local component = eiscp_decode[cmd].comp
                    local capability = eiscp_decode[cmd].cap
                    local attribute = eiscp_decode[cmd].attr
                    local val = eiscp_decode[cmd].values[sub_cmd] or ((attribute == 'volume') and (math.floor(tonumber(sub_cmd,16)*100/device.preferences.volumeScale)) or sub_cmd)
                    if device:component_exists(component) then
                        device:emit_component_event(device.profile.components[component],caps[capability][attribute]({value = val}))
                    end
                end
            end
            end
        end
    end
end

--- Parse incoming to find an ISCP message
---
--- @param driver Driver
function client_functions.msghandler(driver, sock)
    local recvbuf
    local recverr
    local r
    local len

    while not recverr do
        if not len then
            r, recverr = sock:receive(1) -- 1 byte at a time until we discover an ISCP header
        else
            r, recverr = sock:receive(len+4) -- Data length byte is 12th in 16-byte header. Expect 4 more header bytes followed by len data bytes (including EOF/EOL bytes)
            recvbuf = recvbuf .. (r or '')
            break
        end
        if not r then
            break
        else
            recvbuf = (recvbuf or '') .. r
            if not len and string.match(recvbuf,'ISCP........') then -- Detect when header has reached data length byte
            len = string.byte((string.match(recvbuf,'ISCP.......(.)'))) -- Next loop pull len+4 to get last 4 bytes of header plus data bytes
            end
        end
    end
    recvbuf = recvbuf and string.match(recvbuf,'ISCP.+') or nil
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
        parse_eiscp(device,recvbuf)
    elseif (recverr ~= 'timeout') and (recverr ~= nil) then
        log.error (string.format('Socket Receive Error occured: %s', recverr))
        if recverr == 'closed' then
            log.warn(string.format('%s has disconnected',device.device_network_id))
            sock:close()
            DEVICE_MAP[device.device_network_id].sock = nil
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
        client:close()
    else
        client:settimeout(0)
        DEVICE_MAP[device.device_network_id].sock = client
        driver:register_channel_handler(client, client_functions.msghandler, string.format("Socket handler %s",device.device_network_id))
        log.debug(string.format('%s CONNECTED TO %s:%s',device.device_network_id,ip,port))
        driver:inject_capability_command(device,{component="main",capability="refresh",command="refresh",args={}})
        return client
    end
end

--- @param driver Driver
--- @param device st.Device
function client_functions.check_connection(driver,device)
    if not (DEVICE_MAP[device.device_network_id] or {}).sock then
        local devices = driver:get_devices()
        local devices_found = disco.find_device()
        for _, dev in ipairs(devices) do
            local matched = false
            for _, fnd in ipairs(devices_found) do
            if dev.device_network_id == fnd.id then
                log.info(string.format('DEVICE %s FOUND AT %s:%s',dev.device_network_id,fnd.ip,fnd.port))
                if not DEVICE_MAP[dev.device_network_id] then DEVICE_MAP[dev.device_network_id] = {} end
                DEVICE_MAP[dev.device_network_id].ip = fnd.ip
                DEVICE_MAP[dev.device_network_id].model = fnd.model
                matched = true
                break
            end
            end
            if not matched then
            log.info(string.format('DEVICE %s NOT FOUND',dev.device_network_id))
            end
        end
    end
    if ((DEVICE_MAP or {})[device.device_network_id] or {}).ip and not DEVICE_MAP[device.device_network_id].sock then
        client_functions.connect(driver,device,DEVICE_MAP[device.device_network_id].ip,config.MC_PORT)
    elseif not ((DEVICE_MAP or {})[device.device_network_id] or {}).ip then
        log.error(string.format("%s CANNOT CONNECT. CHECK CONNECTION AND REFRESH",device.device_network_id))
    end
end

--- @param driver Driver
--- @param device st.Device
function client_functions.refresh_connection(driver,device)
    if (DEVICE_MAP[device.device_network_id] or {}).sock then
        log.trace(string.format('%s DISCONNECTING - CONNECTION REFRESH',device.device_network_id))
        DEVICE_MAP[device.device_network_id].sock:close()
        DEVICE_MAP[device.device_network_id].sock = nil
    end
    client_functions.check_connection(driver,device)
end

return client_functions