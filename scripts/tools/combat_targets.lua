local M = {}

function M.GetAttacker(data)
    local attacker = data and data.attacker
    if attacker ~= nil and attacker.prefab == "deciduous_root" then
        attacker = attacker.owner
        if attacker ~= nil and not attacker:IsValid() then
            return nil
        end
    end
    return attacker
end

return M
