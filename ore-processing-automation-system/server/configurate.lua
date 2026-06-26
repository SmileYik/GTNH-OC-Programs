local reader = require("common.list_reader")

local setting = require("server.setting")
local roles = require("server.interface_type")
local config = {}

function config.configurateRole(role, first)
    if first == nil then first = false end
    while first or setting.getRole(role) == nil do
        first = false
        print("请在下一个界面中，选择职责类型")
        os.sleep(1)
        local keyList, selected = reader.show(
            roles,
            function(key, _) return key end,
            function(key, _) return key end
        )
        if selected == 0 then
            print("必须选择一种类型")
            _ = io.read()
        else
            io.write(string.format("确定将%s职责所对应的机器类型设置为%s吗?\n> ", role, keyList[selected]))
            if io.read() ~= "n" then
                setting.setRole(role, keyList[selected])
            end
        end
    end
    setting.store()
end

function config.configurateInterface(address)
    print(string.format("即将设置接口%s的职责", address))
    os.sleep(1)
    local list = {address}
    for key, _ in pairs(setting.getRoles()) do
        table.insert(list, key)
    end
    local _, choosed = reader.showList(list)
    local role = address
    if choosed == 0 then
        io.write("输入职责名\n> ")
        role = io.read()
    else
        role = list[choosed]
    end

    if setting.getRole(role) == nil then
        config.configurateRole(role)
    end

    setting.setInterfaceRole(address, role)
    setting.store()
    print(string.format("已将ME接口%s的职责设置为‘%s’", address, role))
end

return config
