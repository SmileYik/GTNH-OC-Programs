local roles = {}

local template = {}

template["%s矿石"] = {
    "粗%s矿石",
    "%s矿石",
    "%s蕴魔石",
    "%s矿砂#gregtech:gt.blockores",
    "%s矿沙砾",
}

template["粉碎的%s矿石"] = {
    "粉碎的%s矿石",
    "粉碎的%s蕴魔石",
    "精研%s矿砂"
}

template["洗净的%s矿石"] = {
    "洗净的%s矿石",
    "洗净的%s蕴魔石",
    "洗净的%s矿砂"
}

template["离心%s矿石"] = {
    "离心%s矿石",
    "离心%s蕴魔石",
    "离心%s矿砂"
}

template["未处理%s粉"] = {
    "含杂%s粉",
    "洁净%s粉",
    "含杂%s魔晶粉",
    "洁净%s魔晶粉",
    "洁净%s矿砂",
    "含杂%s矿砂"
}

template["%s粉"] = {
    "%s#gregtech:gt.metaitem.01",
    "%s粉#gregtech:gt.metaitem.01",
}


roles["洗矿机"] = {
    self = template["粉碎的%s矿石"]
}
roles["粉碎机"] = {
    self = template["%s矿石"]
}
roles["粉碎机"]["粉碎机"] = template["粉碎的%s矿石"]
roles["粉碎机"]["洗矿机"] = template["洗净的%s矿石"]
roles["粉碎机"]["热力离心机"] = template["离心%s矿石"]
roles["离心机"] = {
    self = template["未处理%s粉"]
}
roles["筛选机"] = {
    self = template["洗净的%s矿石"]
}
roles["热力离心机"] = {}
roles["热力离心机"]["粉碎机"] = template["粉碎的%s矿石"]
roles["热力离心机"]["洗矿机"] = template["洗净的%s矿石"]
roles["矿物粉"] = {
    self = template["%s粉"]
}
return roles
