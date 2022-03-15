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

local log = require('log')
local map = require('cap_map')

local function pad(str,padding,len,direction)
    local n = len - #str
    local p = ''
    if n > 0 then
        for i = 1, n, 1 do
            p = p .. padding
        end
    end
    if direction == 'left' then
        p = p .. str
    else
        p = str .. p
    end
    return p
end

local builder = function(device,comp,cap,attr,state)
    if (((map[comp] or {})[cap] or {})[attr] or {}).cmd then
        local cmd = map[comp][cap][attr].cmd
        local type = map[comp][cap][attr].type
        if state == 'query' then
            if map[comp][cap][attr].query then
                cmd = 'E' .. cmd .. pad('','#',16,'left')
            else
                return nil
            end
        else
            if type == 'binary' or type == 'input' then
                cmd = 'C' .. cmd .. pad(map[comp][cap][attr][state],'0',16,'left')
            elseif type == 'integer' then
                cmd = 'C' .. cmd .. pad(state .. '','0',16,'left')
            elseif type == 'decimal' then
                local dec_match = string.match(state,'%d+%.%d+')
                local int_match = string.match(state,'%d+')
                if dec_match then
                    local left, right = string.match(dec_match,'(%d+)%.(%d+)')
                    cmd = 'C' .. cmd .. pad(left,'0',8,'left') .. '.' .. pad(right,'0',7,'right')
                elseif int_match then
                    cmd = 'C' .. cmd .. pad(int_match,'0',8,'left') .. '.' .. pad('','0',7,'right')
                else
                    return nil
                end
            end
        end
        cmd = '*S' .. cmd
        log.trace(string.format('TX > %s',cmd))
        cmd = cmd .. '\x0A'
        return cmd
    else
        return nil
    end
end

return builder