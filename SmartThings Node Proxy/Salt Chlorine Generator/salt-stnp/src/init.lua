local Driver = require('st.driver')
local caps = require('st.capabilities')
local log = require('log')

---------------------------------------
-- local imports
local lifecycles = require('lifecycles')
local commands = require('commands')

---------------------------------------
-- variables
initialized = false

conf = {  ['stnp']  = {
                              ['plugin'] = 'salt',
                              ['ip'] = '192.168.1.nnn',
                              ['port'] = 8080,
                              ['auth'] = 'password'
                      },
       }

TIMERS = {}

---------------------------------------
-- driver functions
local function discovery_handler(driver, _, should_continue)
  if not initialized then
    log.info("Creating primary device")
    commands.createPrimaryDevice(driver, 1)
  else
    log.info ('Primary device already created')
  end
end

---------------------------------------
-- Driver definition
local driver = Driver('salt', {
      discovery = discovery_handler,
      lifecycle_handlers = lifecycles,
      capability_handlers = {
          [caps.refresh.ID] = {
              [caps.refresh.commands.refresh.NAME] = lifecycles.init
          },
      },
    }
  )

--------------------
-- Initialize Driver
driver:run()