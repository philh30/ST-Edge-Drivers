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

local maintain_schedules = {}

local function table_header(row_items)
    local width_map = {'60%','20%','20%'}
    local row = '<tr>'
    local x = 1
    for _,item in pairs(row_items) do
        --row = row .. '<th' .. (width_map[x] and (' style="width:' .. width_map[x] .. '"') or '') .. '>' .. (item or '') .. '</th>'
        row = row .. '<th' .. (width_map[x] and (' style="width:' .. width_map[x] .. '"') or '') .. '>' .. (item or '') .. '</th>'
        x=x+1
    end
    row = row .. '</tr>'
    return row
end

local function table_row(row_items)
    local row = '<tr>'
    local i = 1
    for _,item in pairs(row_items) do
      --row = row .. '<td>' .. (item or '') .. '</td>'
      row = row .. '<td style="text-align:' .. ((i==1) and 'left' or 'center') .. '">' .. (item or '') .. '</td>'
      i=i+1
    end
    row = row .. '</tr>'
    return row
end

local function parse_table(inputstr)
    local t={}
    for str in string.gmatch(inputstr, '<tr>(.-)</tr>') do
        local a = {}
        local i = 1
        --for row in string.gmatch(str, '<td>(.-)</td>') do
        for row in string.gmatch(str, '">(.-)</td>') do
            a[i]=row
            i=i+1
        end
            if a[1] then table.insert(t, {name=a[1],start=a[2],stop=a[3]}) end
    end
    return t
end

function maintain_schedules.update_sched(device,sched)
    local sched_order = {
        ['Circuit 1 - 1'] = 1,
        ['Circuit 1 - 2'] = 2,
        ['Circuit 1 - 3'] = 3,
        ['Circuit 2 - 1'] = 4,
        ['Circuit 2 - 2'] = 5,
        ['Circuit 2 - 3'] = 6,
        ['Circuit 3 - 1'] = 7,
        ['Circuit 3 - 2'] = 8,
        ['Circuit 3 - 3'] = 9,
        ['Circuit 4 - 1'] = 10,
        ['Circuit 4 - 2'] = 11,
        ['Circuit 4 - 3'] = 12,
        ['Circuit 5 - 1'] = 13,
        ['Circuit 5 - 2'] = 14,
        ['Circuit 5 - 3'] = 15,
        ['Pool|Spa - 1'] = 16,
        ['Pool|Spa - 2'] = 17,
        ['Pool|Spa - 3'] = 18,
        ['VSP Speed 1 - 1'] = 19,
        ['VSP Speed 1 - 2'] = 20,
        ['VSP Speed 1 - 3'] = 21,
        ['VSP Speed 2 - 1'] = 22,
        ['VSP Speed 2 - 2'] = 23,
        ['VSP Speed 2 - 3'] = 24,
        ['VSP Speed 3 - 1'] = 25,
        ['VSP Speed 3 - 2'] = 26,
        ['VSP Speed 3 - 3'] = 27,
        ['VSP Speed 4 - 1'] = 28,
        ['VSP Speed 4 - 2'] = 29,
        ['VSP Speed 4 - 3'] = 30,
    }

    local sched_table = device.state_cache.schedules[capdefs.schedules.name].schedules.value
    local sched_array = parse_table(sched_table)
    --sched_table = '<small><table style="width:100%">'
    sched_table = '<table style="font-size:65%;width:100%">'
    sched_table = sched_table .. table_header({ 'Schedule', 'On', 'Off' })
    sched.order = sched_order[sched.name]
    local found = false
    for _,old_sch in ipairs(sched_array) do
        if sched.order == sched_order[old_sch.name] then
            if not found and sched.start then sched_table = sched_table .. table_row({ sched.name, sched.start, sched.stop }) end
            found = true
        elseif (sched.order < sched_order[old_sch.name]) and not found then
            found = true
            if sched.start then sched_table = sched_table .. table_row({ sched.name, sched.start, sched.stop }) end
        end
        if sched.order ~= sched_order[old_sch.name] then
            sched_table = sched_table .. table_row({ old_sch.name, old_sch.start, old_sch.stop })
        end
    end
    if not found and sched.start then sched_table = sched_table .. table_row({ sched.name, sched.start, sched.stop }) end
    sched_table = sched_table .. '</table>' --</small>'
    local evt = capabilities[capdefs.schedules.name].schedules({value = sched_table})
    evt.visibility = {displayed = false}
    device:emit_component_event(device.profile.components['schedules'],evt)
end

return maintain_schedules