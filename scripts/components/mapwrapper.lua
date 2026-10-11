local OceanWrap = require("tools/ocean_wrap")
local VesselTransfer = require("tools/vessel_transfer")
local BLOCKER_EXCLUDE = { "FX", "NOCLICK", "DECOR", "INLIMBO", "_inventoryitem" }

local function Say(inst, key)
    local text = GetString(inst, key)
    if text ~= nil and inst.components.talker ~= nil then inst.components.talker:Say(text) end
end

local function CanTravel(inst)
    return inst:IsValid() and not inst:HasTag("playerghost")
        and not inst:HasTag("region_interior")
        and not (inst.components.health ~= nil and inst.components.health:IsDead())
        and not (inst.sg ~= nil and inst.sg:HasStateTag("jumping"))
end

local function GetTraveller(inst)
    local actor, boat = VesselTransfer.Resolve(inst)
    if actor ~= nil and (boat == nil or actor == inst or boat.components.boatphysics ~= nil) then
        return actor, boat
    end
end

local function FinishTravel(player)
    player:SnapCamera()
    player:ScreenFade(false)
    player:ScreenFade(true, 1)
    if player.components.regionaware ~= nil then player.components.regionaware:RefreshRegion(true) end
    if player.components.sanity ~= nil then player.components.sanity:DoDelta(-TUNING.SANITY_MED) end
    Say(player, "ANNOUNCE_MAPWRAP_RETURN")
    player:PushEvent("oceanwrapped")
end

local MapWrapper = Class(function(self, inst)
    self.inst = inst
    self.warned = false
    self:Refresh()
end)

function MapWrapper:Refresh()
    if not TheWorld.ismastersim or not OceanWrap.IsEnabled(TheWorld) then return end
    local width, height = TheWorld.Map:GetSize()
    self.bounds = OceanWrap.GetBounds(width, height)
    if self.bounds == nil then return end
    if not TheWorld._ta_ocean_wrap_logged then
        TheWorld._ta_ocean_wrap_logged = true
        print(string.format("[Ocean] Boundary wrapping active: %d x %d, trigger %d tiles",
            width, height, OceanWrap.WRAP_TILES))
    end
    if self.task == nil then
        self.task = self.inst:DoPeriodicTask(OceanWrap.CHECK_PERIOD, function() self:Update() end)
    end
end

function MapWrapper:Update()
    if not TheWorld.ismastersim then return end
    local inst = self.inst
    if not CanTravel(inst) then self.warned = false; return end
    local actor, boat = GetTraveller(inst)
    if actor == nil then self.warned = false; return end
    local traveller = boat or actor
    if traveller._ta_ocean_wrap_until ~= nil and GetTime() < traveller._ta_ocean_wrap_until then return end
    local map = TheWorld.Map
    local bounds = self.bounds
    if bounds == nil then return end
    local x, _, z = actor.Transform:GetWorldPosition()
    local distance = OceanWrap.Distance(bounds, x, z)
    if distance < 0 or not map:IsOceanTileAtPoint(x, 0, z) then return end
    local radius = actor == boat and VesselTransfer.GetRadius(boat) or 1
    local trigger = OceanWrap.GetTriggerDistance(radius)
    local arrival_distance = traveller._ta_ocean_wrap_arrival_distance
    if arrival_distance ~= nil then
        if distance > trigger or distance < arrival_distance - .5 then
            traveller._ta_ocean_wrap_arrival_distance = nil
        else
            -- A fallback exit can be inside the trigger band: wait for an outward approach.
            return
        end
    end
    if distance > OceanWrap.WARN_TILES * TILE_SCALE then
        self.warned, self.blocked = false, false
        return
    end
    if not self.warned then
        Say(inst, "ANNOUNCE_MAPWRAP_WARN")
        self.warned = true
    end
    if distance > trigger then return end
    local dx, dz = OceanWrap.FindDestination(bounds, x, z, radius, function(cx, cz)
        if not map:IsOceanTileAtPoint(cx, 0, cz)
            or not map:IsSurroundedByWater(cx, 0, cz, radius) then return false end
        for _, ent in ipairs(TheSim:FindEntities(cx, 0, cz, radius + MAX_PHYSICS_RADIUS, nil, BLOCKER_EXCLUDE)) do
            if ent ~= actor and ent ~= boat and ent.Physics ~= nil and ent.entity:GetParent() == nil then
                local ex, _, ez = ent.Transform:GetWorldPosition()
                local clearance = radius + ent:GetPhysicsRadius(0) + .5
                if (ex - cx)^2 + (ez - cz)^2 < clearance^2 then return false end
            end
        end
        return true
    end)
    if dx == nil then
        if not self.blocked then
            self.blocked = true
            print(string.format("[Ocean] No safe opposite-edge exit at (%.1f, %.1f), radius %.2f", x, z, radius))
        end
        traveller._ta_ocean_wrap_until = GetTime() + 1
        return
    end

    traveller._ta_ocean_wrap_until = GetTime() + OceanWrap.COOLDOWN
    traveller._ta_ocean_wrap_arrival_distance = OceanWrap.Distance(bounds, dx, dz)
    self.blocked = false
    print(string.format("[Ocean] Wrapped traveller (%.1f, %.1f) -> (%.1f, %.1f)", x, z, dx, dz))
    local passengers = VesselTransfer.GetPassengers(actor, boat)
    VesselTransfer.Relocate(actor, boat, dx, 0, dz)
    if actor == inst then
        FinishTravel(inst)
    else
        for player in pairs(passengers) do
            FinishTravel(player)
        end
    end
end

function MapWrapper:OnRemoveFromEntity()
    if self.task ~= nil then self.task:Cancel(); self.task = nil end
end
MapWrapper.OnRemoveEntity = MapWrapper.OnRemoveFromEntity

return MapWrapper
