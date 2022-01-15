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

local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({ version = 1 })
local ThermostatSetpoint = (require "st.zwave.CommandClass.ThermostatSetpoint")({ version = 1 })
local ThermostatMode = (require "st.zwave.CommandClass.ThermostatMode")({ version = 1 })
local ThermostatFanMode = (require "st.zwave.CommandClass.ThermostatFanMode")({ version = 1 })
local ThermostatOperatingState = (require "st.zwave.CommandClass.ThermostatOperatingState")({ version = 1 })
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 2 })
local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local cc = require "st.zwave.CommandClass"
local log = require "log"
local zw = require "st.zwave"
local constants = require "st.zwave.constants"
local utils = require "st.utils"
local capdefs = require "capabilitydefs"
local socket = require "cosock.socket"
local utilities = require "utilities"
local get = require "get_constants"
local manufacturer = require "manufacturer"
local config = require "configuration"
local evt = require "events"

local cc_handlers = {}

--[[
    0x20,	//	Basic
	0x25,	//	Switch Binary
	0x27,	//	Switch All
	0x31,	//	Sensor Multilevel
	0x43,	//	Thermostat setpoint
	0x60,	//	Multi Instance
	0x70,	//	Configuration
	0x72,	//	Manufacturer Specific
	0x73,	//	Powerlevel
	0x81,	//	Clock
	0x85,	//	Association
	0x86,	//	Version
	0x91	//	Manufacturer Proprietary
]]

--- Basic:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Basic.Report
function cc_handlers.basic_report(driver,device,command)
    local update = {
        { type = 'switch1', state = (command.args.value == 0) and 'off' or 'on' },
    }
    evt.post_event(device,command.cmd_class,command.cmd_id,update)
end

--- SwitchBinary:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.SwitchBinary.Report
function cc_handlers.switch_binary_report(driver,device,command)
    log.trace('SWITCH BINARY REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- SwitchAll:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.SwitchAll.Report
function cc_handlers.switch_all_report(driver,device,command)
    log.trace('SWITCH ALL REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- SwitchMultilevel:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.SwitchMultilevel.Report
function cc_handlers.sensor_multilevel_report(driver,device,command)
    log.trace('SENSOR MULTILEVEL REPORT: ')
    utilities.disptable(command.args,'  ')
    local update = {
        { type = 'waterTemp', state = command.args.sensor_value, unit = command.args.scale },
    }
    evt.post_event(device,command.cmd_class,command.cmd_id,update)
end

--- ThermostatSetpoint:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.ThermostatSetpoint.Report
function cc_handlers.thermostat_setpoint_report(driver,device,command)
    local setpoint_type = (command.args.setpoint_type == get.POOL_SETPOINTTYPE) and 'thermostatSetpointPool' or ((command.args.setpoint_type == get.SPA_SETPOINTTYPE) and 'thermostatSetpointSpa' or 'thermostatSetpointUnknown')
    local update = {
        { type = setpoint_type, state = command.args.value },
    }
    evt.post_event(device,command.cmd_class,command.cmd_id,update)
end

--- ThermostatSetpoint:SupportedReport handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.ThermostatSetpoint.SupportedReport
function cc_handlers.thermostat_setpoint_supported_report(driver,device,command)
    log.trace('THERMOSTAT SETPOINT REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- MultiInstance:Encap handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.MultiInstance.MultiInstanceCmdEncap
function cc_handlers.multi_instance_encap(driver,device,command)
    local cmd = {
        instance = string.byte(command.payload,1),
        class = string.byte(command.payload,2),
        id = string.byte(command.payload,3),
        parameter = string.byte(command.payload,4),
    }
    local instance_key = {
        [1] = 'switch1',
        [2] = 'switch2',
        [3] = 'switch3',
        [4] = get.SWITCH_4(device),
        [5] = 'switch5',
        [get.POOL_SPA_CHAN_P5043] = 'poolSpaMode',
        [get.VSP_CHAN_NO(1)] = 'vsp1',
        [get.VSP_CHAN_NO(2)] = 'vsp2',
		[get.VSP_CHAN_NO(3)] = 'vsp3',
		[get.VSP_CHAN_NO(4)] = 'vsp4',
    }
    local resp = {}
    resp.val = (cmd.parameter == 0) and 'off' or 'on'
    if instance_key[cmd.instance] then
        resp.id = instance_key[cmd.instance]
        local update = {
            { type = resp.id, state = (cmd.parameter == 0) and 'off' or 'on' },
        }
        evt.post_event(device,command.cmd_class,command.cmd_id,update)
    else
        log.warn(string.format('Unhandled mutli-instance report: Instance %s, CmdClass %s, CmdID %s, Paramater %s',cmd.instance,cmd.class,cmd.id,cmd.parameter))
    end
end

--- Configuration:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Configuration.Report
function cc_handlers.configuration_report(driver, device, command)
    local str = command.payload
    local payload = {str:byte(1,#str)}
    local param = command.args.parameter_number
    if get.CONFIG_PARAMS[param] then
        local update = config[get.CONFIG_PARAMS[param].handler](payload)
        evt.post_event(device,command.cmd_class,command.cmd_id,update)
    else
        log.trace('Unknown configuration parameter: ' .. param)
        utilities.disptable(payload,'  ')
    end
end

--- ManufacturerSpecific:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.ManufacturerSpecific.Report
function cc_handlers.manufacturer_specific_report(driver,device,command)
    local update = {
        { type = 'manufacturerID', state = command.args.manufacturer_id },
        { type = 'productTypeID', state = command.args.product_type_id },
        { type = 'productID', state = command.args.product_id },
    }
    evt.post_event(device,command.cmd_class,command.cmd_id,update)
end

--- Powerlevel:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Powerlevel.Report
function cc_handlers.power_level_report(driver,device,command)
    log.trace('POWER LEVEL REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- Clock:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Clock.Report
function cc_handlers.clock_report(driver,device,command)
    log.trace('CLOCK REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- Association:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Association.Report
function cc_handlers.association_report(driver,device,command)
    log.trace('ASSOCIATION REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- Version:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Version.Report
function cc_handlers.version_report(driver,device,command)
    local update = {
        { type = 'firmwareVersion', state = command.args.application_version .. '.' .. command.args.application_sub_version },
    }
    evt.post_event(device,command.cmd_class,command.cmd_id,update)
end

--- Version:CommandClassReport handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Version.CommandClassReport
function cc_handlers.version_cc_report(driver,device,command)
    log.trace('VERSION CC REPORT: ')
    utilities.disptable(command.args,'  ')
end

--- ManufacturerProprietary:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function cc_handlers.manufacturer_proprietary_report(driver,device,command)
    local str = command.payload
    local payload = {str:byte(1,#str)}
    if (command.cmd_class == 0x91) and (command.cmd_id == 0x00) then
        if payload[2] == 0x40 then
            if payload[5] == 0x84 then
                manufacturer.process84Event(device,payload)
            end
            if payload[5] == 0x87 then
                manufacturer.process87Event(device,payload)
            end
        end
    end
end

return cc_handlers