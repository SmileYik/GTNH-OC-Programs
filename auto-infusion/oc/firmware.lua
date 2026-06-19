local SLEEP = 0.05
local RS_IN = 0

local rs = component.proxy(component.list("redstone")())
local rb = component.proxy(component.list("robot")())
local ic = component.proxy(component.list("inventory_controller")())


local function main()
    if rs.getInput(RS_IN) == 0 then return end
    while true do
        ic.equip()
        rb.use(0)
        ic.equip()
        rb.use(3)
        if rs.getInput(RS_IN) == 0 then break end
    end
end

while true do pcall(main) computer.pullSignal(SLEEP) end