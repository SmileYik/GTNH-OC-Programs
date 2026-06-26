local config = {
    -- 网络配置
    network = {
        -- 网络通信端口, 避免与其他系统使用同一个端口.
        port = 16500,
    },
    -- 客户端配置
    client = {
        -- 睡眠片时间, 单位秒
        sleepTick = 0.5,
        -- 最大睡眠时间, 单位秒
        maxSleepTime = 60,
    },
    -- 服务器设置
    server = {
        -- 矿物筛选配置文件路径
        configFile = "/home/ore.config"
    },
    -- 调试设置
    debug = {
        -- 是否启用debug日志
        enable = false,
        -- 显示 debug 日志的等级.
        --   1 - 信息
        --   2 - 警告
        --   3 - 严重
        --   4 - 调试
        -- 当设置 0 时为不显示任何日志信息.
        -- 当设置 1 时为仅显示信息级别的日志信息.
        -- 当设置 2 时为仅显示信息级别以及警告级别的日志信息.
        level = 1,
        -- 日志是否打印到屏幕中
        printToScreen = false,
        -- 日志存储的文件路径, 若设置空则不输出日志到文件中.
        saveToFile = "/home/debug.log"
    }
}

return config
