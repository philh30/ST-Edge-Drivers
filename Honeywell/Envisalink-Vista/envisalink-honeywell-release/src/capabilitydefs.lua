local capabilities = require('st.capabilities')

-- statusMessage    = platinummassive43262.statusMessage
-- alarmMode        = platinummassive43262.alarmState
-- alarmCommands    = platinummassive43262.securityPartitionCommands
-- bypass           = platinummassive43262.bypass
-- contactZone      = platinummassive43262.contactZone
-- glassBreakZone   = platinummassive43262.glassBreakZone
-- leakZone         = platinummassive43262.leakZone
-- motionZone       = platinummassive43262.motionZone
-- smokeZone        = platinummassive43262.smokeZone

local capabilitydefs = {}

capabilitydefs.statusMessage = {}
capabilitydefs.statusMessage.name = "platinummassive43262.statusMessage"
capabilitydefs.statusMessage.json = [[
{
    "id": "platinummassive43262.statusMessage",
    "version": 1,
    "status": "proposed",
    "name": "Status Message",
    "attributes": {
        "statusMessage": {
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
capabilitydefs.statusMessage.capability = capabilities.build_cap_from_json_string(capabilitydefs.statusMessage.json)

capabilitydefs.alarmMode = {}
capabilitydefs.alarmMode.name = "platinummassive43262.alarmMode"
capabilitydefs.alarmMode.json = [[
{
    "id": "platinummassive43262.alarmMode",
    "version": 1,
    "status": "proposed",
    "name": "Alarm Mode",
    "attributes": {
        "alarmMode": {
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
            "setter": "setAlarmMode",
            "enumCommands": []
        },
        "supportedAlarmModes": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "array",
                        "items": {
                            "type": "string"
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
        "setAlarmMode": {
            "name": "setAlarmMode",
            "arguments": [
                {
                    "name": "alarmMode",
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
capabilitydefs.alarmMode.capability = capabilities.build_cap_from_json_string(capabilitydefs.alarmMode.json)

capabilitydefs.bypass = {}
capabilitydefs.bypass.name = "platinummassive43262.bypass"
capabilitydefs.bypass.json = [[
{
    "id": "platinummassive43262.bypass",
    "version": 1,
    "status": "proposed",
    "name": "Bypass",
    "attributes": {},
    "commands": {
        "bypass": {
            "name": "bypass",
            "arguments": []
        }
    }
}
]]
capabilitydefs.bypass.capability = capabilities.build_cap_from_json_string(capabilitydefs.bypass.json)

capabilitydefs.contactZone= {}
capabilitydefs.contactZone.name = "platinummassive43262.contactZone"
capabilitydefs.contactZone.json = [[
{
    "id": "platinummassive43262.contactZone",
    "version": 1,
    "status": "proposed",
    "name": "Contact Zone",
    "attributes": {
        "contactZone": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string",
                        "enum": [
                            "closed",
                            "open",
                            "bypassed"
                        ]
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
capabilitydefs.contactZone.capability = capabilities.build_cap_from_json_string(capabilitydefs.contactZone.json)

capabilitydefs.glassBreakZone = {}
capabilitydefs.glassBreakZone.name = "platinummassive43262.glassBreakZone"
capabilitydefs.glassBreakZone.json = [[
{
    "id": "platinummassive43262.glassBreakZone",
    "version": 1,
    "status": "proposed",
    "name": "Glass Break Zone",
    "attributes": {
        "glassBreakZone": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string",
                        "enum": [
                            "noSound",
                            "glassBreaking",
                            "bypassed"
                        ]
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
capabilitydefs.glassBreakZone.capability = capabilities.build_cap_from_json_string(capabilitydefs.glassBreakZone.json)

capabilitydefs.leakZone = {}
capabilitydefs.leakZone.name = "platinummassive43262.leakZone"
capabilitydefs.leakZone.json = [[
{
    "id": "platinummassive43262.leakZone",
    "version": 1,
    "status": "proposed",
    "name": "Leak Zone",
    "attributes": {
        "leakZone": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string",
                        "enum": [
                            "dry",
                            "wet",
                            "bypassed"
                        ]
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
capabilitydefs.leakZone.capability = capabilities.build_cap_from_json_string(capabilitydefs.leakZone.json)

capabilitydefs.motionZone = {}
capabilitydefs.motionZone.name = "platinummassive43262.motionZone"
capabilitydefs.motionZone.json = [[
{
    "id": "platinummassive43262.motionZone",
    "version": 1,
    "status": "proposed",
    "name": "Motion Zone",
    "attributes": {
        "motionZone": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string",
                        "enum": [
                            "active",
                            "inactive",
                            "bypassed"
                        ]
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
capabilitydefs.motionZone.capability = capabilities.build_cap_from_json_string(capabilitydefs.motionZone.json)

capabilitydefs.smokeZone = {}
capabilitydefs.smokeZone.name = "platinummassive43262.smokeZone"
capabilitydefs.smokeZone.json = [[
{
    "id": "platinummassive43262.smokeZone",
    "version": 1,
    "status": "proposed",
    "name": "Smoke Zone",
    "attributes": {
        "smokeZone": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string",
                        "enum": [
                            "clear",
                            "detected",
                            "bypassed"
                        ]
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
capabilitydefs.smokeZone.capability = capabilities.build_cap_from_json_string(capabilitydefs.smokeZone.json)

return capabilitydefs
