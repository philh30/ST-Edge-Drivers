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

local cap_map = require "cap_map"

--- @param device st.zwave.Device
--- @param evt integer
local function event_handler(device,evt)
    local map = cap_map(device)
    if device.preferences.invertStatus then evt = math.abs(evt-1) end
    for _, component in pairs(device.profile.components) do
        for _, capability in pairs(component.capabilities) do
            if (map[capability.id] or {})[evt] then
                device:emit_component_event(component, map[capability.id][evt])
            end
        end
    end
end

return event_handler