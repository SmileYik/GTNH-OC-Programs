local serialization = require("serialization")
local component = require("component")

local itemUtil = require("./commons/item_util")

local REACTOR_ACCESS_HATCH_NAME = "blockReactorAccessHatch"

local shape = {
    SAVE_DIR = "./shape"
}

-- blockReactorFluidPort

-- blockReactorAccessHatch

-- 1~54 实际反应堆容量

local function findHatchSide(transposer)
    for i=0, 5 do
        if transposer.getInventoryName(i) == REACTOR_ACCESS_HATCH_NAME then
            return i
        end
    end
    return 6
end


function shape.record(shapeName, transposerAddress)
    local tr = component.proxy(transposerAddress)
    local side = findHatchSide(tr)

    local record = {
        name = shapeName,
        materials = {},
        shape = {},
        fuelRod = {}
    }

    for i = 1, 54 do
        local item = tr.getStackInSlot(side, i)
        if item == nil then
            record.shape[i] = "nil"
        else
            local id = itemUtil.getId(item)
            if record.materials[id] == nil then
                record.materials[id] = {
                    name = item.name,
                    damage = 0,
                    label = item.label,
                    size = 0
                }
            end
            record.materials[id].size = record.materials[id].size + item.size
            record.shape[i] = id

            if string.find(item.label, "燃料棒") ~= nil then
                table.insert(record.fuelRod, i)
            end
        end
    end
    local str = serialization.serialize(record)
    local file = io.open(string.format("%s/%s.recipe", shape.SAVE_DIR, shapeName), "w")
    if file == nil then return false end
    file:write(str)
    file:flush()
    file:close()
    return true
end

function shape.load(shapeName)
    local file = io.open(string.format("%s/%s.recipe", shape.SAVE_DIR, shapeName), "r")
    if file == nil then return nil end
    local str = file:read("*a")
    file:close()
    return serialization.unserialize(str)
end

return shape
