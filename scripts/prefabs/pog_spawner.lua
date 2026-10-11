local prefabs = { "pog" }

local function OnVacate(inst)
    inst.components.spawner:SetOnlySpawnOffscreen(true)
end

local function OnLoad(inst, data)
    if data ~= nil and data.spawner ~= nil then
        inst.components.spawner:SetOnlySpawnOffscreen(true)
    end
end

local function OnLoadPostPass(inst)
    local spawner = inst.components.spawner
    if spawner.child == nil and spawner.nextspawntime == nil and not spawner:IsSpawnPending() then
        spawner:SpawnWithDelay(spawner.delay)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    if not TheWorld.ismastersim then
        inst:Remove()
        return inst
    end

    inst:AddComponent("spawner")
    inst.components.spawner:SetOnVacateFn(OnVacate)
    inst.components.spawner:Configure("pog", TUNING.TOTAL_DAY_TIME * 4)
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("pog_spawner", fn, nil, prefabs)
