local reader = require("common.list_reader")
local setting = require("server.setting")
local roles = require("server.interface_type")

local chooser = {}

function chooser.chooseRole()
    local keyList, selected = reader.show(
        setting.getRoles(),
        function(key, _) return key end,
        function(key, value) return string.format("%s (%s)", key, value) end
    )
    if selected == 0 then return nil end
    return keyList[selected]
end

function chooser.chooseProcess()
    local choosed = {}
    while true do
        local role = chooser.chooseRole()
        if role == nil then
            io.write("是否选择完毕?\n> ")
            local ans = io.read()
            if ans ~= "n" then
                return choosed
            end
        else
            io.write(string.format("你选择了 '%s' , 是否确定？\n> ", role))
            local ans = io.read()
            if ans ~= "n" then
                table.insert(choosed, role)
            end
        end
    end
end

function chooser.chooseProcessWithCheck()
    local choosed = chooser.chooseProcess()
    for i, role in pairs(choosed) do
        if i == 1 and roles[setting.getRole(role)].self == nil then
            print(string.format("%s职责所属机器类型为%s，无法为矿物处理的开头。", role, setting.getRole(role)))
            return nil
        end
        if i ~= 1 and roles[setting.getRole(role)].self == nil and roles[setting.getRole(role)][setting.getRole(choosed[i - 1])] == nil then
            print(string.format("%s职责所属机器类型为%s，无法处理上一个机器类型为%s类型的%s职责接口的产物。", role, setting.getRole(role), setting.getAddressName(choosed[i - 1]), setting.getRole(choosed[i - 1])))
            return nil
        end
    end
    return choosed
end


return chooser
