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

local cap_map = require('cap_map')

local reflect_cap_map = function(device)
    local map = cap_map(device)
    local reflected = {}
    for comp_key, comp in pairs(map) do
        for cap_key, cap in pairs(comp) do
            for attr_key, attr in pairs(cap) do
                if attr.cmd then
                    reflected[attr.cmd] = {
                        comp = comp_key,
                        cap = cap_key,
                        attr = attr_key,
                        values = {},
                    }
                    for key, value in pairs(attr) do
                        if key ~= 'cmd' then
                            reflected[attr.cmd].values[value] = key
                        end
                    end
                end
            end
        end
    end
    return reflected
end

return reflect_cap_map