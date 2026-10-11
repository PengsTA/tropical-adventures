local assets = { Asset("ANIM", "anim/ant_house.zip"), Asset("MINIMAP_IMAGE", "ant_house") }
local prefabs = { "antman", "antman2", "antman_warrior" }

local function OnSpawned(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
end

local function ReleaseResidents(inst)
    local spawner = inst.components.childspawner
    while spawner:CanSpawn() do
        if spawner:SpawnChild() == nil then break end
    end
end

local function MakeNest(name, child, population)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()
        inst.MiniMapEntity:SetIcon("ant_house.tex")
        inst.AnimState:SetBuild("ant_house")
        inst.AnimState:SetBank("ant_house")
        inst.AnimState:PlayAnimation("idle", true)
        MakeObstaclePhysics(inst, 1.3)
        inst:AddTag("structure")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("childspawner")
        local spawner = inst.components.childspawner
        spawner.childname = child
        spawner:SetRegenPeriod(TUNING.ANTMAN_REGEN_TIME)
        spawner:SetSpawnPeriod(TUNING.ANTMAN_RELEASE_TIME)
        spawner:SetMaxChildren(population)
        spawner:SetSpawnedFn(OnSpawned)
        spawner:StartRegen()
        spawner:StartSpawning()
        inst:AddComponent("inspectable")
        inst:AddComponent("playerprox")
        inst.components.playerprox:SetOnPlayerNear(ReleaseResidents)
        inst.components.playerprox:SetDist(12, 16)
        return inst
    end
    return Prefab(name, fn, assets, prefabs)
end

return MakeNest("antcombhomecave", "antman", 3),
    MakeNest("antcombhomecavenursery", "antman2", 3),
    MakeNest("antcombhomecavewarrior", "antman_warrior", 1)
