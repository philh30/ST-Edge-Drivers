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

local capabilities = require "st.capabilities"
local capdefs = require "capabilitydefs"
local get = require "get_constants"
local map = require "cap_ep_map"

local active = {}

function active.mode(device,inputs)
    -- Determine current pool/spa mode
    local pool_spa_map = {[0]='pool',[1]='spa',on='spa',off='pool',pool='pool',spa='spa'} -- If config is set to Pool Only or Spa Only it will control
    local pool_spa_config = device:get_field('POOL_SPA') or 2 -- Assume Pool and Spa if config is unknown
    local pool_spa_comp = map.GET_COMP(device,'poolSpaMode')
    -- Config setting > Input from event > Last PoolSpaMode status > Assume pool as a fallback
    local pool_spa_current = pool_spa_map[pool_spa_config] or pool_spa_map[inputs.poolSpa] or pool_spa_map[device:get_latest_state(pool_spa_comp,'switch','switch')] or 'pool'

    -- Determine current pump speed
    local pump_speed = 0
    local op_mode_2 = device:get_field('OP_MODE_2') or 0
    local pump_config = get.CONFIG_INSTALLED_PUMP_TYPE[op_mode_2 - (op_mode_2 & 0x01)]
    local on_off_map = {off=0,on=1}
    if pump_config == 'Two Speed' then
        local switch1_comp = map.GET_COMP(device,'switch1')
        local switch2_comp = map.GET_COMP(device,'switch2')
        local switch1 = on_off_map[((inputs.switch2 and inputs.switch2 == 'on' and 'off') or inputs.switch1 or device:get_latest_state(switch1_comp,'switch','switch') or 'off')]
        local switch2 = 2 * on_off_map[((inputs.switch1 and inputs.switch1 == 'on' and 'off') or inputs.switch2 or device:get_latest_state(switch2_comp,'switch','switch') or 'off')]
        pump_speed = switch1 + switch2
    elseif pump_config == 'Variable Speed' then
        local vsp_comp = map.GET_COMP(device,'vspSpeed')
        local pump_speed = inputs.vsp or (inputs.vsp1 and (inputs.vsp1 == 'off' and 0 or 1)) or (inputs.vsp2 and (inputs.vsp2 == 'off' and 0 or 2)) or (inputs.vsp3 and (inputs.vsp3 == 'off' and 0 or 3)) or (inputs.vsp4 and (inputs.vsp4 == 'off' and 0 or 4)) or device:get_latest_state(vsp_comp,capdefs.pumpSpeed.name,'vspSpeed') or 0
    else --One speed or Unknown - use circuit 1
        local switch1_comp = map.GET_COMP(device,'switch1')
        local switch1 = on_off_map[(inputs.switch1 or device:get_latest_state(switch1_comp,'switch','switch') or 'off')]
        pump_speed = (switch1 == 0) and '0' or ''
    end
    local cooldown = (inputs.cooldown == 'on') and '-c' or ''
    local msg = { type = 'activeMode', state = pool_spa_current .. pump_speed .. cooldown }
    return msg
end

return active