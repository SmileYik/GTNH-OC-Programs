local component = require("component")
local computer = require("computer")
local serialization = require("serialization")

local config = require("config")
local reader = require("common.list_reader")
local debug = require("common.debug")
local setting = require("server.setting")
local chooser = require("server.role_chooser")
local configurate = require("server.configurate")
local ruleSpawner = require("server.rule_spawner")

local modem = component.modem
local WAIT_RESPONSE = 0.05
modem.open(config.network.port)

local interfaceHost = {}

local function getModemMessage(sleep)
    local t, _, from, port, _, message = computer.pullSignal(sleep)
    if t ~= "modem_message" or from == modem.address then return nil end
    debug.debug("Pull [%s] signal, from [%s], port [%d], message: %s", t, from, port, message)
    return from, port, serialization.unserialize(message)
end

local function sendMessage(addr, port, table)
    local message = serialization.serialize(table)
    debug.debug("Sending message to '%s:%d': %s", addr, port, message)
    modem.send(addr, port, message)
end

local function searchInterface()
    local result = {}
    modem.broadcast(config.network.port, serialization.serialize({name = "getInterfaces"}))
    for _ = 1, 100 do
        local from, _, message = getModemMessage(WAIT_RESPONSE)
        if message ~= nil and message.name == "registerInterfaces" then
            for _, address in pairs(message.data) do
                result[address] = from
            end
        end
    end
    return result
end

local function waitResponse()
    for _ = 1, 100 do
        local from, _, message = getModemMessage(WAIT_RESPONSE)
        if message ~= nil and message.name == "showMessage" then
            print(from .. ": " .. message.data)
            break
        end
    end
end

local function clearNodeRules(interfaceAddr, hostAddr)
    sendMessage(hostAddr, config.network.port, { name = "updateRules", data = { method = "clear", address = interfaceAddr } })
    waitResponse()
end

local function updateRules(specificRole)
    ---@type table<string, table<table>>
    local roles = {}
    for iaddr, hostAddr in pairs(interfaceHost) do
        local role = setting.getAddressName(iaddr)
        if role ~= nil then
            roles[role] = roles[role] or {}
            table.insert(roles[role], {iaddr = iaddr, hostAddr = hostAddr})
        end
    end
    if specificRole and roles[specificRole] then
        roles = {[specificRole] = roles[specificRole]}
    end

    for iaddr, hostAddr in pairs(interfaceHost) do
        clearNodeRules(iaddr, hostAddr)
    end

    for ore, list in pairs(setting.getAllProcess() or {}) do
        for role, rule in pairs(ruleSpawner.spawnSingleOreRule(ore, list) or {}) do
            for _, info in ipairs(roles[role] or {}) do
                sendMessage(info.hostAddr, config.network.port, { 
                    name = "updateRules", 
                    data = { method = "addOre", address = info.iaddr, rules = rule } 
                })
                waitResponse()
            end
        end
    end

    local rules = ruleSpawner.spawnNormalRules()
    local sendAddNormalPacket = function (hostAddr, iaddr, rule)
        sendMessage(hostAddr, config.network.port, { 
            name = "updateRules", 
            data = { method = "addNormal", address = iaddr, rules = rule } 
        })
        waitResponse()
    end
    for role, rule in pairs(rules) do
        for _, info in ipairs(roles[role] or {}) do
            sendAddNormalPacket(info.hostAddr, info.iaddr, {whitelist = {ids = rule.whitelist.ids}})
            sendAddNormalPacket(info.hostAddr, info.iaddr, {whitelist = {labels = rule.whitelist.labels}})
            sendAddNormalPacket(info.hostAddr, info.iaddr, {blacklist = {ids = rule.blacklist.ids}})
            sendAddNormalPacket(info.hostAddr, info.iaddr, {blacklist = {labels = rule.blacklist.labels}})
            sendAddNormalPacket(info.hostAddr, info.iaddr, {logicals = rule.logicals})
        end
    end
end

local function setOreProccess()
    local choosed = chooser.chooseProcessWithCheck()
    if choosed == nil then return end
    local str = ""
    for i, role in pairs(choosed) do
        str = str .. role .. " => "
    end
    str = str .. "结束"
    print(string.format("你选择的流程为：%s.", str))
    print("请输入矿石名称，如‘红石矿石’则输入‘红石’，输入空白内容则停止")
    while true do
        io.write("\n> ")
        local ore = io.read()
        if ore == "" then break end
        io.write(string.format("是否将%s矿石制作工艺设置为：%s\n> ", ore, str))
        if io.read() ~= "n" then
            setting.setProcess(ore, choosed)
            setting.store()
            io.write("完成\n")
        end
    end
end

local function viewOreProcess()
    local all = setting.getAllProcessNames()
    local keyList, selected = reader.show(
        all,
        function(key, _) return key end,
        function(key, _) return key end
    )
    if selected == 0 then return end
    io.write("是否查看名单？")
    if io.read() ~= "n" then
        reader.showList(all[keyList[selected]])
    end
end

local function updateFileToClient(fileName)
    local file = io.open("/home/" .. fileName, "r")
    if file == nil then print("无 " .. fileName .. " 文件") return end
    local data = file:read("*a")
    file:close()
    local set = {}
    for _, addr in pairs(interfaceHost) do
        if set[addr] == nil then
            sendMessage(addr, config.network.port, {name = "updateFiles", data = {content = data, fileName = fileName, reboot = true}})
            set[addr] = true
        end
    end
end

local function setIdBlacklist()
    local role = chooser.chooseRole()
    io.write(string.format("已选择‘%s’职责, 输入空数据退出\n", role))
    while true do
        io.write("> ")
        local id = io.read()
        if id == nil or id == "" then break end
        io.write(string.format("输入了 %s, 是否继续\n> ", id))
        if io.read() ~= "n" then
            setting.addIdBlacklist(role, id, true, "")
            setting.store()
            -- updateRules()
        end
    end

end

local function setIdWhitelist()
    local role = chooser.chooseRole()
    io.write(string.format("已选择‘%s’职责, 输入空数据退出\n", role))
    while true do
        io.write("> ")
        local id = io.read()
        if id == nil or id == "" then break end
        io.write(string.format("输入了 %s, 是否继续\n> ", id))
        if io.read() ~= "n" then
            setting.addIdWhitelist(role, id, true, "")
            setting.store()
            -- updateRules()
        end
    end
end

local function printNodes()
    reader.show(interfaceHost, function(key, _) return key end, function(key, val) return string.format("%s: %s, host %s", setting.getAddressName(key), key, val) end)
end

local function init()
    while true do
        local result = searchInterface()
        local unconfig = {}
        local flag = false
        for address, ip in pairs(result) do
            if not setting.isConfigurated(address) then
                unconfig[address] = ip
                flag = true
            end
        end

        if flag then
            local keyList, selected = reader.show(unconfig, function(key, _) return key end, function(key, _) return key end)
            if selected ~= 0 then
                io.write(string.format("是否选中 %s?\n> ", keyList[selected]))
                if io.read() ~= "n" then
                    configurate.configurateInterface(keyList[selected])
                end
            end
        else
            interfaceHost = result
            for iaddr, hostAddr in pairs(interfaceHost) do
                local role = setting.getAddressName(iaddr)
                print(iaddr, hostAddr, role)
            end
            break
        end
    end
end

local function main()
    io.write(
        "1. 设定矿处工艺\t2. 开始筛选\n" ..
        "3. 停止筛选\t4. 配置接口\n" ..
        "5. 查看矿处工艺\t6. 更新终端Woker\n" ..
        "7. 更新终端客户端\t8.上传文件\n" ..
        "9. 设置物品黑名单\t10. 设置物品白名单\n" ..
        "11. 重新搜索节点\t12. 查阅现有节点\n" ..
        "> "
    )
    local input = io.read()
    if input == "0" or input == "exit" then return false
    elseif input == "1" then setOreProccess()
    elseif input == "2" then
        updateRules()
        modem.broadcast(config.network.port, serialization.serialize({name = "setFilterStatus", data = {status = true}}))
    elseif input == "3" then modem.broadcast(config.network.port, serialization.serialize({name = "setFilterStatus", data = {status = false}}))
    elseif input == "5" then viewOreProcess()
    elseif input == "6" then updateFileToClient("client/worker.lua")
    elseif input == "7" then updateFileToClient("client/client.lua")
    elseif input == "8" then io.write("\n> ") updateFileToClient(io.read())
    elseif input == "9" then setIdBlacklist()
    elseif input == "10" then setIdWhitelist()
    elseif input == "11" then init()
    elseif input == "12" then printNodes()
    end
    return true
end

setting.init()
init()

while main() do end