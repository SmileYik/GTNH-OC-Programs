local component = require("component")
local DEBUG = require("./commons/debug")

local check = {}

function check.init(reactor, status, model)
    status.model = model
end

function check.tick(reactor, status)
    DEBUG("[rod_check] %s 进入仅燃料棒检查环节.", reactor.name)

    if
        reactor.flags["shape_check"] == nil or
        status.skips["shape_check"] ~= nil or
        reactor.flags["shape_full"] == nil or
        not reactor.flags["shape_full"]
    then
        return "shape_check", nil
    end

    local tr = component.proxy(reactor.accessPort)
    for _, i in pairs(reactor.shape.fuelRod) do
        local target = nil
        local id = reactor.shape.shape[i]
        if id ~= "" or id ~= "nil" then
            target = {
                name = reactor.shape.materials[id].name,
                -- damage = reactor.shape.materials[id].damage,
                label = reactor.shape.materials[id].label,
                size = 1
            }
        end
        local cur = tr.getStackInSlot(reactor.sideAccess, i)
        if
            cur == target or
            cur == nil and target == nil or
            cur ~= nil and target ~= nil and cur.name == target.name
        then
        else
            return "shape_check", nil
        end
    end

    return "switch", {
        nextStep = "fluid_check",
        nextModel = nil
    }
end

function check.getInfo(status)
    return "正在检查燃料棒"
end

return check
