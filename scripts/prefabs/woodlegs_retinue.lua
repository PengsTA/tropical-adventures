local function PlaySound(inst)
    inst.SoundEmittbrainer:PlaySound("dontstarve/characters/wendy/hurt")
end

local assets =
{
    Asset("ANIM", "anim/chester.zip"),
    Asset("ANIM", "anim/ui_chest_3x2.zip"),
    Asset("SOUND", "sound/chester.fsb"),
    Asset("ANIM", "anim/woodlegs1.zip"),

}

local brain = require("brains/woodlegsbrain")

local function Retarget(inst)
    local leader = inst.components.follower.leader
    if leader == nil or not leader:IsValid() then
        return nil
    end
    return FindEntity(
        inst,
        20,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and guy.components.combat ~= nil
                and (guy.components.combat.target == leader or
                    (leader.components.combat ~= nil and leader.components.combat.target == guy))
        end,
        { "_combat", "_health" },
        { "INLIMBO", "noauradamage" }
    )
end


local function OnWaterChange(inst, onwater)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/crocodog/emerge")

    if onwater then
        local pegabarco = SpawnPrefab("woodlegsboat")
        if inst.components.sailor ~= nil then
            inst.components.sailor:Embark(pegabarco)
        end
    else
        local boat = inst.components.sailor ~= nil and inst.components.sailor:GetBoat() or nil
        if inst.components.sailor ~= nil then
            inst.components.sailor:ForceDisembark("land")
        end
        if boat ~= nil and boat:IsValid() then
            boat:Remove()
        end
        inst.sg:GoToState("idle")
    end
end

local function OnAttacked(inst, data)
    if data.attacker == nil then
        inst.components.combat:SetTarget(nil)
    elseif data.attacker == inst._playerlink then
        PlaySound(inst)
        inst.components.talker:Say(say_playerhit[math.random(#say_playerhit)])
    elseif not data.attacker:HasTag("noauradamage") then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function AbleToAcceptTest(inst, item)
    return false, item.prefab == "reviver" and "ABIGAILHEART" or nil
end


local function ShouldAcceptItem(inst, item)
    return true
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible ~= nil then
        --meat makes us friends (unless I'm a guard)
        if item.components.edible.foodtype == FOODTYPE.MEAT or item.components.edible.foodtype == FOODTYPE.HORRIBLE then
            if inst.components.combat:TargetIs(giver) then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader ~= nil and not (inst:HasTag("guard") or giver:HasTag("monster")) then
                giver:PushEvent("makefriend")
                giver.components.leader:AddFollower(inst)
                inst.components.follower:AddLoyaltyTime(item.components.edible:GetHunger() *
                    TUNING.PIG_LOYALTY_PER_HUNGER)
                inst.components.follower.maxfollowtime =
                    giver:HasTag("polite")
                    and TUNING.PIG_LOYALTY_MAXTIME + TUNING.PIG_LOYALTY_POLITENESS_MAXTIME_BONUS
                    or TUNING.PIG_LOYALTY_MAXTIME
            end
        end
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    --I wear hats
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
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

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end


local function OnEat(inst, food)
    if food.components.edible ~= nil then
        if food.components.edible.foodtype == FOODTYPE.VEGGIE then
            SpawnPrefab("poop").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
end

local function NormalShouldSleep(inst)
    return DefaultSleepTest(inst)
        and (inst.components.follower == nil or inst.components.follower.leader == nil
            or (FindEntity(inst, 6, nil, { "campfire", "fire" }) ~= nil and
                (inst.LightWatcher == nil or inst.LightWatcher:IsInLight())))
end


local function OnActivate(inst, player)
    if inst.components.follower:GetLeader() == nil then
        local comida = SpawnPrefab("Meat")
        inst.components.trader:AcceptGift(player, comida)
    elseif inst.components.follower:GetLeader() ~= nil then
        inst.components.talker:Say("Bye")
        inst.components.follower:StopFollowing()
    end


    inst.components.activatable.inactive = true
end

local function OnEntityWake(inst)
    inst.components.tiletracker:Start()
end

local function OnEntitySleep(inst)
    inst.components.tiletracker:Stop()
end

local function fn()
    local inst = CreateEntity()

    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("noauradamage")
    inst:AddTag("notraptrigger")
    inst:AddTag("noauradamage")
    inst:AddTag("flying")

    inst.entity:AddTransform()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("woodlegs.tex")

    --print("   AnimState")
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("woodleg1")
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Show("ARM_normal")

    --print("   sound")
    inst.entity:AddSoundEmitter()

    --print("   shadow")
    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize(2, 1.5)

    --print("   Physics")
    MakeCharacterPhysics(inst, 1, 0.5)
    inst.Physics:ClearCollidesWith(COLLISION.BOAT_LIMITS)
    --    MakeFlyingCharacterPhysics(inst, 75, .5)


    inst.Transform:SetFourFaced()

    inst:AddComponent("talker")

    inst.entity:SetPristine() -- none existing
    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("sailor")
    --print("   health")
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(600)
    inst.components.health:StartRegen(1, 1)

    inst:AddComponent("inspectable")

    --print("   locomotor")
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 5

    inst:SetStateGraph("SGwoodlegs")
    inst.sg:GoToState("idle")

    --print("   follower")
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME

    --print("   knownlocations")
    inst:AddComponent("knownlocations")

    --print("   burnable")
    MakeSmallBurnableCharacter(inst, "chester_body")

    -- San Aura
    --    inst:AddComponent("sanityaura")
    --    inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL / 2
    --    inst:AddComponent("heater")
    --    inst.components.heater.heat = 0 --180

    --Attack
    inst:AddComponent("combat")
    inst.components.combat.defaultdamage = 20
    inst.components.combat.min_attack_period = 0.5
    --    inst.components.combat.playerdamagepercent = 0
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat.attackrange = 1
    inst:ListenForEvent("attacked", OnAttacked)

    --get item from player
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    --can eat
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater.strongstomach = true -- can eat monster meat!
    inst.components.eater:SetOnEatFn(OnEat)

    -- can sleep
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(NormalShouldSleep)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)


    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")


    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = true


    inst:AddComponent("inventory")
    inst:SetBrain(brain)


    inst:AddComponent("tiletracker")
    inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    return inst
end

return Prefab("woodlegs_retinue", fn, assets)
