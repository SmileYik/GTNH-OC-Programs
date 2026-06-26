local component = require("component")
local keyboard = require("keyboard")
local event = require("event")

local gpu = component.gpu
local w, h = gpu.getResolution()

local reader = {}

function reader.showList(list, quitKey, applyKey)
    quitKey = quitKey or "q"
    applyKey = applyKey or 'e'
    list = list or {}
    local size = #list

    local quitChar = string.byte(quitKey:lower())
    local quitCharUpper = string.byte(quitKey:upper())
    local applyChar = string.byte(applyKey:lower())
    local applyCharUpper = string.byte(quitKey:upper())
    
    -- empty
    if size == 0 then
        gpu.fill(1, 1, w, h, " ")
        gpu.set(1, 1, "列表为空。按任意键退出...")
        event.pull("key_down")
        return list, 0
    end

    local selected = 1
    local currentIdx = 1
    local maxVisible = h - 2

    local function redraw()
        gpu.fill(1, 1, w, h, " ")
        
        local endIdx = math.min(size, currentIdx + maxVisible - 1)
        
        for i = currentIdx, endIdx do
            if list[i] ~= nil then
                local prefix = "  "
                if selected == i then prefix = "* " end
                local lineNum = i - currentIdx + 1
                gpu.set(1, lineNum, prefix .. i .. ". " .. tostring(list[i]))
            end
        end
        
        gpu.set(1, h, "↑/W: 向上 | ↓/S: 向下 | [" .. applyKey:upper() .. "]: 选定 | [" .. quitKey:upper() .. "]: 退出")
    end

    while true do
        redraw()
        
        local _, _, char, code = event.pull("key_down")

        -- quit
        if char == quitChar or char == quitCharUpper then
            selected = 0
            break
        elseif char == applyChar or char == applyCharUpper then
            break
        end

        -- up
        if code == keyboard.keys.up or char == string.byte("w") or char == string.byte("W") then
            if selected > 1 then
                selected = selected - 1
                if selected < currentIdx then
                    currentIdx = selected
                end
            end

        -- down
        elseif code == keyboard.keys.down or char == string.byte("s") or char == string.byte("S") then
            if selected < size then
                selected = selected + 1
                if selected >= currentIdx + maxVisible then
                    currentIdx = selected - maxVisible + 1
                end
            end
        end
    end

    gpu.fill(1, 1, w, h, " ")
    return list, selected
end

function reader.showTable(t)
    t = t or {}
    local keyList = {}
    for k in pairs(t) do
        table.insert(keyList, k)
    end
    table.sort(keyList, function(a, b) return tostring(a) < tostring(b) end)

    local list = {}
    for _, k in ipairs(keyList) do
        table.insert(list, tostring(k) .. " (" .. tostring(t[k]) .. ")")
    end
    
    local _, idx = reader.showList(list)
    return keyList, idx
end

function reader.show(obj, getKey, toString)
    obj = obj or {}
    getKey = getKey or function(k, v) return k end
    toString = toString or function(k, v) return tostring(k) .. " (" .. tostring(v) .. ")" end

    local list = {}
    local keyList = {}
    for k, v in pairs(obj) do
        table.insert(list, toString(k, v))
        table.insert(keyList, getKey(k, v))
    end
    
    local _, idx = reader.showList(list)
    return keyList, idx
end

return reader