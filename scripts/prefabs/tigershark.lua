--Need to make this enemy much less player focused.
--Doesn't target player by default.
--Only if hit or if sharkittens threatened.

local assets =
{
    Asset("ANIM", "anim/tigershark_ground_build.zip"),
    Asset("ANIM", "anim/tigershark_ground.zip"),
    Asset("ANIM", "anim/tigershark_water_build.zip"),
    Asset("ANIM", "anim/tigershark_water.zip"),
    Asset("ANIM", "anim/tigershark_water_ripples_build.zip"),
}

local prefabs =
{
    "tigersharkshadow",
    "groundpound_fx",
    "groundpoundring_fx",
    "shark_gills",
    "woodlegs_key3",
}

SetSharedLootTable('tigershark',
    {
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },
        { "fishmeat",    1.00 },

        { "tigereye",    1.00 },
        { "tigereye",    0.50 },

        { "shark_gills", 1.00 },
        { "shark_gills", 1.00 },
        { "shark_gills", 0.10 },
        { "shark_gills", 0.33 },

        { "shark_tooth", 1.00 },
        { "shark_tooth", 1.00 },
        { "shark_tooth", 1.00 },
        { "shark_tooth", 1.00 },
        { "shark_tooth", 1.00 },

        { "mysterymeat", 1.00 },
        { "mysterymeat", 0.10 },
    })


local brain = require "brains/tigersharkbrain"

local function ShouldSleep(inst)
    if TheWorld.state.isday and not inst.sg:HasStateTag("specialattack") and inst.components.combat.target == nil and math.random() > 0.95 then
        return true
    end
    return false
end

local function ShouldWake(inst)
    return not TheWorld.state.isday
end

local function MakeWater(inst)
    inst:ClearStateGraph()
    inst:SetStateGraph("SGtigershark_water")
    inst.AnimState:SetBuild("tigershark_water_build")
    inst.AnimState:AddOverrideBuild("tigershark_water_ripples_build")
    inst:AddTag("aquatic")
    inst.DynamicShadow:Enable(false)
end

local function MakeGround(inst)
    inst:ClearStateGraph()
    inst:SetStateGraph("SGtigershark_ground")
    inst.AnimState:SetBuild("tigershark_ground_build")
    inst:RemoveTag("aquatic")
    inst.DynamicShadow:Enable(true)
end


local function GetTarget(inst)
    --Used for logic of moving between land and water states
    local target = inst.components.combat.target and inst.components.combat.target:GetPosition()

    if not target and inst:GetBufferedAction() then
        target = (inst:GetBufferedAction().target and inst:GetBufferedAction().target:GetPosition()) or
            inst:GetBufferedAction().pos
    end

    --Returns a position
    return target
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.AttackCounter = inst.AttackCounter + 0.3
end


local function RetargetFn(inst)
    if not TheWorld.state.isday and inst.sg:HasStateTag("sleeping") then
        inst.sg:GoToState("wake")
    end
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end


local function OnSave(inst, data)
    data.CanRun = inst.CanRun
    data.feed_remaining = math.max(0, inst.NextFeedTime - GetTime())
end

local function OnLoad(inst, data)
    if data then
        inst.CanRun = data.CanRun ~= false
        inst.NextFeedTime = GetTime() + (data.feed_remaining or 0)
    end
end

local function CanBeAttacked(inst, attacker)
    return not inst.sg:HasStateTag("specialattack")
end


local function OnWaterChange(inst, onwater)
    if onwater and not inst.sg:HasStateTag("specialattack") then
        MakeWater(inst)
    end
    if not onwater and not inst.sg:HasStateTag("specialattack") then --and not casaperto then
        MakeGround(inst)
    end


    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
end


local function OnEntityWake(inst)
    inst.components.tiletracker:Start()
end

local function OnEntitySleep(inst)
    inst.components.tiletracker:Stop()
end

local function OnDeadTiger(inst)
    TheWorld.components.tigersharker:OnBossDeath(inst)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(6, 3)
    --    inst.DynamicShadow:Enable(false)
    inst.DynamicShadow:Enable(true)

    inst:AddTag("scarytoprey")
    inst:AddTag("tigershark")
    inst:AddTag("largecreature")
    inst:AddTag("epic")
    inst:AddTag("monster")

    MakeCharacterPhysics(inst, 10, 0.5)
    inst.Physics:ClearCollidesWith(COLLISION.BOAT_LIMITS)

    inst.AnimState:SetBank("tigershark")
    inst.AnimState:SetRayTestOnBB(true)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 8 --TUNING.TIGERSHARK_WALK_SPEED
    inst.components.locomotor.runspeed = 10 --TUNING.TIGERSHARK_RUN_SPEED

    inst:AddComponent("rowboatwakespawner")

    inst:AddComponent("talker")
    inst:AddComponent("inspectable")
    inst.no_wet_prefix = true

    inst:AddComponent("knownlocations")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(8000 * TUNING.bosslife)
    inst.components.health.absorb = .3

    inst:AddComponent("eater")
    inst.components.eater.foodprefs = { "MEAT" }
    inst.components.eater.ablefoods = { "MEAT", "VEGGIE", "GENERIC" }

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('tigershark')

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 3
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.numRings = 3
    inst.components.groundpounder.noTags = { "sharkitten" }

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)
    inst.components.combat.playerdamagepercent = .8
    inst.components.combat:SetRange(4, 4)
    inst.components.combat:SetAreaDamage(5, 1.25)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/bearger/hurt")
    inst.components.combat.canbeattackedfn = CanBeAttacked
    inst.components.combat.battlecryenabled = false
    inst.components.combat.notags = { "sharkitten" }

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    inst:ListenForEvent("killed", function(inst, data)
        if inst.components.combat and data and data.victim == inst.components.combat.target then
            inst.components.combat.target = nil
        end
    end)
    inst:ListenForEvent("death", OnDeadTiger)

    inst.CanRun = true     --Can do charge attack
    inst.CanFly = false    --Can do leap attack
    inst.podeFeed = false  -- Can do feed  anim
    inst.podeFeed = false  -- Can do feed  anim
    inst.podeTaunt = false -- Can do taunt  anim


    inst.AttackCounter = 0
    inst.TauntCounter = 0
    inst.FeedCounter = 0

    inst:AddComponent("tiletracker")
    inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    inst.NextFeedTime = 0
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    --    inst.FindSharkHome = FindSharkHome
    --    inst.DoDespawn = DoDespawn
    inst.GetTarget = GetTarget

    inst:AddComponent("timer")

    inst:ListenForEvent("attacked", OnAttacked)

    inst.AnimState:SetBuild("tigershark_water_build")
    inst.AnimState:AddOverrideBuild("tigershark_water_ripples_build")
    inst:AddTag("aquatic")
    inst:SetStateGraph("SGtigershark_water")


    inst:SetBrain(brain)

    if not TheWorld.components.tigersharker:RegisterBoss(inst) then
        inst:DoTaskInTime(0, inst.Remove)
    end

    return inst
end

return Prefab("tigershark", fn, assets, prefabs)
