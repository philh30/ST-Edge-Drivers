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

--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({ version=4 })
--- @type st.zwave.CommandClass.SwitchColor
local SwitchColor = (require "st.zwave.CommandClass.SwitchColor")({ version=3 })
local paramMap = require('inovelli-lzw45.param_map')

local function basic_refresh(device)
    device:send(SwitchMultilevel:Get({}))
    device:send(SwitchColor:Get({color_component_id=SwitchColor.color_component_id.WARM_WHITE}))
    device:send(SwitchColor:Get({color_component_id=SwitchColor.color_component_id.COLD_WHITE}))
    device:send(SwitchColor:Get({color_component_id=SwitchColor.color_component_id.RED}))
    device:send(SwitchColor:Get({color_component_id=SwitchColor.color_component_id.GREEN}))
    device:send(SwitchColor:Get({color_component_id=SwitchColor.color_component_id.BLUE}))
    for param, _ in pairs(paramMap) do
        device:send(Configuration:Get({parameter_number = param}))
    end
end

return basic_refresh