local assets =
{
    Asset("ANIM", "anim/ox_flute.zip"),
}

local function onfinished(inst)
    inst:Remove()
end

local OX_FLUTE_USES = 5

local function OnPlayed(inst, musician, instrument)
    TheWorld:DoTaskInTime(2, function(world)
        world:PushEvent("ms_forceprecipitation")
    end)
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("ox_flute")
    inst.AnimState:SetBuild("ox_flute")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    inst:AddTag("flute")
    MakeInventoryFloatable(inst)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("instrument")
    inst.components.instrument:SetAssetOverrides("ox_flute", "ox_flute01", "dontstarve_DLC002/common/ox_flute")
    inst.components.instrument.onplayed = OnPlayed

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(OX_FLUTE_USES)
    inst.components.finiteuses:SetUses(OX_FLUTE_USES)
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    inst:AddComponent("inventoryitem")



    inst.flutebuild = "ox_flute"
    inst.flutesymbol = "ox_flute01"

    return inst
end

return Prefab("common/inventory/ox_flute", fn, assets)
