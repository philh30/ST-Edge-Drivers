local capabilities = require('st.capabilities')
local capabilitydefs = {}

capabilitydefs.associationGroups = {}
capabilitydefs.associationGroups.name = "platinummassive43262.zwubAssociationGroups"
capabilitydefs.associationGroups.json = [[
{
    "id": "platinummassive43262.zwubAssociationGroups",
    "version": 1,
    "status": "proposed",
    "name": "Zwub Association Groups",
    "ephemeral": false,
    "attributes": {
        "associationGroups": {
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
capabilitydefs.associationGroups.capability = capabilities.build_cap_from_json_string(capabilitydefs.associationGroups.json)

capabilitydefs.associationGroup = {}
capabilitydefs.associationGroup.name = "platinummassive43262.zwubAssociationGroup"
capabilitydefs.associationGroup.json = [[
{
    "id": "platinummassive43262.zwubAssociationGroup",
    "version": 1,
    "status": "proposed",
    "name": "Zwub Association Group",
    "ephemeral": false,
    "attributes": {
        "associationGroup": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 255
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "getAssociationGroup",
            "enumCommands": []
        }
    },
    "commands": {
        "getAssociationGroup": {
            "name": "getAssociationGroup",
            "arguments": [
                {
                    "name": "associationGroup",
                    "optional": false,
                    "schema": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 255
                    }
                }
            ]
        }
    }
}
]]
capabilitydefs.associationGroup.capability = capabilities.build_cap_from_json_string(capabilitydefs.associationGroup.json)

capabilitydefs.associationNodes = {}
capabilitydefs.associationNodes.name = "platinummassive43262.zwubAssociationNodes"
capabilitydefs.associationNodes.json = [[
{
    "id": "platinummassive43262.zwubAssociationNodes",
    "version": 1,
    "status": "proposed",
    "name": "Zwub Association Nodes",
    "ephemeral": false,
    "attributes": {
        "associationNodes": {
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
capabilitydefs.associationNodes.capability = capabilities.build_cap_from_json_string(capabilitydefs.associationNodes.json)

capabilitydefs.associationMax = {}
capabilitydefs.associationMax.name = "platinummassive43262.zwubAssociationMax"
capabilitydefs.associationMax.json = [[
{
    "id": "platinummassive43262.zwubAssociationMax",
    "version": 1,
    "status": "proposed",
    "name": "Zwub Association Max",
    "ephemeral": false,
    "attributes": {
        "associationMax": {
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
capabilitydefs.associationMax.capability = capabilities.build_cap_from_json_string(capabilitydefs.associationMax.json)

capabilitydefs.associationSet = {}
capabilitydefs.associationSet.name = "platinummassive43262.zwubAssociationSet"
capabilitydefs.associationSet.json = [[
{
    "id": "platinummassive43262.zwubAssociationSet",
    "version": 1,
    "status": "proposed",
    "name": "Zwub Association Set",
    "ephemeral": false,
    "attributes": {
        "associationSet": {
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
            "setter": "setNodes",
            "enumCommands": []
        }
    },
    "commands": {
        "setNodes": {
            "name": "setNodes",
            "arguments": [
                {
                    "name": "associationSet",
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
capabilitydefs.associationSet.capability = capabilities.build_cap_from_json_string(capabilitydefs.associationSet.json)

return capabilitydefs