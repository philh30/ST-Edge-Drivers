local log = require('log')

local utilities = {}

---------------------------------------
-- Parses string inputstr using sep as delimeter, returns a table of results
function utilities.splitString(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

---------------------------------------
-- Iterate through and log.debug all levels of a table. Pass '  ' to function as tab
function utilities.disptable(table, tab)
  
  for key, value in pairs(table) do
    log.debug (tab .. key, value)
    if type(value) == 'table' then
      utilities.disptable(value, '  ' .. tab)
    end
  end
end

---------------------------------------
-- Pad a string with blank space to n characters
function utilities.pad(str, n)
  if #str < n then
    for x=#str,n,1 do
      str = str .. ' '
    end
  end
  return str
end

---------------------------------------
-- Returns x if it is between min and max, otherwise returns nil
function utilities.isBetween(x,min,max)
  x = tonumber(x)
  if x and (x >= min) and (x <= max) then
    return x
  else
    return nil
  end
end

---------------------------------------
-- Validates a passed time is not nil and in the range of 00:00-23:59
function utilities.validateTime(hour,minute)
  hour = utilities.isBetween(hour,0,23)
  minute = utilities.isBetween(minute,0,59)
  if hour and minute then
    return hour,minute
  else
    return nil
  end
end

---------------------------------------
-- Parses string in format of '00:00-00:00'
function utilities.splitTime(inputstr)
  local times = { inputstr:match('(%d+):(%d+)-(%d+):(%d+)') }
  local start = {utilities.validateTime(times[1],times[2])}
  local stop = {utilities.validateTime(times[3],times[4])}
  if start[1] and start[2] and stop[1] and stop[2] then
    return start[1],start[2],stop[1],stop[2]
  end
  return nil
end

return utilities