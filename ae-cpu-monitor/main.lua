local component = require("component")
local computer = require("computer")
local menu = require("menu")
local screen = component.screen
local cpu_detail = require("cpu")
local cache = require("cache")

local pages = {
    menu = menu,
    cpu_detail = cpu_detail
}

local page = menu
screen.setTouchModeInverted(true)
page.init()
cache.init()

computer.beep()
computer.beep()

while true do
    -- local event, address, arg1, arg2, arg3, from = computer.pullSignal(0.5)
    -- print(event, address, arg1, arg2, arg3, from)
    local maxTimes = 10
    while not cache.tick() and maxTimes > 0 do maxTimes = maxTimes - 1 end
    local result, model = page.tick()
    if result == "exit" then break
    elseif result ~= nil then
        page = pages[result]
        if page ~= nil then
            page.init(model)
            computer.beep()
            computer.beep()
        else
            break
        end
    end
end
screen.setTouchModeInverted(false)
