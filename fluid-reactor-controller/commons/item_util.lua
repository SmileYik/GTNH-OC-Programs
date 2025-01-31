local itemUtil = {
    SPLIT_CHAR = "#"
}

local function split(str, chrs)
    local ret = {} string.gsub(str, "[^"..chrs.."]+", function(s) table.insert(ret, s) end) return ret
end

function itemUtil.getId(item)
	if item == nil or item == "" or item == "nil" then return nil end
	return item.name .. itemUtil.SPLIT_CHAR .. item.damage
end

function itemUtil.getItemFromId(id)
	local meta = split(id, itemUtil.SPLIT_CHAR)
	return {
        name = meta[1],
        damage = meta[2]
	}
end

return itemUtil;
