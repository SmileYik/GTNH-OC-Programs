local newRuleTable = require("common.rule_define")
local setting = require("server.setting")
local roles = require("server.interface_type")

local spawner = {}

---comment
---@return Rules
function spawner.spawnNormalRules()
    ---@type Rules
    local rules = {}

    ---set rule
    ---@param source table<string, table<string, RuleMeta>>
    ---@param callback function(Rule, string)
    local setTableRule = function (source, callback)
        for role, ruleMap in pairs(source) do
            rules[role] = rules[role] or newRuleTable()
            local rule = rules[role]
            for key, val in pairs(ruleMap) do
                if val == true or type(val) ==  "table" and val.enable then
                    callback(rule, key)
                end
            end
        end
    end
    
    setTableRule(
        setting.getAllIdBlacklist(),
        ---@param rule Rule
        ---@param key string
        function(rule, key) 
            rule.blacklist.ids[key] = true 
        end
    )
    
    setTableRule(
        setting.getAllIdWhitelist(),
        ---@param rule Rule
        ---@param key string
        function(rule, key)
            table.insert(rule.whitelist.ids, key)
        end
    )

    setTableRule(
        setting.getLogicalRules(),
        ---@param rule Rule
        ---@param key string
        function(rule, key) 
            table.insert(rule.logicals, key)
        end
    )

    return rules
end

---生成符合网络传输要求的矿物流程白名单规则列表.
---@param ore string 矿物名称
---@param process table 职责流程列表
---@return Rules 返回一个键值对表，Key为职责名称，Value为格式化后的标签白名单列表
function spawner.spawnSingleOreRule(ore, process)
    ---@type Rules
    local rules = {}
    local whiteLabelRules = spawner.spawnLableWhiteListRulesByList(ore, process)
    for role, list in pairs(whiteLabelRules) do
        rules[role] = rules[role] or newRuleTable()
        local roleRoles = rules[role]
        roleRoles.whitelist.labels = list
    end
    return rules
end

---根据给定的矿物名称和职责序列，生成物品标签的白名单规则
---@param ore string 矿物名称
---@param process table 职责流程列表
---@return table<string, table<string>> 返回一个键值对表，Key为职责名称，Value为格式化后的标签白名单列表
function spawner.spawnLableWhiteListRulesByList(ore, process)
    ---@type table<string, table<string>>
    local rules = {}
    if not process then return rules end

    local prevRoleKey = nil
    for i, role in ipairs(process) do
        local currentRoleKey = setting.getRole(role)
        local roleConfig     = roles[currentRoleKey]
        local pattern = roleConfig and roleConfig.self

        if i > 1 and roleConfig and prevRoleKey then
            local specificPattern = roleConfig[prevRoleKey]
            if specificPattern ~= nil then
                pattern = specificPattern
            end
        end

        prevRoleKey = currentRoleKey
        if pattern then
            rules[role] = rules[role] or {}
            local targetList = rules[role]

            if type(pattern) == "table" then
                for _, lab in ipairs(pattern) do
                    table.insert(targetList, string.format(lab, ore))
                end
            else
                table.insert(targetList, string.format(pattern, ore))
            end
        end
    end

    return rules
end

return spawner