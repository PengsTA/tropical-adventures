local M = {}

-- Unlike DST explosive:OnBurnt, this leaves the source alive for its loot timeline.
function M.Apply(inst, damage, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, radius, nil, { "INLIMBO", "notarget" })
    for _, target in ipairs(targets) do
        if target ~= inst and target:IsValid() then
            local workable = target.components.workable
            if workable ~= nil and workable:CanBeWorked() then
                workable:WorkedBy(inst, 10)
            end
            if target:IsValid() then
                local combat, health = target.components.combat, target.components.health
                if combat ~= nil and combat:CanBeAttacked() and (health == nil or not health:IsDead()) then
                    local resistance = target.components.explosiveresist
                    local dealt = resistance and damage * (1 - resistance:GetResistance()) or damage
                    if resistance ~= nil then resistance:OnExplosiveDamage(dealt, inst) end
                    combat:GetAttacked(inst, dealt)
                end
                target:PushEvent("explosion", { explosive = inst })
            end
        end
    end
    if TheWorld.components.dockmanager ~= nil then
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, damage)
    end
    TheWorld:PushEvent("explosion", { damage = damage })
end

return M
