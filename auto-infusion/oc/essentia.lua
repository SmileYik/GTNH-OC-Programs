local DIR = "/home/essentia/"
local serialization = require("serialization")

local mod = {}

function mod.load(name)
    local file = io.open(DIR .. name, "r")
    if file == nil then return {} end
    local data = file:read("*a")
    file:close()
    print("read: " .. data)
    local result = serialization.unserialize(data) or {}
    return result.aspect or result
end

function mod.store(name, essentia)
    local file = io.open(DIR .. name, "w")
    if file == nil then return false end
    file:write(serialization.serialize(essentia))
    file:flush()
    file:close()
    return true
end

return mod
