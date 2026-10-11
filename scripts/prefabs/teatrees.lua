local assets = { Asset("ANIM", "anim/tree_leaf_short.zip"), Asset("ANIM", "anim/tree_leaf_normal.zip"),
    Asset("ANIM", "anim/tree_leaf_tall.zip"), Asset("ANIM", "anim/teatree_trunk_build.zip"), -- trunk build (winter leaves build)
    Asset("ANIM", "anim/teatree_build.zip"), Asset("ANIM", "anim/dust_fx.zip"),
    Asset("SOUND", "sound/forest.fsb") }

local day_time = 300
local DECIDUOUS_GROW_TIME = { {
    base = 1.5 * day_time,
    random = .5 * day_time,
}, -- short
    {
        base = 5 * day_time,
        random = 2 * day_time,
    }, -- normal
    {
        base = 5 * day_time,
        random = 2 * day_time,
    }, -- tall
    {
        base = 1 * day_time,
        random = .5 * day_time,
    } -- old
}

local DECIDUOUS_CHOPS_SMALL = 5
local DECIDUOUS_CHOPS_NORMAL = 10
local DECIDUOUS_CHOPS_TALL = 15

TUNING.TEATREE_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 4
TUNING.TEATREE_RELEASE_TIME = 8

local prefabs = { "log", "twigs", "teatree_nut", "charcoal", "green_leaves", "green_leaves_chop", "spoiled_food" }

local treecommon = {
    leavesbuild = "teatree_build",
    prefab_name = "teatree",
    short_loot = { "log" },
    normal_loot = { "log", "twigs", "teatree_nut" },
    tall_loot = { "log", "log", "twigs", "teatree_nut", "teatree_nut" },
    drop_nut = true,
    fx = "green_leaves",
    chopfx = "green_leaves_chop",
    shelter = true
}

local function makeanims(stage)
    return {
        idle = "idle_" .. stage,
        sway1 = "sway1_loop_" .. stage,
        sway2 = "sway2_loop_" .. stage,
        chop = "chop_" .. stage,
        fallleft = "fallleft_" .. stage,
        fallright = "fallright_" .. stage,
        stump = "stump_" .. stage,
        burnt = "burnt_" .. stage,
        chop_burnt = "chop_burnt_" .. stage,
    }
end

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")

local function PushSway(inst, ...)
    inst.AnimState:PushAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
end

local function ChangeSizeFn(inst)
    inst:RemoveEventCallback("animover", ChangeSizeFn)
    if inst.components.growable then
        inst.anims = ({ short_anims, normal_anims, tall_anims })[inst.components.growable.stage]
        PushSway(inst)
    end
end

local function SetShort(inst)
    inst.anims = short_anims
    PushSway(inst)
    if inst.components.workable then inst.components.workable:SetWorkLeft(DECIDUOUS_CHOPS_SMALL) end
    inst.components.lootdropper:SetLoot(treecommon.short_loot)
end

local function GrowShort(inst)
    inst.AnimState:PlayAnimation("grow_tall_to_short")
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function SetNormal(inst)
    inst.anims = normal_anims
    PushSway(inst)
    if inst.components.workable then inst.components.workable:SetWorkLeft(DECIDUOUS_CHOPS_NORMAL) end
    inst.components.lootdropper:SetLoot(treecommon.normal_loot)
end

local function GrowNormal(inst)
    inst.AnimState:PlayAnimation("grow_short_to_normal")
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function SetTall(inst)
    inst.anims = tall_anims
    PushSway(inst)
    if inst.components.workable then inst.components.workable:SetWorkLeft(DECIDUOUS_CHOPS_TALL) end
    inst.components.lootdropper:SetLoot(treecommon.tall_loot)
end

local function GrowTall(inst)
    inst.AnimState:PlayAnimation("grow_normal_to_tall")
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local growth_stages = { {
    name = "short",
    time = function(inst) return GetRandomWithVariance(DECIDUOUS_GROW_TIME[1].base, DECIDUOUS_GROW_TIME[1].random) end,
    fn = SetShort,
    growfn = GrowShort,
}, {
    name = "normal",
    time = function(inst) return GetRandomWithVariance(DECIDUOUS_GROW_TIME[2].base, DECIDUOUS_GROW_TIME[2].random) end,
    fn = SetNormal,
    growfn = GrowNormal,
}, {
    name = "tall",
    time = function(inst) return GetRandomWithVariance(DECIDUOUS_GROW_TIME[3].base, DECIDUOUS_GROW_TIME[3].random) end,
    fn = SetTall,
    growfn = GrowTall,
} }

local function chop_tree(inst, chopper, chops)
    if chopper and chopper:HasTag("beaver") then
        inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/beaver_chop_tree")
    else
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end

    inst.AnimState:PlayAnimation(inst.anims.chop)

    PushSway(inst)
end

local function dig_up_stump(inst)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function chop_down_tree(inst, chopper)
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    while inst:HasTag("shelter") do inst:RemoveTag("shelter") end
    while inst:HasTag("cattoyairborne") do inst:RemoveTag("cattoyairborne") end
    inst:AddTag("stump")

    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    local pt = inst:GetPosition()
    local hispos = chopper:GetPosition()
    local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        if inst.components.growable and inst.components.growable.stage == 3 then
            inst.components.lootdropper:SpawnLootPrefab("teatree_nut", pt - TheCamera:GetRightVec())
        end
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        if inst.components.growable and inst.components.growable.stage == 3 then
            inst.components.lootdropper:SpawnLootPrefab("teatree_nut", pt + TheCamera:GetRightVec())
        end
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    -- if inst.components.inventory then
    inst.components.inventory:DropEverything(false, false)
    -- end

    if inst.components.childspawner then
        inst.components.childspawner:ReleaseAllChildren()
        inst.components.childspawner:StopSpawning()
        inst:RemoveComponent("childspawner")
    end

    RemovePhysicsColliders(inst)
    inst.AnimState:PushAnimation(inst.anims.stump)
    inst.MiniMapEntity:SetIcon("teatree_stump.tex")

    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.growable then inst.components.growable:StopGrowing() end
end

local function chop_down_burnt_tree(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
    RemovePhysicsColliders(inst)
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)
    inst.components.inventory:DropEverything(false, false)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
    if inst.acorntask then
        inst.acorntask:Cancel()
        inst.acorntask = nil
    end
end

local function BurnInventoryItems(inst)
    if inst.components.inventory then
        local burnableItems = inst.components.inventory:FindItems(function(item) return item.components.burnable end)
        for index, burnableItem in ipairs(burnableItems) do burnableItem.components.burnable:Ignite(true) end
    end
end

local function onburntchanges(inst)
    inst:RemoveComponent("growable")
    inst:RemoveTag("shelter")
    inst:RemoveTag("cattoyairborne")
    inst:RemoveTag("fire")

    inst.components.lootdropper:SetLoot({})
    if treecommon.drop_nut then inst.components.lootdropper:AddChanceLoot("teatree_nut", .1) end

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
    end

    inst:RemoveComponent("childspawner")

    inst.AnimState:PlayAnimation(inst.anims.burnt, true)
    inst.MiniMapEntity:SetIcon("teatree_burnt.tex")
    inst:DoTaskInTime(3 * FRAMES, function(inst)
        if inst.components.burnable and inst.components.propagator then
            inst.components.burnable:Extinguish()
            inst.components.propagator:StopSpreading()
            inst:RemoveComponent("burnable")
            inst:RemoveComponent("propagator")
        end
    end)
end

local function OnBurnt(inst, imm)
    inst:AddTag("burnt")
    if imm then
        onburntchanges(inst)
    else
        inst:DoTaskInTime(.5, function(inst) onburntchanges(inst) end)
    end
    inst.AnimState:SetRayTestOnBB(true);
end

local function tree_burnt(inst)
    OnBurnt(inst)
    inst.acorntask = inst:DoTaskInTime(10, function()
        local pt = inst:GetPosition() + (math.random(0, 1) == 1 and TheCamera:GetRightVec() or -TheCamera:GetRightVec())
        inst.components.lootdropper:DropLoot(pt)
        inst.acorntask = nil
    end)
    if inst.leaveschangetask then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end
end

local function handler_growfromseed(inst)
    inst.components.growable:SetStage(1)

    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    inst.anims = short_anims

    PushSway(inst)
end

local function inspect_tree(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local function OnIgnite(inst)
    BurnInventoryItems(inst)
    if inst.components.childspawner then
        inst.components.childspawner:ReleaseAllChildren()
        inst.components.childspawner:StopSpawning()
    end
end

local function OnEntitySleep(inst)
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("inspectable")
end

local function OnEntityWake(inst)
    if not inst:HasTag("burnt") and not inst:HasTag("fire") then
        if not inst.components.burnable then
            if inst:HasTag("stump") then
                MakeSmallBurnable(inst)
            else
                MakeLargeBurnable(inst)
                inst.components.burnable:SetFXLevel(5)
                inst.components.burnable:SetOnBurntFn(tree_burnt)
                inst.components.burnable.extinguishimmediately = false
                inst.components.burnable:SetOnIgniteFn(OnIgnite)
                inst.components.burnable.onextinguish = function(inst)
                end
            end
        end
        if not inst.components.propagator then MakeLargePropagator(inst) end
    end

    if not inst:HasTag("burnt") and inst:HasTag("fire") then
        inst.AnimState:SetBank("tree_leaf")
        OnBurnt(inst, true)
    end

    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end

local function TestSpawning(inst)
    if TheWorld.state.isday or (TheWorld.state.moonphase == "new" and TheWorld.state.isnight) then
        inst.components.childspawner:StartSpawning()
    else
        inst.components.childspawner:StopSpawning()
    end
end

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.TEATREE_RELEASE_TIME, TUNING.TEATREE_REGEN_TIME)
end

local function spawner_presetup(inst)
    local childspawner = inst:AddComponent("childspawner")
    childspawner.childname = "piko"
    childspawner:SetRareChild("piko_orange", .25)
    childspawner:SetRegenPeriod(TUNING.TEATREE_REGEN_TIME)   -- 4 days regen
    childspawner:SetSpawnPeriod(TUNING.TEATREE_RELEASE_TIME) -- 8 seconds spawn
    childspawner:SetMaxChildren(1)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.TEATREE_REGEN_TIME, true)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.TEATREE_RELEASE_TIME, true)
end

local setupfns = {
    normal = function(inst)
        inst:RemoveComponent("childspawner")
    end,
    stump = function(inst)
        inst.AnimState:PlayAnimation(inst.anims.stump)
        inst:AddTag("stump")
        inst:RemoveTag("teatree")
        inst:RemoveTag("shelter")
        inst:RemoveTag("cattoyairborne")
        inst.MiniMapEntity:SetIcon("teatree_stump.tex")

        inst:RemoveComponent("burnable")
        MakeSmallBurnable(inst)
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("growable")
        RemovePhysicsColliders(inst)
        inst:RemoveComponent("childspawner")

        inst:RemoveComponent("workable")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(dig_up_stump)
        inst.components.workable:SetWorkLeft(1)
    end,
    burnt = function(inst)
        inst:AddTag("burnt")
        inst:AddTag("fire") -- Add the fire tag here: OnEntityWake will handle it actually doing burnt logic
        inst.MiniMapEntity:SetIcon("teatree_burnt.tex")
        inst:RemoveComponent("childspawner")
    end,
    nest = function(inst)
        if not inst.components.childspawner then
            spawner_presetup(inst)
        end
        TestSpawning(inst)
        inst:ListenForEvent("enterlight", TestSpawning)
        inst:ListenForEvent("enterdark", TestSpawning)
    end
}

local function onsave(inst, data)
    if inst:HasTag("stump") then
        data.stump = true
    elseif inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    elseif inst.components.childspawner ~= nil then
        data.nest = true
    end
end

local function onload(inst, data)
    if not data then return end
    setupfns[data.nest and "nest" or data.burnt and "burnt" or data.stump and "stump" or
        "normal"](inst)
    if not inst.components.growable then return end
    inst.anims = ({ short_anims, normal_anims, tall_anims })[inst.components.growable.stage]
    PushSway(inst)
end

local function tree(name, stage, type)
    return Prefab(name, function()
        stage = stage ~= 0 and stage or math.random(1, 3)

        local inst = CreateEntity()
        inst.entity:AddNetwork()
        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        local anim = inst.entity:AddAnimState()
        inst.color = .7 + math.random() * .3
        anim:SetBank("tree_leaf")
        anim:SetBuild("teatree_trunk_build")
        anim:OverrideSymbol("swap_leaves", treecommon.leavesbuild, "swap_leaves")
        anim:SetMultColour(inst.color, inst.color, inst.color, 1)

        MakeObstaclePhysics(inst, .25)

        inst.MiniMapEntity:SetIcon("teatree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("teatree")
        inst:AddTag("shelter")
        inst:AddTag("workable")
        inst:AddTag("cattoyairborne")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventory")

        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)
        inst.components.burnable.extinguishimmediately = false
        inst.components.burnable:SetOnIgniteFn(OnIgnite)

        MakeLargePropagator(inst)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        inst:AddComponent("lootdropper")
        inst:AddComponent("mystery")

        local growable = inst:AddComponent("growable")
        growable.stages = growth_stages
        growable:SetStage(stage)
        growable.loopstages = true
        growable.springgrowth = true
        growable:StartGrowing()

        inst.growfromseed = handler_growfromseed

        inst.AnimState:SetTime(math.random() * 2)

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnPreLoad = OnPreLoad

        MakeSnowCovered(inst, .01)

        inst:SetPrefabName(treecommon.prefab_name)

        spawner_presetup(inst)
        if type == "burnt" then
            inst:RemoveComponent("childspawner")
            OnBurnt(inst)
        else
            setupfns[type or "normal"](inst)
        end

        inst.setupspawner = spawner_presetup
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        return inst
    end, assets, prefabs)
end

return tree("teatree", 0), tree("teatree_burnt", 0, "burnt"),
    tree("teatree_stump", 0, "stump"), tree("teatree_piko_nest", 0, "nest"),
    tree("teatree_tall", 3), tree("teatree_normal", 2), tree("teatree_short", 1)
