local SLEEP = 1
local OUTPUT = 0
local TARGET_NAME = "AWWayofTime:activationCrystal"
local PORT = 10000
local MAX_FILLER = 8
local DISCOVER_TIMEOUT = 5
local WEAKUP = "__START_BREAK_BLOCKS__"

local COLOR_FREE = 0x0000FF
local COLOR_MINE = 0x00FF00
local COLOR_FILLER = 0xFFFF00
local COLOR_DISCOVER_FILLER = 0xFF4488
local COLOR_NOLP = 0xFF8000

local c = component
local proxy = function(name) return c.proxy(c.list(name)()) end
local r, ic, m = proxy("robot"), proxy("inventory_controller"), proxy("modem")
local color = r.setLightColor
local iItem = ic.getStackInInternalSlot
c = computer
local cTime, cSignal = c.uptime, c.pullSignal

local signals, filler = {}, {}
local mineWorking, fillerWorking = false, false

m.open(PORT) m.setWakeMessage(WEAKUP) m.broadcast(PORT, WEAKUP)

local function message()
  local t, _, from, port, _, msg, a1, a2, a3 = cSignal(SLEEP)
  if t ~= "modem_message" or from == m.address then return nil end
  if msg ~= nil and signals[msg] ~= nil then signals[msg](from, port, a1, a2, a3) end
end

local function sleep(time, callback)
  if callback == nil then callback = function() cSignal(SLEEP) end end
  time = time + cTime()
  while cTime() < time and true ~= callback() do end
end

local function reset()
  local item = iItem()
  if item ~= nil and item.name == TARGET_NAME then return end
  for i = 1, r.inventorySize() do
    item = iItem(i)
    if item ~= nil and item.name == TARGET_NAME then
      r.select(i) ic.equip() break
    end
  end
end

local function tryToCheckLP()
  local lp, maxLP, found = 0, 0, false
  for i=1,r.inventorySize() do
    local item = iItem(i)
    if item ~= nil and item.networkEssence then
      found = true
      lp = math.max(lp, item.networkEssence)
      maxLP = math.max(maxLP, item.maxNetworkEssence)
    end
  end
  return found, lp >= maxLP, lp, maxLP
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
    if iItem(i) ~= nil then r.select(i) end
  end
end

local function trySpawn()
  local result, side, idx = hasNext()
  local foundLP, enoughLP = tryToCheckLP()
  if foundLP and not enoughLP then result = false color(COLOR_NOLP) end
  if result then
    reset() r.use(OUTPUT)
    if not r.suck(side, 1) then return end
    selectFirst() r.drop(OUTPUT, 1)
    sleep(15)

    color(COLOR_MINE)
    mineWorking = true
    m.broadcast(PORT, "mine-start")
    while mineWorking do message() end
    
    if MAX_FILLER > 0 then
      for _ = 1, 5 do
        color(COLOR_FILLER)
        fillerWorking = true
        for k in pairs(filler) do filler[k] = false end
        m.broadcast(PORT, WEAKUP)
        m.broadcast(PORT, "filler-start")
        while fillerWorking do message() end
      end
    end
  end
end

signals["mine-done"] = function (from, port, ...)
  mineWorking = false
  m.send(from, port, "ack")
end

signals["filler-done"] = function (from, port, ...)
  filler[from] = true
  local flag = true
  m.send(from, port, "ack")
  for _, v in pairs(filler) do
    if not v then flag = false break end
  end
  if flag then fillerWorking = false end
end
signals["reply-discover"] = function (from, port, a1, a2, a3) filler[from] = false end

local function main()
  color(COLOR_DISCOVER_FILLER)
  local flag = true
  while flag do
    m.broadcast(PORT, "filler-discover")
    filler = {}
    sleep(DISCOVER_TIMEOUT, function()
      message()
      local i = 0
      for _ in pairs(filler) do i = i + 1 end
      if i >= MAX_FILLER then flag = false return true end
    end)
    if next(filler) ~= nil then break end
  end
  while true do color(COLOR_FREE) trySpawn() sleep(SLEEP) end
end
while true do pcall(main) end