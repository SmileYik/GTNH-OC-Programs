local component = require("component")
local DEBUG = require("./commons/debug")
local computer = require("computer")
local gpu = component.gpu
local w, h = gpu.getResolution()
local renderUtil = require("./commons/render_util")
local MAX_SHOW = 6

local menu = {}

function menu.init(reactors, status, model)
    menu.current = 1
    menu.repaint = true
    menu.model = model
    menu.cache = nil
end

local function paintFoot()
    local f = gpu.getForeground()
    local b = gpu.getBackground()
    gpu.setBackground(0x992480)
    gpu.setForeground(0x660080)
    gpu.fill(4, h - 3, w - 6, 3, " ")

    local me = component.me_interface
    local fluids = me.getFluidsInNetwork({name = "ic2coolant"})
    local cool = 0
    local hot = 0
    for _, fluid in pairs(fluids) do
        if fluid ~= nil and fluid.name == "ic2coolant" then
            cool = fluid.amount
        elseif fluid ~= nil and fluid.name == "ic2hotcoolant" then
            hot = fluid.amount
        end
    end

    if cool + hot ~= 0 then
        local total = w - 16
        local coolPercent = cool / (cool + hot)
        local coolLength = math.ceil(coolPercent * total)
        local hotLength = total - coolLength


        local offsetX = 9
        if coolLength > 0 then
            gpu.setBackground(0x0024ff)
            gpu.setForeground(0xff0040)
            gpu.fill(offsetX, h - 2, coolLength, 1, " ")
            renderUtil.drawHCenter2(offsetX, h - 2, coolLength, string.format("%.0fK", cool / 1000))
        end
        if hotLength > 0 then
            gpu.setBackground(0xff0040)
            gpu.setForeground(0x660080)
            gpu.fill(offsetX + coolLength, h - 2, hotLength, 1, " ")
            renderUtil.drawHCenter2(offsetX + coolLength, h - 2, hotLength, string.format("%.0fK", hot / 1000))
        end
    end

    gpu.setBackground(b)
    gpu.setForeground(f)
end

local function paintFrame()
    gpu.setBackground(0x0092FF)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, w, h, " ")
    gpu.setBackground(0xCC0080)
    gpu.fill(4, 4, w - 6, h - 4, " ")
    gpu.setBackground(0x0092FF)
    gpu.setForeground(0xFFFFFF)
    renderUtil.drawHCenter(1, 2, "液体堆")
    gpu.set(w - 5, 2, "X")
end

local function paint(reactors, status)
    paintFrame()
    local x = 12
    local y = 4
    local current = menu.current
    local idx = 1
    for name, obj in pairs(reactors) do
        if idx - current == MAX_SHOW then break end
        if idx >= current then
            if idx % 2 == 1 then
                gpu.setBackground(0xCC0080)
                gpu.setForeground(0xFFFFFF)
            else
                gpu.setBackground(0xFF6DFF)
                gpu.setForeground(0xFFFFFF)
            end
            gpu.fill(4, y, w - 6, 3, " ")
            local str = name
            gpu.set(x, y + 1, str)
            if not status[name].valid then
                str = "无  效"
                gpu.setForeground(0xFF0000)
            elseif status[name].info.enable then
                str = "运行中"
                gpu.setForeground(0x0000FF)
            elseif not status[name].active then
                str = "未接管"
                gpu.setForeground(0xFFFF00)
            else
                str = "未运行"
                gpu.setForeground(0x33FFFF)
            end
            renderUtil.drawHCenter2(w - 10, y + 1, 5, str)

            if status[name].active then
                gpu.setForeground(0x0092FF)
                gpu.setBackground(0xFF0000)
                renderUtil.drawHCenter2(x - 4, y + 1, 2, "下线")
            else
                gpu.setForeground(0xFFFFFF)
                gpu.setBackground(0x0092FF)
                renderUtil.drawHCenter2(x - 4, y + 1, 2, "上线")
            end

            y = y + 3
        end
        idx = idx + 1
    end
    paintFoot()
end

local function checkRepaint(reactors, status)
    if menu.cache == nil then
        menu.repaint = true
        return
    end

    for k, v in pairs(menu.cache) do
        if status[k] == nil or status[k].enable ~= v then
            menu.repaint = true
            return
        end
    end

    for k, v in pairs(status) do
        if menu.cache[k] == nil or menu.cache[k] ~= v.enable then
            menu.repaint = true
            return
        end
    end
end

local function spawnCache(reactors, status)
    menu.cache = {
        list = {}
    }
    for name in pairs(reactors) do
        menu.cache[name] = status[name].info.enable
        table.insert(menu.cache.list, name)
    end
end

function menu.tick(reactors, status)

    local event, _, arg1, arg2, arg3, _ = computer.pullSignal(0.001)
    if event == "scroll" then
        local old = menu.current
        menu.current = menu.current - arg3
        if menu.current < 1 then
            menu.current = 1
        end
        menu.repaint = old ~= menu.current
    elseif event == "touch" then
        local x = arg1
        local y = arg2
        local i = (y - 1) // 3
        if i == 0 and gpu.get(x, y) == "X" then
            return "exit"
        elseif i > 0 and x > 3 and x < w - 6 and menu.cache.list ~= nil and menu.cache.list[menu.current + i - 1] ~= nil then
            DEBUG("[outlines] 点击的坐标为 (%d, %d), 其坐标对应字符为 %s.", x, y, gpu.get(x, y))
            local name = menu.cache.list[menu.current + i - 1]
            local c = gpu.get(x, y)
            if (x < 12) and (c == "上" or c == "下" or c == "线") then
                status[name].active = not status[name].active
                DEBUG("[outlines] 设置 %s 的状态为 %s.", name, status[name].active)
            else
                return "details", {name = name}
            end
        end
    end


    checkRepaint(reactors, status)

    if menu.repaint then
        paint(reactors, status)
    end

    spawnCache(reactors, status)

    return nil, nil
end

return menu
