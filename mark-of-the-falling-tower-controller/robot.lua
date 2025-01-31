local SLEEP = 1
local OUTPUT = 0
local TARGET_NAME = "AWWayofTime:activationCrystal"
local PORT = 10000
local MAX_FILLER = 8
local DISCOVER_TIMEOUT = 5

local COLOR_FREE = 0x0000FF
local COLOR_MINE = 0x00FF00
local COLOR_FILLER = 0xFFFF00
local COLOR_DISCOVER_FILLER = 0xFF4488

local proxy = function(name) return component.proxy(component.list(name)()) end
local r, ic, m = proxy("robot"), proxy("inventory_controller"), proxy("modem")

local signals = {}
local filler = {}
local mineWorking, fillerWorking = false, false

m.open(PORT)
m.setWakeMessage("__START_BREAK_BLOCKS__")
m.broadcast(PORT, "__START_BREAK_BLOCKS__")

local color = r.setLightColor

local function handleMessage()
  local t, _, from, port, _, msg, a1, a2, a3 = computer.pullSignal(SLEEP)
  if t ~= "modem_message" or from == m.address then return nil end
  if msg ~= nil and signals[msg] ~= nil then signals[msg](from, port, a1, a2, a3) end
end

local function sleep(time, callback)
  if callback == nil then callback = function() computer.pullSignal(SLEEP) end end
  time = time + computer.uptime()
  while computer.uptime() < time and true ~= callback() do end
end

local function reset()
  local item = ic.getStackInInternalSlot()
  if item ~= nil and item.name == TARGET_NAME then return end
  for i = 1, r.inventorySize() do
    item = ic.getStackInInternalSlot(i)
    if item ~= nil and item.name == TARGET_NAME then
      r.select(i) 
      ic.equip()
      break
    end
  end
end

local function findChest()
  for i = 0, 5 do
    local result, size = pcall(ic.getInventorySize, i)
    if result and size ~= nil then return i, size end
  end
  return nil
end

local function hasNext()
  local side, size = findChest()
  if side == nil then return false end
  for i = 1, size do
    if ic.getStackInSlot(side, i) then return true, side, i end
  end
  return false
end

local function selectFirst()
  for i = 1, r.inventorySize() do
    if ic.getStackInInternalSlot(i) ~= nil then r.select(i) end
  end
end

local function trySpawn()
  local result, side, idx = hasNext()
  if result then
    reset() r.use(OUTPUT)
    if not r.suck(side, 1) then return end
    selectFirst() r.drop(OUTPUT, 1)
    sleep(15)

    color(COLOR_MINE)
    mineWorking = true
    m.broadcast(PORT, "mine-start")
    while mineWorking do handleMessage() end
    
    if MAX_FILLER > 0 then
      for i = 1, 5 do
        color(COLOR_FILLER)
        fillerWorking = true
        for k in pairs(filler) do filler[k] = false end
        m.broadcast(PORT, "__START_BREAK_BLOCKS__")
        m.broadcast(PORT, "filler-start")
        while fillerWorking do handleMessage() end
      end
    end
  end
end

signals["mine-done"] = function (from, port, a1, a2, a3)
  mineWorking = false
  m.send(from, port, "ack")
end

signals["filler-done"] = function (from, port, a1, a2, a3)
  filler[from] = true
  local flag = true
  m.send(from, port, "ack")
  for _, v in pairs(filler) do
    if not v then 
      flag = false
      break
    end
  end
  if flag then fillerWorking = false end
end

signals["reply-discover"] = function (from, port, a1, a2, a3)
  filler[from] = false
end

local function main()
  color(COLOR_DISCOVER_FILLER)
  local flag = true
  while flag do
    m.broadcast(PORT, "filler-discover")
    filler = {}
    sleep(DISCOVER_TIMEOUT, function() 
      handleMessage(0.01)
      local i = 0
      for key in pairs(filler) do i = i + 1 end
      if i == MAX_FILLER then flag = false return true end
    end)
  end

  while true do
    color(COLOR_FREE)
    trySpawn()
    sleep(SLEEP)
  end
end

while true do pcall(main) end