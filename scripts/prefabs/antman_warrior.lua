require "brains/antwarriorbrain"
require "stategraphs/SGwarriorant"
local AntEcology = require("tools/antecology")

local assets =
{
    Asset("ANIM", "anim/antman_basic.zip"),
    Asset("ANIM", "anim/antman_attacks.zip"),
    Asset("ANIM", "anim/antman_actions.zip"),
    Asset("ANIM", "anim/antman_egghatch.zip"),
    Asset("ANIM", "anim/antman_guard_build.zip"),
    Asset("ANIM", "anim/antman_warpaint_build.zip"),

    Asset("ANIM", "anim/antman_translucent_build.zip"),
}

local prefabs =
{
    "monstermeat",
    "chitin",
    "antman",
    "antman2",
    "antman_warrior_egg"
}

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30
local ANTMAN_WARRIOR_DAMAGE = 34 * 1.25
local ANTMAN_WARRIOR_HEALTH = 300
local ANTMAN_WARRIOR_ATTACK_PERIOD = 3
local ANTMAN_WARRIOR_TARGET_DIST = 16

local ANTMAN_WARRIOR_RUN_SPEED = 7
local ANTMAN_WARRIOR_WALK_SPEED = 3.5


local ANTMAN_WARRIOR_ATTACK_ON_SIGHT_DIST = 8

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("antman") end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = nil
    ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST / 2)

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
    local attacker = data and data.attacker
    if attacker == nil then return end
    inst:ClearBufferedAction()

    if attacker.prefab == "deciduous_root" and attacker.owner then
        OnAttackedByDecidRoot(inst, attacker.owner)
    elseif attacker.prefab ~= "deciduous_root" then
        AntEcology.DefendColony(inst, attacker)
    end
end

local function NormalRetargetFn(inst)
    return FindEntity(inst, ANTMAN_WARRIOR_TARGET_DIST, function(target)
        return AntEcology.IsIntruder(inst, target, ANTMAN_WARRIOR_ATTACK_ON_SIGHT_DIST)
    end)
end

local function UpdateAporkalypse(inst, active)
    if inst.components.health:IsDead() then return end
    if not active and inst.worker_prefab then
        AntEcology.RestoreWorker(inst)
        return
    end
    local empowered = active or inst.queen_enraged
    inst.Light:Enable(empowered == true)
    inst.AnimState:SetBloomEffectHandle(empowered and "shaders/anim.ksh" or "")
    inst.build = empowered and "antman_warpaint_build" or "antman_guard_build"
    inst.AnimState:SetBuild(inst.build)
    local percent = inst.components.health:GetPercent()
    inst.components.health:SetMaxHealth(ANTMAN_WARRIOR_HEALTH + (empowered and 100 or 0))
    inst.components.health:SetPercent(percent)
end

local function BindQueen(inst, queen)
    if inst._boundqueen == queen then return end
    if inst._boundqueen then
        inst:RemoveEventCallback("death", inst._onqueengone, inst._boundqueen)
        inst:RemoveEventCallback("onremove", inst._onqueengone, inst._boundqueen)
    end
    inst.queen = queen
    inst._boundqueen = queen
    local function OnQueenGone()
        inst.queen_enraged = nil
        inst.queen = nil
        UpdateAporkalypse(inst, TheWorld.state.isaporkalypse)
    end
    inst._onqueengone = OnQueenGone
    inst:ListenForEvent("death", OnQueenGone, queen)
    inst:ListenForEvent("onremove", OnQueenGone, queen)
end

local function common()
    local inst = CreateEntity()
    inst.entity:AddNetwork()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, .75)

    local light = inst.entity:AddLight()
    light:SetFalloff(.35)
    light:SetIntensity(.25)
    light:SetRadius(1)
    light:SetColour(120 / 255, 120 / 255, 120 / 255)
    light:Enable(false)

    trans:SetFourFaced()
    trans:SetScale(1.15, 1.15, 1.15)

    inst.entity:AddLightWatcher()

    inst:AddComponent("talker")
    AntEcology.SetupSpeech(inst)

    MakeCharacterPhysics(inst, 50, .5)

    inst.build = "antman_guard_build"
    inst:AddTag("character")
    inst:AddTag("antmanwarrior")
    inst:AddTag("ant")
    inst:AddTag("insect")
    inst:AddTag("scarytoprey")
    anim:SetBank("antman")
    inst.AnimState:SetBuild(inst.build)
    anim:PlayAnimation("idle_loop")
    anim:Hide("hat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")                                  -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = ANTMAN_WARRIOR_RUN_SPEED   --5
    inst.components.locomotor.walkspeed = ANTMAN_WARRIOR_WALK_SPEED --3
    ------------------------------------------
    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")

    inst:AddComponent("combat")
    AntEcology.SetupAggro(inst)
    inst.components.combat.hiteffectsymbol = "antman_torso"
    inst.components.combat.debris_immune = true
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
    inst.components.combat:SetTarget(nil)
    inst.components.combat:SetDefaultDamage(ANTMAN_WARRIOR_DAMAGE)
    inst.components.combat:SetAttackPeriod(ANTMAN_WARRIOR_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(AntEcology.KeepTarget)

    MakeMediumBurnableCharacter(inst, "antman_torso")

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.ANTWARRIORNAMES
    inst.components.named:PickNewName()

    ------------------------------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(ANTMAN_WARRIOR_HEALTH)
    inst.components.health.save_maxhealth = true

    inst:AddComponent("inventory")
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.ANTMAN_LOYALTY_MAXTIME

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("monstermeat", 3)
    inst.components.lootdropper:AddRandomLoot("chitin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("knownlocations")
    inst:AddComponent("sleeper")
    inst:AddComponent("inspectable")
    ------------------------------------------
    MakeMediumFreezableCharacter(inst, "antman_torso")
    ------------------------------------------

    inst.OnSave = function(inst, data)
        data.worker_prefab = inst.worker_prefab
        data.worker_eattype = inst.worker_eattype
        data.queen_enraged = inst.queen_enraged
        if inst.queen and inst.queen:IsValid() then
            data.queen_guid = inst.queen.GUID
            return { inst.queen.GUID }
        end
    end
    inst.OnLoad = function(inst, data)
        if data then
            inst.worker_prefab = data.worker_prefab
            inst.worker_eattype = data.worker_eattype
            AntEcology.ConfigureFriendship(inst)
            inst.queen_enraged = data.queen_enraged
        end
    end
    inst.OnLoadPostPass = function(inst, newents, data)
        local queen = data and data.queen_guid and newents[data.queen_guid]
        if queen and not queen.entity.components.health:IsDead() then
            BindQueen(inst, queen.entity)
        else
            inst.queen_enraged = nil
        end
    end
    inst:ListenForEvent("attacked", OnAttacked)
    inst:WatchWorldState("isaporkalypse", UpdateAporkalypse)
    inst:ListenForEvent("antqueenbattle", function(_, data)
        local queen = data and data.queen
        if queen and (inst.queen == queen or inst:IsNear(queen, 30)) then
            BindQueen(inst, queen)
            inst.queen_enraged = true
            UpdateAporkalypse(inst, TheWorld.state.isaporkalypse)
        end
    end, TheWorld)
    inst:DoTaskInTime(0, function()
        UpdateAporkalypse(inst, TheWorld.state.isaporkalypse)
    end)

    local brain = require "brains/antwarriorbrain"
    inst:SetBrain(brain)
    inst:SetStateGraph("SGwarriorant")

    return inst
end

return Prefab("common/characters/antman_warrior", common, assets, prefabs)
