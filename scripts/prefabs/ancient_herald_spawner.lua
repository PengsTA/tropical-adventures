local prefabs =
{
    "ancient_herald",
}

local RESPAWN_DAYS = 15
local RESPAWN_TIME = RESPAWN_DAYS * (TUNING and TUNING.TOTAL_DAY_TIME or 480)

local function OnHeraldKilled(inst)
    inst.herald = nil
    if not inst.components.timer:TimerExists("spawndelay") then
        inst.components.timer:StartTimer("spawndelay", RESPAWN_TIME)
    end
end

local function OnHeraldRemoved(inst, herald)
    if inst.herald == herald then
        inst.herald = nil
        if herald.components.health and herald.components.health:IsDead() then
            if not inst.components.timer:TimerExists("spawndelay") then
                inst.components.timer:StartTimer("spawndelay", RESPAWN_TIME)
            end
        end
    end
end

local function TrackHerald(inst, herald)
    inst.herald = herald
    herald:AddTag("ruins_guardian")
    inst:ListenForEvent("death", function() OnHeraldKilled(inst) end, herald)
    inst:ListenForEvent("onremove", function() OnHeraldRemoved(inst, herald) end, herald)
end

local function SpawnHerald(inst)
    if inst.components.timer:TimerExists("spawndelay") then
        return
    end

    if inst.herald and inst.herald:IsValid() and not (inst.herald.components.health and inst.herald.components.health:IsDead()) then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local herald = SpawnPrefab("ancient_herald")
    if herald then
        herald.Transform:SetPosition(x, y, z)
        TrackHerald(inst, herald)
    end
end

local function OnTimerDone(inst, data)
    if data and data.name == "spawndelay" then
        SpawnHerald(inst)
    end
end

local function OnSave(inst, data)
    if inst.herald and inst.herald:IsValid() then
        data.herald_id = inst.herald.GUID
        return { inst.herald.GUID }
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data and data.herald_id and newents[data.herald_id] then
        local herald = newents[data.herald_id].entity
        if herald and herald:IsValid() then
            TrackHerald(inst, herald)
        end
    end

    if not inst.components.timer:TimerExists("spawndelay") and (inst.herald == nil or not inst.herald:IsValid()) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 40, { "ancient_herald" })
        if #ents > 0 then
            TrackHerald(inst, ents[1])
        else
            SpawnHerald(inst)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst:DoTaskInTime(0, function()
        if not inst.components.timer:TimerExists("spawndelay") and (inst.herald == nil or not inst.herald:IsValid()) then
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 40, { "ancient_herald" })
            if #ents > 0 then
                TrackHerald(inst, ents[1])
            else
                SpawnHerald(inst)
            end
        end
    end)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("ancient_herald_spawner", fn, nil, prefabs)
