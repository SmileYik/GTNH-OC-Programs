local component = require("component")
local DEBUG = require("./commons/debug")
local computer = require("computer")
local gpu = component.gpu
local w, h = gpu.getResolution()
local renderUtil = require("./commons/render_util")

local menu = {}

function menu.init(reactors, status, model)
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
    renderUtil.drawHCenter(1, 2, menu.model.name)
    gpu.set(w - 3, 2, "_")
end

local function paint(reactors, status)
    local info = status[menu.model.name].info

    paintFrame()

    local y = 4
    local width = w - 16
    local offsetH = 3
    local offsetW = 6
    gpu.setBackground(0xCC0080)
    gpu.setForeground(0xFFFFFF)

    gpu.set(offsetW, y + 0.5 * offsetH, "运行状态：")
    gpu.set(offsetW, y + 2 * offsetH, "运行阶段：")
    gpu.set(offsetW, y + 3 * offsetH, "能量输出：")
    gpu.set(offsetW, y + 4 * offsetH, "EU  输出：")
    gpu.set(offsetW, y + 5 * offsetH, " 堆  温 ：")

    offsetW = offsetW + 12
    if not status[menu.model.name].valid then
        gpu.setForeground(0xff0040)
        gpu.set(offsetW, y + 0.5 * offsetH, "无  效")
    elseif not status[menu.model.name].active then
        gpu.setForeground(0x66DB00)
        gpu.set(offsetW, y + 0.5 * offsetH, "未接管")
    elseif info.enable ~= nil and info.enable then
        gpu.setForeground(0xCC9200)
        gpu.set(offsetW, y + 0.5 * offsetH, "运行中")
    else
        gpu.setForeground(0x66DB00)
        gpu.set(offsetW, y + 0.5 * offsetH, "空闲中")
    end
    if info.error ~= nil then
        gpu.setForeground(0xff0040)
        gpu.set(offsetW, y + 0.5 * offsetH, "异  常")
        renderUtil.drawHCenter2(8, y + 1 * offsetH, width, info.error)
    end

    gpu.setForeground(0x66DB00)
    gpu.set(offsetW, y + 2 * offsetH, status[menu.model.name].step.getInfo(status[menu.model.name]))

    if info.energyOutput ~= nil then
        gpu.setForeground(0x66DB00)
        gpu.set(offsetW, y + 3 * offsetH, string.format("%.2f", info.energyOutput))
    end

    if info.euOutput ~= nil then
        gpu.setForeground(0x66DB00)
        gpu.set(offsetW, y + 4 * offsetH, string.format("%.2f", info.euOutput))
    end

    if info.heat ~= nil and info.maxHeat ~= nil then
        gpu.setForeground(0x66DB00)
        gpu.set(offsetW, y + 5 * offsetH, string.format("%.2f/%.2f", info.heat, info.maxHeat))
    end


    gpu.setBackground(0xFF6DFF)
    gpu.setForeground(0xFFFFFF)

    y = y + 2
    gpu.fill(width, y, 13, 15, " ")

    -- 冷却液
    if info ~= nil and info.tankLevel ~= nil then
        local num = info.tankLevel / 10000.0
        gpu.setBackground(0xFF6DFF)
        gpu.setForeground(0xFFFFFF)
        gpu.set(width + 2, y, string.format("%.0f%%", num * 100))

        gpu.setBackground(0x0024ff)
        gpu.fill(width + 3, y + 1, 3, 14-3, " ")
        gpu.setBackground(0xFFFFFF)
        gpu.fill(width + 3, y + 1, 3, math.max(0, math.ceil((14 - 3) * (1 - num))), " ")
        gpu.setBackground(0xFF6DFF)
        gpu.setForeground(0x0024ff)
        gpu.set(width + 3, y + 15 - 3, "冷却液", true)
    end

    -- 堆温
    if info~= nil and info.heat ~= nil and info.maxHeat ~= nil then
        local num = info.heat / info.maxHeat
        gpu.setBackground(0xFF6DFF)
        gpu.setForeground(0xFFFFFF)
        gpu.set(width + 7, y, string.format("%.0f%%", num * 100))

        gpu.setBackground(0xff0040)
        gpu.setForeground(0x660080)
        gpu.fill(width + 7, y + 1, 3, 14 - 3, " ")
        gpu.setBackground(0x0024ff)
        gpu.fill(width + 7, y + 1, 3, math.min(13, math.ceil((14 - 3) * (1 - num))), " ")
        gpu.setForeground(0xffffff)
        gpu.setBackground(0xFF6DFF)
        gpu.setForeground(0xff0040)
        gpu.set(width + 7, y + 15 - 3, "堆 温", true)

    end

    gpu.setBackground(0xCC0080)
    gpu.setForeground(0xFFFFFF)
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
    menu.cache = {}
    for name in pairs(reactors) do
        menu.cache[name] = status[name].info.enable
    end
end

function menu.tick(reactors, status)
    if menu.model == nil or menu.model.name == nil or status[menu.model.name] == nil then
        return "outlines", nil
    end

    local event, _, arg1, arg2, arg3, _ = computer.pullSignal(0.001)
    if event == "touch" then
        local x = arg1
        local y = arg2
        local i = (y - 1) // 3
        if i == 0 and x >= w - 4 and x < w and gpu.get(x, y) == "_" then
            return "outlines", nil
        end
    end

    checkRepaint(reactors, status)
    menu.repaint = true
    if menu.repaint then
        paint(reactors, status)
    end

    spawnCache(reactors, status)

    return nil, nil
end

return menu
