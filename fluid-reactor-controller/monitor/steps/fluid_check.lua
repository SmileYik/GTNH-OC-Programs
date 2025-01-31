local component = require("component")

local DEBUG = require("./commons/debug")

-- 当流体堆中冷却液大于多少mB时允许核反应堆继续运行。
local PASS_CHECK_LEVEL = 4000
-- 当AE网络中的冷却液数量大于多少mB时允许反应堆运行。
local WORK_LEVEL = 50000000

local check = {}

function check.init(reactor, status, model)
    if reactor.flags["fluid_check"] ~= nil then
        return
    end

    local tr = component.proxy(reactor.fluidPort)
    for i = 0, 5 do
        if tr.getTankCount(i) == 2 then
            DEBUG("[fluid_check] 寻找到 %s 的流体接口位置，为 %d", reactor.name, i)
            reactor.flags["fluid_check"] = true
            reactor.sideFluid = i
        end
    end
end

function check.tick(reactor, status)
    DEBUG("[fluid_check] %s进入流体检查.", reactor.name)
    if reactor.flags["fluid_check"] == nil then
        return "fluid_check", nil
    end

    local me = component.proxy(reactor.me)
    local fluids = me.getFluidsInNetwork({name = "ic2coolant"})
    local cool = 0
    for _, fluid in pairs(fluids) do
        if fluid ~= nil and fluid.name == "ic2coolant" then
            cool = fluid.amount
            break
        end
    end

    if cool < WORK_LEVEL / 2 then
        reactor.flags["fluid_check_stop"] = true
        return "switch", {
            forceStop = true,
            reason = string.format("总体冷却液不足，仅有 %.2f K", cool / 1000),
            nextStep = "fluid_check",
            nextModel = nil
        }
    elseif reactor.flags["fluid_check_stop"] == true then
        if cool <= WORK_LEVEL then
            return "switch", {
                forceStop = true,
                reason = string.format("总体冷却液不足，仅有 %.2f K", cool / 1000),
                nextStep = "fluid_check",
                nextModel = nil
            }
        else
            reactor.flags["fluid_check_stop"] = false
        end
    end


    local tr = component.proxy(reactor.fluidPort)
    status.info.tankLevel = tr.getTankLevel(reactor.sideFluid, 1)
    if status.info.tankLevel <= PASS_CHECK_LEVEL then
        status.pass = false
        return "switch", {
            forceStop = true,
            reason = string.format("冷却液不足，仅有 %d", status.info.tankLevel),
            nextStep = "fluid_check",
            nextModel = nil
        }
    end
    return "heat_check", nil
end

function check.getInfo(status)
    return "正在检测冷却液是否正常"
end

return check