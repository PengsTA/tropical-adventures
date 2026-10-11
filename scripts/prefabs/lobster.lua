require "stategraphs/SGwobster"
require "stategraphs/SGwobsterland"

local lobster_assets            =
{
    Asset("ANIM", "anim/lobster_build.zip"),
    Asset("ANIM", "anim/lobster_build_color.zip"),
    Asset("ANIM", "anim/lobster_tropical.zip"),
    Asset("ANIM", "anim/lobster_water.zip"),
}

local ocean_prefabs             =
{
    "ocean_splash_small1",
    "wobster_sheller_land",
    "lobster_land",
}

local land_prefabs              =
{
    "lobster_dead",
    "lobster_dead_cooked",
    "wobster_sheller_dead",
    "wobster_sheller_dead_cooked",
}

local LOBSTER_FISH_DEF =
{
    prefab = "lobster",
    loot = { "lobster_dead" },
    lures = TUNING.OCEANFISH_LURE_PREFERENCE.WOBSTER,
    weight_min = 142.56,
    weight_max = 299.44,
}

local function OnTrawl(inst)
    local loot = SpawnPrefab("lobster_land")
    if inst.components.weighable ~= nil and loot ~= nil and loot.components.weighable ~= nil then
        loot.components.weighable:CopyWeighable(inst.components.weighable)
    end
    inst:Remove()
    return loot
end

local function fn()
    local inst = Prefabs.wobster_sheller_land.fn()
    inst:SetPrefabName("lobster_land")

    inst.AnimState:SetBank("lobster_tropical")
    inst.AnimState:SetBuild("lobster_build_color")

    if not TheWorld.ismastersim then return inst end

    inst.fish_def = LOBSTER_FISH_DEF

    inst.components.lootdropper:SetLoot({ "lobster_dead" })

    inst.components.cookable.product = "lobster_dead_cooked"

    inst:SetStateGraph("SGlobsterland")

    return inst
end

local function water_fn()
    local inst = Prefabs.wobster_sheller.fn()
    inst:SetPrefabName("lobster")

    inst:AddTag("lobster")

    inst.AnimState:SetBank("lobster_tropical")
    inst.AnimState:SetBuild("lobster_build")
    inst.AnimState:SetMultColour(1, 1, 1, .3)

    if not TheWorld.ismastersim then return inst end

    inst.fish_def = LOBSTER_FISH_DEF

    local lootdropper = inst.components.lootdropper or inst:AddComponent("lootdropper")
    lootdropper.trappable = true
    lootdropper:SetLoot({ "lobster_land" })

    inst:AddComponent("trawlable")
    inst.components.trawlable:SetIgnoreVisibility(true)
    inst.components.trawlable:SetTrawlFn(OnTrawl)

    inst:SetStateGraph("SGlobster")

    return inst
end

return Prefab("lobster_land", fn, lobster_assets, land_prefabs),
    Prefab("lobster", water_fn, lobster_assets, ocean_prefabs)
