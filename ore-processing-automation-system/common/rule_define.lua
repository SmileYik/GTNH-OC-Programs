---@class Whitelist
---@field ids table<string>
---@field labels table<string>
local Whitelist = {}

---@class Blacklist
---@field ids table<string, boolean>
---@field labels table<string, boolean>
local Blacklist = {}

---@class Rule
---@field whitelist Whitelist
---@field blacklist Blacklist
---@field logicals table<string>
local Rule = {}

---@alias Rules table<string, Rule> 
local Rules = {}

---new rule table
---@return Rule
local function newRuleTable()
    return {
        whitelist = { ids = {}, labels = {} },
        blacklist = { ids = {}, labels = {} },
        logicals = {},
    } --[[@as Rule]]
end

return newRuleTable