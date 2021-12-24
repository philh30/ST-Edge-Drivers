local orpMeasurement = [[
{
    "id": "platinummassive43262.orpMeasurement",
    "version": 1,
    "status": "proposed",
    "name": "ORP Measurement",
    "attributes": {
        "ORP": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "integer",
                        "minimum": 0
                    },
                    "unit": {
                        "type": "string",
                        "enum": [
                            "mV"
                        ],
                        "default": "mV"
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

local phMeasurement = [[
{
    "id": "platinummassive43262.phMeasurement",
    "version": 1,
    "status": "proposed",
    "name": "pH Measurement",
    "attributes": {
        "pH": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "number",
                        "minimum": 0,
                        "maximum": 14
                    },
                    "unit": {
                        "type": "string",
                        "enum": [
                            "pH"
                        ],
                        "default": "pH"
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

local statusMessage = [[
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

local saltMeasurement = [[
{
    "id": "platinummassive43262.saltMeasurement",
    "version": 1,
    "status": "proposed",
    "name": "Salt Measurement",
    "attributes": {
        "salt": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 1000000
                    },
                    "unit": {
                        "type": "string",
                        "enum": [
                            "ppm"
                        ],
                        "default": "ppm"
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

local currentMeter = [[
{
    "id": "platinummassive43262.currentMeter",
    "version": 1,
    "status": "proposed",
    "name": "Current Meter",
    "attributes": {
        "current": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "number"
                    },
                    "unit": {
                        "type": "string",
                        "enum": [
                            "A"
                        ],
                        "default": "A"
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

local errorReport = [[
{
    "id": "platinummassive43262.errorReport",
    "version": 1,
    "status": "proposed",
    "name": "Error Report",
    "attributes": {
        "errorReport": {
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

return {
	orpMeasurement = orpMeasurement,
	phMeasurement = phMeasurement,
	saltMeasurement = saltMeasurement,
	currentMeter = currentMeter;
	statusMessage = statusMessage,
	errorReport = errorReport,
}
