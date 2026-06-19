local SLEEP = 0.01
local MAX_SLEEP = 60
local infusion = require("infusion")

local function main()
    local valid, why = infusion.check()
    if not valid then
        print(why)
--        return
    end

    print("cleaning ... ")
    infusion.cleanItems(5)

    local sleep = SLEEP
    while true do
        if infusion.hasNext() then
            infusion.cleanItems(0.5)
            infusion.craft()
            sleep = SLEEP
        end
        os.sleep(sleep)
        sleep = math.min(sleep * 2, MAX_SLEEP)
    end
end


local result, why = pcall(main)
if not result then
    print(why)
end