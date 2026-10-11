local ClimateProfiles = require("tools/climateprofiles")

local assets =
{
    Asset("ANIM", "anim/sharkitten_den.zip"),
}

local prefabs =
{
    "sharkitten",
    "tigershark",
}

local function ReturnChildren(inst)
    for _, child in pairs(inst.components.childspawner.childrenoutside) do
        if child:IsValid() then
            if child.components.homeseeker ~= nil then
                child.components.homeseeker:GoHome()
            end
            child:PushEvent("gohome")
        end
    end
end

local function CanRelease(inst)
    return inst.spawneractive and TheWorld.state.iscaveday
end

local function SummonShark(inst, player)
    if inst.spawneractive then
        TheWorld.components.tigersharker:Protect(inst:GetPosition(), player)
    end
end

local function SpawnKittens(inst, num)
    if not CanRelease(inst) then return 0 end
    local population = inst.components.childspawner
    local spawned = 0
    for _ = 1, math.min(num or 0, population.childreninside) do
        if population:SpawnChild() == nil then break end
        spawned = spawned + 1
    end
    return spawned
end

local function UpdateActivity(inst)
    local active = ClimateProfiles.IsShipwreckedMonsoon(TheWorld.state)
    if active ~= inst.spawneractive then
        inst.spawneractive = active
        inst.AnimState:PlayAnimation(active and "idle_active" or "idle_inactive")
        if active then
            inst.blink_task = inst:DoPeriodicTask(10 + math.random() * 10, function()
                if inst.components.childspawner.childreninside > 0 then
                    inst.AnimState:PlayAnimation("blink")
                    inst.AnimState:PushAnimation("idle_active")
                end
            end)
        elseif inst.blink_task ~= nil then
            inst.blink_task:Cancel()
            inst.blink_task = nil
        end
    end

    local population = inst.components.childspawner
    if CanRelease(inst) then
        if not population.spawning then population:StartSpawning() end
    else
        population:StopSpawning()
        ReturnChildren(inst)
    end
end

local function GetStatus(inst)
    return not inst.spawneractive and "INACTIVE" or nil
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("sharkitten_den.tex")
    inst.AnimState:SetBuild("sharkitten_den")
    inst.AnimState:SetBank("sharkittenden")
    inst.AnimState:PlayAnimation("idle_inactive")
    inst:AddTag("sharkhome")
    MakeObstaclePhysics(inst, 2)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "sharkitten"
    inst.components.childspawner:SetRegenPeriod(60 * 4)
    inst.components.childspawner:SetSpawnPeriod(60 * 4)
    inst.components.childspawner:SetMaxChildren(4)
    inst.components.childspawner.canspawnfn = CanRelease
    inst.components.childspawner:StartRegen()

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(SummonShark)
    inst.components.playerprox:SetDist(7.5, 10)
    inst.components.playerprox:SetPlayerAliveMode(true)
    inst.components.playerprox:Schedule(1)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.SpawnKittens = SpawnKittens

    inst:WatchWorldState("season", UpdateActivity)
    inst:WatchWorldState("iscaveday", UpdateActivity)
    -- Run after component save data and child references have been restored.
    inst:DoTaskInTime(0, UpdateActivity)

    return inst
end

return Prefab("sharkittenspawner", fn, assets, prefabs)
