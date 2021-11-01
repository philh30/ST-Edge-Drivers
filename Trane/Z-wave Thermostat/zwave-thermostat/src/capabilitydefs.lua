local capabilities = require('st.capabilities')
local capabilitydefs = {}

capabilitydefs.thermostatScheduleMode = {}
capabilitydefs.thermostatScheduleMode.name = "platinummassive43262.thermostatScheduleMode"
capabilitydefs.thermostatScheduleMode.json = [[
{
    "id": "platinummassive43262.thermostatScheduleMode",
    "version": 1,
    "status": "proposed",
    "name": "Thermostat Schedule Mode",
    "attributes": {
        "thermostatScheduleMode": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "title": "ThermostatScheduleMode",
                        "type": "string",
                        "enum": [
                            "run",
                            "hold",
                            "esm"
                        ]
                    },
                    "data": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [],
                        "properties": {
                            "supportedThermostatScheduleModes": {
                                "type": "array",
                                "items": {
                                    "title": "ThermostatScheduleMode",
                                    "type": "string",
                                    "enum": [
                                        "run",
                                        "hold",
                                        "esm"
                                    ]
                                }
                            }
                        }
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setThermostatScheduleMode",
            "enumCommands": []
        },
        "supportedThermostatScheduleModes": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "array",
                        "items": {
                            "title": "ThermostatScheduleMode",
                            "type": "string",
                            "enum": [
                                "run",
                                "hold",
                                "esm"
                            ]
                        }
                    }
                },
                "additionalProperties": false,
                "required": []
            },
            "enumCommands": []
        }
    },
    "commands": {
        "setThermostatScheduleMode": {
            "name": "setThermostatScheduleMode",
            "arguments": [
                {
                    "name": "mode",
                    "optional": false,
                    "schema": {
                        "title": "ThermostatScheduleMode",
                        "type": "string",
                        "enum": [
                            "run",
                            "hold",
                            "esm"
                        ]
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.thermostatScheduleMode.capability = capabilities.build_cap_from_json_string(capabilitydefs.thermostatScheduleMode.json)

return capabilitydefs