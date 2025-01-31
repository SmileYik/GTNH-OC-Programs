local component = require("component")
local computer = require("computer")
local gpu = component.gpu
local w, h = gpu.getResolution()
local renderUtil = require("render_util")
local MAX_SHOW = 7

local cpu_detail = {}
local RENDER_COUNT = 10
local count = 0

local function render()
    gpu.setBackground(0xCC0080)
    gpu.setForeground(0x3392FF)
    gpu.fill(1, 1, w, h, "*")
    gpu.fill(2, 2, w - 2, 1, " ")
    gpu.fill(1, 3, w, 1, "*")
    gpu.fill(4, 4, w - 6, h - 4, " ")
    gpu.set(w - 3, 2, "X")
    local busy = ""
    if cpu_detail.cpu.cpu.isBusy() == true then
        busy = "忙碌中"
        gpu.setForeground(0xFF0000)
        gpu.set(4, 2, "取消任务")
    else
        busy = "空闲中"
        gpu.setForeground(0x33FFFF)
    end
    renderUtil.drawHCenter(1, 2, string.format("%s  %d核  %dKB[%s]", cpu_detail.cpu.name, cpu_detail.cpu.coprocessors, cpu_detail.cpu.storage / 1024, busy))

    local x = 10
    local y = 4
    local i = 1
    local current = cpu_detail.current
    local items = cpu_detail.cpu.cpu.activeItems()
    for _, item in pairs(cpu_detail.cpu.cpu.pendingItems()) do
        item.pending = true
        table.insert(items, item)
    end
    for idx, item in pairs(items) do
        if idx - current == MAX_SHOW then break end
        if idx >= current then
            if i % 2 == 1 then
                gpu.setBackground(0xCC0080)
                gpu.setForeground(0xFFFFFF)
            else
                gpu.setBackground(0xFF6DFF)
                gpu.setForeground(0xFFFFFF)
            end
            gpu.fill(4, y, w - 6, 3, " ")
            local str
            if item.pending ~= nil then
                gpu.setForeground(0x3392FF)
                str = string.format("等待合成 %s", item.label)
            else
                gpu.setForeground(0xCCDB00)
                str = string.format("正在合成 %s", item.label)
            end
            gpu.set(x, y + 1, str)
            str = string.format("%d 个", item.size)
            gpu.setForeground(0x3392FF)
            renderUtil.drawHCenter2(w - 10, y + 1, 5, str)
            y = y + 3
            i = i + 1
        end
    end
end

function cpu_detail.init(cpu)
    cpu_detail.current = 1
    cpu_detail.repaint = true
    cpu_detail.cpu = cpu
    count = 0
end

local function checkRepaint()
    if cpu_detail.activeItems == nil then
        cpu_detail.repaint = true
        cpu_detail.activeItems = cpu_detail.cpu.cpu.activeItems()
    end
    local items = cpu_detail.cpu.cpu.activeItems()
    if items == nil then items = {} end
    if #items ~= #cpu_detail.activeItems then
        cpu_detail.repaint = true
        cpu_detail.activeItems = items
    else
        for idx, item in ipairs(items) do
            if cpu_detail.activeItems[idx].label ~= item.label or cpu_detail.activeItems[idx].size ~= item.size then
                cpu_detail.repaint = true
                cpu_detail.activeItems = items
                break
            end
        end
    end
end

function cpu_detail.tick()
    local event, _, arg1, arg2, arg3, _ = computer.pullSignal(0.5)
    if event == "scroll" then
        local old = cpu_detail.current
        cpu_detail.current = cpu_detail.current - arg3
        if cpu_detail.current < 1 then
            cpu_detail.current = 1
        end
        cpu_detail.repaint = old ~= cpu_detail.current
        count = 0
    elseif event == "touch" then
        local x = arg1
        local y = arg2
        local i = (y - 1) // 3
        if i == 0 and x >= 4 and x <= 7 then
            -- cancel
            cpu_detail.cpu.cpu.cancel()
            cpu_detail.repaint = true
            count = 0
        elseif i == 0 and x >= w - 4 and x < w then
            -- return to menu
            return "menu"
        end
    end
    checkRepaint()
    if cpu_detail.repaint then
        if count == 0 then
            render()
            cpu_detail.repaint = false
            count = RENDER_COUNT
        else
            count = count - 1
        end
    end
    return nil
end

return cpu_detail