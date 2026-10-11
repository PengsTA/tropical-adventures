local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")

local BRAMBLE_THORN_DAMAGE = TUNING.BRAMBLE_THORN_DAMAGE or 3
local BRAMBLE_SPIKE_HEALTH = TUNING.BRAMBLE_THORN_HEALTH or 40
local BRAMBLE_CORE_HEALTH = TUNING.BRAMBLE_CORE_HEALTH or 200
local THICKET_RADIUS = 2
local THICKET_SPIKE_COUNT = 6

local assets = {
    Asset("ANIM", "anim/bramble.zip"),
    Asset("ANIM", "anim/bramble1_build.zip"),
    Asset("ANIM", "anim/bramble_core.zip"),
}

local prefabs = {
    "bramble_bulb",
    "vine",
}

SetSharedLootTable("bramble", {
    { "bramble_bulb", 1.00 },
    { "vine", 1.00 },
    { "vine", 1.00 },
    { "vine", .25 },
    { "vine", .25 },
})

local function IsLushBrambleLocation(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    local map = TheWorld.Map
    return TUNING.brambles
        and ClimateProfiles.IsHamletLush(TheWorld.state)
        and map:IsAboveGroundAtPoint(x, 0, z)
        and not map:IsInteriorAtPoint(x, 0, z)
        and map:IsPrimaryRegionAtPoint(x, 0, z, RegionDefs.PRIMARY.hamlet)
        and not map:IsSubregionAtPoint(x, 0, z, RegionDefs.SUBREGION.ham_city)
end

local function RemoveOutsideLushSeason(inst)
    if not IsLushBrambleLocation(inst) then
        inst:Remove()
    end
end

local function IsMeleeAttack(data)
    return data ~= nil
        and (data.weapon == nil or (not data.weapon:HasTag("projectile") and data.weapon.projectile == nil))
end

local function RetaliateWithThorns(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if IsMeleeAttack(data)
        and attacker ~= nil
        and attacker.components.combat ~= nil
        and data.stimuli ~= "thorns"
        and not attacker:HasTag("thorny")
        and (attacker.components.combat.defaultdamage or 0) > 0 then
        attacker.components.combat:GetAttacked(inst, BRAMBLE_THORN_DAMAGE, nil, "thorns")
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/armour/cactus")
    end
end

local function BindSpike(core, spike)
    core._spikes = core._spikes or {}
    core._spikes[spike] = true
    spike._core = core
end

local function ClearSpikes(inst)
    for spike in pairs(inst._spikes or {}) do
        if spike:IsValid() then spike:Remove() end
    end
    inst._spikes = nil
end

local function OnCoreDeath(inst)
    ClearSpikes(inst)
    inst.AnimState:PlayAnimation("wither")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/wilther")
    inst.components.lootdropper:DropLoot()
    inst:DoTaskInTime(2, inst.Remove)
end

local function OnSpikeDeath(inst)
    if inst._core ~= nil and inst._core._spikes ~= nil then
        inst._core._spikes[inst] = nil
    end
    inst.AnimState:PlayAnimation("wither")
    inst:DoTaskInTime(2, inst.Remove)
end

local function SaveSpike(inst, data)
    if inst._core ~= nil and inst._core:IsValid() then
        data.core = inst._core.GUID
        return { data.core }
    end
end

local function LoadSpike(inst, newents, data)
    local entry = data ~= nil and data.core ~= nil and newents[data.core] or nil
    if entry ~= nil and entry.entity:IsValid() then BindSpike(entry.entity, inst) end
end

local function AdoptLegacySpikes(inst, newents, data)
    inst:DoTaskInTime(0, function(core)
        if core.components.health:IsDead() then ClearSpikes(core); return end
        local x, y, z = core.Transform:GetWorldPosition()
        local spikes = TheSim:FindEntities(x, y, z, THICKET_RADIUS + .5, { "bramble" }, { "bramble_core", "INLIMBO" })
        for _, spike in ipairs(spikes) do
            if spike._core == nil and not spike.components.health:IsDead() then BindSpike(core, spike) end
        end
    end)
end

local function ConfigureBrambleEntity(inst, health, is_core)
    inst:AddTag("hostile")
    inst:AddTag("bramble")
    inst:AddTag("tropical_bramble")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(health)
    inst:AddComponent("combat")
    inst:AddComponent("inspectable")

    if is_core then
        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("bramble")
        inst:ListenForEvent("death", OnCoreDeath)
        inst.OnRemoveEntity = ClearSpikes
        inst.OnLoadPostPass = AdoptLegacySpikes
    else
        inst:ListenForEvent("death", OnSpikeDeath)
        inst.OnSave = SaveSpike
        inst.OnLoadPostPass = LoadSpike
    end

    inst:ListenForEvent("attacked", RetaliateWithThorns)
    inst:WatchWorldState("season", RemoveOutsideLushSeason)
    inst:DoTaskInTime(0, RemoveOutsideLushSeason)
end

local function spikefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("bramble_" .. math.random(1, 3))
    inst.AnimState:SetBuild("bramble1_build")
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle")
    inst.Transform:SetTwoFaced()

    ConfigureBrambleEntity(inst, BRAMBLE_SPIKE_HEALTH, false)

    return inst
end

local function corefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("bramble_core")
    inst.AnimState:SetBuild("bramble_core")
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)

    inst:AddTag("bramble_core")
    ConfigureBrambleEntity(inst, BRAMBLE_CORE_HEALTH, true)

    return inst
end

local function IsClearForSpike(x, z)
    if not TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then
        return false
    end

    for _, entity in ipairs(TheSim:FindEntities(x, 0, z, .75, nil, { "INLIMBO", "FX", "NOCLICK" })) do
        if entity:HasTag("player")
            or entity:HasTag("structure")
            or entity:HasTag("wall")
            or entity:HasTag("tree")
            or entity:HasTag("boulder")
            or entity:HasTag("bramble") then
            return false
        end
    end
    return true
end

local function SpawnThicket(inst)
    if not IsLushBrambleLocation(inst) then
        inst:Remove()
        return
    end

    local x, _, z = inst.Transform:GetWorldPosition()
    if not IsClearForSpike(x, z) then
        inst:Remove()
        return
    end

    local core = SpawnPrefab("bramble_core")
    if core ~= nil then
        core.Transform:SetPosition(x, 0, z)
    end

    local angle_offset = math.random() * 2 * PI
    for index = 1, THICKET_SPIKE_COUNT do
        local angle = angle_offset + (index - 1) * 2 * PI / THICKET_SPIKE_COUNT
        local spike_x = x + math.cos(angle) * THICKET_RADIUS
        local spike_z = z + math.sin(angle) * THICKET_RADIUS
        if IsClearForSpike(spike_x, spike_z) then
            local spike = SpawnPrefab("bramblespike")
            if spike ~= nil then
                if core ~= nil then BindSpike(core, spike) end
                spike.Transform:SetPosition(spike_x, 0, spike_z)
                spike.Transform:SetRotation(angle * 180 / PI)
            end
        end
    end

    inst:Remove()
end

local function bramblefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("tropical_bramble")
    inst.persists = false

    inst.entity:SetPristine()

    if TheWorld.ismastersim then
        inst:DoTaskInTime(0, SpawnThicket)
    end

    return inst
end

return Prefab("bramblespike", spikefn, assets, prefabs),
    Prefab("bramble", bramblefn, assets, prefabs),
    Prefab("bramble_core", corefn, assets, prefabs)
