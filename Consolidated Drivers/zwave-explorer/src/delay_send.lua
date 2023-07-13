local log = require "log"

local function delay_send(device,commands,delay)
    local function send_loop()
        log.trace('~~~~~ Send ' .. ((#commands == 1) and '' or ('with delay: ' .. #commands .. ' commands to send')) .. '~~~~~')
        device:send(commands[1])
        table.remove(commands,1)
        if #commands > 0 then
            device.thread:call_with_delay(delay, send_loop)
        else
            log.trace('~~~~~ All commands sent ~~~~~')
        end
    end
    send_loop()
end

return delay_send