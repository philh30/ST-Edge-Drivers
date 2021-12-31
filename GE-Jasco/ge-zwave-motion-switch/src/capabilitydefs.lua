-- Author: philh30
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

capabilitydefs.LightSensing = {}
capabilitydefs.LightSensing.name = "platinummassive43262.jascoLightSensing"
capabilitydefs.LightSensing.json = [[
{
    "id": "platinummassive43262.jascoLightSensing",
    "version": 1,
    "status": "proposed",
    "name": "Jasco Light Sensing",
    "ephemeral": false,
    "attributes": {
        "lightSensing": {
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
            "setter": "setLightSensing",
            "enumCommands": []
        }
    },
    "commands": {
        "setLightSensing": {
            "name": "setLightSensing",
            "arguments": [
                {
                    "name": "value",
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
capabilitydefs.LightSensing.capability = capabilities.build_cap_from_json_string(capabilitydefs.LightSensing.json)

capabilitydefs.OperationMode = {}
capabilitydefs.OperationMode.name = "platinummassive43262.jascoOperationMode"
capabilitydefs.OperationMode.json = [[
{
    "id": "platinummassive43262.jascoOperationMode",
    "version": 1,
    "status": "proposed",
    "name": "Jasco Operation Mode",
    "ephemeral": false,
    "attributes": {
        "operationMode": {
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
            "setter": "setOperationMode",
            "enumCommands": []
        }
    },
    "commands": {
        "setOperationMode": {
            "name": "setOperationMode",
            "arguments": [
                {
                    "name": "operationMode",
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
capabilitydefs.OperationMode.capability = capabilities.build_cap_from_json_string(capabilitydefs.OperationMode.json)

capabilitydefs.MotionSensitivity = {}
capabilitydefs.MotionSensitivity.name = "platinummassive43262.jascoMotionSensitivity"
capabilitydefs.MotionSensitivity.json = [[
{
    "id": "platinummassive43262.jascoMotionSensitivity",
    "version": 1,
    "status": "proposed",
    "name": "Jasco Motion Sensitivity",
    "ephemeral": false,
    "attributes": {
        "motionSensitivity": {
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
            "setter": "setMotionSensitivity",
            "enumCommands": []
        }
    },
    "commands": {
        "setMotionSensitivity": {
            "name": "setMotionSensitivity",
            "arguments": [
                {
                    "name": "motionSensitivity",
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
capabilitydefs.MotionSensitivity.capability = capabilities.build_cap_from_json_string(capabilitydefs.MotionSensitivity.json)

capabilitydefs.TimeoutDuration = {}
capabilitydefs.TimeoutDuration.name = "platinummassive43262.jascoTimeoutDuration"
capabilitydefs.TimeoutDuration.json = [[
{
    "id": "platinummassive43262.jascoTimeoutDuration",
    "version": 1,
    "status": "proposed",
    "name": "Jasco Timeout Duration",
    "ephemeral": false,
    "attributes": {
        "timeoutDuration": {
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
            "setter": "setTimeoutDuration",
            "enumCommands": []
        }
    },
    "commands": {
        "setTimeoutDuration": {
            "name": "setTimeoutDuration",
            "arguments": [
                {
                    "name": "timeoutDuration",
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
capabilitydefs.TimeoutDuration.capability = capabilities.build_cap_from_json_string(capabilitydefs.TimeoutDuration.json)

return capabilitydefs