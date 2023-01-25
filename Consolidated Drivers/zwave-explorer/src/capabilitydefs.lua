local capabilities = require('st.capabilities')
local capabilitydefs = {}

capabilitydefs.deviceInfo = capabilities['platinummassive43262.deviceInformation']

capabilitydefs.associationGroups = {}
capabilitydefs.associationGroups.name = "platinummassive43262.zwubAssociationGroups"
capabilitydefs.associationGroups.capability = capabilities[capabilitydefs.associationGroups.name]

capabilitydefs.associationGroup = {}
capabilitydefs.associationGroup.name = "platinummassive43262.zwubAssociationGroup"
capabilitydefs.associationGroup.capability = capabilities[capabilitydefs.associationGroup.name]

capabilitydefs.associationSet = {}
capabilitydefs.associationSet.name = "platinummassive43262.zwubAssociationSet"
capabilitydefs.associationSet.capability = capabilities[capabilitydefs.associationSet.name]

capabilitydefs.commandClasses = capabilities["platinummassive43262.zwubCommandClasses"]

capabilitydefs.messageQueue = capabilities["platinummassive43262.zwubMessageQueue"]

capabilitydefs.reset = capabilities["platinummassive43262.reset"]

return capabilitydefs