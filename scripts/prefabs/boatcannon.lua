local assets =
{
    Asset("ANIM", "anim/swap_cannon.zip"),
}

local prefabs =
{
    "cannonshot",
    "collapse_small",
}

local BoatEquip = require("tools/boat_equipment_helper")

local BOATCANNON_AMMO_COUNT = 15

local function onthrowfn(inst)
    if inst.components.finiteuses then
        inst.components.finiteuses:Use()
    end
end

local function canshootfn(inst, pt)
    return inst.components.equippable:IsEquipped()
end

local function DetachFromBoat(inst)
    local boat = BoatEquip.GetItemBoat(inst)
    if boat ~= nil then
        boat.AnimState:ClearOverrideSymbol(inst.symboltooverride, inst.build, inst.symbol)
    end
    BoatEquip.ClearItemBoatState(inst)
end

local function onfinished(inst)
    inst:Remove()
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cannon")
    inst.AnimState:SetBuild("swap_cannon")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    inst.build = "swap_cannon"
    inst.symbol = "swap_cannon"
    inst.symboltooverride = "swap_lantern"
    inst:AddTag("cannon")
    inst:AddTag("sw_boatcannon")
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_LAMP
    inst.components.equippable.restrictedtag = "ta_boat_equipment"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(BOATCANNON_AMMO_COUNT)
    inst.components.finiteuses:SetUses(BOATCANNON_AMMO_COUNT)
    inst.components.finiteuses:SetOnFinished(onfinished)


    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function()
        return inst.components.thrower:GetThrowPoint()
    end
    inst.components.reticule.ease = true

    inst:AddComponent("thrower")
    inst.components.thrower.throwable_prefab = "cannonshot"
    inst.components.thrower.onthrowfn = onthrowfn
    inst.components.thrower.canthrowatpointfn = canshootfn
    inst:ListenForEvent("onpickup", DetachFromBoat)

    return inst
end

return Prefab("common/inventory/boatcannon", fn, assets, prefabs)
