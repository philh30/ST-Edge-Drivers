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

local capabilities = require('st.capabilities')
local capabilitydefs = {}

capabilitydefs.firmwareVersion = {}
capabilitydefs.firmwareVersion.name = "platinummassive43262.firmwareVersion"
capabilitydefs.firmwareVersion.json = [[
{
    "id": "platinummassive43262.firmwareVersion",
    "version": 1,
    "status": "proposed",
    "name": "Firmware Version",
    "attributes": {
        "version": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "enumCommands": []
        }
    },
    "commands": {}
}
]]
capabilitydefs.firmwareVersion.capability = capabilities.build_cap_from_json_string(capabilitydefs.firmwareVersion.json)

capabilitydefs.pumpSpeed = {}
capabilitydefs.pumpSpeed.name = "platinummassive43262.pe653VariableSpeedPump"
capabilitydefs.pumpSpeed.json = [[
{
    "id": "platinummassive43262.pe653VariableSpeedPump",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Variable Speed Pump",
    "ephemeral": false,
    "attributes": {
        "vspSpeed": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setVSPSpeed",
            "enumCommands": []
        }
    },
    "commands": {
        "setVSPSpeed": {
            "name": "setVSPSpeed",
            "arguments": [
                {
                    "name": "vspSpeed",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.pumpSpeed.capability = capabilities.build_cap_from_json_string(capabilitydefs.pumpSpeed.json)

capabilitydefs.schedule = {}
capabilitydefs.schedule.name = "platinummassive43262.pe653Schedule"
capabilitydefs.schedule.json = [[
{
    "id": "platinummassive43262.pe653Schedule",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Schedule",
    "ephemeral": false,
    "attributes": {
        "schedule": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "fetchSchedule",
            "enumCommands": []
        }
    },
    "commands": {
        "fetchSchedule": {
            "name": "fetchSchedule",
            "arguments": [
                {
                    "name": "schedule",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.schedule.capability = capabilities.build_cap_from_json_string(capabilitydefs.schedule.json)

capabilitydefs.scheduleTime = {}
capabilitydefs.scheduleTime.name = "platinummassive43262.pe653ScheduleTime"
capabilitydefs.scheduleTime.json = [[
{
    "id": "platinummassive43262.pe653ScheduleTime",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Schedule Time",
    "ephemeral": false,
    "attributes": {
        "scheduleTime": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setScheduleTime",
            "enumCommands": []
        },
        "parameter": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "integer"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "enumCommands": []
        }
    },
    "commands": {
        "setScheduleTime": {
            "name": "setScheduleTime",
            "arguments": [
                {
                    "name": "scheduleTime",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.scheduleTime.capability = capabilities.build_cap_from_json_string(capabilitydefs.scheduleTime.json)

capabilitydefs.poolSpaConfig = {}
capabilitydefs.poolSpaConfig.name = "platinummassive43262.pe653PoolSpaConfig"
capabilitydefs.poolSpaConfig.json = [[
{
    "id": "platinummassive43262.pe653PoolSpaConfig",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Pool Spa Config",
    "ephemeral": false,
    "attributes": {
        "poolSpaConfig": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setPoolSpaConfig",
            "enumCommands": []
        }
    },
    "commands": {
        "setPoolSpaConfig": {
            "name": "setPoolSpaConfig",
            "arguments": [
                {
                    "name": "poolSpaConfig",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.poolSpaConfig.capability = capabilities.build_cap_from_json_string(capabilitydefs.poolSpaConfig.json)

capabilitydefs.pumpTypeConfig = {}
capabilitydefs.pumpTypeConfig.name = "platinummassive43262.pe653PumpTypeConfig"
capabilitydefs.pumpTypeConfig.json = [[
{
    "id": "platinummassive43262.pe653PumpTypeConfig",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Pump Type Config",
    "ephemeral": false,
    "attributes": {
        "pumpType": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setPumpType",
            "enumCommands": []
        }
    },
    "commands": {
        "setPumpType": {
            "name": "setPumpType",
            "arguments": [
                {
                    "name": "pumpType",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.pumpTypeConfig.capability = capabilities.build_cap_from_json_string(capabilitydefs.pumpTypeConfig.json)

capabilitydefs.boosterPumpConfig = {}
capabilitydefs.boosterPumpConfig.name = "platinummassive43262.pe653BoosterPumpConfig"
capabilitydefs.boosterPumpConfig.json = [[
{
    "id": "platinummassive43262.pe653BoosterPumpConfig",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Booster Pump Config",
    "ephemeral": false,
    "attributes": {
        "boosterPumpConfig": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setBoosterPumpConfig",
            "enumCommands": []
        }
    },
    "commands": {
        "setBoosterPumpConfig": {
            "name": "setBoosterPumpConfig",
            "arguments": [
                {
                    "name": "boosterPumpConfig",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.boosterPumpConfig.capability = capabilities.build_cap_from_json_string(capabilitydefs.boosterPumpConfig.json)

capabilitydefs.firemanConfig = {}
capabilitydefs.firemanConfig.name = "platinummassive43262.pe653FiremanConfig"
capabilitydefs.firemanConfig.json = [[
{
    "id": "platinummassive43262.pe653FiremanConfig",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Fireman Config",
    "ephemeral": false,
    "attributes": {
        "firemanConfig": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setFiremanConfig",
            "enumCommands": []
        }
    },
    "commands": {
        "setFiremanConfig": {
            "name": "setFiremanConfig",
            "arguments": [
                {
                    "name": "firemanConfig",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.firemanConfig.capability = capabilities.build_cap_from_json_string(capabilitydefs.firemanConfig.json)

capabilitydefs.heaterSafetyConfig = {}
capabilitydefs.heaterSafetyConfig.name = "platinummassive43262.pe653HeaterSafetyConfig"
capabilitydefs.heaterSafetyConfig.json = [[
{
    "id": "platinummassive43262.pe653HeaterSafetyConfig",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Heater Safety Config",
    "ephemeral": false,
    "attributes": {
        "heaterSafetyConfig": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setHeaterSafetyConfig",
            "enumCommands": []
        }
    },
    "commands": {
        "setHeaterSafetyConfig": {
            "name": "setHeaterSafetyConfig",
            "arguments": [
                {
                    "name": "heaterSafetyConfig",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.heaterSafetyConfig.capability = capabilities.build_cap_from_json_string(capabilitydefs.heaterSafetyConfig.json)

capabilitydefs.circuit1FreezeControl = {}
capabilitydefs.circuit1FreezeControl.name = "platinummassive43262.pe653Circuit1Freeze"
capabilitydefs.circuit1FreezeControl.json = [[
{
    "id": "platinummassive43262.pe653Circuit1Freeze",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Circuit 1 Freeze",
    "ephemeral": false,
    "attributes": {
        "freezeControl": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setFreezeCircuitOne",
            "enumCommands": []
        }
    },
    "commands": {
        "setFreezeCircuitOne": {
            "name": "setFreezeCircuitOne",
            "arguments": [
                {
                    "name": "freezeControl",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.circuit1FreezeControl.capability = capabilities.build_cap_from_json_string(capabilitydefs.circuit1FreezeControl.json)

capabilitydefs.circuit2FreezeControl = {}
capabilitydefs.circuit2FreezeControl.name = "platinummassive43262.pe653Circuit2Freeze"
capabilitydefs.circuit2FreezeControl.json = [[
{
    "id": "platinummassive43262.pe653Circuit2Freeze",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Circuit 2 Freeze",
    "ephemeral": false,
    "attributes": {
        "freezeControl": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setFreezeCircuitTwo",
            "enumCommands": []
        }
    },
    "commands": {
        "setFreezeCircuitTwo": {
            "name": "setFreezeCircuitTwo",
            "arguments": [
                {
                    "name": "freezeControl",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.circuit2FreezeControl.capability = capabilities.build_cap_from_json_string(capabilitydefs.circuit2FreezeControl.json)

capabilitydefs.circuit3FreezeControl = {}
capabilitydefs.circuit3FreezeControl.name = "platinummassive43262.pe653Circuit3Freeze"
capabilitydefs.circuit3FreezeControl.json = [[
{
    "id": "platinummassive43262.pe653Circuit3Freeze",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Circuit 3 Freeze",
    "ephemeral": false,
    "attributes": {
        "freezeControl": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setFreezeCircuitThree",
            "enumCommands": []
        }
    },
    "commands": {
        "setFreezeCircuitThree": {
            "name": "setFreezeCircuitThree",
            "arguments": [
                {
                    "name": "freezeControl",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.circuit3FreezeControl.capability = capabilities.build_cap_from_json_string(capabilitydefs.circuit3FreezeControl.json)

capabilitydefs.circuit4FreezeControl = {}
capabilitydefs.circuit4FreezeControl.name = "platinummassive43262.pe653Circuit4Freeze"
capabilitydefs.circuit4FreezeControl.json = [[
{
    "id": "platinummassive43262.pe653Circuit4Freeze",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Circuit 4 Freeze",
    "ephemeral": false,
    "attributes": {
        "freezeControl": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setFreezeCircuitFour",
            "enumCommands": []
        }
    },
    "commands": {
        "setFreezeCircuitFour": {
            "name": "setFreezeCircuitFour",
            "arguments": [
                {
                    "name": "freezeControl",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.circuit4FreezeControl.capability = capabilities.build_cap_from_json_string(capabilitydefs.circuit4FreezeControl.json)

capabilitydefs.circuit5FreezeControl = {}
capabilitydefs.circuit5FreezeControl.name = "platinummassive43262.pe653Circuit5Freeze"
capabilitydefs.circuit5FreezeControl.json = [[
{
    "id": "platinummassive43262.pe653Circuit5Freeze",
    "version": 1,
    "status": "proposed",
    "name": "Pe653 Circuit 5 Freeze",
    "ephemeral": false,
    "attributes": {
        "freezeControl": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setFreezeCircuitFive",
            "enumCommands": []
        }
    },
    "commands": {
        "setFreezeCircuitFive": {
            "name": "setFreezeCircuitFive",
            "arguments": [
                {
                    "name": "freezeControl",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.circuit5FreezeControl.capability = capabilities.build_cap_from_json_string(capabilitydefs.circuit5FreezeControl.json)

return capabilitydefs