local serialization = require("serialization")
local config = require("config")
local debug = require("common.debug")

local DEFAULT_KEYS = {
    "interfaces", "role", "process", "processReverse", "idWhitelist", "idBlacklist", "logicalRules"
}

---@class RuleMeta
---@field enable boolean enable or not
---@field comments string rule commands
local RuleMeta = {}

---@class SettingData
---@field interfaces table<string, string>
---@field role table<string, string>
---@field process table<string, table<string>>>
---@field processReverse table<string, table<string>>>
---@field idWhitelist table<string, table<string, boolean|RuleMeta>>
---@field idBlacklist table<string, table<string, boolean|RuleMeta>>
---@field logicalRules table<string, table<string, RuleMeta>>
local SettingData = {}

---@class Setting
---@field data SettingData
local setting = {}

function setting.init()
    local file = io.open(config.server.configFile, "r")
    if file then
        local content = file:read("*a")
        file:close()
        debug.debug("Loaded setting file: %s", content)
        if content then
            setting.data = serialization.unserialize(content) --[[@as SettingData]]
        end
    end
    
    setting.data = setting.data or {}
    
    for _, key in ipairs(DEFAULT_KEYS) do
        setting.data[key] = setting.data[key] or {}
    end

    debug.info("Convert old whitelist/blacklist setting")
    -- 老配置文件是使用的 boolean 的, 转成 table
    local bool2RuleMeta = function (t)
        for role, map in pairs(t) do
            for key, val in pairs(map) do
                if type(val) == "boolean" then
                    t[role][key] = {enable = val, comments = ""}
                end
            end
        end
    end
    bool2RuleMeta(setting.data.idBlacklist)
    bool2RuleMeta(setting.data.idWhitelist)
end

function setting.store()
    debug.info("Store setting...")
    local file = io.open(config.server.configFile, "w")
    if file then
        file:write(serialization.serialize(setting.data))
        file:flush()
        file:close()
        debug.info("Store successful.")
    end
end

function setting.isConfigurated(address)
    return setting.data.interfaces[address] ~= nil
end

function setting.setInterfaceRole(address, role)
    setting.data.interfaces[address] = role
end

function setting.getRole(role)
    return setting.data.role[role]
end

function setting.getRoles()
    return setting.data.role
end

function setting.setRole(role, t)
    setting.data.role[role] = t
end

function setting.getAddressName(address)
    return setting.data.interfaces[address]
end

function setting.getAddressRole(address)
    return setting.data.role[setting.getAddressName(address)]
end

function setting.removeProcess(name)
    local process_data = setting.data.process[name]
    if not process_data then return end
    
    local process_str = table.concat(process_data, "=>")
    local reverse_list = setting.data.processReverse[process_str]

    if reverse_list then
        for i, v in ipairs(reverse_list) do
            if v == name then
                table.remove(reverse_list, i)
                break
            end
        end
    end

    setting.data.process[name] = nil
end

function setting.setProcess(name, process)
    setting.removeProcess(name)
    setting.data.process[name] = process
    local pid = table.concat(process, "=>")
    
    setting.data.processReverse[pid] = setting.data.processReverse[pid] or {}
    table.insert(setting.data.processReverse[pid], name)
    setting.store()
end

function setting.getNamesByProcess(process)
    return setting.data.processReverse[process]
end

function setting.getAllProcessNames()
    return setting.data.processReverse
end

function setting.getProcess(name)
    return setting.data.process[name] or {}
end

function setting.getAllProcess()
    return setting.data.process
end

---set item id whitelist rule
---@param role string
---@param id string
---@param flag boolean
---@param comments string
function setting.addIdWhitelist(role, id, flag, comments)
    setting.data.idWhitelist[role] = setting.data.idWhitelist[role] or {}
    setting.data.idWhitelist[role][id] = {
        enable = flag,
        comments = comments
    }
end

---set item id blacklist rule
---@param role string
---@param id string
---@param flag boolean
---@param comments string
function setting.addIdBlacklist(role, id, flag, comments)
    setting.data.idBlacklist[role] = setting.data.idBlacklist[role] or {}
    setting.data.idBlacklist[role][id] = {
        enable = flag,
        comments = comments
    }
end

function setting.getAllIdWhitelist()
    return setting.data.idWhitelist --[[@as table<string, table<string, RuleMeta>>]]
end

function setting.getAllIdBlacklist()
    return setting.data.idBlacklist --[[@as table<string, table<string, RuleMeta>>]]
end

---set logical rule
---@param role string
---@param rule string
---@param flag boolean
---@param comments string
function setting.setLogicalRule(role, rule, flag, comments)
    setting.data.logicalRules[role] = setting.data.logicalRules[role] or {}
    setting.data.logicalRules[role][rule] = {
        enable = flag,
        comments = comments
    }
end

function setting.getLogicalRules()
    return setting.data.logicalRules
end

return setting