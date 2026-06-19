local sides = require("sides")
local essentia = require("essentia")
local component = require("component")
local transposer = component.transposer
local redstone = component.redstone
local serialization = require("serialization")

-- 转运器设置
-- 物品输入口
local IN = sides.top
-- 物品输出口
local OUT = sides.bottom
-- 主注魔台
local MAIN = sides.east

-- 配方标记物品ID及Damage, 这里设置的是Doge币
local END_ITEM_NAME = "gregtech:gt.metaitem.01"
local END_ITEM_DAMAGE = 32009

-- 红石配置
-- 红石合成信号输出方向
local RS_CRAFT = sides.top
-- 物品输出信号方向
local RS_OUT = sides.bottom

local SLEEP = 1

local mod = {}

local function checkSideContainter(side)
    if side <= 0 or side > 5 then return false, "side must in number [0, 5]" end
    local result, r = pcall(transposer.getInventorySize(side))
    if not result or r == nil then
        return false, "side " .. side .. " is not a containter"
    end
    return true
end

function mod.check()
    if transposer == nil then return false, "need transposer" end
    if redstone == nil then return false, "need redstone card" end
    local a, b = checkSideContainter(IN)
    if not a then return a, b end
    a, b = checkSideContainter(OUT)
    if not a then return a, b end
    a, b = checkSideContainter(MAIN)
    if not a then return a, b end
end

function mod.cleanItems(waitTime)
    redstone.setOutput(RS_OUT, 15)
    os.sleep(waitTime)
    redstone.setOutput(RS_OUT, 0)
end

-- 检测是否含有下一个注魔, 若有下一个注魔则返回下一个注魔的配方名或者物品默认名
function mod.hasNext()
    local size = transposer.getInventorySize(IN)
    for i = 1, size do
        local item = transposer.getStackInSlot(IN, i)
        if item == nil then break end
        if item.name == END_ITEM_NAME and item.damage == END_ITEM_DAMAGE then
            return item.label
        end
    end
    return nil
end

local function getMeInterface()
    return component.me_interface
end

local function canCheckEssentia()
    return pcall(getMeInterface)
end

local function checkEssentia(name)
    local flag, me = canCheckEssentia()
    if not flag then return end

    local ori = essentia.load(name)
    print("load " .. name .. ": " .. serialization.serialize(ori))
    while true do
        flag = true
        local need = serialization.unserialize(serialization.serialize(ori))
        local had = me.getEssentiaInNetwork()
        for _, ess in pairs(had) do
            local targetName = string.sub(ess.name, 8, #ess.name - 8)
            if need[targetName] ~= nil then
                need[targetName] = need[targetName] - ess.amount
                if need[targetName] > 0 then
                    flag = false
                    -- 短路会更快但是无法检测出具体少了多少源质
                    break
                end
            end
        end

        if flag then
            for _, val in pairs(need) do
                if val > 0 then
                    flag = false
                    break
                end
            end
        end

        if not flag then
            print(string.format("合成 '%s' 时, 发现缺少以下源质:", name))
            for ess, val in pairs(need) do
                if (val > 0) then
                    print(string.format("需要 '%s' 数量为 %d, 缺口为 %d", ess, ori[ess], val))
                end
            end
        else break end

        os.sleep(SLEEP)
    end
end

function mod.craft()
    local mainItem = transposer.getStackInSlot(IN, 1)
    while transposer.transferItem(IN, MAIN, 1, 1) ~= 1 do end
    print("finished put main item.")

    -- 放其他材料
    local endItemIdx = 1
    local essentiaFileName = nil
    local size = transposer.getInventorySize(IN)
    for i = 2, size do
        local item = transposer.getStackInSlot(IN, i)
        if item.name == END_ITEM_NAME and item.damage == END_ITEM_DAMAGE then
            endItemIdx = i
            essentiaFileName = item.label
            break
        end

        while transposer.getStackInSlot(IN, i) ~= nil do
            transposer.transferItem(IN,OUT, i)
        end
    end
    print("finished put other material.")

    -- 源质检查
    print("check essentia ...")
    checkEssentia(essentiaFileName)
    print("essentia passed ...")

    -- 合成开始
    redstone.setOutput(RS_CRAFT, 15)
    while true do
        local item = transposer.getStackInSlot(MAIN, 1)
        if item.name ~= mainItem.name or item.damage ~= mainItem.damage then
            break
        end
    end
    redstone.setOutput(RS_CRAFT, 0)
    print("finished infusion.")

    -- 运出产物
    redstone.setOutput(RS_OUT, 15)
    while transposer.transferItem(IN, MAIN, endItemIdx) == 0 do end
    while transposer.getStackInSlot(MAIN, 1) ~= nil do end
    redstone.setOutput(RS_OUT, 0)
end


return mod
