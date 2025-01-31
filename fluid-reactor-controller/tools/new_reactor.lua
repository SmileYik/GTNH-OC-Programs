local reactor = require("./commons/reactor")

io.write("录入时确保仅有一个反应堆组建接入电脑，确认无误后回车后继续\n> ")
io.read()

io.write("为反应堆命名：")
local name = io.read()

io.write("设定反应堆形状: ")
local shape = io.read()

print("录入结果:", reactor.record(name, shape))
