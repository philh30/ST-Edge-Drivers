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

local get_resp = {}

function get_resp.SWITCH_SCHED_PARAM(sw, sch)   -- Configuration schedule for switch 1-5
    return (4 + (sw-1)*3 + (sch-1))
end

function get_resp.VSP_RPM_SCHED_PARAM(sp)       -- Configuration schedule for VSP RPM Speeds 1-4
    return (32 + (sp-1))
end

get_resp.VSP_RPMMAX_SCHED_PARAM = 49            -- VSP RPM Max speed Schedule 0x31

function get_resp.POOL_SPA_SCHED_PARAM(sch)     -- Pool/Spa mode Schedule 1-3 - 0x13
    return 19 + (sch-1)
end

get_resp.POOL_SPA_CONFIG = 22             		-- Pool/Spa mode config - 0x16
get_resp.OPERATION_MODE_CONFIG = 1				-- Operation mode - 0x01
get_resp.FIREMAN_CONFIG = 2						-- Fireman and Heater Safety - 0x02

function get_resp.VSP_SCHED_PARAM(sp, sch)      -- VSP Speed 1-4 Schedule 1-3 - 0x24
    return (36 + (sp-1)*3 + (sch-1))
end

get_resp.POOL_SPA_CHAN_P5043 = 39				-- Pool/Spa channel - 0x27 for P5043 expansion
get_resp.POOL_SPA_EP = 6						-- Pool/Spa endpoint - 6
get_resp.POOL_TEMPERATURE_EP = 11				-- Child Temperature Endpoint for Pool 11
get_resp.SPA_TEMPERATURE_EP = 12				-- Child Temperature Endpoint for Spa 12
get_resp.POOL_SETPOINT_EP = 13					-- Child Setpoint Endpoint for Pool 13
get_resp.SPA_SETPOINT_EP = 14					-- Child Setpoint Endpoint for Spa 14
get_resp.POOL_THERMOSTATMODE_EP = 15			-- Child Mode Endpoint for Pool 15
get_resp.SPA_THERMOSTATMODE_EP = 16				-- Child Mode Endpoint for Spa 16
get_resp.POOL_THERMOSTATOPERATINGSTATE_EP = 17  -- Child State Endpoint for Pool 17
get_resp.SPA_THERMOSTATOPERATINGSTATE_EP = 18	-- Child State Endpoint for Spa 18
get_resp.POOL_SETPOINTTYPE = 1					-- Setpoint Type 1 is for the Pool
get_resp.SPA_SETPOINTTYPE = 7					-- Setpoint Type 7 is for the Spa

function get_resp.VSP_SPEED(sched)		        -- Convert from sched to speed
    return ((sched - 35) / 3)
end

function get_resp.VSP_CHAN_NO(spd)		        -- VSP Speed 1 Channel  - 0x10 - 0x13
    return (16 + (spd - 1))
end

function get_resp.VSP_EP(spd)				    -- VSP Endpoint 7 - 10
    return (6 + spd)
end

function get_resp.VSP_SPEED_FROM_CHAN(chan)     -- Convert from channel to speed - 0x10
    return ((chan - 16) + 1)
end

function get_resp.SCHED_PARAM(ep, sch)
	if (ep >= 1 and ep <= 5) 	then 	return get_resp.SWITCH_SCHED_PARAM(ep, sch) 	end
	if (ep == 6)				then	return get_resp.POOL_SPA_SCHED_PARAM(sch) 		end
	if (ep >= 7 and ep <= 10) 	then	return get_resp.VSP_SCHED_PARAM(ep-6, sch) 		end
	return 0
end

function get_resp.EP_FROM_SCHED_PARM(paramNum)
	if (paramNum >= get_resp.SCHED_PARAM(1, 1) and paramNum <= get_resp.SCHED_PARAM(5, 3)) then
		return ((paramNum - get_resp.SCHED_PARAM(1,1)).intdiv(3) + 1)
	end
	if (paramNum >= get_resp.SCHED_PARAM(6, 1) and paramNum <= get_resp.SCHED_PARAM(6, 3)) then
		return 6
	end
	if (paramNum >= get_resp.SCHED_PARAM(7, 1) and paramNum <= get_resp.SCHED_PARAM(10, 3)) then
		return ((paramNum - get_resp.SCHED_PARAM(7,1)).intdiv(3) + 1 + 6)
	end
	return 0
end

function get_resp.FIRMWARE_VERSION(device)
	local firmwareVersion = device:get_field('FIRMWARE')
	return firmwareVersion or '0.0'
end

function get_resp.EXPANSION_5043(device)
	local expansionVersion = device:get_field('EXP_VERSION')
	return expansionVersion == '3.4'
end

---------------------------------------------------------------------------------
-- Work on these!!!!!!!!!!!!!
function get_resp.POOL_SPA_CHAN(device)				-- Pool/Spa channel - 0x27 if P5043 otherwise 0x04 (Switch 4)
	return get_resp.EXPANSION_5043(device) and 39 or 4
end

function get_resp.VSP_ENABLED(device)					-- True if a Variable Speed Pump configured
	local operationMode2 = '5'					-- NEED TO POPULATE THIS IN A FIELD FIRST
	return (operationMode2 >= '4') and 1 or 0
end

function get_resp.HAS_HEATER(device)					-- True if Heater equipped
	local fireman = 0							-- NEED TO POPULATE THIS IN A FIELD FIRST
	return tonumber(fireman) ~= 255
end

function get_resp.POOL_SPA_COMBO(device)				-- True if both Pool and Spa
	local poolSpa1 = '2'						-- NEED TO POPULATE THIS IN A FIELD FIRST
	return (poolSpa1 == '2') and 1 or 0
end

function get_resp.SWITCH_4(device)					-- Report sw4 change as Pool/Spa unless P5043
	if not get_resp.EXPANSION_5043(device) then
		return 'poolSpaMode'
	else
		return 'switch4'
    end
end


-- Ver 3.1 firmware offsets (per logs from ethelredkent)
-- Pool switch : 6
-- waterTemp : 10
-- airTempFreeze : 11
-- airTempSolar : 12

-- All of these updated +1 to account for Lua arrays starting at 1

function get_resp.ADJ_84(device)						-- Determine the adjustment for old firmware
	local firmwareVersion = device:get_field('FIRMWARE')
	return (firmwareVersion == '3.1') and -2 or 0
end

function get_resp.SWITCHES_84(device)					-- Bit mask of 5 switches. SW1 = 01X, SW5 = 10X
	return 9  + get_resp.ADJ_84(device)
end

function get_resp.POOL_SPA_MODE_84(device)			-- Pool/Spa mode. 01x Pool mode, 00x Spa mode
	return 12 + get_resp.ADJ_84(device)
end

function get_resp.WATER_TEMP_84(device)				-- Water Temperature
	return 13 + get_resp.ADJ_84(device)
end

function get_resp.AIR_TEMP_FREEZE_84(device)			-- Air Temperature for Freeze sensing
	return 14 + get_resp.ADJ_84(device)
end

function get_resp.AIR_TEMP_SOLAR_84(device)			-- Air Temperature for Solar control
	return 15 + get_resp.ADJ_84(device)
end

function get_resp.CLOCK_HOUR_84(device)				-- Clock Hour
	return 16 + get_resp.ADJ_84(device)
end

function get_resp.CLOCK_MINUTE_84(device)				-- Clock Minute
	return 17 + get_resp.ADJ_84(device)
end

function get_resp.VSP_SPEED_84(device)				-- VSP Speed bit mask. 01x = VSP1, 08x = VSP4
	return 21 + get_resp.ADJ_84(device)
end

function get_resp.VER_MAIN_MAJOR_84(device)			-- Firmware version - PE653 - Major
	return 22 + get_resp.ADJ_84(device)
end

function get_resp.VER_MAIN_MINOR_84(device)			-- Firmware version - PE653 - Minor
	return 23 + get_resp.ADJ_84(device)
end

get_resp.VER_EXP_MAJOR_87 = 12					-- Firmware version - PE653 - Major
get_resp.VER_EXP_MINOR_87 = 13					-- Firmware version - PE653 - Minor
get_resp.HEATER_87 = 15							-- Heater. 04x = on, 00x = off
get_resp.CLOCK_HOUR_87 = 24						-- Clock Hour
get_resp.CLOCK_MINUTE_87 = 25					-- Clock Minute

get_resp.CONFIG_PARAMS = {
	[0x01] = { description = 'PE653_OPERATION_MODE', handler = 'operation_mode_handler', size = 2 },
	[0x02] = { description = 'FIREMAN_TIMEOUT', handler = 'fireman_handler', size = 2 },
	[0x03] = { description = 'TEMP_CALIBRATION_OFFSETS', handler = 'temp_offset_handler'},
	[0x04] = { description = 'CIR_1_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 1, Schedule 1' },
	[0x05] = { description = 'CIR_1_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 1, Schedule 2' },
	[0x06] = { description = 'CIR_1_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 1, Schedule 3' },
	[0x07] = { description = 'CIR_2_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 2, Schedule 1' },
	[0x08] = { description = 'CIR_2_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 2, Schedule 2' },
	[0x09] = { description = 'CIR_2_EV_SCHED_3', handler = 'schedule_handler', size = 1, friendlyname = 'Circuit 2, Schedule 3' },
	[0x0A] = { description = 'CIR_3_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 3, Schedule 1' },
	[0x0B] = { description = 'CIR_3_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 3, Schedule 2' },
	[0x0C] = { description = 'CIR_3_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 3, Schedule 3' },
	[0x0D] = { description = 'CIR_4_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 4, Schedule 1' },
	[0x0E] = { description = 'CIR_4_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 4, Schedule 2' },
	[0x0F] = { description = 'CIR_4_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 4, Schedule 3' },
	[0x10] = { description = 'CIR_5_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 5, Schedule 1' },
	[0x11] = { description = 'CIR_5_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 5, Schedule 2' },
	[0x12] = { description = 'CIR_5_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'Circuit 5, Schedule 3' },
	[0x13] = { description = 'POOL_SPA_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'Pool/Spa Mode, Schedule 1' },
	[0x14] = { description = 'POOL_SPA_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'Pool/Spa Mode, Schedule 2' },
	[0x15] = { description = 'POOL_SPA_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'Pool/Spa Mode, Schedule 3' },
	[0x16] = { description = 'POOL_SPA_SUPPORT_MODE', handler = 'pool_spa_handler'},
	[0x20] = { description = 'VSP_SPD_SETTING_1', handler = 'pump_speed_handler'},
	[0x21] = { description = 'VSP_SPD_SETTING_2', handler = 'pump_speed_handler'},
	[0x22] = { description = 'VSP_SPD_SETTING_3', handler = 'pump_speed_handler'},
	[0x23] = { description = 'VSP_SPD_SETTING_4', handler = 'pump_speed_handler'},
	[0x24] = { description = 'VSP_SPD_1_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 1, Schedule 1' },
	[0x25] = { description = 'VSP_SPD_1_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 1, Schedule 2' },
	[0x26] = { description = 'VSP_SPD_1_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 1, Schedule 3' },
	[0x27] = { description = 'VSP_SPD_2_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 2, Schedule 1' },
	[0x28] = { description = 'VSP_SPD_2_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 2, Schedule 2' },
	[0x29] = { description = 'VSP_SPD_2_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 2, Schedule 3' },
	[0x2A] = { description = 'VSP_SPD_3_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 3, Schedule 1' },
	[0x2B] = { description = 'VSP_SPD_3_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 3, Schedule 2' },
	[0x2C] = { description = 'VSP_SPD_3_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 3, Schedule 3' },
	[0x2D] = { description = 'VSP_SPD_4_EV_SCHED_1', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 4, Schedule 1' },
	[0x2E] = { description = 'VSP_SPD_4_EV_SCHED_2', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 4, Schedule 2' },
	[0x2F] = { description = 'VSP_SPD_4_EV_SCHED_3', handler = 'schedule_handler', size = 4, friendlyname = 'VSP Speed 4, Schedule 3' },
	[0x31] = { description = 'VSP_MAX_PUMP_SPEED', handler = 'pump_speed_handler'},
	[0x32] = { description = 'FREEZE_CONTROL', handler = 'freeze_control_handler'},
}

get_resp.ENDPOINT_SCHEDULES = {
	switch1 =		{ 0x04, 0x05, 0x06 },
	switch2 =		{ 0x07, 0x08, 0x09 },
	switch3 =		{ 0x0A, 0x0B, 0x0C },
	switch4 =		{ 0x0D, 0x0E, 0x0F },
	switch5 =		{ 0x10, 0x11, 0x12 },
	poolSpaMode =	{ 0x13, 0x14, 0x15 },
	vsp1 =			{ 0x24, 0x25, 0x26 },
	vsp2 =			{ 0x27, 0x28, 0x29 },
	vsp3 =			{ 0x2A, 0x2B, 0x2C },
	vsp4 =			{ 0x2D, 0x2E, 0x2F },
}

get_resp.CONFIG_BOOSTER_CIRCUIT = {
	[0x01] = 'Booster/Cleaner functionality not supported',
	[0x02] = 'Circuit 1 used for Booster/Cleaner',
	[0x03] = 'Variable speed pump Speed 1 used for Booster/Cleaner',
	[0x04] = 'Variable speed pump Speed 2 used for Booster/Cleaner',
	[0x05] = 'Variable speed pump Speed 3 used for Booster/Cleaner',
	[0x06] = 'Variable speed pump Speed 4 used for Booster/Cleaner',
}

get_resp.CONFIG_INSTALLED_PUMP_TYPE = {
	[0x00] = 'One Speed',
	[0x02] = 'Two Speed',
}

get_resp.CONFIG_BOOSTER_CLEANER_INSTALLED = {
	[0x00] = 'No',
	[0x01] = 'Yes',
}

get_resp.CONFIG_FIREMAN_TIMEOUT = {
	[0xFF] = 'Fireman Disabled (no heater installed)',
	[0x00] = 'Fireman Enabled (heater installed) with no cool down period',
	[0x01] = 'Fireman Enabled (heater installed) with cool down period = 1 minute',
	[0x02] = 'Fireman Enabled (heater installed) with cool down period = 2 minute',
	[0x03] = 'Fireman Enabled (heater installed) with cool down period = 3 minute',
	[0x04] = 'Fireman Enabled (heater installed) with cool down period = 4 minute',
	[0x05] = 'Fireman Enabled (heater installed) with cool down period = 5 minute',
	[0x06] = 'Fireman Enabled (heater installed) with cool down period = 6 minute',
	[0x07] = 'Fireman Enabled (heater installed) with cool down period = 7 minute',
	[0x08] = 'Fireman Enabled (heater installed) with cool down period = 8 minute',
	[0x09] = 'Fireman Enabled (heater installed) with cool down period = 9 minute',
	[0x0A] = 'Fireman Enabled (heater installed) with cool down period = 10 minute',
	[0x0B] = 'Fireman Enabled (heater installed) with cool down period = 11 minute',
	[0x0C] = 'Fireman Enabled (heater installed) with cool down period = 12 minute',
	[0x0D] = 'Fireman Enabled (heater installed) with cool down period = 13 minute',
	[0x0E] = 'Fireman Enabled (heater installed) with cool down period = 14 minute',
	[0x0F] = 'Fireman Enabled (heater installed) with cool down period = 15 minute',
}

get_resp.CONFIG_HEATER_SAFETY = {
	[0x00] = 'Disabled',
	[0x01] = 'Enabled',
}

get_resp.CONFIG_POOL_SPA = {
	[0x00] = 'Pool Only',
	[0x01] = 'Spa Only',
	[0x02] = 'Both Pool and Spa',
}

get_resp.CONFIG_FREEZE_CONTROL_CIRCUITS = {
	[0x01] = 'Circuit 1',
	[0x02] = 'Circuit 2',
	[0x04] = 'Circuit 3',
	[0x08] = 'Circuit 4',
	[0x10] = 'Circuit 5',
}

get_resp.CONFIG_FREEZE_CONTROL_VSP_SPD = {
	[0x00] = 'None',
	[0x01] = 'Variable Pump Speed 1',
	[0x02] = 'Variable Pump Speed 2',
	[0x03] = 'Variable Pump Speed 3',
	[0x04] = 'Variable Pump Speed 4',
}

get_resp.THERM_SETPOINTS = {
	HEATING_1	= 'Pool',
	FURNACE 	='Spa',
}

return get_resp