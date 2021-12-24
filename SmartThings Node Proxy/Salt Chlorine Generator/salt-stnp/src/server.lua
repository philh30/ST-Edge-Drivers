local lux = require('luxure')
local cosock = require('cosock.socket')
local json = require('dkjson')
local log = require('log')
local commands = require('commands')

local hub_server = {}

local function disptable(table, tab)

  for key, value in pairs(table) do
    log.debug (tab .. key, value)
    if type(value) == 'table' then
      disptable(value, '  ' .. tab)
    end
  end
end

function hub_server.start(driver, device)
  log.debug ('Starting server......')
  local server = lux.Server.new_with(cosock.tcp(), {env='debug'})

  -- Register server
  driver:register_channel_handler(server.sock, function ()
    server:tick()
  end)

  -- Endpoint
  server:notify('/notify', function (req, res)
    log.info("SERVER:NOTIFY")
    local body = json.decode(req:get_body())
    device:online()

    --disptable(req:get_headers(),'  ')
    if req:get_headers().stnp_plugin == conf.stnp.plugin then
      log.debug (string.format('Received message from STNP plugin %s: %s',conf.stnp.plugin,req:get_body()))
      commands.notification_handler(driver,body)
    end
    res:send('HTTP/1.1 200 OK')
  end)
  server:listen()
  driver.server = server
end

return hub_server