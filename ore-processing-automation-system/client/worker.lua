local component = require("component")
local ItemUtil = require("common.item_util")
local LogicalRule = require("common.logical_rule")
local LogicalExectors = require("common.logical_exectors")
local newRuleTable = require("common.rule_define")

---@type table<string, function>
local commands = {}

local worker = {
    ---@type Rules
    rules = {},
    ---@type boolean working or not
    working = false
}

--- ========================
--- Local Functions
--- ========================

local function split(str, chrs)
    local ret = {} string.gsub(str, "[^"..chrs.."]+", function(s) table.insert(ret, s) end) return ret
end

---append array table or single element to target array table
---@param target table
---@param values string|table
---@param callback function|nil
local function appentArray(target, values, callback)
    if type(values) == "table" then
        for _, elem in ipairs(values) do
            table.insert(target, elem)
            if callback then callback(elem) end
        end
    else
        table.insert(target, values)
        if callback then callback(values) end
    end
end

---append table to target table
---@param target table
---@param map table
---@param callback function|nil
local function appendTable(target, map, callback)
    for key, val in pairs(map) do
        target[key] = val
        if callback then callback(key, val) end
    end
end

--- =====================
--- Commands
--- =====================

---clear rules
---@param data any
function commands.clear(data)
    worker.rules = {}
    worker.rules[data.address] = newRuleTable()
    print(string.format("接口 %s 的规则已清空", data.address))
end

---add ore rule
---@param data any
function commands.addOre(data)
    worker.rules[data.address] = worker.rules[data.address] or newRuleTable()
    local roleRules = worker.rules[data.address]

    appentArray(roleRules.whitelist.labels, data.rules.whitelist.labels, function(label)
        print(string.format("为接口 %s 添加矿石规则: %s", data.address, label))
    end)
end

---add normal rule
---@param data any
function commands.addNormal(data)
    worker.rules[data.address] = worker.rules[data.address] or newRuleTable()
    local roleRules = worker.rules[data.address]

    if not data.rules then return end
    local remote = data.rules
    
    -- whitelist and blacklist
    local tags = {whitelist = appentArray, blacklist = appendTable}
    for tag, func in pairs(tags) do
        if remote[tag] then
            local list = remote[tag]
            if list.ids then
                func(roleRules[tag].ids, list.ids)
            elseif list.labels then
                func(roleRules[tag].labels, list.labels)
            end
        end
    end

    -- logicals
    if remote.logicals then
        appentArray(roleRules.logicals, remote.logicals)
    end
end

--- ===========================
--- Worker
--- ===========================

function worker.updateRules(data)
    if data.method == nil then return end
    commands[data.method](data)
    print(string.format("接口 %s 的规则已更新", data.address))
end

---set me interface output
---@param db any
---@param me any
---@param idx any
---@param filterItem any
---@return boolean|nil
function worker.setInterface(db, me, idx, filterItem)
    if idx == 10 then return end
    db.clear(1)
    me.store(filterItem, db.address, 1, 64)
    if db.get(1) ~= nil then
        me.setInterfaceConfiguration(idx, db.address, 1, 64)
        return true
    end
    return false
end

---find suitable item
---@param me any
---@param filterItem any
---@param rules Rule
---@param callback function
function worker.findSuit(me, filterItem, rules, callback)
    for _, item in pairs(me.getItemsInNetwork(filterItem)) do
        if not worker.working then break end
        local flag = item == nil or item.size == nil or item.size == 0 or
                    rules.blacklist.ids[ItemUtil.getId(item)] or
                    rules.blacklist.labels[item.label]
        if not flag then callback(item) end
    end
end

---遍历白名单物品标签
---@param me any
---@param rules Rule
---@param callback function
function worker.foreachByLabel(me, rules, callback)
    for _, label in ipairs(rules.whitelist.labels) do
        if not worker.working then break end
        -- 如果含有 # 则代表这个物品标签只在某一个物品name类型下寻找
        if string.find(label, "#") ~= nil then
            local names = split(label, "#")
            for i = 2, #names do
                worker.findSuit(me, {name = names[i], label = names[1]}, rules, callback)
            end
        else
            worker.findSuit(me, {label = label}, rules, callback)
        end
    end
end

---set working or not
---@param flag boolean
function worker.setWorking(flag) worker.working = flag end

function worker.work()
    local workResult = false
    if component.list("database") == nil then
        print("No Database")
        return workResult
    end
    for address in pairs(component.list("me_interface")) do
        local rules = worker.rules[address]
        if rules then
            local items = {}
            local me = component.proxy(address)
            local markItem = function (item) table.insert(items, item) end

            -- find label first
            worker.foreachByLabel(me, rules, function(item)
                table.insert(items, item)
            end)
            -- find ids second
            if rules.whitelist.ids then
                for _, id in ipairs(rules.whitelist.ids) do
                    worker.findSuit(me, ItemUtil.getItemFromId(id), rules, markItem)
                end
            end

            -- logical rule
            local logicalCache = nil
            LogicalExectors.setComponent(LogicalExectors.COMPONENT_NAME.ME, me)
            for _, rule in ipairs(rules.logicals) do
                ---@type boolean, LogicalCache
                local result, cache = LogicalRule.eval(rule, LogicalExectors.exector)
                if result then
                    logicalCache = cache
                    for _, marked in ipairs(cache.markedItems or {}) do
                        worker.findSuit(me, marked, rules, markItem)
                    end
                end
            end
            LogicalExectors.clearComponent()

            -- sort and work
            table.sort(items, function(p, q)
                local a = p.size or 0
                local b = q.size or 0
                return b < a
            end)

            for i, item in ipairs(items) do
                if i > 9 then break end
                worker.setInterface(component.database, me, i, {
                    label = item.label,
                    name = item.name,
                    damage = item.damage
                })
                workResult = true
            end

            -- clear interface configuration
            if logicalCache and logicalCache.clearMeInterface == true then
                for i = #items, 9 do
                    me.setInterfaceConfiguration(i)
                end
            end
        end
    end
    return workResult
end

return worker