local assets=
{
	Asset("ANIM", "anim/mystery_meat.zip"),
}

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local function impact(inst)
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/mysterymeat_impactland")
end

local function GetFertilizerKey(inst)
    return inst.prefab
  end

  local function fertilizerresearchfn(inst)
    return inst:GetFertilizerKey()
  end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst:AddTag("kittenchow")

    inst.AnimState:SetBank("mysterymeat")
    inst.AnimState:SetBuild("mystery_meat")
    inst.AnimState:PlayAnimation("idle")

    MakeDeployableFertilizerPristine(inst)

    inst:AddTag("fertilizerresearchable")

    inst.GetFertilizerKey = GetFertilizerKey

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end

    inst:ListenForEvent("floater_startfloating", impact)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")


    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.SPOILED_HEALTH
    inst.components.edible.hungervalue = TUNING.SPOILED_HUNGER
    inst.components.edible.foodtype = "MEAT"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("fertilizerresearchable")
    inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)

    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.SPOILEDFOOD_FERTILIZE
    inst.components.fertilizer.soil_cycles = TUNING.SPOILEDFOOD_SOILCYCLES
    inst.components.fertilizer.withered_cycles = TUNING.SPOILEDFOOD_WITHEREDCYCLES
    inst.components.fertilizer:SetNutrients(FERTILIZER_DEFS.mysterymeat.nutrients)

    MakeDeployableFertilizer(inst)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab( "mysterymeat", fn, assets)
