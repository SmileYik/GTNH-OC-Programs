local util = {}

local component = require("component")
local gpu = component.gpu
local w, h = gpu.getResolution()


function util.drawHCenter(x, y, text)
    local aW = w - x
    local l = #text
    x = (aW - l) / 2 + x
    gpu.set(x, y, text)
end

function util.drawHCenter2(x, y, width, text)
    x = (width - #text) / 2 + x
    gpu.set(x, y, text)
end

return util
