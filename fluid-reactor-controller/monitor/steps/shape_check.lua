local component = require("component")
local DEBUG = require("./commons/debug")

-- 检查反应堆布局时，最大处理几次物品，默认为一次（为了保证其他反应堆正常运行）。
local MAX_HANDLE = 1 -- 大约一秒处理一次

local check = {}

function check.init(reactor, status, model)
    status.model = model

    if reactor.flags["shape_check"] ~= nil then
        return
    end

    local tr = component.proxy(reactor.accessPort)
    for i = 0, 5 do
        if tr.getInventorySize(i) == 58 then
            DEBUG("[shape_check] 找到反应堆访问接口，位于方位%d", i)
            reactor.sideAccess = i
        elseif tr.getInventorySize(i) == 9 then
            DEBUG("[shape_check] 找到ME接口，位于方位%d", i)
            reactor.sideMe = i
        end
    end
    reactor.flags["shape_check"] = true
end

function check.tick(reactor, status)
    DEBUG("[shape_check] [%s] 进入物品检查.", reactor.name)
    if status.model ~= nil and status.model.retry then
        DEBUG("[shape_check] [%s] 在本次物品检查过程中具有在检查失败后重试机会.", reactor.name)
    end

    reactor.flags["shape_full"] = false

    if status.skips["shape_check"] ~= nil then
        local moveTo = status.skips["shape_check"].moveTo
        local model = status.skips["shape_check"].model
        status.skips["shape_check"] = nil
        return moveTo, model
    end

    local tr = component.proxy(reactor.accessPort)
    local me = component.proxy(reactor.me)
    local database = component.database
    local finishCheck = true
    me.setInterfaceConfiguration(1) -- 复位物品

    local handled = 0
    for i, id in pairs(reactor.shape.shape) do
        if handled == MAX_HANDLE then break end

        local target = nil
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
            cur ~= nil and target ~= nil and cur.name == target.name -- and cur.damage == target.damage
        then

        elseif target == nil then
            handled = handled + 1
            if tr.transferItem(reactor.sideAccess, reactor.sideMe, 1, i, 9) == 0 then
                finishCheck = false
            end
        else
            handled = handled + 1
            finishCheck = false
            tr.transferItem(reactor.sideAccess, reactor.sideMe, 1, i, 9)
            database.clear(1)
            me.store({
                name = target.name,
                -- damage = target.damage
            }, database.address, 1)
            local flag = false
            if database.get(1) ~= nil then
                me.setInterfaceConfiguration(1, database.address, 1)
                flag = tr.transferItem(reactor.sideMe, reactor.sideAccess, 1, 1, i) == 0
                DEBUG("[shape_check] [%s] 转运结果为：%s", reactor.name, flag)
                me.setInterfaceConfiguration(1)
            else
                flag = true
            end
            if flag then
                if status.model ~= nil and status.model.retry then
                    return "shape_check", nil
                end
                return "switch", {
                    forceStop = true,
                    reason = string.format("在槽 #%d 中缺失 [%s] 元件", i, target.label),
                    nextStep = "require_item",
                    nextModel = {
                        target = target,
                        nextStep = "fluid_check",
                        nextModel = nil
                    }
                }
            end
        end
    end

    reactor.flags["shape_full"] = finishCheck

    return "switch", {
        forceStop = not finishCheck,
        reason = "元件布局未检测完毕",
        nextStep = "fluid_check",
        nextModel = nil
    }
end

function check.getInfo(status)
    return "正在检查反应堆布局是否正确"
end

return check
