local config = require("config")

local mod = {}

local isDebug  = config.debug and config.debug.enable
local dbgLevel = (config.debug and config.debug.level) or 0
local printable = (config.debug and config.debug.printToScreen) or false
local saveToFile = nil
if config.debug and config.debug.saveToFile then
    saveToFile = config.debug.saveToFile
    local file = io.open(saveToFile, "a")
    if file then
        file:close()
    else
        saveToFile = nil
    end
end

---@param message string message
---@param ... any paramas
local function empty(message, ...) end

local function printToFile(filepath, message)
    local file = io.open(filepath, "a")
    if file then 
        file:write(message)
        file:write("\n")
        file:flush()
        file:close()
    end
end

local function createLogger(prefix)
    local computer = require("computer")
    ---@param message string message
    ---@param ... any paramas
    return function(message, ...)
        local trace = debug.getinfo(3, "Sl")
        local src = trace and trace.short_src or "unknown"
        local line = trace and trace.currentline or 0

        if src:sub(1, 1) == "@" then
            src = src:sub(2)
        end

        local success, formattedMessage = pcall(string.format, message, ...)
        if not success then
            formattedMessage = "[日志格式化失败]: " .. tostring(message)
        end

        local timeStr = string.format("%s (Up: %.2fs)", os.date("%H:%M:%S"), computer.uptime())
        local msg = string.format("[%-24s] %-10s [%s:%d] %s", timeStr, prefix, src, line, formattedMessage)
        if printable then
            print(msg)
        end
        if saveToFile then
            pcall(printToFile, saveToFile, msg)
        end
    end
end

mod.info   = (isDebug and dbgLevel >= 1) and createLogger("[INFO]")   or empty
mod.warn   = (isDebug and dbgLevel >= 2) and createLogger("[WARN]")   or empty
mod.sereve = (isDebug and dbgLevel >= 3) and createLogger("[SEVERE]") or empty
mod.debug  = (isDebug and dbgLevel >= 4) and createLogger("[DEBUG]")  or empty

return mod