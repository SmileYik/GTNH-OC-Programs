local essentia = require("essentia")
local reader = require("./tools/list_reader")

local function newEssentiaFile(name, allEssentia)
    local map = {}
    while true do
        local list, idx = reader.show(allEssentia, function(_, ess) return string.sub(ess.name, 8, #ess.name - 8) end, function(_, ess) return string.sub(ess.name, 8, #ess.name - 8) end)
        if idx == 0 then
            local str = ""
            for k, v in pairs(map) do
                str = string.format("%s%s: %d;", str, k, v)
            end
            print(str)
            io.write("finished?\n> ")
            if io.read() ~= "n" then
                break
            end
        else
            io.write(string.format("you choosed '%s', please type the amount. \n> ", list[idx]))
            local result, amount = pcall(tonumber, io.read())
            if result and amount ~= 0 then
                map[list[idx]] = amount
            end
        end
    end
    essentia.store(name, map)
end

local function main()
    local component = require("component")
    local me = component.me_interface
    local all = me.getEssentiaInNetwork()
    
    print(#all)
    io.write("enter 'exit' to quit.\n")
    while true do
        io.write("enter file name.\n> ")
        local name = io.read()
        if name == "exit" then break end
        newEssentiaFile(name, all)
    end
end

local result, why = pcall(main)
if not result then print(why) end