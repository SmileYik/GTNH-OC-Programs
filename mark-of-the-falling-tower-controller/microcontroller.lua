local SLEEP = 1
local OUTPUT = 2
local INPUT = 0
local PORT = 10000

local r = component.proxy(component.list("redstone")())
local m = component.proxy(component.list("modem")())
local signals = {}
local working = false
local workDone = false

m.open(PORT)
m.setWakeMessage("__START_BREAK_BLOCKS__")

local function message()
    local t, _, from, port, _, msg, a1, a2, a3 = computer.pullSignal(SLEEP)
    if t ~= "modem_message" or from == m.address then return nil end
    return from, port, msg, a1, a2, a3
end

local function handleMessage()
    local from, port, msg, a1, a2, a3 = message()
    if from ~= nil and msg ~= nil and signals[msg] ~= nil then
        signals[msg](from, port, a1, a2, a3)
    end
end

signals["filler-discover"] = function(from, port, a1, a2, a3)
    m.send(from, port, "reply-discover")
end

signals["filler-start"] = function(from, port, a1, a2, a3)
    working = true
    workDone = false
    r.setOutput(OUTPUT, 15)

    while working do
        local type, _, side, _, val = computer.pullSignal(SLEEP)
        if type == "redstone_changed" and side == INPUT and val > 0 then
            working = true
            workDone = true
            r.setOutput(OUTPUT, 0)
            while working do
                pcall(handleMessage)
                m.send(from, port, "filler-done")
            end
        end
    end
    for i = 0, 5 do r.setOutput(i, 0) end
end

signals["ack"] = function(from, port, a1, a2, a3)
    working = false
end

signals["filler-stop"] = function(from, port, a1, a2, a3)
    working = false
end

signals["filler-query"] = function(from, port, a1, a2, a3)
    m.send(from, port, working, workDone)
end

signals["filler-shutdown"] = function(from, port, a1, a2, a3)
    r.setOutput(OUTPUT, 0)
    computer.shutdown()
end

local function main()
    while true do handleMessage() end
end

while true do pcall(main) end
