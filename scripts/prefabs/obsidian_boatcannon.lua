local assets =
{
    Asset("ANIM", "anim/cannon_obsidian.zip"),
    Asset("ANIM", "anim/swap_cannon_pirate.zip"),
}

local prefabs =
{
    "collapse_small",
}

local BoatEquip = require("tools/boat_equipment_helper")

local BOATCANNON_AMMO_COUNT = 12

local function onfinished(inst)
    inst:Remove()
end

local function DetachFromBoat(inst)
    local boat = BoatEquip.GetItemBoat(inst)
    if boat ~= nil then
        boat.AnimState:ClearOverrideSymbol(inst.symboltooverride, inst.build, inst.symbol)
    end
    BoatEquip.ClearItemBoatState(inst)
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cannon_obsidian")
    inst.AnimState:SetBuild("cannon_obsidian")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    inst.build = "swap_cannon_pirate"
    inst.symbol = "swap_cannon"
    inst.symboltooverride = "swap_lantern"
    inst:AddTag("sw_boatcannon")
    inst:AddTag("cannon")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(BOATCANNON_AMMO_COUNT)
    inst.components.finiteuses:SetUses(BOATCANNON_AMMO_COUNT)
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_LAMP
    inst.components.equippable.restrictedtag = "ta_boat_equipment"
    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function()
        return inst.components.thrower ~= nil and inst.components.thrower:GetThrowPoint() or nil
    end
    inst.components.reticule.ease = true

    inst:ListenForEvent("onpickup", DetachFromBoat)
    return inst
end

return Prefab("obsidian_boatcannon", fn, assets, prefabs)
