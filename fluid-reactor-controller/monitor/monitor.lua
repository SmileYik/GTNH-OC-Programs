local component = require("component")
local computer = require("computer")

local DEBUG = require("./commons/debug")

local pageOutlines = require("./monitor/pages/outlines")
local pageDetails  = require("./monitor/pages/details")

local stepFluidCheck = require("./monitor/steps/fluid_check")
local stepHeatCheck = require("./monitor/steps/heat_check")
local stepRodCheck = require("./monitor/steps/rod_check")
local stepShapeCheck = require("./monitor/steps/shape_check")
local stepSwitch = require("./monitor/steps/switch")
local stepRequireItem = require("./monitor/steps/require_item")

local shape = require("./commons/shape")
local reactor = require("./commons/reactor")
local runFlag = true

local monitor = {
    firstRun = true,
    pages = {
        outlines = pageOutlines,
        details = pageDetails
    },
    gui = {
        page = nil,
        model = nil
    },
    reactors = {},
    status = {},
    steps = {
        fluid_check = stepFluidCheck,
        heat_check = stepHeatCheck,
        rod_check = stepRodCheck,
        shape_check = stepShapeCheck,
        switch = stepSwitch,
        require_item = stepRequireItem,
    }
}

local function isValid(rea)
    return component.proxy(rea.me) ~= nil
end

local function init()
    runFlag = true
    monitor.reactors = reactor.load()
    for name, obj in pairs(monitor.reactors) do
        obj.flags = {}
        monitor.status[name] = {
            step = monitor.steps.fluid_check,
            pass = true,
            info = {},
            skips = {},
            valid = isValid(obj),
            active = false
        }
        obj.shape = shape.load(obj.shape)
        DEBUG(string.format("[%s] 设备有效检测结果为：%s", name, monitor.status[name].valid))
    end
end

local function stopReactor(name)
    monitor.status[name].info = {}
    local rp = component.proxy(monitor.reactors[name].redstonePort)
    if rp ~= nil then rp.setActive(false) end
end

local function exit()
    for name in pairs(monitor.reactors) do
        stopReactor(name)
    end
    runFlag = false
end

local function run()
    for name, obj in pairs(monitor.reactors) do
        monitor.status[name].valid = isValid(obj)
        if monitor.status[name].valid and monitor.status[name].active then
            local moveTo, model = monitor.status[name].step.tick(obj, monitor.status[name])
            if moveTo ~= nil and monitor.steps[moveTo] ~= nil then
                monitor.status[name].step = monitor.steps[moveTo]
                monitor.status[name].step.init(obj, monitor.status[name], model)
            end
        else
            stopReactor(name)
        end
    end
end

local function render()
    if monitor.gui.page == nil then
        monitor.gui.page = pageDetails-- pageOutlines
        monitor.gui.model = nil
        monitor.gui.page.init(monitor.reactors, monitor.status, monitor.gui.model)
    end

    local moveTo, model = monitor.gui.page.tick(monitor.reactors, monitor.status)
    if moveTo ~= nil and moveTo == "exit" then
        exit()
    elseif moveTo ~= nil and monitor.pages[moveTo] ~= nil then
        computer.beep(1000)
        monitor.gui.page = monitor.pages[moveTo]
        monitor.gui.model = model
        monitor.gui.page.init(monitor.reactors, monitor.status, monitor.gui.model)
    end
end

function monitor.tick()
    if monitor.firstRun then
        monitor.firstRun = false
        init()
        return runFlag
    end

    if not runFlag then return runFlag end

    run()

    render()
    return runFlag
end

return monitor
