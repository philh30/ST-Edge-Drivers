--- @type st.capabilities
local capabilities = require "st.capabilities"
--- @type st.utils
local utils = require "st.utils"

local config_handlers = {}

config_handlers.color_handler = function(device,comp,value)
    device:emit_component_event(device.profile.components[comp],capabilities.colorControl.hue(utils.round(value / 255 * 100)))
    device:emit_component_event(device.profile.components[comp],capabilities.colorControl.saturation(100))
end

config_handlers.intensity_handler = function(device,comp,value)
    device:emit_component_event(device.profile.components[comp],capabilities.switchLevel.level(value * 10))
end

config_handlers.effect_handler = function(device,comp,value)

end

return config_handlers