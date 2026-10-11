local VesselTransfer = require("tools/vessel_transfer")
local BermudaTravel = {}

BermudaTravel.RANGE = 3
BermudaTravel.CHARGE_TIME = 2
local CHARGE_CHECK_PERIOD = .1
local CHARGE_FX_PERIOD = .4
local COOLDOWN = 4.5
local EXIT_SEARCH_DISTANCE = 12
local EXCLUDE = { "FX", "NOCLICK", "DECOR", "INLIMBO", "_inventoryitem", "bermudatriangle" }

local function IsAtArrival(entity)
    local exit = entity._ta_bermuda_exit
    if exit ~= nil then
        local radius = VesselTransfer.GetRadius(entity)
        if exit:IsValid() and entity:GetDistanceSqToInst(exit) <= (BermudaTravel.RANGE + radius + .5)^2 then
            return true
        end
        entity._ta_bermuda_exit = nil
    end
    return false
end

local function IsCoolingDown(entity)
    local at_arrival = IsAtArrival(entity)
    return entity._avoid_whirlportals_hack or at_arrival
end

local function MarkArrival(entity, exit)
    entity._ta_bermuda_exit = exit
    exit._ta_bermuda_arrivals = exit._ta_bermuda_arrivals or {}
    exit._ta_bermuda_arrivals[entity] = true
    entity._avoid_whirlportals_hack = true
    entity:DoTaskInTime(COOLDOWN, function(inst) inst._avoid_whirlportals_hack = nil end)
end

function BermudaTravel.RefreshArrivals(inst)
    for entity in pairs(inst._ta_bermuda_arrivals or {}) do
        if not entity:IsValid() or entity._ta_bermuda_exit ~= inst then
            inst._ta_bermuda_arrivals[entity] = nil
        elseif not IsAtArrival(entity) then
            inst._ta_bermuda_arrivals[entity] = nil
        end
    end
end

local function IsBlocked(actor, boat, x, z, radius)
    for _, ent in ipairs(TheSim:FindEntities(x, 0, z, radius + MAX_PHYSICS_RADIUS, nil, EXCLUDE)) do
        local parent = ent.entity:GetParent()
        local platform = ent.GetCurrentPlatform ~= nil and ent:GetCurrentPlatform() or nil
        if ent ~= actor and ent ~= boat and parent == nil and (boat == nil or platform ~= boat)
            and ent.Physics ~= nil then
            local ex, _, ez = ent.Transform:GetWorldPosition()
            local clearance = radius + ent:GetPhysicsRadius(0) + .5
            if (ex - x)^2 + (ez - z)^2 < clearance^2 then return true end
        end
    end
    return false
end

local function FindArrival(actor, boat, exit)
    local map = TheWorld.Map
    local x, _, z = exit.Transform:GetWorldPosition()
    local radius = VesselTransfer.GetRadius(boat or actor)
    local function IsSafe(pt)
        if map:IsPointNearHole(pt) then return false end
        if boat ~= nil then
            if not map:IsOceanAtPoint(pt.x, 0, pt.z, false)
                or not map:IsSurroundedByWater(pt.x, 0, pt.z, radius) then return false end
        elseif not (map:IsOceanAtPoint(pt.x, 0, pt.z, false) or map:IsPassableAtPoint(pt.x, 0, pt.z, false)) then
            return false
        end
        return not IsBlocked(actor, boat, pt.x, pt.z, radius)
    end
    local point = Vector3(x, 0, z)
    if IsSafe(point) then return x, z end
    local search = boat ~= nil and FindSwimmableOffset or FindWalkableOffset
    for distance = 1, EXIT_SEARCH_DISTANCE do
        local offset = search(point, 0, distance, 16, false, false, IsSafe, boat == nil)
        if offset ~= nil then return x + offset.x, z + offset.z end
    end
end

function BermudaTravel.UpdatePlayer(inst, player)
    ProfileStatsSet("wormhole_used", true)
    AwardPlayerAchievement("wormhole_used", player)
    if player.components.talker ~= nil then player.components.talker:ShutUp() end
    if player.components.sanity ~= nil and not player:HasTag("nowormholesanityloss")
        and not inst.disable_sanity_drain then
        player.components.sanity:DoDelta(-TUNING.SANITY_MED)
    end
end

local function TransferFollowers(player, boat, x, z, moved)
    local visited = {}
    local function Visit(owner)
        if owner == nil or visited[owner] then return end
        visited[owner] = true
        local leader = owner.components.leader
        if leader ~= nil then
            for follower in pairs(leader.followers) do
                local inventoryitem = follower.components.inventoryitem
                if follower:IsValid() and not moved[follower]
                    and not (follower.components.follower ~= nil and follower.components.follower.noleashing)
                    and not (inventoryitem ~= nil and inventoryitem:IsHeld()) then
                    moved[follower] = true
                    local platform = follower.GetCurrentPlatform ~= nil and follower:GetCurrentPlatform() or nil
                    if boat == nil or platform ~= boat then
                        VesselTransfer.MoveEntity(follower, x, 0, z)
                    end
                end
            end
        end
        local inventory = owner.components.inventory
        if inventory ~= nil then
            for _, item in pairs(inventory.itemslots) do Visit(item) end
            for _, item in pairs(inventory.equipslots) do Visit(item) end
        end
        local container = owner.components.container
        if container ~= nil then
            for _, item in pairs(container.slots) do Visit(item) end
        end
    end
    Visit(player)
    Visit(boat)
end

local function GetExit(inst, target)
    local teleporter = inst.components.teleporter
    local exit = target or teleporter.targetTeleporterTemporary or teleporter.targetTeleporter
    if teleporter:IsActive() and exit ~= nil and exit:IsValid() and exit ~= inst then return exit end
end

local function CanTravel(actor, boat)
    return actor ~= nil and (boat ~= nil or actor:HasTag("player"))
        and not IsCoolingDown(actor) and not (boat ~= nil and IsCoolingDown(boat))
        and not (actor.components.health ~= nil and actor.components.health:IsDead() and not actor:HasTag("playerghost"))
        and not (actor.sg ~= nil and actor.sg:HasStateTag("jumping"))
end

local function InRange(inst, actor)
    return inst:GetDistanceSqToInst(actor) <= BermudaTravel.RANGE^2
end

local function ClearCharge(inst, charge)
    inst._ta_bermuda_pending[charge.actor] = nil
    if charge.actor._ta_bermuda_charge == charge then charge.actor._ta_bermuda_charge = nil end
    if charge.boat ~= nil and charge.boat._ta_bermuda_charge == charge then charge.boat._ta_bermuda_charge = nil end
    for _, fx in ipairs(charge.fx) do
        if fx:IsValid() then fx:Remove() end
    end
    if next(inst._ta_bermuda_pending) == nil then
        if inst._ta_bermuda_charge_task ~= nil then
            inst._ta_bermuda_charge_task:Cancel()
            inst._ta_bermuda_charge_task = nil
        end
        if inst:IsValid() then
            if inst.sg:HasStateTag("charging") then inst.sg:GoToState("open") end
            inst:PushEvent("doneteleporting")
        end
    end
end

local function ChargeIsValid(inst, charge)
    if not charge.entity:IsValid() or not charge.actor:IsValid()
        or (charge.boat ~= nil and not charge.boat:IsValid())
        or GetExit(inst, charge.target) ~= charge.exit then return false end
    local actor, boat = VesselTransfer.Resolve(charge.entity)
    return actor == charge.actor and boat == charge.boat
        and CanTravel(actor, boat) and InRange(inst, actor)
end

local function PlayChargeFX(charge)
    local targets = VesselTransfer.GetPassengers(charge.actor, charge.boat)
    targets[charge.actor] = true
    -- Native sparks animate independently without changing player control or tint.
    local remaining = {}
    for _, fx in ipairs(charge.fx) do
        if fx:IsValid() then remaining[#remaining + 1] = fx end
    end
    charge.fx = remaining
    for target in pairs(targets) do
        local fx = SpawnPrefab("electrichitsparks")
        if fx ~= nil then
            fx.entity:SetParent(target.entity)
            fx.Transform:SetPosition(0, .5, 0)
            charge.fx[#charge.fx + 1] = fx
        end
    end
    charge.nextfx = GetTime() + CHARGE_FX_PERIOD
end

function BermudaTravel.IsCharging(inst)
    return inst._ta_bermuda_pending ~= nil and next(inst._ta_bermuda_pending) ~= nil
end

function BermudaTravel.CancelAll(inst)
    for _, charge in pairs(inst._ta_bermuda_pending or {}) do ClearCharge(inst, charge) end
end

function BermudaTravel.UpdateCharges(inst)
    local now = GetTime()
    for _, charge in pairs(inst._ta_bermuda_pending) do
        if not ChargeIsValid(inst, charge) then
            ClearCharge(inst, charge)
        elseif now >= charge.deadline then
            ClearCharge(inst, charge)
            BermudaTravel.Teleport(inst, charge.entity, charge.exit)
        elseif now >= charge.nextfx then
            PlayChargeFX(charge)
        end
    end
end

function BermudaTravel.Request(inst, entity, target)
    local exit = GetExit(inst, target)
    if exit == nil then return false end
    local actor, boat = VesselTransfer.Resolve(entity)
    if not CanTravel(actor, boat) or not InRange(inst, actor) then return false end
    local pending = actor._ta_bermuda_charge or (boat ~= nil and boat._ta_bermuda_charge)
    if pending then return pending.source == inst end
    local charge = {
        source = inst, entity = entity, actor = actor, boat = boat,
        target = target, exit = exit, deadline = GetTime() + BermudaTravel.CHARGE_TIME, fx = {},
    }
    actor._ta_bermuda_charge = charge
    if boat ~= nil then boat._ta_bermuda_charge = charge end
    inst._ta_bermuda_pending = inst._ta_bermuda_pending or {}
    inst._ta_bermuda_pending[actor] = charge
    if inst.closetask ~= nil then inst.closetask:Cancel(); inst.closetask = nil end
    if not inst.sg:HasStateTag("charging") then inst.sg:GoToState("charging") end
    PlayChargeFX(charge)
    if inst._ta_bermuda_charge_task == nil then
        inst._ta_bermuda_charge_task = inst:DoPeriodicTask(CHARGE_CHECK_PERIOD, BermudaTravel.UpdateCharges)
    end
    return true
end

function BermudaTravel.Teleport(inst, entity, target)
    local exit = GetExit(inst, target)
    if exit == nil then return false end
    local actor, boat = VesselTransfer.Resolve(entity)
    if not CanTravel(actor, boat) then return false end
    local x, z = FindArrival(actor, boat, exit)
    if x == nil then return false end

    local players = VesselTransfer.GetPassengers(actor, boat)
    if entity:HasTag("player") then players[entity] = true end
    MarkArrival(actor, exit)
    if boat ~= nil and boat ~= actor then MarkArrival(boat, exit) end
    for player in pairs(players) do
        if player ~= actor then MarkArrival(player, exit) end
        if player.ClearBufferedAction ~= nil then player:ClearBufferedAction() end
        if player.components.locomotor ~= nil then player.components.locomotor:Stop() end
    end
    VesselTransfer.Relocate(actor, boat, x, 0, z)
    if inst.components.entitytracker ~= nil then inst.components.entitytracker:TrackEntity("blocker", actor) end
    if exit.components.entitytracker ~= nil then exit.components.entitytracker:TrackEntity("blocker", actor) end
    local moved = {}
    for player in pairs(players) do moved[player] = true end
    for player in pairs(players) do
        TransferFollowers(player, boat, x, z, moved)
        BermudaTravel.UpdatePlayer(inst, player)
        player:PushEvent("wormholetravel", WORMHOLETYPE.OCEANWHIRLPORTAL)
        player:SnapCamera()
        player:ScreenFade(false)
        player:ScreenFade(true, 1)
        if player.components.regionaware ~= nil then player.components.regionaware:RefreshRegion(true) end
        player:DoTaskInTime(1, function(p) p:PushEvent("bermudatriangleexit") end)
    end
    DeleteCloseEntsWithTag({ "WORM_DANGER" }, exit, 15)
    for _, portal in ipairs({ inst, exit }) do
        if portal.SoundEmitter ~= nil then
            portal.SoundEmitter:PlaySound("dontstarve_DLC002/common/bermudatriangle_spark", "wormhole_swallow")
        end
        if portal.sg ~= nil and not portal.sg:HasStateTag("open") then portal.sg:GoToState("opening") end
        portal:PushEvent("doneteleporting")
    end
    return true
end

return BermudaTravel
