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

local cap_defs = require("cap_defs")

--- @param device st.Device
local function add_sources(device,source_list,source_type)
    local count = device.preferences['inputs' .. source_type]
    if count > 0 then
        for i = 1, count, 1 do
            table.insert(source_list,source_type .. i)
        end
    end
end

--- @param device st.Device
local function emit_source_list(device)
    local supportedInputs = {'TV'}
    add_sources(device,supportedInputs,'HDMI')
    add_sources(device,supportedInputs,'COMPONENT')
    add_sources(device,supportedInputs,'COMPOSITE')
    add_sources(device,supportedInputs,'MIRROR')
    add_sources(device,supportedInputs,'PC')
    add_sources(device,supportedInputs,'SCART')
    device:emit_event(cap_defs.inputSource.supportedInputSources({value = supportedInputs}))
end

return emit_source_list