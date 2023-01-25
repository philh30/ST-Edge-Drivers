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

local function splitString(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local function splitAssocString (inputstr, sep, maxnodes, addhub, supports_multi)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  local m={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    if (#m + #t) < maxnodes then
      local u = splitString(str,":")
      if tonumber(u[1],16) and ((tonumber(u[1],16) ~= 1) or not addhub) then
        if #u == 1 then
          table.insert(t, tonumber(u[1],16))
        elseif supports_multi and tonumber(u[2],16) then
          table.insert(m, {multi_channel_node_id=tonumber(u[1],16),end_point=tonumber(u[2],16),bit_address=false})
        end
      end
    end
  end
  return t,m
end

return splitAssocString