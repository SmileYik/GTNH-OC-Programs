local TARGET_CPU_NAME = "OC-Cache"
local component = require("component")
local me = component.me_interface
local db = component.database

local mod = {}

local function nextCpu()
    for _, cpu in pairs(me.getCpus()) do
        if cpu ~= nil and cpu.busy ~= nil and not cpu.busy and cpu.name ~= nil and string.find(cpu.name, TARGET_CPU_NAME, 1, true) ~= nil then
            return cpu.name
        end
    end
    return nil
end

local function craft(count)
    me.storeInterfacePatternInput(mod.pI, mod.i, db.address, 1)
    local item = db.get(1)
    if item == nil or item.name == nil or item.damage == nil then return end
    local filter = {
        name = item.name,
        damage = item.damage
    }
    local result = me.getItemsInNetwork(filter)
    local currentCount = 0
    if result ~= nil and result[1] ~= nil and result[1].size ~= nil then
        currentCount = result[1].size
    end

    if currentCount >= count then return end
    result = me.getCraftables(filter)[1]
    if result == nil then return end
    local targetCpu = nextCpu()
    if targetCpu == nil then return end
    result = result.request(count / 4, true, targetCpu)
    if result == nil or result.hasFailed() then
        return
    end
end

function mod.init()
    mod.pI = 1
    mod.i = 1
end

function mod.tick()
    -- if mod.pI > 36 then mod.pI = 1 mod.i = 1 end
    local hit = false
    local pattern = me.getInterfacePattern(mod.pI)
    if pattern ~= nil and pattern.inputs ~= nil then
        local target = pattern.inputs[mod.i]
        if target ~= nil and target.count ~= nil then
            hit = true
            local count = target.count
            craft(count)
        end
        mod.i = mod.i + 1
        if mod.i > #pattern.inputs then
            mod.i = 1
            mod.pI = mod.pI + 1
        end
    else
        mod.pI = mod.pI + 1
    end
    if mod.pI > 36 then mod.pI = 1 mod.i = 1 end
    return hit
end


return mod
