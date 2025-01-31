local component = require("component")
local DEBUG = require("./commons/debug")

local check = {}

function check.init(reactor, status, model)
    status.model = model
end

function check.tick(reactor, status)
    DEBUG("[switch] %s进入反应堆开关评定.", reactor.name)
    local rs = component.proxy(reactor.redstonePort)
    status.info.error = nil
    if status.model.forceStop then
        rs.setActive(false)
        status.info.error = status.model.reason
        DEBUG("[switch] 强制关机，原因为: %s", status.model.reason)
        reactor.flags["shape_check"] = nil
    elseif not rs.producesEnergy() then
        rs.setActive(true)
    end
    status.info.enable = rs.producesEnergy()
    status.info.euOutput = rs.getReactorEUOutput()
    status.info.energyOutput = rs.getReactorEnergyOutput()
    DEBUG(status.info)
    return status.model.nextStep, status.model.nextModel
end


function check.getInfo(status)
    return "正在评定反应堆运行状态"
end

return check
