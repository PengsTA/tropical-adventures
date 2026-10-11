local DenPopulation = require("tools/den_population")
local assets =
{
    Asset("ANIM", "anim/ballphin_house.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "ballphin",
}

local loot =
{
    "limestone",
    "limestone",
    "seaweed",
    "seaweed",
    "dorsalfin",
}

local function onfar(inst)

end
local TOTAL_DAY_TIME = 480
local function LightsOn(inst)
    if not inst:HasTag("burnt") then
        inst.Light:Enable(true)

        inst.AnimState:PlayAnimation("lit", true)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/ballphin_house/lit")
        inst.lightson = true
    end
end

local function LightsOff(inst)
    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
    inst.lightson = false
end

local function getstatus(inst)
    if inst.components.childspawner and inst.components.childspawner.childreninside > 0 then
        return "FULL"
    end
end

local function onnear(inst)

end

local function onoccupied(inst, child)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/balphin/in_house_LP", "pigsound")
    inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end

    inst.doortask = inst:DoTaskInTime(1, function() LightsOn(inst) end)
end

local function onvacate(inst, child)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
    inst.SoundEmitter:KillSound("pigsound")

    if child then
        if child.components.health then
            child.components.health:SetPercent(1)
        end
    end
end


local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
    if inst.components.childspawner then inst.components.childspawner:ReleaseAllChildren() end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function ongusthammerfn(inst)
    onhammered(inst, nil)
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnDay(inst)
    --print(inst, "OnDay")
    if not inst:HasTag("burnt") then
        if inst.components.childspawner.childreninside > 0 then
            LightsOff(inst)
            if inst.doortask then
                inst.doortask:Cancel()
                inst.doortask = nil
            end
            inst.doortask = inst:DoTaskInTime(1 + math.random() * 2,
                function() inst.components.childspawner:ReleaseAllChildren() end)
        end
    end
end
--[[
local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/ballphin_house_craft")
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_medium")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end]]


local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local light = inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("ballphinhouse.tex")

    light:SetFalloff(1)
    light:SetIntensity(.5)
    light:SetRadius(2)
    light:Enable(false)
    light:SetColour(0 / 255, 180 / 255, 255 / 255)
    inst:SetPhysicsRadiusOverride(2)
    MakeWaterObstaclePhysics(inst, 1, 2, 1.25)

    anim:SetBank("ballphin_house")
    anim:SetBuild("ballphin_house")
    anim:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("mudacamada")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    local population = DenPopulation.Configure(inst, "ballphin", TUNING.TOTAL_DAY_TIME * 4, true, false)
    population.onoccupied = onoccupied
    population.onvacate = onvacate

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(10, 13)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    inst:AddComponent("inspectable")

    inst.components.inspectable.getstatus = getstatus

    MakeSnowCovered(inst, .01)

    inst:ListenForEvent("burntup", function(inst)
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
    end)
    inst:ListenForEvent("onignite", function(inst)
        if inst.components.childspawner then
            inst.components.childspawner:ReleaseAllChildren()
        end
    end)


    --inst:ListenForEvent("onbuilt", onbuilt)
    inst:DoTaskInTime(math.random(), function()
        --print(inst, "spawn check day")
        if TheWorld.state.isday then
            OnDay(inst)
        end
    end)

    inst:WatchWorldState("startcaveday", OnDay)
    inst:WatchWorldState("isday", function(den, isday)
        if isday then den.components.childspawner:StartSpawning()
        else den.components.childspawner:StopSpawning() end
    end)
    inst:DoTaskInTime(0, function(den)
        if TheWorld.state.isday then den.components.childspawner:StartSpawning() end
    end)

    return inst
end

return Prefab("ballphinhouse", fn, assets, prefabs),
    MakePlacer("ballphinhouse_placer", "ballphin_house", "ballphin_house", "idle", false, false, false)
