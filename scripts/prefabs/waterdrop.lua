local assets =
{
    Asset("ANIM", "anim/waterdrop.zip"),
    Asset("ANIM", "anim/lifeplant.zip"),
}

local function oneat(inst, eater)
    TroRemovePoison(eater)
end

local function ondeploy(inst, pt)
    local plant = SpawnPrefab("lifeplant")
    plant.Transform:SetPosition(pt:Get())
    plant.AnimState:PlayAnimation("grow")
    plant.AnimState:PushAnimation("idle_loop", true)
    plant.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/flower_of_life/plant")

    inst.planted = true
    inst:Remove()
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("waterdrop")
    inst.AnimState:SetBuild("waterdrop")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("waterdrop")
    inst:AddTag("deployedplant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GOODIES
    inst.components.edible.healthvalue = TUNING.HEALING_SUPERHUGE * 3
    inst.components.edible.hungervalue = TUNING.CALORIES_SUPERHUGE * 3
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE * 3
    inst.components.edible:SetOnEatenFn(oneat)

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
    inst.components.deployable.ondeploy = ondeploy

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.LIVINGARTIFACT
    inst.components.fuel.fuelvalue = TUNING.IRON_LORD_TIME

    return inst
end

return Prefab("waterdrop", fn, assets),
    MakePlacer("waterdrop_placer", "lifeplant", "lifeplant", "idle_loop")
