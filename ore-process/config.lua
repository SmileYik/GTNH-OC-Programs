local config = {
    network = {
        port = 16500,
    },
    client = {
        sleepTick = 0.5,
        maxSleepTime = 60,
    },
    server = {
        configFile = "/home/ore.config"
    },
    debug = {
        enable = false,
        level = 1,
        printToScreen = false,
        saveToFile = "/home/debug.log"
    }
}

return config