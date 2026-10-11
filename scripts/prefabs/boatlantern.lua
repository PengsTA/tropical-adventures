local assets =
{
    Asset("ANIM", "anim/swap_lantern_boat.zip"),
    Asset("INV_IMAGE", "boat_lantern_off"),
}

local BoatEquip = require("tools/boat_equipment_helper")

local BOAT_LANTERN_LIGHTTIME = (60 + 120) * 2.6

local prefabs =
{
    "boat_lantern_light",
}

local function fuelupdate(inst)
    if inst._light ~= nil then
        local fuelpercent = inst.components.fueled:GetPercent()
        inst._light.Light:SetIntensity(Lerp(.4, .6, fuelpercent))
        inst._light.Light:SetRadius(Lerp(3, 5, fuelpercent))
        inst._light.Light:SetFalloff(.9)
    end
end

local function SetSwapSymbol(inst, symbol)
    inst.symbol = symbol
    inst.AnimState:OverrideSymbol("swap_lantern", inst.build, symbol)

    local boat = BoatEquip.GetItemBoat(inst)
    if boat ~= nil and boat.components.boatequipment ~= nil then
        boat.components.boatequipment:UpdateVisuals()
    end
end

local function RemoveLight(inst)
    if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
    end
end

local function RefreshLightParent(inst)
    if inst._light ~= nil and inst._light:IsValid() then
        local owner = inst.components.inventoryitem.owner
        inst._light.entity:SetParent((owner or inst).entity)
    end
end

local function TurnOn(inst)
    if inst.components.fueled:IsEmpty() then
        inst.components.equippable:ToggleOff()
        return
    end

    inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
    if not inst.SoundEmitter:PlayingSound("boatlamp") then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boatlantern_lp", "boatlamp")
    end

    inst.components.fueled:StartConsuming()
    if inst._light == nil or not inst._light:IsValid() then
        inst._light = SpawnPrefab("boat_lantern_light")
        if inst._light ~= nil then
            fuelupdate(inst)
        end
    end

    RefreshLightParent(inst)
    SetSwapSymbol(inst, "swap_lantern")
    inst.components.inventoryitem:ChangeImageName("boat_lantern")
end

local function TurnOff(inst)
    inst.SoundEmitter:KillSound("boatlamp")
    if inst:GetTimeAlive() > 0 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boatlantern_turnoff")
    end

    inst.components.fueled:StopConsuming()
    SetSwapSymbol(inst, "swap_lantern_off")
    RemoveLight(inst)
    inst.components.inventoryitem:ChangeImageName("boat_lantern_off")
end

local function SetBoatLightEnabled(inst, enabled)
    if enabled then
        if inst.components.fueled:IsEmpty() then
            if inst.components.equippable:IsToggledOn() then
                inst.components.equippable:ToggleOff()
            end
            return
        end

        if not inst.components.equippable:IsToggledOn() then
            inst.components.equippable:ToggleOn()
        elseif not inst.components.fueled.consuming or inst._light == nil then
            TurnOn(inst)
        end
    elseif inst.components.equippable:IsToggledOn() or inst.components.fueled.consuming or inst._light ~= nil then
        inst.components.equippable:ToggleOff()
    end
end


local function OnRemove(inst)
    RemoveLight(inst)
end

local function nofuel(inst)
    if inst.components.fueled.accepting then
        inst.components.equippable.togglable = false
        inst.components.equippable:ToggleOff()
    else
        inst:Remove()
    end
end

--------------------------------------------------------------------------

local function OnSave(inst)
    return { was_on = inst.components.fueled.consuming }
end

local function OnLoad(inst, data)
    inst.components.equippable:ToggleOff()
end

local function OnBoatEquipped(inst)
    RefreshLightParent(inst)
    SetBoatLightEnabled(inst, true)
end

local function OnBoatUnequipped(inst)
    SetBoatLightEnabled(inst, false)
end

local function OnDropped(inst)
    SetBoatLightEnabled(inst, false)
end

local function MakeBoatLanternLight()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetColour(200 / 255, 200 / 255, 50 / 255)
    inst.Light:SetRadius(5)
    inst.Light:SetIntensity(.6)
    inst.Light:SetFalloff(.9)
    inst.Light:Enable(true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()

    if TheWorld.ismastersim then
        inst.persists = false
    end

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    --  MakeInventoryFloatable(inst, "idle_water", "idle")
    inst.build = "swap_lantern_boat"
    inst.symbol = "swap_lantern_off"
    inst.symboltooverride = "swap_lantern"
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lantern_boat")
    inst.AnimState:SetBuild("swap_lantern_boat")
    inst.AnimState:PlayAnimation("idle_water")

    inst:AddTag("light")
    inst:AddTag("boatlight")
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("interactions")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("boat_lantern_off")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_LAMP
    inst.components.equippable.restrictedtag = "ta_boat_equipment"
    inst.components.equippable:SetOnEquip(OnBoatEquipped)
    inst.components.equippable:SetOnUnequip(OnBoatUnequipped)
    inst.components.equippable.togglable = true
    inst.components.equippable.toggledonfn = TurnOn
    inst.components.equippable.toggledofffn = TurnOff



    inst:AddComponent("fueled")

    inst.components.fueled.fueltype = FUELTYPE.CAVE
    inst.components.fueled:InitializeFuelLevel(BOAT_LANTERN_LIGHTTIME)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetUpdateFn(fuelupdate)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.accepting = true

    inst._light = nil
    inst.SetBoatLightEnabled = SetBoatLightEnabled

    MakeHauntableLaunch(inst)

    inst.OnRemoveEntity = OnRemove
    inst:ListenForEvent("boatequipped", OnBoatEquipped)
    inst:ListenForEvent("boatunequipped", OnBoatUnequipped)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    return inst
end

return Prefab("common/inventory/boat_lantern", fn, assets, prefabs),
    Prefab("boat_lantern_light", MakeBoatLanternLight)
