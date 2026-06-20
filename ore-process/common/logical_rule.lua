local mod = {}

local function tokenize(str)
    local tokens = {}
    local i = 1
    local len = #str

    while i <= len do
        local char = string.sub(str, i, i)

        if string.match(char, "%s") then
            i = i + 1
        -- !非 及 括号
        elseif char == "(" or char == ")" or char == "!" then
            table.insert(tokens, { type = char })
            i = i + 1
        -- &&
        elseif string.sub(str, i, i + 1) == "&&" then
            table.insert(tokens, { type = "&&" })
            i = i + 2
        -- ||
        elseif string.sub(str, i, i + 1) == "||" then
            table.insert(tokens, { type = "||" })
            i = i + 2
        -- {command-name: args-string}
        elseif char == "{" then
            local close_idx = string.find(str, "}", i)
            if not close_idx then 
                error("语法错误：缺少闭合括号 '}'") 
            end
            
            local content = string.sub(str, i + 1, close_idx - 1)
            -- 匹配 command-name 和 args-string，允许名称前后有空格
            local name, args = string.match(content, "^%s*([a-zA-Z0-9_%-]+)%s*:(.*)$")
            
            if not name then 
                error("语法错误：命令项格式不正确 {" .. content .. "}") 
            end
            
            table.insert(tokens, { type = "cmd", name = name, args = args })
            i = close_idx + 1
        else
            error("语法错误：未知的字符 '" .. char .. "'")
        end
    end

    return tokens
end

local function parse(tokens)
    local idx = 1

    local function peek() return tokens[idx] end
    local function consume() local t = tokens[idx]; idx = idx + 1; return t end

    local parse_expr, parse_or, parse_and, parse_not, parse_primary

    -- 表达式入口
    function parse_expr()
        return parse_or()
    end

    -- ||
    function parse_or()
        local node = parse_and()
        while peek() and peek().type == "||" do
            consume()
            local right = parse_and()
            node = { type = "||", left = node, right = right }
        end
        return node
    end

    -- &&
    function parse_and()
        local node = parse_not()
        while peek() and peek().type == "&&" do
            consume()
            local right = parse_not()
            node = { type = "&&", left = node, right = right }
        end
        return node
    end

    -- !
    function parse_not()
        if peek() and peek().type == "!" then
            consume()
            local node = parse_not()
            return { type = "!", expr = node }
        end
        return parse_primary()
    end

    -- 括号或具体命令
    function parse_primary()
        local t = peek()
        if not t then error("语法错误：表达式意外结束") end

        if t.type == "(" then
            consume()
            local node = parse_expr()
            local close = consume()
            if not close or close.type ~= ")" then 
                error("语法错误：缺少右括号 ')'") 
            end
            return node
        elseif t.type == "cmd" then
            consume()
            return { type = "cmd", name = t.name, args = t.args }
        else
            error("语法错误：不期望的 Token '" .. t.type .. "'")
        end
    end

    local ast = parse_expr()
    if idx <= #tokens then 
        error("语法错误：表达式尾部存在多余字符") 
    end
    return ast
end

local function evaluate(node, executor, cache)
    if node.type == "cmd" then
        return not not executor(node.name, node.args, cache)

    elseif node.type == "!" then
        return not evaluate(node.expr, executor, cache)

    elseif node.type == "&&" then
        local left_val = evaluate(node.left, executor, cache)
        if not left_val then return false end
        return evaluate(node.right, executor, cache)

    elseif node.type == "||" then
        local left_val = evaluate(node.left, executor, cache)
        if left_val then return true end
        return evaluate(node.right, executor, cache)
    end
end

--- 解析并执行规则字符串
--- @param rule_str string 规则字符串
--- @param executor function 执行器函数，格式为 function(name, args, cache) -> bool
--- @return boolean 是否执行成功, table 执行缓存
function mod.eval(rule_str, executor)
    if type(rule_str) ~= "string" or rule_str == "" then return false, {} end
    if type(executor) ~= "function" then 
        error("使用错误：eval 方法必须传入一个 executor 执行器函数") 
    end

    local tokens = tokenize(rule_str)
    local ast = parse(tokens)
    local cache = {}
    return evaluate(ast, executor, cache), cache
end

return mod