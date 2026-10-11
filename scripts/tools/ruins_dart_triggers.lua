local function Trigger(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local traps = TheSim:FindEntities(x, y, z, 50, { "dartthrower" },
        { "INTERIOR_LIMBO", "ta_cave_ruins_trap" })
    for _, trap in ipairs(traps) do
        if trap:IsValid() and trap.shoot ~= nil then
            trap:shoot()
        end
    end

    local cave_traps = TheSim:FindEntities(x, y, z, 12, { "ta_cave_ruins_trap" }, { "INLIMBO" })
    for _, trap in ipairs(cave_traps) do
        if trap:IsValid() and not trap._ruins_owner then
            if trap.TriggerBurst then
                trap:TriggerBurst()
            elseif trap.components.autodartthrower then
                trap.components.autodartthrower:TurnOn()
            elseif trap:HasTag("spear_trap") then
                trap:PushEvent("triggertrap")
            end
        end
    end
end

return { Trigger = Trigger }
