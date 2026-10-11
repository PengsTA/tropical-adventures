local M = { TARGET_TAG = "ta_cave_ruins_trap", RANGE = 9.0, NEAR_DIST = 0.85, FAR_DIST = 1.05 }

local function HasTag(ent, tag)
    if not ent then return false end
    if ent.HasTag then return ent:HasTag(tag) end
    if ent.tags then return ent.tags[tag] or false end
    return false
end

function M.IsWeight(inst)
    return not HasTag(inst, "flying") and not HasTag(inst, "playerghost") and not HasTag(inst, "INLIMBO")
        and not (inst.components.health and inst.components.health:IsDead())
end

function M.GetTargets(inst)
    if inst._ruins_owner then return {} end
    local x, y, z = inst.Transform:GetWorldPosition()
    local range = inst.trap_range or M.RANGE
    local candidates = TheSim:FindEntities(x, y, z, range, { M.TARGET_TAG }, { "INLIMBO" })
    local result = {}
    for _, target in ipairs(candidates) do
        if not target._ruins_owner and (HasTag(target, "dartthrower") or (target.components and target.components.autodartthrower)) then
            table.insert(result, target)
        end
    end
    return result
end

function M.IsActive(target)
    if not target or (target.IsValid and not target:IsValid()) then return false end
    local thrower = target.components and target.components.autodartthrower
    return (thrower and thrower.on) or target._bursttask ~= nil or target.updating == true or target._active == true
end

function M.ActivateTarget(target, inst)
    if not target or (target.IsValid and not target:IsValid()) then return end
    if inst then
        if target._ruins_silencers then
            target._ruins_silencers[inst] = nil
            if next(target._ruins_silencers) ~= nil then
                -- Another plate is still pressing down and keeping this trap silent!
                return
            end
        end
    else
        target._ruins_silencers = nil
    end
    target._active = true
    if target.components and target.components.autodartthrower then
        target.components.autodartthrower:TurnOn()
    elseif target.TriggerBurst then
        target:TriggerBurst()
    elseif target.shootdart then
        target:shootdart()
    elseif target.shoot then
        target:shoot()
    end
end

function M.DeactivateTarget(target, inst)
    if not target or (target.IsValid and not target:IsValid()) then return end
    if inst then
        target._ruins_silencers = target._ruins_silencers or {}
        target._ruins_silencers[inst] = true
    else
        target._ruins_silencers = nil
    end
    target._active = nil
    target.startactive = nil
    if target._bursttask then
        target._bursttask:Cancel()
        target._bursttask = nil
    end
    if target.components and target.components.autodartthrower then
        target.components.autodartthrower:TurnOff()
    end
    target:PushEvent("reset")
end

function M.Activate(inst)
    if inst._ruins_owner then return inst._ruins_owner:Control(inst, "press") end
    local targets = M.GetTargets(inst)
    for _, target in ipairs(targets) do
        M.ActivateTarget(target, inst)
    end
end

function M.Deactivate(inst)
    if inst._ruins_owner then return inst._ruins_owner:Control(inst, "release") end
    local targets = M.GetTargets(inst)
    for _, target in ipairs(targets) do
        M.DeactivateTarget(target, inst)
    end
end

function M.Toggle(inst)
    local targets = M.GetTargets(inst)
    local any_active = false
    for _, target in ipairs(targets) do
        if M.IsActive(target) then
            any_active = true
            break
        end
    end

    if any_active then
        for _, target in ipairs(targets) do
            M.DeactivateTarget(target, inst)
        end
    else
        for _, target in ipairs(targets) do
            M.ActivateTarget(target, inst)
        end
    end
    return not any_active
end

function M.Trigger(inst)
    if inst._ruins_owner then return inst._ruins_owner:Control(inst, "press") end
    return M.Deactivate(inst)
end

function M.Release(inst)
    if inst._ruins_owner then return inst._ruins_owner:Control(inst, "release") end
    return M.Activate(inst)
end

return M
