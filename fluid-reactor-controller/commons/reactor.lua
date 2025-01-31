local serialization = require("serialization")
local component = require("component")

local reactor = {
    SAVE_FILE = "./reactors"

}

-- local reactorDara = {
--     name = ""
--     shape = "",
--     accessPort = "", -- address
--     fluidPort = "",  -- address
--     redstonePort = "", -- address
--     me = "" -- address
-- }

local function storeRecord(data)
    local reactors = reactor.load()
    if reactors == nil then reactors = {} end
    reactors[data.name] = data

    local str = serialization.serialize(reactors)
    local file = io.open(reactor.SAVE_FILE, "w")
    if file == nil then return false end
    file:write(str)
    file:flush()
    file:close()
    return true
end

function reactor.load()
    local file = io.open(reactor.SAVE_FILE, "r")
    if file == nil then return nil end
    local str = file:read("*a")
    file:close()
    return serialization.unserialize(str)
end

function reactor.record(name, shape)
    local trs = {}
    local idx = 1
    for address in component.list("transposer") do
        table.insert(trs, address)
        print(idx, address)
        idx = idx + 1
    end
    io.write("哪个转运器紧靠流体: ")
    local i = tonumber(io.read())
    local j = 3 - i
    local data = {
        name = name,
        shape = shape,
        accessPort = trs[j],
        fluidPort = trs[i],
        redstonePort = component.list("reactor_redstone_port")(),
        me = component.list("me_interface")()
    }
    return storeRecord(data)
end

function reactor.recordByInput()
    local data = {
        name = "",
        shape = "",
        accessPort = "", -- address
        fluidPort = "",  -- address
        redstonePort = "", -- address
        me = "" -- address
    }

    io.write("Name: ")
    data.name = io.read()
    io.write("Shape Name: ")
    data.shape = io.read()
    io.write("Access Port Address: ")
    data.accessPort = io.read()
    io.write("Fluid Port Address: ")
    data.fluidPort = io.read()
    io.write("Redstone Port Address: ")
    data.redstonePort = io.read()
    io.write("ME Interface Address: ")
    data.me = io.read()

    return storeRecord(data)
end

return reactor
