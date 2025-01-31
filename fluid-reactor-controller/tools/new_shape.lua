local component = require("component")
local reactor = require("./commons/reactor")
local shape = require("./commons/shape")
local reader = require("./tools/list_reader")

local reactors = reactor.load()
if reactors == nil then
    print("没有记录任何一个反应堆")
    return
end

io.write("请在下个界面中选择需要记录元件布局的反应堆，按回车键继续下一步\n> ")
io.read()

local keyList, selected = reader.show(
    reactors,
    function(k, _) return k end,
    function(k, _) return k end
)

if selected ~= nil and selected ~= 0 and keyList[selected] ~= nil then
    local key = keyList[selected]

    local tr = component.proxy(reactors[key].accessPort)
    if tr == nil then
        print("无法找到所选反应堆的物品交互转运器")
        return
    end
    io.write("请输入该元件布局名称\n> ")
    local name = io.read()
    print("元件布局记录结果：", shape.record(name, tr.address))
end
