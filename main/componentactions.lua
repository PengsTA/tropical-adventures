local AddComponentAction = AddComponentAction
local ACTIONS = ACTIONS
local BoatEquip = require("tools/boat_equipment_helper")
local BoatRepair = require("tools/boat_repair_helper")


AddComponentAction("SCENE", "hackable", function(inst, doer, actions, right)
    local equipamento = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not right then
        if equipamento and equipamento:HasTag("machete") and not (doer.replica.rider:IsRiding()) then
            table.insert(actions, ACTIONS.HACK1)
        end
    end
end)


AddComponentAction("SCENE", "melter", function(inst, doer, actions, right)
    if not inst:HasTag("burnt") then
        if right and not inst:HasTag("alloydone") and inst.replica.container ~= nil and inst.replica.container:IsFull() then
            table.insert(actions, ACTIONS.SMELT)
        elseif not right and inst:HasTag("alloydone") then
            table.insert(actions, ACTIONS.HARVEST)
        end
    end
end)

-------------------------------------------
AddComponentAction("SCENE", "dislodgeable", function(inst, doer, actions, right)
    local equipamento = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not right then
        if equipamento and equipamento:HasTag("ballpein_hammer") and inst:HasTag("dislodgeable") and
            not (doer.replica.rider:IsRiding()) then
            table.insert(actions, ACTIONS.DISLODGE)

            return
        end
    end
end)

-- AddComponentAction("SCENE", "breeder", function(inst, doer, actions, right)
--     if not right then
--         if inst.components.breeder and inst.components.breeder.volume > 0 then
--             table.insert(actions, ACTIONS.HARVEST)
--             return
--         end
--     end
-- end)


AddComponentAction("SCENE", "mystery", function(inst, doer, actions, right)
    if not right then
        local equipamento = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equipamento and equipamento:HasTag("magnifying_glass") and
            not (doer.replica.rider:IsRiding()) then
            table.insert(actions, ACTIONS.INVESTIGATEGLASS)
        end
    end
end)


AddComponentAction("SCENE", "interactions", function(inst, doer, actions, right)
    if not right then
        if inst:HasTag("boatsw") and not inst:HasTag("boat_occupied") and
            not (doer.replica.rider:IsRiding())
        then
            table.insert(actions, ACTIONS.BOATMOUNT)
        end
    else
        if not inst:HasTag("boat_occupied") and (inst.prefab == "surfboard" or inst.prefab == "corkboat") then
            table.insert(actions, ACTIONS.RETRIEVE)
        end

        if inst.prefab == "fish_farm" then
            -- if inst.components.breeder and inst.components.breeder.volume > 0 then
            table.insert(actions, ACTIONS.RETRIEVE)
            return
        end
    end
end
)

AddComponentAction("SCENE", "health",
    function(inst, doer, actions, right)
        local containedsail = doer.replica.sailor ~= nil and doer.replica.sailor:GetBoat() or nil
        local cannon = BoatEquip.GetHead(BoatEquip.GetBoatContainer(containedsail))
        if right and doer:HasTag("aquatic") and cannon ~= nil and cannon:HasTag("sw_boatcannon") and
            not (doer.replica.rider:IsRiding() or doer.replica.inventory:IsHeavyLifting() or doer:HasTag("deleidotiro")) then
            table.insert(actions, ACTIONS.BOATCANNON)
        end
    end)

AddComponentAction("SCENE", "shopped", function(inst, doer, actions, right)
    if not right then
        if doer.components.shopper then
            table.insert(actions, ACTIONS.SHOP)
        end
    end
end)


local function AddBoatRepairAction(inst, doer, target, actions)
    if BoatRepair.ShouldAddUseItemAction(inst, doer, target) then
        BoatRepair.AddUniqueAction(actions, ACTIONS.BOATREPAIR)
        return true
    end
    return false
end

AddComponentAction("USEITEM", "interactions", function(inst, doer, target, actions, right)
    AddBoatRepairAction(inst, doer, target, actions)
end)

AddComponentAction("USEITEM", "equippable", function(inst, doer, target, actions, right)
    AddBoatRepairAction(inst, doer, target, actions)
end)

AddComponentAction("USEITEM", "sailable", function(inst, doer, target, actions, right)
    AddBoatRepairAction(inst, doer, target, actions)
end)

AddComponentAction("USEITEM", "boathealth", function(inst, doer, target, actions, right)
    AddBoatRepairAction(inst, doer, target, actions)
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    local prefab = inst.prefab
    if target.tro_repair ~= nil and target.tro_repair[prefab] ~= nil then
        table.insert(actions, ACTIONS.TROREPAIR)
    end
    if AddBoatRepairAction(inst, doer, target, actions) then
        return
    end
    if not right then
        if target:HasTag("shelfcanaccept") then
            table.insert(actions, ACTIONS.GIVE2)
        end
    end
end)

AddComponentAction("USEITEM", "fuel", function(inst, doer, target, actions, right)
    if not target.components.container then return end
    if right then
        if inst:HasTag("ANCIENT_REMNANT_fuel") and
            target:HasTag("ANCIENT_REMNANT_fueled") then
            RemoveByValue(actions, ACTIONS.STORE)
        end
    else
        if target.components.inventoryitem and not target:IsInLimbo() then
            RemoveByValue(actions, ACTIONS.ADDFUEL)
        end
    end
end)

AddComponentAction("INVENTORY", "interactions", function(inst, doer, actions)
    if inst:HasTag("tunacan") then
        table.insert(actions, ACTIONS.OPENTUNA) ----这个需要修改
    end
    if BoatRepair.ShouldAddInventoryAction(inst, doer) then
        BoatRepair.AddUniqueAction(actions, ACTIONS.BOATREPAIR)
    end
end)

AddComponentAction("INVENTORY", "inventoryitem", function(inst, doer, actions)
    if BoatRepair.ShouldAddInventoryAction(inst, doer) then
        BoatRepair.AddUniqueAction(actions, ACTIONS.BOATREPAIR)
    end
end)

AddComponentAction("INVENTORY", "equippable", function(inst, doer, actions)
    local boat = BoatEquip.GetBoatForDoer(doer)
    local container = BoatEquip.GetBoatContainer(boat)
    if not BoatEquip.HasBoatEquipSlots(container) then
        return
    end

    if not BoatEquip.IsBoatEquipment(inst) then
        return
    end

    local eslot = BoatEquip.GetSlotForItem(inst)
    local is_installed = eslot ~= nil and BoatEquip.GetEquippedItem(container, eslot) == inst
        or inst.entity:GetParent() == boat
    if is_installed then
        RemoveByValue(actions, ACTIONS.EQUIP)
        RemoveByValue(actions, ACTIONS.UNEQUIP)
        RemoveByValue(actions, ACTIONS.BOATEQUIP)
        table.insert(actions, ACTIONS.BOATUNEQUIP)
        return
    end

    RemoveByValue(actions, ACTIONS.EQUIP)
    table.insert(actions, ACTIONS.BOATEQUIP)
end)


AddComponentAction("EQUIPPED", "gasser", function(inst, doer, target, actions, right)
    if right and not (doer.replica.rider:IsRiding() or doer:HasTag("bonked")) then
        table.insert(actions, ACTIONS.GAS)
    end
end)

AddComponentAction("POINT", "gasser", function(inst, doer, pos, actions, right)
    if right then
        table.insert(actions, ACTIONS.GAS)
    end
end)

AddComponentAction("POINT", "equippable", function(inst, doer, pos, actions, right, target)
    if not doer:HasTag("aquatic") then return end

    if right then
        local containedsail = BoatEquip.GetBoatForDoer(doer)
        local cannon = BoatEquip.GetHead(BoatEquip.GetBoatContainer(containedsail))
        if cannon ~= nil and cannon:HasTag("sw_boatcannon") and
            not (doer.replica.inventory:IsHeavyLifting() or doer:HasTag("deleidotiro")) then
            return table.insert(actions, ACTIONS.BOATCANNON)
        end
    else
        if TheWorld.Map:IsPassableAtPoint(pos:Get()) then
            table.insert(actions, ACTIONS.BOATDISMOUNT)
        end
    end

    --ACTIONS.SURF完全触发不了啊
end)

local ARTIFACT_FORBIDDEN = { "beaver", "weremoose", "weregoose", "wonkey" }
AddComponentAction("POINT", "sailable", function(inst, doer, pos, actions, right, target)
    local sailor = doer.replica ~= nil and doer.replica.sailor or nil
    if not right and sailor ~= nil and sailor:GetBoat() == inst and TheWorld.Map:IsPassableAtPoint(pos:Get()) then
        for _, action in ipairs(actions) do
            if action == ACTIONS.BOATDISMOUNT then
                return
            end
        end
        table.insert(actions, ACTIONS.BOATDISMOUNT)
    end
end)


AddComponentAction("INVENTORY", "ironmachine", function(inst, doer, actions)
    if (doer.replica.rider and doer.replica.rider:IsRiding()) or
        not (inst.replica.inventoryitem and inst.replica.inventoryitem:IsHeldBy(doer)) then
        return
    end

    for _, v in pairs(ARTIFACT_FORBIDDEN) do
        if doer:HasTag(v) then return end
    end

    if inst:HasTag("ironmachineon") then
        table.insert(actions, ACTIONS.IRONTURNOFF)
    elseif not doer:HasTag("ironlord") then
        table.insert(actions, ACTIONS.IRONTURNON)
    end
end)
