require "prefabutil"
local DenPopulation = require("tools/den_population")

local assets =
{
    Asset("ANIM", "anim/dragoon_den.zip"),
}

local prefabs =
{
    "dragoon",
}

local function ongohome(inst, child)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function onhammered(inst, worker)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/dragoon_den_place")
end

local function OnStartDay(inst)
    --print(inst, "OnStartDay")
    if inst.components.childspawner.childreninside > 0 then
        inst.components.childspawner:ReleaseAllChildren()
    end
end

local function spawncheckday(inst)
    inst.inittask = nil
    inst:WatchWorldState("startcaveday", OnStartDay)
    if inst.components.childspawner ~= nil then
        if TheWorld.state.iscaveday or
            (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
            inst.components.childspawner:StartSpawning()
            inst.components.childspawner:ReleaseAllChildren()
        else
            inst.components.childspawner:StopSpawning()
        end
    end
end

local function oninit(inst)
    inst.inittask = inst:DoTaskInTime(math.random(), spawncheckday)
end

local function onoccupied(inst, child)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/idle")
end

local function onvacate(inst, child)
    if child ~= nil then
        if child.components.health ~= nil then
            child.components.health:SetPercent(1)
        end
    end
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    MakeObstaclePhysics(inst, 1.5)

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("dragoon_den.tex")

    anim:SetBank("dragoon_den")
    anim:SetBuild("dragoon_den")
    anim:PlayAnimation("idle", true)

    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(nil)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    local population = DenPopulation.Configure(inst, "dragoon", TUNING.TOTAL_DAY_TIME, false, true)
    population.onoccupied = onoccupied
    population.onvacate = onvacate
    population.ongohome = ongohome
    inst:WatchWorldState("iscaveday", function(den, isday)
        if isday then den.components.childspawner:StartSpawning()
        else den.components.childspawner:StopSpawning() end
    end)

    inst:AddComponent("inspectable")

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.inittask = inst:DoTaskInTime(0, oninit)
    return inst
end

return Prefab("dragoonden", fn, assets, prefabs),
    MakePlacer("dragoonden_placer", "dragoon_den", "dragoon_den", "idle")
