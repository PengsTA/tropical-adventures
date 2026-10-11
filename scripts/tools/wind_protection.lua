local M = {}

function M.Get(inventory)
    if inventory == nil then return 0 end
    if inventory.GetWindproofness ~= nil then return inventory:GetWindproofness() or 0 end
    local protection = 0
    for _, item in pairs(inventory.equipslots) do
        local windproofer = item.components.windproofer
        if windproofer ~= nil then protection = protection + windproofer:GetEffectiveness() end
    end
    return math.min(1, protection)
end

return M
