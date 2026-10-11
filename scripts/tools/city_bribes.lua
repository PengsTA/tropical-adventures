local M = {}

function M.Accept(inst, giver, item, value, threshold)
    if value == nil or giver == nil or not giver:HasTag("player")
        or not inst:HasTag("angry_at_player") then
        return false
    end
    local stackable = item.components.stackable
    inst.bribe_count = (inst.bribe_count or 0) + value * (stackable and stackable:StackSize() or 1)
    if inst.bribe_count >= threshold then
        inst:RemoveTag("angry_at_player")
        local combat = inst.components.combat
        if combat ~= nil and combat.target == giver then
            combat:GiveUp()
        end
        inst.bribe_count = 0
        return true, true
    end
    return true, false
end

return M
