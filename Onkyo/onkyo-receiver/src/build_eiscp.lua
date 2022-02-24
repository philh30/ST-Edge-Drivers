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
local wrap = require('wrap_eiscp')

local builder = function(device,comp,cap,attr,state)
    if (((map[comp] or {})[cap] or {})[attr] or {}).cmd then
        local cmd = map[comp][cap][attr].cmd .. (map[comp][cap][attr][state] or state)
        local msg = wrap(cmd)
        log.trace(string.format('TX > %s',msg))
        return msg
    else
        return nil
    end
end

return builder