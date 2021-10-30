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

local Driver = require('st.driver')
local caps = require('st.capabilities')
local log = require('log')
local capdefs = require('capabilitydefs')
local events = require "evthandler"

---------------------------------------
-- local imports
local lifecycles = require('lifecycles')

---------------------------------------
-- custom capabilities
caps[capdefs.statusMessage.name]  = capdefs.statusMessage.capability
caps[capdefs.alarmMode.name]  = capdefs.alarmMode.capability
caps[capdefs.bypass.name]         = capdefs.bypass.capability
caps[capdefs.contactZone.name]    = capdefs.contactZone.capability
caps[capdefs.glassBreakZone.name] = capdefs.glassBreakZone.capability
caps[capdefs.leakZone.name]       = capdefs.leakZone.capability
caps[capdefs.motionZone.name]     = capdefs.motionZone.capability
caps[capdefs.smokeZone.name]      = capdefs.smokeZone.capability

---------------------------------------
-- variables
initialized = false
timers = { ['reconnect'] = nil, ['waitlogin'] = nil, ['throttle'] = nil }

conf = {  ['ip'] = '192.168.1.nnn',
          ['port'] = 4025,
          ['password'] = 'user',
          ['alarmcode']   = 1111,
          ['zoneclosedelay'] = 2,
          ['wiredzonemax'] = 8,
          ['partitions'] = { [1] = {}, [2] = {} },
          ['zones'] = { [1] = {}, [2] = {} },
          ['switches'] = { [1] = {}, [2] = {} },
}

zone_timers = { [1] = {}, [2] = {} }

last_event = {}

to_send_queue = {}

---------------------------------------
-- driver functions
local function discovery_handler(driver, _, should_continue)
  if not initialized then
    log.info("Creating primary partition device")
    events.createDevice(driver, 'partition', 'Primary Partition', 1, nil)
  else
    log.info ('Primary partition already created')
  end
end

---------------------------------------
-- Driver definition
local driver = Driver('envisalink-honeywell', {
      discovery = discovery_handler,
      lifecycle_handlers = lifecycles,
      sub_drivers = { 
        require('partitions'),
        require('zones'),
        require('switches')
      }
    }
  )

--------------------
-- Initialize Driver
driver:run()