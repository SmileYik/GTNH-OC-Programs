local SLEEP = 1
local PORT = 10000

local m = component.proxy(component.list("modem")())
local signals = {}
local working = false

m.open(PORT)
m.setWakeMessage("__START_BREAK_BLOCKS__")

local function message()
  local t, _, from, port, _, msg, a1, a2, a3 = computer.pullSignal(SLEEP)
  if t ~= "modem_message" or from == m.address then return nil end
  return from, port, msg, a1, a2, a3
end

local function handleMessage()
  local from, port, msg, a1, a2, a3 = message()
  if from ~= nil and msg ~= nil and signals[msg] ~= nil then
    signals[msg](from, port, a1, a2, a3)
  end
end

signals["mine-start"] = function(from, port, a1, a2, a3)
  working = true
  for addr in component.list("gt_machine") do
    component.proxy(addr).setWorkAllowed(true)
  end

  while working do
    pcall(handleMessage)

    local flag = true
    for addr in component.list("gt_machine") do
      if component.proxy(addr).hasWork() then
        flag = false
        break
      end
    end

    while flag and working do
      pcall(handleMessage)
      m.send(from, port, "mine-done")
    end
  end
end

signals["ack"] = function(from, port, a1, a2, a3)
  working = false
end

local function main()
  while true do handleMessage() end
end

while true do pcall(main) end
