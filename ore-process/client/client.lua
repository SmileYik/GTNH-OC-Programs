local component = require("component")
local computer = require("computer")
local serialization = require("serialization")
local modem = component.modem

local config = require("config")

local filter = false
local sleepTime = config.client.sleepTick
local runningFlag = true

modem.open(config.network.port)

local worker = {}
local commands = {}

-- command = {
--     name = "abc",
--     data = ???
-- }

local function pullModem(timeout)
    local t, _, from, port, _, msg, a1, a2, a3 = computer.pullSignal(timeout)
    if t == "modem_message" and from ~= modem.address and msg then
        local message, exceptions = serialization.unserialize(msg)
        if not message then print(exceptions)
        elseif message.name and commands[message.name] then
            pcall(commands[message.name], from, port, message)
        end
    end
end

local function sleep(duration)
    duration = duration or config.client.sleepTick
    local endTime = computer.uptime() + duration

    while computer.uptime() < endTime do
        local timeout = math.min(config.client.sleepTick, endTime - computer.uptime())
        pullModem(timeout)
    end
end

local function sendMessage(addr, port, table)
    modem.send(addr, port, serialization.serialize(table))
end

local function sendSuccessMessage(addr, port, msg)
    sendMessage(addr, port, { name = "showMessage", data = msg })
end

--- ============================
--- Remote Commands
--- ============================

function commands.getInterfaces(from, port, message)
    print("搜索接口")
    local interfaces = {}
    for address in pairs(component.list("me_interface")) do
        table.insert(interfaces, address)
    end
    sendMessage(from, port, { name = "registerInterfaces", data = interfaces })
end

function commands.setFilterStatus(from, port, message)
    filter = message.data.status
    worker.setWorking(filter)
    sleepTime = config.client.sleepTick
    print("筛选状态：", filter)
    if filter then
        sendSuccessMessage(from, port, "开启筛选")
    else
        sendSuccessMessage(from, port, "停止筛选")
    end
end

function commands.shutdown(from, port, message)
    runningFlag = false
    sendSuccessMessage(from, port, "终端即将终止")
end

function commands.updateRules(from, port, message)
    worker.updateRules(message.data)
    sendSuccessMessage(from, port, "接收且更新物品标签规则")
end

function commands.updateFiles(from, port, message)
    local file = io.open(string.format("/home/%s", message.data.fileName), "w")
    if file ~= nil then
        file:write(message.data.content)
        file:flush()
        file:close()
        print(message.data.fileName .. " 已更新， 请重启机器")
        if message.data.reboot then
            print("即将自动重启")
            os.sleep(0.5)
            computer.shutdown(true)
        end
    else
        print(message.data.fileName .. " 无法更新。")
    end
end

local function main()
    if filter then
        worker.setWorking(filter)
        if worker.work() then
            sleepTime = config.client.sleepTick
        else
            sleepTime = math.min(sleepTime * 2, config.client.maxSleepTime)
        end
    end
    sleep(sleepTime)
end

local file = io.open("/home/client/worker.lua")
if file then
    file:close()
    worker = require("client.worker")
    local oriFindSuit = worker.findSuit

    ---find suitable item
    ---@param me any
    ---@param filterItem any
    ---@param rules Rule
    ---@param callback function
    worker.findSuit = function (me, filterItem, rules, callback)
        pullModem(0)
        return oriFindSuit(me, filterItem, rules, callback)
    end
end

while runningFlag do main() end
