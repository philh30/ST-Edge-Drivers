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
local utilities = require "utilities"
local get = require "get_constants"
local capabilities = require "st.capabilities"
local manufacturer = require "manufacturer"
local config = require "configuration"
local evt = require "events"
local map = require "cap_ep_map"

local cc_handlers = {}

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
    local pool_spa_config = device:get_field('POOL_SPA')
    local pool_spa_comp = map.GET_COMP(device,'poolSpaMode')
    local pool_spa_mode = pool_spa_comp and (((device.state_cache[pool_spa_comp].switch.switch.value or 'off') == 'on') and 'thermostatSetpointSpa') or 'thermostatSetpointPool'
    local current_setpoint = ((pool_spa_config == 0) and 'thermostatSetpointPool') or ((pool_spa_config == 1) and 'thermostatSetpointSpa') or pool_spa_mode
    if setpoint_type == current_setpoint then
        table.insert(update,{ type = 'activeSetpoint', command.args.value })
    end
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
        [1] = { key = 'switch1', type = 'switch' },
        [2] = { key = 'switch2', type = 'switch' },
        [3] = { key = 'switch3', type = 'switch' },
        [4] = { key = get.SWITCH_4(device), type = 'switch' },
        [5] = { key = 'switch5', type = 'switch' },
        [get.POOL_SPA_CHAN_P5043] = { key = 'poolSpaMode', type = 'poolSpa' },
        [get.VSP_CHAN_NO(1)] = { key = 'vsp1', type = 'vsp', num = 1 },
        [get.VSP_CHAN_NO(2)] = { key = 'vsp2', type = 'vsp', num = 1 },
		[get.VSP_CHAN_NO(3)] = { key = 'vsp3', type = 'vsp', num = 1 },
		[get.VSP_CHAN_NO(4)] = { key = 'vsp4', type = 'vsp', num = 1 },
    }
    local resp = {}
    resp.val = (cmd.parameter == 0) and 'off' or 'on'
    if instance_key[cmd.instance] then
        resp.id = instance_key[cmd.instance].key
        local update = {
            { type = resp.id, state = resp.val },
        }
        if instance_key[cmd.instance].type == 'poolSpa' then
            local msg = {}
            msg.id = 'activeMode'
            msg.val = (cmd.parameter == 0) and 'pool' or 'spa'
            table.insert(update,{ type=msg.id, state=msg.val})
            local pool_comp = map.GET_COMP(device,'thermostatSetpointPool')
            local spa_comp = map.GET_COMP(device,'thermostatSetpointSpa')
            local pool_setpoint = pool_comp and (device.state_cache[pool_comp].thermostatHeatingSetpoint.heatingSetpoint.value) or 0
            local spa_setpoint = spa_comp and (device.state_cache[spa_comp].thermostatHeatingSetpoint.heatingSetpoint.value) or 0
            msg.id = 'activeSetpoint'
            msg.val = (cmd.parameter == 0) and pool_setpoint or spa_setpoint
            table.insert(update,{ type=msg.id, state=msg.val})
        end
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
        local update = config[get.CONFIG_PARAMS[param].handler](device,payload)
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