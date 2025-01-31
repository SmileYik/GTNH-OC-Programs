local component = require("component")
local DEBUG = require("./commons/debug")
-- 哪个CPU为流体堆专用CPU
local ALLOW_CPU_NAME = "核电用CPU"

local check = {}

function check.init(reactor, status, model)
    status.model = model
end

local function hasTargetItem(me, status)
    local items = me.getItemsInNetwork({
        name = status.model.target.name
    })
    return #items ~= 0 and items[1] ~= nil and items[1].size > 0
end

function check.tick(reactor, status)
    DEBUG("[require_item] %s 进入物品请求.", reactor.name)
    local me = component.proxy(reactor.me)
    if status.model.craft == nil then
        -- failed request item
        if hasTargetItem(me, status) then
            status.skips["shape_check"] = nil
            return status.model.nextStep, status.model.nextModel
        end
    else
        -- request done, check status
        if status.model.craft.hasFailed() then
            status.model.craft = nil
            status.info.require.status = "failed"
        elseif status.model.craft.isCanceled() then
            status.model.craft = nil
            status.info.require.status = "canceled"
        elseif status.model.craft.isDone() then
            status.skips["shape_check"] = nil
            status.model.craft = nil
            status.info.require.status = "done"
            return status.model.nextStep, status.model.nextModel
        end

        status.skips["shape_check"] = {
            moveTo = "require_item",
            model = {
                target = status.model.target,
                craft = status.model.craft,
                nextStep = status.model.nextStep,
                nextModel = status.model.nextModel
            }
        }

        return status.model.nextStep, status.model.nextModel
    end

    local patterns = me.getCraftables(status.model.target)
    status.skips["shape_check"] = {
        moveTo = "require_item",
        model = {
            target = status.model.target,
            craft = status.model.craft,
            nextStep = status.model.nextStep,
            nextModel = status.model.nextModel
        }
    }

    DEBUG(status.info)

    status.info.require = {
        target = status.model.target,
        status = "requesting"
    }

    if #patterns ~= 0 then
        status.skips["shape_check"].model.craft = patterns[1].request(1, true, ALLOW_CPU_NAME)
    else
        if hasTargetItem(me, status) then
            status.skips["shape_check"] = nil
            return status.model.nextStep, status.model.nextModel
        end
    end

    return status.model.nextStep, status.model.nextModel
end

function check.getInfo(status)
    if status.info.require ~= nil and status.info.require.status ~= nil then
        local signal = status.info.require.status
        if signal == "requesting" then
            return string.format("正在请求制作[%s]中", status.info.require.target.label)
        elseif signal == "failed" then
            return string.format("请求制作[%s]失败", status.info.require.target.label)
        elseif signal == "canceled" then
            return string.format("[%s]制作请求被取消", status.info.require.target.label)
        elseif signal == "done" then
            return string.format("[%s]制作完成", status.info.require.target.label)
        end
    end
    return "正在请求制作缺失的物品"
end

return check
