require "brains/antbrain"
require "stategraphs/SGant2"
local ClimateProfiles = require("tools/climateprofiles")
local AntEcology = require("tools/antecology")

local assets =
{
    Asset("ANIM", "anim/antman_basic.zip"),
    Asset("ANIM", "anim/antman_attacks.zip"),
    Asset("ANIM", "anim/antman_actions.zip"),

    Asset("ANIM", "anim/antman_translucent_build.zip"),
    Asset("ANIM", "anim/antman_build.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "monstermeat",
    "chitin",
    "antman_warrior",
}

local SPRING_COMBAT_MOD = 1.33
local ANTMAN_DAMAGE = 34 * 2 / 3
local ANTMAN_HEALTH = 250
local ANTMAN_ATTACK_PERIOD = 3
local ANTMAN_TARGET_DIST = 16
local ANTMAN_LOYALTY_MAXTIME = 2.5 * 480
local ANTMAN_LOYALTY_PER_HUNGER = 480 / 25

local ANTMAN_RUN_SPEED = 5
local ANTMAN_WALK_SPEED = 3


local ANTMAN_ATTACK_ON_SIGHT_DIST = 4

local PIG_MIN_POOP_PERIOD = 30 * .5

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local setEatType = AntEcology.SetNurseryDiet


local function CalcSanityAura(inst, observer)
    if inst.components.follower and inst.components.follower.leader == observer then
        return TUNING.SANITYAURA_SMALL
    end

    return 0
end

local function ShouldAcceptItem(inst, item)
    if inst.components.sleeper:IsAsleep() then
        return false
    end

    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    end
    if item.components.edible then
        if not inst.components.eater:CanEat(item) then return false end
        if (item.components.edible.foodtype == "MEAT" or item.components.edible.foodtype == "HORRIBLE")
            and inst.components.follower.leader
            and inst.components.follower:GetLoyaltyPercent() > 0.9 then
            return false
        end

        if (item.components.edible.foodtype == "VEGGIE" or item.components.edible.foodtype == "RAW") then
            local last_eat_time = inst.components.eater:TimeSinceLastEating()
            if last_eat_time and last_eat_time < PIG_MIN_POOP_PERIOD then
                return false
            end

            if inst.components.inventory:Has(item.prefab, 1) then
                return false
            end
        end

        return true
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible then
        --meat makes us friends
        if inst.components.eater:CanEat(item) then
            --  if item.components.edible.foodtype == "MEAT" or item.components.edible.foodtype == "HORRIBLE" then
            if inst.components.combat.target and inst.components.combat.target == giver then
                inst.components.combat:SetTarget(nil)
            end
            if giver.components.leader then
                inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                giver.components.leader:AddFollower(inst)
                local hunger = math.max(item.components.edible:GetHunger(), TUNING.CALORIES_TINY)
                inst.components.follower:AddLoyaltyTime(hunger * ANTMAN_LOYALTY_PER_HUNGER)
            end
        end
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    --I wear hats
    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current then
            inst.components.inventory:DropItem(current)
        end

        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function OnEat(inst, food)
end

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("antman") end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = nil
    if ClimateProfiles.IsHamletRainy(TheWorld.state) then
        ents = TheSim:FindEntities(x, y, z, (SHARE_TARGET_DIST * SPRING_COMBAT_MOD) / 2)
    else
        ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST / 2)
    end

    if ents then
        local num_helpers = 0
        for k, v in pairs(ents) do
            if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and fn(v) then
                if v:PushEvent("suggest_tree_target", { tree = attacker }) then
                    num_helpers = num_helpers + 1
                end
            end
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end
        end
    end
end

local function OnAttacked(inst, data)
    --print(inst, "OnAttacked")
    local attacker = data and data.attacker
    if attacker == nil then return end
    inst:ClearBufferedAction()

    if attacker.prefab == "deciduous_root" and attacker.owner then
        OnAttackedByDecidRoot(inst, attacker.owner)
    elseif attacker.prefab ~= "deciduous_root" then
        AntEcology.DefendColony(inst, attacker)
    end
end

local function OnNewTarget(inst, data)
end

local builds = { "antman_build" }

local is_complete_disguise = AntEcology.IsDisguised

local function NormalRetargetFn(inst)
    return FindEntity(inst, ANTMAN_TARGET_DIST, function(target)
        return AntEcology.IsIntruder(inst, target, ANTMAN_ATTACK_ON_SIGHT_DIST)
    end)
end

local NormalKeepTargetFn = AntEcology.KeepTarget

local function NormalShouldSleep(inst)
    if AntEcology.GetLeader(inst) then
        local fire = FindEntity(inst, 6,
            function(ent)
                return ent.components.burnable and ent.components.burnable:IsBurning()
            end,
            { "campfire" })

        return DefaultSleepTest(inst) and fire and (not inst.LightWatcher or inst.LightWatcher:IsInLight())
    else
        return DefaultSleepTest(inst)
    end
end

local function SetNormalAnt(inst)
    inst.AnimState:SetBuild(inst.build)
    inst.AnimState:OverrideSymbol("antman_arm", "antman_translucent_build", "antman_arm")
end

local function common()
    local inst = CreateEntity()
    inst.ant_caste = "nursery"
    inst.entity:AddNetwork()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.Transform:SetScale(1.15, 1.15, 1.15)

    inst.entity:AddLightWatcher()

    inst:AddComponent("talker")
    AntEcology.SetupSpeech(inst)

    MakeCharacterPhysics(inst, 50, .5)
    --    MakePoisonableCharacter(inst)

    anim:SetBank("antman")
    anim:PlayAnimation("idle_loop", true)
    anim:Hide("hat")
    inst:AddTag("character")
    inst:AddTag("ant")
    inst:AddTag("antman")
    inst:AddTag("insect")
    inst:AddTag("scarytoprey")
    inst:AddTag("trader")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")                          -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = ANTMAN_RUN_SPEED   --5
    inst.components.locomotor.walkspeed = ANTMAN_WALK_SPEED --3


    inst.combatTargetWasDisguisedOnExit = false

    ------------------------------------------
    inst:AddComponent("eater")
    AntEcology.SetupNurseryDiet(inst)
    inst.SetEatType = setEatType

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem:SetSinks(true)

    inst.components.eater.strongstomach = true -- can eat monster meat!
    inst.components.eater:SetOnEatFn(OnEat)
    ------------------------------------------
    inst:AddComponent("combat")
    AntEcology.SetupAggro(inst)
    inst.components.combat.hiteffectsymbol = "antman_torso"

    MakeMediumBurnableCharacter(inst, "antman_torso")

    inst:AddComponent("named")
    AntEcology.NameWorker(inst)

    ------------------------------------------
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = ANTMAN_LOYALTY_MAXTIME
    AntEcology.ConfigureFriendship(inst)
    ------------------------------------------
    inst:AddComponent("health")

    ------------------------------------------

    inst:AddComponent("inventory")

    ------------------------------------------

    inst:AddComponent("lootdropper")

    ------------------------------------------

    inst:AddComponent("knownlocations")

    ------------------------------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------------------------------

    inst:AddComponent("sleeper")

    ------------------------------------------
    MakeMediumFreezableCharacter(inst, "antman_torso")

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst)
        if AntEcology.GetLeader(inst) ~= nil then
            return "FOLLOWER"
        end
    end

    ------------------------------------------

    inst.components.sleeper:SetResistance(2)

    inst.components.combat:SetDefaultDamage(ANTMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(ANTMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.locomotor.runspeed = ANTMAN_RUN_SPEED
    inst.components.locomotor.walkspeed = ANTMAN_WALK_SPEED

    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")

    inst.components.sleeper:SetSleepTest(NormalShouldSleep)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("monstermeat", 3)
    inst.components.lootdropper:AddRandomLoot("chitin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst.components.health:SetMaxHealth(ANTMAN_HEALTH)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
    inst.components.combat:SetTarget(nil)
    inst:ListenForEvent("suggest_tree_target", function(inst, data)
        if not AntEcology.IsNursery(inst) and data and data.tree and inst:GetBufferedAction() ~= ACTIONS.CHOP then
            inst.tree_target = data.tree
        end
    end)

    inst.components.trader:Enable()
    inst.components.talker:StopIgnoringAll()

    local brain = require "brains/antbrain"
    inst:SetBrain(brain)
    inst:SetStateGraph("SGant2")

    inst.OnSave = function(inst, data)
        data.build = inst.build
        data.eattype = inst.eattype
        data.combatTargetWasDisguisedOnExit = inst.combatTargetWasDisguisedOnExit
    end

    inst.OnLoad = function(inst, data)
        if data then
            inst.build = data.build or builds[1]

            inst.combatTargetWasDisguisedOnExit = data.combatTargetWasDisguisedOnExit
            inst.AnimState:SetBuild(inst.build)
            inst.AnimState:OverrideSymbol("antman_arm", "antman_translucent_build", "antman_arm")
            setEatType(inst, data.eattype or inst.eattype)
        end
    end

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst.is_complete_disguise = is_complete_disguise


    AntEcology.WatchWorker(inst)

    return inst
end

local function normal()
    local inst = common()
    inst.build = builds[math.random(#builds)]
    inst.AnimState:SetBuild(inst.build)
    inst.AnimState:OverrideSymbol("antman_arm", "antman_translucent_build", "antman_arm")

    SetNormalAnt(inst)
    return inst
end

return Prefab("common/characters/antman2", normal, assets, prefabs)
