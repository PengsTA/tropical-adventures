local Traps = require("tools/cave_ruins_traps")
local Connections = require("map/ruins_connections")
local assets = { Asset("ANIM", "anim/wall_pig_ruins.zip") }
local dependencies = { "ta_ruins_pressure_plate", "ta_ruins_dart_statue", "ta_ruins_row_spear",
    "ta_ruins_treasure_spear",
    "ta_ruins_stone_block", "ta_ruins_dense_vine", "ta_ruins_rubble",
    "pig_ruins_creeping_vines", "rock1", "wall_pig_ruins" }

local function Valid(inst)
    return inst ~= nil and inst:IsValid()
end

local function Ground(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, 0, z)
end

local function StoneBlock()
    local inst = Prefabs.wall_pig_ruins.fn()
    inst:SetPrefabNameOverride("wall_pig_ruins")
    inst.Physics:SetCapsule(.55, 2)
    inst:SetPhysicsRadiusOverride(.55)
    if not TheWorld.ismastersim then return inst end
    local oldload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if oldload then oldload(inst, data) end
        Ground(inst)
    end
    return inst
end

local function WideObstacle(base)
    return function()
        local inst = Prefabs[base].fn()
        inst:SetPrefabNameOverride(base)
        inst.Physics:SetCapsule(1.3, 2)
        inst.Physics:SetDontRemoveOnSleep(true)
        inst:SetPhysicsRadiusOverride(1.3)
        if TheWorld.ismastersim then
            local oldload = inst.OnLoad
            inst.OnLoad = function(inst, data)
                if oldload then oldload(inst, data) end
                Ground(inst)
            end
            inst:DoTaskInTime(0, Ground)
        end
        if TheWorld.ismastersim and base == "rock1" and inst.components.workable then
            inst.components.workable.onloadfn = function(inst)
                local left = inst.components.workable.workleft
                inst.AnimState:PlayAnimation(left < TUNING.ROCKS_MINE / 3 and "low"
                    or left < TUNING.ROCKS_MINE * 2 / 3 and "med" or "full")
            end
        end
        return inst
    end
end

local function ConfigureSpear(inst)
    inst:AddTag(Traps.TARGET_TAG)
    inst:SetPrefabNameOverride("pig_ruins_spear_trap")
    inst.Physics:SetCapsule(.55, 2)
    inst:SetPhysicsRadiusOverride(.55)
    if not TheWorld.ismastersim then return inst end
    local function Hit(other)
        if inst.components.health and inst.components.health:IsDead() then return end
        if not inst.extended or not Valid(other) or not other.components.health
            or other:HasTag("wall") or other:HasTag("structure") or other:HasTag("spear_trap") then return end
        local owner = inst._ruins_owner
        if not owner then return end
        local now = GetTime()
        if (owner._hits[other] or -100) + .8 <= now then
            owner._hits[other] = now
            inst.components.combat:DoAttack(other)
        end
    end
    inst.inflictdamage = function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        for _, other in ipairs(TheSim:FindEntities(x, y, z, 1.1, nil, { "INLIMBO", "FX", "spear_trap" })) do
            Hit(other)
        end
    end
    inst.Physics:SetCollisionCallback(function(_, other) Hit(other) end)
    inst.HitTarget = Hit
    return inst
end

local function Spear(periodic)
    return function()
        return ConfigureSpear(Prefabs[periodic and "ta_ruins_spear_trap" or "pig_ruins_spear_trap"].fn())
    end
end

local function Burst(inst)
    if inst:IsAsleep() then return false end
    if inst.disarmed then return false end
    for _, part in ipairs(inst.parts) do
        if part.role == "dart" and Valid(part.entity) then Traps.ActivateTarget(part.entity) end
        if part.role == "spike" and Valid(part.entity) then
            local child = part.entity
            child.wantstoretract, child.wantstoextend = nil, true
            child:PushEvent("spring")
            child:DoTaskInTime(1.2, function(child)
                child.wantstoretract, child.wantstoextend = true, nil
                child:PushEvent("reset")
            end)
        end
    end
    return true
end

local function Stop(inst)
    if inst._stoptask then inst._stoptask:Cancel(); inst._stoptask = nil end
    inst._active_until = nil
    for _, part in ipairs(inst.parts) do
        if Valid(part.entity) then
            if part.role == "dart" then Traps.DeactivateTarget(part.entity) end
            if part.role == "spike" then
                part.entity.wantstoretract, part.entity.wantstoextend = true, nil
                part.entity:PushEvent("reset")
            end
        end
    end
end

local function Start(inst, duration)
    if inst.disarmed or inst._removing then return false end
    local hasplate = false
    for _, part in ipairs(inst.parts) do
        if part.role == "plate" and Valid(part.entity) and part.entity.components.disarmable.armed then hasplate = true end
    end
    if not hasplate or not Burst(inst) then return false end
    if inst._stoptask then inst._stoptask:Cancel() end
    duration = duration or 4
    inst._active_until = GetTime() + duration
    inst._stoptask = inst:DoTaskInTime(duration, Stop)
    return true
end

local function Damage(inst)
    if inst:IsAsleep() then return end
    local raised = {}
    for _, part in ipairs(inst.parts) do
        local child = part.entity
        if (part.role == "spear" or part.role == "spike") and Valid(child) and child.extended
            and not (child.components.health and child.components.health:IsDead()) then
            raised[#raised + 1] = child
        end
    end
    if #raised == 0 then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, target in ipairs(TheSim:FindEntities(x, y, z, 5, nil, { "INLIMBO", "FX", "spear_trap" })) do
        if target.components.health then
            local tx, _, tz = target.Transform:GetWorldPosition()
            for _, child in ipairs(raised) do
                local cx, _, cz = child.Transform:GetWorldPosition()
                if (tx-cx)^2 + (tz-cz)^2 <= 1.21 then child.HitTarget(target); break end
            end
        end
    end
end

local function FireTreasure(inst)
    if not inst.triggered or inst.fired or inst.disarmed then return end
    if inst._warning then return end
    for _, part in ipairs(inst.parts) do
        if part.role == "plate" and Valid(part.entity) then
            part.entity.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/pressure_plate/hit")
            part.entity.AnimState:PlayAnimation("popup")
            part.entity.AnimState:PushAnimation("up_idle", true)
        end
    end
    inst._warning = inst:DoTaskInTime(1.2, function(inst)
        inst._warning = nil
        if Start(inst) then inst.fired = true end
    end)
end

local function Control(inst, plate, action)
    if inst._removing then return end
    if inst.kind == "gate" then return end
    if action == "disarm" then
        inst.disarmed = true
        Stop(inst)
    elseif action == "press" then
        Start(inst)
    end
end

local function Attach(inst, child, role)
    if not child then return end
    child.persists = false
    child._ruins_owner = inst
    if child.components.workable then child.components.workable.savestate = true end
    inst.parts[#inst.parts + 1] = { entity = child, role = role }
    if role == "dart" then
        Traps.DeactivateTarget(child)
        child.components.autodartthrower.updatefn = child.updaterotation
    elseif role == "plate" and not child.components.disarmable.armed then
        Control(inst, child, "disarm")
    elseif role == "obstacle" and inst.kind == "rubble" then
        inst:ListenForEvent("worked", function()
            inst.triggered = true
            FireTreasure(inst)
        end, child)
    end
end

local function Part(inst, prefab, along, across, role, rotation)
    local x, _, z = inst.Transform:GetWorldPosition()
    local nx, nz = Connections.Normal({ savedrotation = { rotation = inst.rotation } })
    x, z = x + nx * along - nz * across, z + nz * along + nx * across
    if not TheWorld.Map:IsPassableAtPoint(x, 0, z)
        and not (along == 0 and TheWorld.Map:IsPassableAtPoint(x - nx * .05, 0, z - nz * .05)) then return end
    local child = SpawnPrefab(prefab)
    if not child then return end
    child.Transform:SetPosition(x, 0, z)
    if rotation then
        if child.setrotation then child:setrotation(rotation) else child.Transform:SetRotation(rotation) end
    end
    Attach(inst, child, role)
    return child
end

local function BindTreasure(inst, target)
    if not Valid(target) or inst.targets[target] then return end
    inst.targets[target] = true
    inst.target = inst.target or target
    local function Trigger()
        if inst.triggered then return end
        inst.triggered = true
        FireTreasure(inst)
    end
    for _, event in ipairs({ "dislodged", "worked", "onopen", "itemlose", "onpickup", "ta_ruins_looted" }) do
        inst:ListenForEvent(event, Trigger, target)
    end
    -- Demolishing the reward must not bypass its encounter.
    inst:ListenForEvent("onremove", function()
        if not inst._removing then Trigger() end
    end, target)
end

local function FindTreasure(inst)
    if inst.triggered then return end
    local x, _, z = inst.Transform:GetWorldPosition()
    for _, spec in ipairs(inst.targetspecs or { { prefab = inst.targetprefab, x = x, z = z } }) do
        for _, target in ipairs(TheSim:FindEntities(spec.x, 0, spec.z, .3, nil, { "INLIMBO" })) do
            if target.prefab == spec.prefab then BindTreasure(inst, target) end
        end
    end
end

local function Build(inst)
    if inst.treasure then
        if not Part(inst, "ta_ruins_pressure_plate", 1.5, 0, "plate") then return end
        if inst.style == "spike" then
            for _, side in ipairs({ -1.5, 0, 1.5 }) do
                Part(inst, "ta_ruins_treasure_spear", 2.5, side, "spike")
            end
        elseif inst.style == "vault" then
            -- Use the cache's side windows rather than placing turrets in its walls.
            Part(inst, "ta_ruins_dart_statue", 0, -3, "dart", inst.rotation - 90)
            Part(inst, "ta_ruins_dart_statue", 0, 3, "dart", inst.rotation + 90)
        else
            Part(inst, "ta_ruins_dart_statue", 3, 1.5, "dart", inst.rotation)
            Part(inst, "ta_ruins_stone_block", 1, -2.5, "cover")
        end
        FindTreasure(inst)
    elseif inst.kind == "vine" or inst.kind == "rubble" then
        local half = (inst.width or 8) / 2
        for side = -half + 1, half - 1, 2 do
            local child = Part(inst, inst.kind == "vine" and "ta_ruins_dense_vine" or "ta_ruins_rubble", 0, side, "obstacle")
            if child and inst.kind == "vine" then
                local nx, nz = Connections.Normal({ savedrotation = { rotation = inst.rotation } })
                child:OnLoad({ stage = child.stage,
                    facing = nx == 1 and "east" or nx == -1 and "west" or nz == 1 and "south" or "north" })
            end
        end
        if inst.kind == "rubble" then
            Part(inst, "ta_ruins_pressure_plate", -3, 0, "plate")
            for _, side in ipairs({ -1.5, 0, 1.5 }) do Part(inst, "ta_ruins_treasure_spear", -2, side, "spike") end
        end
    elseif inst.kind == "gate" or inst.kind == "spear" then
        local half = (inst.width or 8) / 2
        for side = -half + .5, half - .5, 1 do
            local child = Part(inst, inst.kind == "gate" and "ta_ruins_stone_block" or "ta_ruins_row_spear", 0, side,
                inst.kind == "gate" and "gate" or "spear")
            if child and inst.kind == "spear" then
                child.initial_delay, child.down_time, child.up_time = 0, 3.6, 1.2
            end
        end
    elseif inst.kind == "dart" then
        for _, side in ipairs({ -3, 3 }) do
            Part(inst, "ta_ruins_pressure_plate", side, 0, "plate")
            Part(inst, "ta_ruins_stone_block", side, 2.5, "cover")
        end
        Part(inst, "ta_ruins_dart_statue", 0, -3, "dart", inst.rotation)
    end
    -- Never leave an armed ambush without a reachable control plate.
    local hasplate = false
    for _, part in ipairs(inst.parts) do if part.role == "plate" then hasplate = true end end
    if not hasplate then
        for _, part in ipairs(inst.parts) do
            if part.role == "dart" or part.role == "spike" then part.entity:Remove() end
        end
    end
end

local function Initialize(inst)
    if inst.initialized then return end
    inst.initialized = true
    if inst.treasure then
        Ground(inst)
    else
        local x, _, z = inst.Transform:GetWorldPosition()
        local ax, az, width = Connections.Align(TheWorld.Map, x, z, inst.rotation)
        inst.Transform:SetPosition(ax, 0, az)
        inst.width = width
        for _, record in ipairs(inst._records or {}) do
            record.x, record.z = record.x + ax - x, record.z + az - z
        end
    end
    if inst._records then
        for _, record in ipairs(inst._records) do
            local child = SpawnPrefab(record.prefab)
            if child then
                child.Transform:SetPosition(record.x, 0, record.z)
                -- Set ownership before load callbacks can search nearby traps.
                Attach(inst, child, record.ruins_role)
                if record.ruins_disarmed and child.components.disarmable then
                    child.components.disarmable.armed = false
                end
                child:SetPersistData(record.data)
                if record.ruins_role == "dart" then Traps.DeactivateTarget(child) end
                if record.ruins_role == "spike" and child.sg then child.sg:GoToState("idle") end
                if record.ruins_role == "plate" and not child.components.disarmable.armed then
                    Control(inst, child, "disarm")
                end
            end
        end
        inst._records = nil
    elseif not inst.built then
        Build(inst)
    end
    inst.built = true
    if inst.kind == "spear" or inst.kind == "rubble" or inst.style == "spike" then inst:DoPeriodicTask(.15, Damage) end
    if inst.treasure or inst.kind == "rubble" then
        if inst.treasure then FindTreasure(inst) end
        FireTreasure(inst)
    end
    if inst._remaining then Start(inst, inst._remaining); inst._remaining = nil end
end

local function Controller(treasure)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end
        inst.treasure = treasure
        inst.kind, inst.rotation = "open", 0
        inst.parts = {}
        inst.targets = {}
        inst._hits = setmetatable({}, { __mode = "k" })
        inst.Control = Control
        inst:DoTaskInTime(0, Initialize)
        inst.OnSave = function(inst, data)
            data.kind, data.rotation, data.built = inst.kind, inst.rotation, inst.built
            data.triggered, data.fired = inst.triggered, inst.fired
            data.targetprefab = inst.targetprefab
            data.style = inst.style
            data.targetspecs = inst.targetspecs
            data.disarmed = inst.disarmed
            data.remaining = inst._active_until and math.max(0, inst._active_until - GetTime()) or inst._remaining
            data.parts = inst._records or (inst.built and {} or nil)
            for _, part in ipairs(inst.parts) do
                if Valid(part.entity) then
                    local record = part.entity:GetSaveRecord()
                    record.ruins_role = part.role
                    record.ruins_disarmed = part.entity.components.disarmable
                        and not part.entity.components.disarmable.armed or nil
                    data.parts[#data.parts + 1] = record
                end
            end
            local refs = {}
            for target in pairs(inst.targets) do if Valid(target) then refs[#refs + 1] = target.GUID end end
            data.targetguids = refs
            return refs
        end
        inst.OnLoad = function(inst, data)
            if not data then return end
            inst.kind = data.kind or "open"
            inst.rotation = data.rotation or (data.savedrotation and data.savedrotation.rotation) or 0
            inst.built = data.built
            inst.triggered, inst.fired = data.triggered, data.fired
            inst.targetprefab = data.targetprefab or data.target
            inst.style = data.style
            inst.targetspecs = data.targetspecs or data.targets
            inst.disarmed = data.disarmed
            inst._remaining = data.remaining and data.remaining > 0 and data.remaining or nil
            inst._records = data.parts
        end
        inst.OnLoadPostPass = function(inst, newents, data)
            if data and data.targetguid and newents[data.targetguid] then
                BindTreasure(inst, newents[data.targetguid].entity)
            end
            for _, guid in ipairs(data and data.targetguids or {}) do
                if newents[guid] then BindTreasure(inst, newents[guid].entity) end
            end
        end
        inst.OnEntitySleep = Stop
        inst.OnEntityWake = function(inst)
            if inst.treasure or inst.kind == "rubble" then FireTreasure(inst) end
        end
        inst:ListenForEvent("onremove", function(inst)
            inst._removing = true
            for _, part in ipairs(inst.parts) do if Valid(part.entity) then part.entity:Remove() end end
        end)
        return inst
    end
end

return Prefab("ta_ruins_connection", Controller(false), assets, dependencies),
    Prefab("ta_ruins_treasure_guard", Controller(true), assets, dependencies),
    Prefab("ta_ruins_stone_block", StoneBlock, assets, { "wall_pig_ruins" }),
    Prefab("ta_ruins_dense_vine", WideObstacle("pig_ruins_creeping_vines"), nil, { "pig_ruins_creeping_vines" }),
    Prefab("ta_ruins_rubble", WideObstacle("rock1"), nil, { "rock1" }),
    Prefab("ta_ruins_row_spear", Spear(true), nil, { "ta_ruins_spear_trap" }),
    Prefab("ta_ruins_treasure_spear", Spear(false), nil, { "pig_ruins_spear_trap" })
