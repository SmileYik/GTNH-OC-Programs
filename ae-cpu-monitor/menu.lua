local component = require("component")
local computer = require("computer")
local gpu = component.gpu
local w, h = gpu.getResolution()
local me = component.me_interface
local renderUtil = require("render_util")
local MAX_SHOW = 7

local menu = {}

local function render()
    gpu.fill(1, 1, w, h, "*")
    gpu.fill(2, 2, w - 2, 1, " ")
    gpu.fill(1, 3, w, 1, "*")
    gpu.fill(4, 4, w - 6, h - 4, " ")
    gpu.set(w - 3, 2, "X")
    renderUtil.drawHCenter(1, 2, "AE CPUS")
    local x = 10
    local y = 4
    local current = menu.current
    for idx, cpu in pairs(me.getCpus()) do
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
            local str = string.format("%d. %s  %d核  %dKB", idx, cpu.name, cpu.coprocessors, cpu.storage / 1024)
            gpu.set(x, y + 1, str)
            if cpu.busy == true then
                str = "忙碌中"
                gpu.setForeground(0xFF0000)
            else
                str = "空闲中"
                gpu.setForeground(0x33FFFF)
            end
            renderUtil.drawHCenter2(w - 10, y + 1, 5, str)
            y = y + 3
        end
    end
end

function menu.init()
    menu.current = 1
    menu.repaint = true
end

local function checkRepaint()
    if menu.cpus == nil then
        menu.repaint = true
        menu.cpus = me.getCpus()
    end
    local cpus = me.getCpus()
    if #cpus ~= #menu.cpus then
        menu.repaint = true
        menu.cpus = cpus
    else
        for idx, cpu in ipairs(cpus) do
            if menu.cpus[idx].busy ~= cpu.busy then
                menu.repaint = true
                menu.cpus = cpus
                break
            end
        end
    end
end

function menu.tick()
    local event, address, arg1, arg2, arg3, from = computer.pullSignal(0.5)
    if event == "scroll" then
        local old = menu.current
        menu.current = menu.current + arg3
        if menu.current < 1 then
            menu.current = 1
        end
        menu.repaint = old ~= menu.current
    elseif event == "touch" then
        local x = arg1
        local y = arg2
        local i = (y - 1) // 3
        if i == 0 and x >= w - 4 and x < w then
            return "exit"
        elseif i > 0 and x > 3 and x < w - 3 and menu.cpus ~= nil and menu.cpus[menu.current + i - 1] ~= nil then
            return "cpu_detail", menu.cpus[menu.current + i - 1]
        end
    end
    checkRepaint()
    if menu.repaint then
        render()
        menu.repaint = false
    end
    return nil
end

return menu