local serialization = require("serialization")

local DEBUG = false

return function(msg, ...)
    if type(msg) == "table" and DEBUG then
        print(serialization.serialize(msg))
        return
    end
    if DEBUG then print(string.format(msg, ...)) end
end
