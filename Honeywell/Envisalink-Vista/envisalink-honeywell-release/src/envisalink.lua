--[[
This module adapted from the DSC-Envisalink module authored by Todd Austin.

Copyright 2021 Todd Austin

  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
  except in compliance with the License. You may obtain a copy of the License at:

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  either express or implied. See the License for the specific language governing permissions
  and limitations under the License.


  DESCRIPTION
  
  Samsung SmartThings Edge Driver for Envisalink - module to (1) handle incoming Envisalink messages, (2) create
  json tables & log messages based on them, and (3) send commands to Envisalink

  ** The Envisalink message-parsing code here is ported from the alarmserver Python package
  originally developed by donnyk+envisalink@gmail.com, which also included subsequent modifications/enhancements by
  leaberry@gmail.com, jordan@xeron.cc, and ralphtorchia1@gmail.com

--]]


local log = require "log"
local utilities = require "utilities"

local socket = require "cosock.socket"
local evl = require "envisalinkdefs"
local events = require "evthandler"

-- Module variables
local clientsock
local connected = false
local loggedin = false
local handlers={}

local evlClient = {}

local throttleSeconds = 2

evlClient.msghandler = {}			-- forward reference to msghandler function

function evlClient.connect(driver)

	local listen_ip = "0.0.0.0"
	local listen_port = 0

	local client = assert(socket.tcp(), "create LAN socket")

	assert(client:bind(listen_ip, listen_port), "LAN socket setsockname")

	local ret, msg = client:connect(conf.ip, conf.port)
	
	if ret == nil then
		log.error (string.format('Could not connect to EnvisaLink: %s', msg))
		client:close()
	else
		client:settimeout(0)
		connected = true
		clientsock = client
		driver:register_channel_handler(client, evlClient.msghandler, 'LAN client handler')
		return client
	end
end


function evlClient.disconnect(driver)

	connected = false
	loggedin = false
	
	if timers.reconnect then
		driver:cancel_timer(timers.reconnect)
	end
	if timers.waitlogin then
		driver:cancel_timer(timers.waitlogin)
	end
	timers.reconnect = nil
	socket.sleep(.1)
	timers.waitlogin = nil
	
	if clientsock then
		driver:unregister_channel_handler(clientsock)
		clientsock:close()
	end
	utilities.set_online(driver,'offline')

end

local doreconnect						-- Forward reference

-- This function invoked by delayed timer
local function dowaitlogin(driver)
	
	timers.waitlogin = nil
	if not loggedin then
		log.warn('Failed to log into Envisalink; connect retry in 15 seconds')
		evlClient.disconnect()
		if timers.reconnect then
			driver:cancel_timer(timers.reconnect)
			timers.reconnect = nil
		end
		timers.reconnect = driver:call_with_delay(15, doreconnect, 'Re-connect timer')
	else
		utilities.set_online(driver,'online')
	end
end

-- This function invoked by delayed timer
doreconnect = function(driver)

	log.info ('Attempting to reconnect to EnvisaLink')
	timers.reconnect = nil
	local client = evlClient.connect(driver)
	
	if client then
	
		log.info ('Re-connected to Envisalink')
		
		timers.waitlogin = driver:call_with_delay(3, dowaitlogin, 'Wait for Login')
		
	else
		timers.reconnect = driver:call_with_delay(15, doreconnect, 'Re-connect timer')
	end
end

local function throttle_loop(driver)
	if #to_send_queue > 0 then
		local to_send = table.remove(to_send_queue,1)
		for _,msg in ipairs(to_send) do
			log.trace('THROTTLE: TX > ' .. msg)
			clientsock:send(msg)
		end
		timers.throttle = driver:call_with_delay(throttleSeconds, throttle_loop, 'Throttle commands to panel')
	else
		log.trace('THROTTLE: No more commands to send')
		driver:cancel_timer(timers.throttle)
		timers.throttle = nil
	end
end

-------------------------------------------------------------------------------------------------
local function throttle_send(driver)
	if timers.throttle then
		log.trace ('THROTTLE: Message queued')
	else
		timers.throttle = driver:call_with_delay(0, throttle_loop, 'Throttle commands to panel')
	end
end

local function send_command(driver,code,data)
-- Send a command in the proper honeywell format.
	local to_send = '^' .. code .. ',' .. data .. '$\n'
	log.trace ('TX > ' .. to_send)
	local send_array ={}
	table.insert(send_array,to_send)
	table.insert(to_send_queue,send_array)
	throttle_send(driver)
end

local function send_raw(driver,to_send)
-- Send keypress sequence to active partition
	to_send = to_send .. '\n'
	log.trace ('TX > ' .. to_send)
	local send_array ={}
	table.insert(send_array,to_send)
	table.insert(to_send_queue,send_array)
	throttle_send(driver)
end

local function dump_zone_timers(driver)
-- Send a command to dump out the zone timers.
	send_command(driver,evl.Commands.DumpZoneTimers, '')
end

local function keypresses_to_partition(driver,partitionNumber,keypresses)
-- Send keypresses to a particular partition.
	log.trace ('TX Keypresses > ^' .. evl.Commands.PartitionKeypress .. ',' .. partitionNumber .. ',' .. keypresses .. '$')
	local send_array = {}
	for char in keypresses:gmatch(".") do
		table.insert(send_array,'^' .. evl.Commands.PartitionKeypress .. ',' .. partitionNumber .. ',' .. char .. '$\n')
	end
	table.insert(to_send_queue,send_array)
	throttle_send(driver)
end

function evlClient.disarm_partition(driver,code,partitionNumber)
-- Disarm a partition
	local to_send = code .. evl.ArmCommands.disarm
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.arm_away_partition(driver,code,partitionNumber)
-- Arm away a partition
	local to_send = code .. evl.ArmCommands.armAway
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.arm_stay_partition(driver,code,partitionNumber)
-- Arm stay a partition
	local to_send = code .. evl.ArmCommands.armStay
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.arm_instant_partition(driver,code,partitionNumber)
-- Arm instant a partition
	local to_send = code .. evl.ArmCommands.armInstant
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end
	
function evlClient.arm_night_partition(driver,code,partitionNumber)
-- Arm night a partition
	local to_send = code .. evl.ArmCommands.armNight
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.arm_max_partition(driver,code,partitionNumber)
-- Arm max a partition
	local to_send = code .. evl.ArmCommands.armMax
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.chime_partition(driver,code,partitionNumber)
-- Toggle chime for a partition
	local to_send = code .. evl.ArmCommands.chime
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.bypass_zone_partition(driver,code,partitionNumber,zone)
-- Bypass a zone on a partition
	local zone_int = tonumber(zone)
	if zone_int then
		if (zone_int <= 128) and (zone_int > 0) then
			local zone_string = ''
			if zone_int < 10 then
				zone_string = '0'
			end
			zone_string = zone_string .. zone
			local to_send = code .. evl.ArmCommands.bypass .. zone_string
			if tonumber(partitionNumber) == 1 then
				send_raw(driver,to_send)
			else
				keypresses_to_partition(driver,partitionNumber,to_send)
			end
		end
	end
end

function evlClient.trigger_one_partition_on(driver,code,partitionNumber)
-- Turn trigger 1 on
	local to_send = code .. evl.ArmCommands.triggerOneOn
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.trigger_one_partition_off(driver,code,partitionNumber)
-- Turn trigger 1 off
	local to_send = code .. evl.ArmCommands.triggerOneOff
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.trigger_two_partition_on(driver,code,partitionNumber)
-- Turn trigger 1 on
	local to_send = code .. evl.ArmCommands.triggerTwoOn
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

function evlClient.trigger_two_partition_off(driver,code,partitionNumber)
-- Turn trigger 1 off
	local to_send = code .. evl.ArmCommands.triggerTwoOff
	if tonumber(partitionNumber) == 1 then
		send_raw(driver,to_send)
	else
		keypresses_to_partition(driver,partitionNumber,to_send)
	end
end

-- Login to Envisalink; once successful, send Refresh request
function handlers.handle_login(driver,sock)
	log.info ('Received login password request; sending password')
	local to_send = conf.password .. '\n'
	log.trace ('TX > ' .. to_send)
	clientsock:send(to_send)
end		

function handlers.handle_login_success(driver,sock)
	log.info('Successfully logged in to Envisalink...')
	loggedin = true
	-- Set Partition 1 as active
	send_command(driver,evl.Commands.ChangeDefaultPartition, '1')
end

function handlers.handle_login_failure(driver,sock)
	log.error ('Envisalink login failed - incorrect password')
end

function handlers.handle_login_timeout(driver,sock)
	log.error ('Envisalink login failed - timeout')
end

local function get_partition_state(flags, alpha)
	if flags.alarm or flags.alarm_fire_zone or flags.fire then
		return 'alarm'
	elseif flags.alarm_in_memory then
		return 'alarmcleared'
    elseif alpha:find('You may exit now') then
		return 'arming'
    elseif flags.armed_stay and flags.armed_zero_entry_delay then
		return 'armedinstant'
    elseif flags.armed_away and flags.armed_zero_entry_delay then
		return 'armedmax'
    elseif flags.armed_stay then
		return 'armedstay'
    elseif flags.armed_away then
		return 'armedaway'
    elseif flags.ready then
		return 'ready'
    elseif not flags.ready then
		return 'notready'
	else
		return 'unknown'
	end
end

local function get_zone_report_type(flags,alpha)
	if flags.alarm or flags.alarm_fire_zone or flags.fire then
		return 'alarm'
	elseif flags.alarm_in_memory then
		return 'alarmcleared'
	elseif flags.system_trouble then
		return 'tamper'
	elseif flags.low_battery then
		return 'battery'
	elseif flags.bypass and alpha:find('BYPAS') then
		return 'bypass'
	elseif not flags.ready then
		return 'notready'
	else
		return 'unknown'
	end
end

local function parse_led_bitfield(led_bitfield)
	local flags = {}
	for key, value in pairs(evl.LED_Flags) do
		flags[key] = (value & led_bitfield) ~= 0
	end
	return flags
end

function handlers.handle_keypad_update(driver,sock,data)
	if #data == 6 then 
		local partition = tonumber(data[2],16)
		local led_bitfield = tonumber(data[3],16)
		local zone_user = tonumber(data[4],10)
		local beep = tonumber(data[5],16)
		local alpha = data[6]
		local flags = parse_led_bitfield(led_bitfield)
		local partition_status = get_partition_state(flags, alpha)
		local open_timer_count = 0
		for _ in pairs(zone_timers[partition]) do open_timer_count = open_timer_count + 1 end
		local new_msg = data[1] .. ',' .. data [2] .. ',' .. data [3] .. ',' .. data [4] .. ',' .. data [5] .. ',' .. data [6]
		if (new_msg ~= last_event[partition]) or (open_timer_count > 1) then
			last_event[partition] = new_msg
			local partition_code = flags.not_used2 and flags.not_used3
			local partition_response = {
				type 		= 'partition',
				partition 	= partition,
				alpha 		= alpha,
				state 		= partition_status,
				chime 		= flags.chime and 'chime' or 'off',
				power 		= flags.ac_present and 'mains' or 'battery',
				bypass 		= flags.bypass and 'bypassed' or (flags.ready and 'closed' or 'open')
			}
			if partition_code then
				-- Keypad update is giving partition status
				partition_response.battery = flags.low_battery and 0 or 100
			elseif tonumber(zone_user) then
				-- Keypad update is giving zone status
				local zone_code = get_zone_report_type(flags,alpha)
				local zone_response = {
					type 		= 'zone',
					partition 	= partition,
					zone 		= zone_user
				}
				local timer_type
				if zone_code == 'battery' then
					zone_response.battery = 0
					timer_type = 'battery'
				elseif zone_code == 'tamper' then
					zone_response.tamper = 'detected'
					timer_type = 'tamper'
				elseif zone_code == 'bypass' then
					zone_response.state = 'bypassed'
					-- Zones stay bypassed until the entire partition is disarmed, so zone timers won't help here
					timer_type = nil
				elseif (zone_code == 'alarm') or (zone_code == 'alarmcleared') or (zone_code == 'notready') then
					zone_response.state = flags.ready and 'closed' or 'open'
					timer_type = 'state'
				end
				events.stnp_notification_handler(driver,zone_response)
				if timer_type then
					-- Increment zone timers. This is a workaround since the Vista doesn't notify on zone closure
					local timer_count = 0
					for _, the_timer in pairs(zone_timers[partition]) do
						zone_timers[partition][_] = the_timer + 1
						timer_count = timer_count + 1
					end
					utilities.disptable(zone_timers[partition], '  ')
					if zone_timers[partition][zone_user .. '|' .. timer_type] then
						log.debug (string.format('Zone timer for %s reset from %s to 0',zone_user,zone_timers[partition][zone_user .. '|' .. timer_type]))
					end
					zone_timers[partition][zone_user .. '|' .. timer_type] = 0
					
					local kill_timers = {}
					for zone_type, the_timer in pairs(zone_timers[partition]) do
						-- If zone is more than 2 overdue in showing on panel, assume it has closed
						if the_timer >= timer_count + conf.zoneclosedelay then
							local the_zone = zone_type:match('(%d+)|.+')
							local the_type = zone_type:match('%d+|(.+)')
							local the_zone_response = {
								type 		= 'zone',
								partition	= partition,
								zone 		= the_zone
							}
							if the_type == 'state' then
								the_zone_response.state = 'closed'
							elseif the_type == 'battery' then
								the_zone_response.battery = 100
							elseif the_type == 'tamper' then
								the_zone_response.tamper = 'clear'
							end
							events.stnp_notification_handler(driver,the_zone_response)
							table.insert(kill_timers,zone_type)
						end
					end
					-- Kill any timers for zones that are being closed
					for _,zone_type in pairs(kill_timers) do
						log.debug (string.format('Removing %s from zone_timers', zone_type))
						zone_timers[partition][zone_type] = nil
					end
				end
			end
			events.stnp_notification_handler(driver,partition_response)
		end
	else
		log.error('Error - Keypad Update event has incorrect length!')
	end
end

function handlers.handle_zone_state_change(driver,sock,data)
	log.info (string.format('%s event received. Data: %s',evl.ResponseTypes[data[1]].name, data[2]))
end

function handlers.handle_partition_state_change(driver,sock,data)
	log.info (string.format('%s event received. Data: %s',evl.ResponseTypes[data[1]].name, data[2]))
end

function handlers.handle_realtime_cid_event(driver,sock,data)
	log.info (string.format('%s event received. Data: %s',evl.ResponseTypes[data[1]].name, data[2]))
end

function handlers.handle_zone_timer_dump(driver,sock,data)
	log.info (string.format('%s event received. Data: %s',evl.ResponseTypes[data[1]].name, data[2]))
end

function handlers.handle_poll_response(driver,sock,data)
	log.info (string.format('%s event received. Data: %s',evl.ResponseTypes[data[1]].name, data[2]))
end

function handlers.handle_command_response(driver,sock,data)
	log.info (string.format('%s event received. Data: %s',evl.ResponseTypes[data[1]].name, data[2]))
end

local function handle_line(driver, sock, input)
	if input then
		if evl.ResponseTypes[input] then
			handlers[evl.ResponseTypes[input].handler](driver,sock)
		else
			local data = input:match('(%%.+)%$') or input:match('(%^.+)%$')
			if data then
				local responseTable = utilities.splitString(data,',')
				handlers[evl.ResponseTypes[responseTable[1]].handler](driver,sock,responseTable)
			else
				log.error ('Unknown response received')
			end
		end
	end
end

function evlClient.reconnect(driver)
	if timers.reconnect then
		driver:cancel_timer(timers.reconnect)
		timers.reconnect = nil
	end
	timers.reconnect = driver:call_with_delay(15, doreconnect, 'Re-connect timer')

end

------------------------------------------------------------------------
--							Channel Handler
------------------------------------------------------------------------

evlClient.msghandler = function(driver, sock)
    local recvbuf
    local recverr
	recvbuf, recverr = sock:receive('*l')
	
	if recverr ~= nil then
		log.debug (string.format('Receive status = %s', recverr))
	end
	
	if (recverr ~= 'timeout') and recvbuf then
		log.trace (string.format('RX < %s', recvbuf))
		
		handle_line(driver, sock, recvbuf)
	
	elseif (recverr ~= 'timeout') and (recverr ~= nil) then
		log.error (string.format('Socket Receive Error occured: %s', recverr))
		
		if recverr == 'closed' then
			log.warn ('Envisalink has disconnected')
			evlClient.disconnect(driver)
			evlClient.reconnect(driver)
		
		end
	end	
end

function evlClient.is_loggedin(driver)

	return loggedin

end

function evlClient.is_connected(driver)

	return connected

end

return evlClient

