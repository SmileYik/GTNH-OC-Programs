local component = require("component")
local gpu = component.gpu
local w, h = gpu.getResolution()
local keyboard = require("keyboard")

local reader = {}

function reader.showList(list, quitKey)
    if quitKey == nil then quitKey = "q" end
    if list == nil then list = {} end
    local currentIdx = 1
    local selected = 0
    local size = #list
    while (true) do
        gpu.fill(1, 1, w, h, " ")
        local target = math.min(h - 1, size)
        for i = currentIdx, target do
            if i <= size and list[i] ~= nil then
                local prefix = ""
                if selected == i then prefix = "* " end
                gpu.set(1, i - currentIdx + 1, prefix .. i .. ". " .. list[i])
            end
        end
        gpu.set(1, h - 1, "↑/W键向上滚动 | ↓/S键向下滚动 | " .. quitKey .. "键退出")

        if     keyboard.isKeyDown(quitKey) then break
        elseif keyboard.isKeyDown(keyboard.keys.up)   then currentIdx = math.max(1, currentIdx - 1)
        elseif keyboard.isKeyDown(keyboard.keys.down) then currentIdx = math.min(currentIdx + 1, size - h + 1)
        elseif keyboard.isKeyDown("w") then selected = math.max(0, selected - 1)
        elseif keyboard.isKeyDown("s") then selected = math.min(size, selected + 1)
        end
        os.sleep(0.1)
    end
    gpu.fill(1, 1, w, h, " ")
    return list, selected
end

function reader.showTable(t)
    if t == nil then t = {} end
    local list = {}
    local keyList = {}
    for k, v in pairs(t) do
        table.insert(list, k .. "(" .. v .. ")")
        table.insert(keyList, k)
    end
    local _, idx = reader.showList(list)
    return keyList, idx
end

function reader.show(obj, getKey, toString)
    if obj == nil then obj = {} end
    local list = {}
    local keyList = {}
    for k, v in pairs(obj) do
        local key = getKey(k, v)
        local str = toString(k, v)
        table.insert(list, str)
        table.insert(keyList, key)
    end
    local _, idx = reader.showList(list)
    return keyList, idx
end

return reader
