local template = {}

-- 模板列表, 使用 # 符号在末尾筛选物品名称
template["%s矿石"] = {
    -- xx 粗矿
    "%s Ore",
    -- 粗 xx 矿砂
    "Raw %s Ore",
    -- xx 附魔石
    "%s Infused Stone",
    -- xx 矿砂
    "%s Sand#gregtech:gt.blockores",
    -- 粗 xx 矿砂
    "Raw %s Sand Ore",
    -- xx 矿沙砾
    "%s Gravel Ore"
}

template["粉碎的%s矿石"] = {
    -- 粉碎的xx矿石
    "Crushed %s Ore",
    -- 粉碎的xx宝石
    "Crushed %s Crystals",
    -- 精研的xx矿砂
    "Ground %s Sand",
    -- 精研的xx
    "Ground %s"
}

template["洗净的%s矿石"] = {
    -- 洗净的%s矿石
    "Purified %s Ore",
    -- 洗净的%s宝石
    "Purified %s Crystals",
    -- 洗净的 xx 矿砂
    "Purified %s Sand"
}

template["离心%s矿石"] = {
    -- 离心的 xx 矿石
    "Centrifuged %s Ore",
    -- 离心的 xx 宝石
    "Centrifuged %s Crystals",
    -- 离心的 xx 矿砂
    "Centrifuged %s Sand"
}

template["未处理%s粉"] = {
    -- 未处理的xx粉
    "Impure Pile of %s Dust",
    -- 已净化的xx粉
    "Purified Pile of %s Dust",
    -- 未处理的xx宝石粉
    "Impure Pile of %s Crystal Powder",
    -- 已净化的xx宝石粉
    "Purified Pile of %s Crystal Powder",
    -- 未处理的xx矿砂
    "Impure Pile of %s Sand",
    -- 已净化的xx矿砂
    "Purified Pile of %s Sand",
    -- 未处理的xx
    "Impure Pile of %s",
    -- 已净化的xx
    "Purified Pile of %s"
}

template["%s粉"] = {
    -- xx粉
    "%s#gregtech:gt.metaitem.01",
    -- xx粉
    "%s Dust#gregtech:gt.metaitem.01",
    -- xx宝石粉
    "%s Crystal Powder#gregtech:gt.metaitem.01",
    -- xx矿砂
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