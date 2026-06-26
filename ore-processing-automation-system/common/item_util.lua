local mod = {
    SPLIT_CHAR = ":"
}

---get item from item name id. item id like "namespace:name:damage" or "name:damage"
---@param id string item id like "namespace:name:damage" or "name:damage"
---@return table|nil
function mod.getItemFromId(id)
    if not id then return nil end

    local name, damage = string.match(id, "^(.-)[%#%:]([+-]?%d+)$")
    if name and damage then
        return { name = name, damage = tonumber(damage) }
    end
    return { name = id, damage = 0 }
end

---item table to item id
---@param item table|nil
---@return nil|string
function mod.getId(item)
    if item == nil then return nil end
    return item.name .. mod.SPLIT_CHAR .. (item.damage or 0)
end

return mod