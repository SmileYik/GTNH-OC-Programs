local template = {}

-- 模板列表, 使用 # 符号在末尾筛选物品名称
template["%s矿石"] = {
    "%s Ore",
    "Raw %s Ore",
    "%s Infused Stone",
    "%s Sand#gregtech:gt.blockores",
    "Raw %s Sand Ore"
}

template["粉碎的%s矿石"] = {
    "Crushed %s Ore",
    "Crushed %s Crystals",
    "Ground %s Sand",
    "Ground %s"
}

template["洗净的%s矿石"] = {
    "Purified %s Ore",
    "Purified %s Crystals",
    "Purified %s Sand"
}

template["离心%s矿石"] = {
    "Centrifuged %s Ore",
    "Centrifuged %s Crystals",
    "Centrifuged %s Sand"
}

template["未处理%s粉"] = {
    "Impure Pile of %s Dust",
    "Purified Pile of %s Dust",
    "Impure Pile of %s Crystal Powder",
    "Purified Pile of %s Crystal Powder",
    "Impure Pile of %s Sand",
    "Purified Pile of %s Sand",
    "Impure Pile of %s",
    "Purified Pile of %s"
}

template["%s粉"] = {
    "%s#gregtech:gt.metaitem.01",
    "%s Dust#gregtech:gt.metaitem.01",
    "%s Crystal Powder#gregtech:gt.metaitem.01",
    "%s Sand#gregtech:gt.metaitem.01"
}

-- 职责列表
-- 制定每个职责下应该筛选的物品列表, self 代表仅为本职责下应该干什么,
-- 如果键为其他职责的名字, 则代表如果上一个职责是 xxx 时, 本职责下应该干什么. 

local roles = {}

roles["洗矿机"] = {
    self = template["粉碎的%s矿石"]
}
roles["粉碎机"] = {
    self = template["%s矿石"],
    ["粉碎机"] = template["粉碎的%s矿石"],
    ["洗矿机"] = template["洗净的%s矿石"],
    ["热力离心机"] = template["离心%s矿石"],
}
roles["离心机"] = {
    self = template["未处理%s粉"],
    ["离心机"] = template["%s粉"],
}
roles["筛选机"] = {
    self = template["洗净的%s矿石"]
}
roles["热力离心机"] = {
    ["粉碎机"] = template["粉碎的%s矿石"],
    ["洗矿机"] = template["洗净的%s矿石"]
}
roles["电解机"] = {
    self = template["%s粉"]
}
roles["矿物粉"] = {
    self = template["%s粉"]
}

return roles