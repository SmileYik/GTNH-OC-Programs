local event = require("event")

local monitor = require("./monitor/monitor")

-- event.timer(0.05, monitor.tick, math.huge)
while true do
    if not monitor.tick() then break end
    os.sleep(0.1)
end
