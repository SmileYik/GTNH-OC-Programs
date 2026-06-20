local ItemUtil = require("common.item_util")

---@class LogicalCache
---@field markedItems table<table>
---@field fluids table<string,number>
local LogicalCache = {}

---@class LogicalExectors
---@field config table<string,any>
local mod = {
    config = {},
    COMPONENT_NAME = {
        ME = "me_interface"
    }
}

local function getComponent(name)
    if mod.config[name] then return mod.config[name] end
    local result, me = pcall(function ()
        return require("component")[name]
    end)
    return result and me or nil
end

--- Compare operators
local COMP_OPS = {
    ["<"]  = function(l, r) return l < r end,
    ["<="] = function(l, r) return l <= r end,
    ["=="] = function(l, r) return l == r end,
    [">="] = function(l, r) return l >= r end,
    [">"]  = function(l, r) return l > r end,
    ["!="] = function(l, r) return l ~= r end,
    ["~="] = function(l, r) return l ~= r end,
    def    = function(_, _) return false end
}

--- compare name with number
--- @param input string input string, format: "name < 123"
--- @param toNumber function<string>  toNumber is a function to convert name to number, define is function(name) return 0 end
local function compareNumber(input, toNumber)
    local name, opt, number = string.match(input, "^%s*([^%s<=>!~].-[^%s<=>!~]?)%s*([<=>!~]+)%s*([+-]?[0-9.]+)%s*$")
    if not name then return false end

    local func = COMP_OPS[opt] or COMP_OPS.def
    local l, r = toNumber and toNumber(name) or nil, tonumber(number)
    
    if not l or not r then return false end
    return func(l, r)
end

local exectors = {}

--- check fluid in me_interface
---@param args string
---@param cache LogicalCache
---@return boolean
exectors["check-fluid"] = function (args, cache)
    local me = getComponent(mod.COMPONENT_NAME.ME)
    if me == nil then return false end
    return compareNumber(args, function(fluid)
        if cache.fluids and cache.fluids[fluid] then 
            return cache.fluids[fluid]
        end
        for _, f in ipairs(me.getFluidsInNetwork()) do
            if f.name == fluid then
                cache.fluids = cache.fluids or {}
                cache.fluids[fluid] = f.amount
                return f.amount
            end
        end
        return 0;
    end)
end
exectors["CF"] = exectors["check-fluid"]

---check item amount in me_interface by item id
---@param args string
---@return boolean
exectors["check-item"] = function (args, cache)
    local me = getComponent(mod.COMPONENT_NAME.ME)
    if me == nil then return false end
    return compareNumber(args, function(itemId)
        local item = ItemUtil.getItemFromId(itemId)
        -- item id is wrong then always return nil
        if not item then return nil end

        local items = me.getItemsInNetwork(item)
        item = items and items[1] or {size=0}
        return item.size or 0;
    end)
end
exectors["CI"] = exectors["check-item"]

---check item amount in me_interface by item name
---@param args string
---@param cache LogicalCache
---@return boolean
exectors["check-item-label"] = function (args, cache)
    local me = getComponent(mod.COMPONENT_NAME.ME)
    if me == nil then return false end
    return compareNumber(args, function(label)
        local item = {label = label}
        local items = me.getItemsInNetwork(item)
        local size = 0
        for _, i in ipairs(items) do
            size = size + (i.size or 0)
        end
        return size
    end)
end
exectors["CIL"] = exectors["check-item-label"]

---mark item in me_interface by item id
---@param args string
---@param cache LogicalCache
---@return boolean
exectors["mark-item"] = function (args, cache)
    local me = getComponent(mod.COMPONENT_NAME.ME)
    if me == nil then return false end
    local item = ItemUtil.getItemFromId(string.match(args, "^%s*(.-)%s*$"))
    if item then
        cache.markedItems = cache.markedItems or {}
        table.insert(cache.markedItems, item)
    end
    return true
end
exectors["MI"] = exectors["mark-item"]

---mark item in me_interface by item name
---@param args string
---@param cache LogicalCache
---@return boolean
exectors["mark-item-label"] = function (args, cache)
    local me = getComponent(mod.COMPONENT_NAME.ME)
    if me == nil then return false end
    local label = string.match(args, "^%s*(.-)%s*$")
    if label then
        cache.markedItems = cache.markedItems or {}
        table.insert(cache.markedItems, {label = label})
    end
    return true
end
exectors["MIL"] = exectors["mark-item-label"]

---print message
---@param args string
---@param cache LogicalCache
---@return boolean
exectors["print"] = function (args, cache)
    pcall(print, args)
    return true
end
exectors["P"] = exectors["print"]

---execute custom lua script with direct cache access
---@param args string lua code snippet
---@param cache LogicalCache
---@return boolean
exectors["eval-lua"] = function (args, cache)
    local env = setmetatable({ cache = cache }, { __index = _G })
    local chunk, err = load(args, "=eval-lua", "t", env)
    
    if not chunk then
        pcall(print, "Lua 编译错误: " .. tostring(err))
        return false
    end

    local success, ret = pcall(chunk)   
    if not success then
        pcall(print, "Lua 运行错误: " .. tostring(ret))
        return false
    end

    if type(ret) == "boolean" then
        return ret
    end
    return true
end
exectors["L"] = exectors["eval-lua"]

local function defaultExector(...) return false end

--- @param name string exector name
--- @param args string arguments string
--- @param cache table cache
function mod.exector(name, args, cache)
    local exector = exectors[name] or defaultExector
    return exector(args, cache)
end

---set component
---@param name string
---@param component any
function mod.setComponent(name, component)
    mod.config[name] = component
end

---clear components
function mod.clearComponent()
    mod.config = {}
end

mod.exectors = exectors
return mod