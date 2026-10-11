local VALUES = require("datadefs/volcano_offerings")
local DEFAULT_WRATH = -8

local function GetValue(item)
    if item == nil or item.components == nil or item.components.inventoryitem == nil
        or item:HasTag("irreplaceable") then
        return nil
    end
    -- Trader deletes accepted items before onaccept; do not test IsValid here.
    return VALUES[item.prefab] or DEFAULT_WRATH
end

return { GetValue = GetValue }
