local assets = {Asset("ANIM", "anim/nettle.zip"), Asset("SOUND", "sound/common.fsb"), Asset("MINIMAP_IMAGE", "nettle")}
local ClimateProfiles = require("tools/climateprofiles")

local VINE_REGROW_TIME = 480 * 3

local prefabs = {"cutnettle"}

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
    -- inst.AnimState:PlayExtendAnim("shake")
    inst.components.animcontroller:PlayAnimation("shake")
    inst.components.animcontroller:SetFilter("generic")
    inst.AnimState:PlayAnimation("picked", true)
end

local function makebarrenfn(inst) 
    inst.components.animcontroller:SetFilter("withered")
    -- inst.AnimState:SetFilter("withered")
    inst.AnimState:PlayAnimation("picked", true)
end

local function onpickedfn(inst)
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked", false)
end

local function testForGrowth(inst)
    local tile = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())
    local valid = tile == GROUND.DEEPRAINFOREST or tile == GROUND.RAINFOREST
        or (GROUND.DEEPRAINFOREST_NOCANOPY ~= nil and tile == GROUND.DEEPRAINFOREST_NOCANOPY)
    local pickable = inst.components.pickable
    local wet = inst.components.tropicalplantmoisture:IsWet()
    local suitable = valid and not ClimateProfiles.IsHamletHumid(TheWorld.state)
    pickable.caninteractwith = suitable and wet
    if not suitable then
        if not pickable:IsBarren() then pickable:MakeBarren() end
        pickable:Pause()
    elseif wet then
        if pickable:IsBarren() then
            pickable.cycles_left = nil
            pickable.paused = false
            pickable:MakeEmpty()
        else
            pickable:Resume()
        end
    else
        pickable:Pause()
    end
end

local function getstatus(inst) if not inst.components.pickable.canbepicked then return "EMPTY" end end

local function ontransplantfn(inst)
    inst.components.pickable:MakeEmpty()
    testForGrowth(inst)
end

local function fn()
    local function dig_up(inst, digger)
        if inst.components.pickable and inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab("cutnettle")
        end
        local bush = inst.components.lootdropper:SpawnLootPrefab("dug_nettle")
        -- print(inst.prefab)
        inst:Remove()
    end

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local minimap = inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("nettle.tex")
    anim:SetBank("nettle")
    anim:SetBuild("nettle")

    anim:PlayAnimation("idle", true)
    anim:SetTime(math.random() * 2)

    inst:AddTag("gustable")
    inst:AddTag("nettle_plant")
    inst:AddTag("plant")

    inst.entity:SetPristine()

    inst:AddComponent("animcontroller")

    if not TheWorld.ismastersim then return inst end

    local pickable = inst:AddComponent("pickable")
    pickable.picksound = "dontstarve/wilson/pickup_reeds"

    pickable:SetUp("cutnettle", VINE_REGROW_TIME)
    pickable.onregenfn = onregenfn
    pickable.onpickedfn = onpickedfn
    pickable.makeemptyfn = makeemptyfn
    pickable.makebarrenfn = makebarrenfn
    pickable.ontransplantfn = ontransplantfn

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("tropicalplantmoisture")
    inst:ListenForEvent("itemwet", testForGrowth)
    inst:ListenForEvent("itemdry", testForGrowth)
    inst.components.inspectable.getstatus = getstatus

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.DIG)
    workable:SetOnFinishCallback(dig_up)
    workable:SetWorkLeft(1)
    --	    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)

    ---------------------
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    -- inst.components.burnable:MakeDragonflyBait(1)
    inst:WatchWorldState("season", testForGrowth)
    inst:DoTaskInTime(0, testForGrowth)
    --		inst:ListenForEvent("seasonChange", function(it, data) testForGrowth(inst) end, TheWorld)

    return inst
end

PICKABLE_FOOD_PRODUCTS["cutnettle"] = true

return Prefab("forest/objects/nettle", fn, assets, prefabs)
