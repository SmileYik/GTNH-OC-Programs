local component = require("component")

local DEBUG = require("./commons/debug")

-- 当核温大于多少时停止运行。取值范围 0～1
local PASS_HEAT_PERCENT = 0.4

local check = {}

function check.init(reactor, status, model)

end

function check.tick(reactor, status)
    DEBUG("[heat_check] %s进入堆温检查.", reactor.name)
    local port = component.proxy(reactor.redstonePort)
    status.info.heat = port.getHeat()
    status.info.maxHeat = port.getMaxHeat()
    local percent = status.info.heat / status.info.maxHeat

    if percent >= PASS_HEAT_PERCENT then
        status.pass = false
        return "switch", {
            forceStop = true,
            reason = string.format("堆温为 %.2f%% 超过预设阀值 %.2f%%", percent * 100, PASS_HEAT_PERCENT * 100),
            nextStep = "fluid_check",
            nextModel = nil
        }
    end
    return "rod_check", nil
end

function check.getInfo(status)
    return "堆温检查中"
end

return check
