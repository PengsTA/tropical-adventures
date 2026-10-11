local BoatEquip = require("tools/boat_equipment_helper")

local BoatRepairHelper = {}

function BoatRepairHelper.IsRepairItem(item)
    return item ~= nil and item.HasTag ~= nil and item:HasTag("boatrepairkit")
end

function BoatRepairHelper.IsBoatTarget(target)
    return target ~= nil
        and target.HasTag ~= nil
        and target:HasTag("boatsw")
end

function BoatRepairHelper.ResolveTarget(target)
    return target
end

function BoatRepairHelper.IsRepairableBoat(boat)
    return boat ~= nil
        and boat.IsValid ~= nil
        and boat:IsValid()
        and boat.components ~= nil
        and boat.components.boathealth ~= nil
end

function BoatRepairHelper.GetActionTarget(doer, target)
    local boat = target ~= nil and BoatRepairHelper.ResolveTarget(target) or nil
    if not BoatRepairHelper.IsRepairableBoat(boat) then
        boat = BoatEquip.GetBoatForDoer(doer)
    end
    return BoatRepairHelper.IsRepairableBoat(boat) and boat or nil
end

local function IsHeldByDoer(inst, doer)
    if inst == nil or doer == nil then
        return false
    end

    local invItem = inst.components ~= nil and inst.components.inventoryitem or nil
    if invItem ~= nil and invItem.IsHeldBy ~= nil then
        return invItem:IsHeldBy(doer)
    end

    local replicaInvItem = inst.replica ~= nil and inst.replica.inventoryitem or nil
    return replicaInvItem ~= nil and replicaInvItem:IsHeldBy(doer) or false
end

function BoatRepairHelper.IsCurrentBoatTarget(target, doer)
    local boat = BoatEquip.GetBoatForDoer(doer)
    return boat ~= nil
        and target ~= nil
        and target == boat
end

function BoatRepairHelper.ShouldAddUseItemAction(inst, doer, target)
    if target == nil then
        return false
    end

    return BoatRepairHelper.IsRepairItem(inst)
        and (BoatRepairHelper.IsBoatTarget(target)
            or BoatRepairHelper.IsCurrentBoatTarget(target, doer))
end

function BoatRepairHelper.ShouldAddInventoryAction(inst, doer)
    return BoatRepairHelper.IsRepairItem(inst)
        and doer ~= nil
        and BoatEquip.GetBoatForDoer(doer) ~= nil
end

function BoatRepairHelper.AddUniqueAction(actions, action)
    for _, existing in ipairs(actions) do
        if existing == action then
            return false
        end
    end
    table.insert(actions, action)
    return true
end

function BoatRepairHelper.ConsumeItem(item)
    if item == nil then
        return
    end

    if item.components.stackable ~= nil then
        item.components.stackable:Get():Remove()
    elseif item.components.finiteuses ~= nil then
        item.components.finiteuses:Use(1)
    else
        item:Remove()
    end
end

return BoatRepairHelper
