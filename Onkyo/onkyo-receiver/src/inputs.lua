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

local function get_inputs(device)
    local inputs = {
        query = 'QSTN',
    }
    if device.preferences.input00 then
        for key, label in pairs(device.preferences) do
            local hex = string.match(key,'input(..)')
            if hex and tonumber(hex,16) and label ~= 'NONE' then
                inputs[label] = hex
            end
        end
    else
        inputs.CABLE = '01'
        inputs.GAME = '02'
        inputs.AUX = '03'
        inputs.PC = '05'
        inputs.BDDVD = '10'
        inputs.STREAMINGBOX = '11'
        inputs.TV = '12'
        inputs.PHONO = '22'
        inputs.CD = '23'
        inputs.FM = '24'
        inputs.AM = '25'
        inputs.USB = '29'
        inputs.NET = '2B'
        inputs.BLUETOOTH = '2E'
        inputs.UNKNOWN = '80'
    end
    return inputs
end

return get_inputs