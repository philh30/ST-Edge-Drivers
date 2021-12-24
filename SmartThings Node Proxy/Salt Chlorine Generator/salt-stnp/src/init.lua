local Driver = require('st.driver')
local caps = require('st.capabilities')
local log = require('log')
local capdefs = require('capabilitydefs')

---------------------------------------
-- local imports
local lifecycles = require('lifecycles')
local commands = require('commands')

---------------------------------------
-- custom capabilities
cap_orp = caps.build_cap_from_json_string(capdefs.orpMeasurement)
caps["platinummassive43262.orpMeasurement"] = cap_orp
cap_ph = caps.build_cap_from_json_string(capdefs.phMeasurement)
caps["platinummassive43262.phMeasurement"] = cap_ph
cap_salt = caps.build_cap_from_json_string(capdefs.saltMeasurement)
caps["platinummassive43262.saltMeasurement"] = cap_salt
cap_current = caps.build_cap_from_json_string(capdefs.currentMeter)
caps["platinummassive43262.currentMeter"] = cap_current
cap_status = caps.build_cap_from_json_string(capdefs.statusMessage)
caps["platinummassive43262.statusMessage"] = cap_status
cap_error = caps.build_cap_from_json_string(capdefs.errorReport)
caps["platinummassive43262.errorReport"] = cap_error

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
    }
  )

--------------------
-- Initialize Driver
driver:run()