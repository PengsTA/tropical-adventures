local UPDATE_PERIOD = 5
local ClimateProfiles = require("tools/climateprofiles")
local INITIAL_SPAWN_TIME = 60
local MIN_SPAWN_TIME = 60
local MAX_SPAWN_TIME = 120
local MOSQUITO_CAP = 3
local MOSQUITO_CAP_RADIUS = 25
local MIN_FLOOD_LEVEL = require("tools/floodpattern").MIN_VISIBLE_LEVEL
local FLOOD_ZONES = { "shipwrecked", "hamlet" }

local FloodMosquitoSpawner = Class(function(self, inst)
    self.inst = inst
    self.next_spawn = {}
    for _, zone_name in ipairs(FLOOD_ZONES) do
        self.next_spawn[zone_name] = INITIAL_SPAWN_TIME
    end
    -- Spawning cadence remains world-owned per flood zone. The cap itself is
    -- evaluated around the selected player, not across the entire region.
    self.time_to_spawn = self.next_spawn.shipwrecked
    self.mosquito_cap = MOSQUITO_CAP
    self.mosquitos = setmetatable({}, { __mode = "k" })
    self.task = inst:DoPeriodicTask(UPDATE_PERIOD, function()
        self:Tick()
    end)
end)

function FloodMosquitoSpawner:IsMosquitoSeason(zone_name)
    if ClimateProfiles.GetProgress(TheWorld.state) <= .5 then
        return false
    end
    return (zone_name == "shipwrecked" or zone_name == "hamlet")
        and ClimateProfiles.IsShipwreckedMonsoon(TheWorld.state)
end

function FloodMosquitoSpawner:GetFloodPlayer(zone_name)
    local floodmanager = TheWorld.components.floodmanager
    if floodmanager == nil or floodmanager:GetFloodLevel(zone_name) < MIN_FLOOD_LEVEL
        or not self:IsMosquitoSeason(zone_name) then
        return nil
    end

    local candidates = {}
    for _, player in ipairs(AllPlayers) do
        if player:IsValid() then
            local player_zone = floodmanager:GetFloodZoneForPlayer(player)
            if player_zone == zone_name and self:GetNearbyCount(player) < self.mosquito_cap then
                candidates[#candidates + 1] = player
            end
        end
    end
    return #candidates > 0 and candidates[math.random(#candidates)] or nil
end

function FloodMosquitoSpawner:GetCount(zone_name)
    local count = 0
    for mosquito, mosquito_zone in pairs(self.mosquitos) do
        if mosquito:IsValid() and (zone_name == nil or mosquito_zone == zone_name) then
            count = count + 1
        end
    end
    return count
end

function FloodMosquitoSpawner:GetNearbyCount(player)
    local x, _, z = player.Transform:GetWorldPosition()
    local radius_sq = MOSQUITO_CAP_RADIUS * MOSQUITO_CAP_RADIUS
    local count = 0
    for mosquito in pairs(self.mosquitos) do
        if mosquito:IsValid() then
            local mosquito_x, _, mosquito_z = mosquito.Transform:GetWorldPosition()
            local dx = mosquito_x - x
            local dz = mosquito_z - z
            if dx * dx + dz * dz <= radius_sq then
                count = count + 1
            end
        end
    end
    return count
end

function FloodMosquitoSpawner:GetSpawnPoint(player, zone_name)
    local floodmanager = TheWorld.components.floodmanager
    if floodmanager == nil then
        return nil
    end

    local origin_x, _, origin_z = player.Transform:GetWorldPosition()
    for radius = 8, 20, 4 do
        local theta = math.random() * 2 * PI
        local offset = FindValidPositionByFan(theta, radius, 12, function(test_offset)
            local x = origin_x + test_offset.x
            local z = origin_z + test_offset.z
            return TheWorld.Map:IsAboveGroundAtPoint(x, 0, z)
                and not TheWorld.Map:IsInteriorAtPoint(x, 0, z)
                and floodmanager:IsFloodedAtPointForZone(zone_name, x, z)
        end)
        if offset ~= nil then
            return origin_x + offset.x, origin_z + offset.z
        end
    end
end

function FloodMosquitoSpawner:Track(mosquito, zone_name)
    mosquito.persists = false
    self.mosquitos[mosquito] = zone_name

    mosquito:ListenForEvent("onremove", function()
        self.mosquitos[mosquito] = nil
    end)
    mosquito:ListenForEvent("entitysleep", function()
        if mosquito:IsValid() then
            mosquito:Remove()
        end
    end)
end

function FloodMosquitoSpawner:ScheduleNextSpawn(zone_name)
    self.next_spawn[zone_name] = MIN_SPAWN_TIME + math.random() * (MAX_SPAWN_TIME - MIN_SPAWN_TIME)
    self.time_to_spawn = self.next_spawn.shipwrecked
end

function FloodMosquitoSpawner:Tick()
    if not TUNING.flood then
        return
    end

    for _, zone_name in ipairs(FLOOD_ZONES) do
        self.next_spawn[zone_name] = self.next_spawn[zone_name] - UPDATE_PERIOD
        if self.next_spawn[zone_name] <= 0 then
            local player = self:GetFloodPlayer(zone_name)
            if player ~= nil then
                local x, z = self:GetSpawnPoint(player, zone_name)
                if x ~= nil and z ~= nil then
                    local mosquito = SpawnPrefab("mosquito_poison")
                    if mosquito ~= nil then
                        mosquito.Transform:SetPosition(x, 0, z)
                        self:Track(mosquito, zone_name)
                    end
                end
            end
            self:ScheduleNextSpawn(zone_name)
        end
    end
end

function FloodMosquitoSpawner:OnSave()
    return {
        next_spawn = self.next_spawn,
        time_to_spawn = self.next_spawn.shipwrecked,
    }
end

function FloodMosquitoSpawner:OnLoad(data)
    if data ~= nil then
        for _, zone_name in ipairs(FLOOD_ZONES) do
            self.next_spawn[zone_name] = data.next_spawn ~= nil and data.next_spawn[zone_name]
                or (zone_name == "shipwrecked" and data.time_to_spawn)
                or self.next_spawn[zone_name]
        end
        self.time_to_spawn = self.next_spawn.shipwrecked
    end
end

function FloodMosquitoSpawner:OnRemoveEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function FloodMosquitoSpawner:GetDebugString()
    return string.format("sw:%0.1f/%d, ham:%0.1f/%d, localcap:%d@%d",
        self.next_spawn.shipwrecked,
        self:GetCount("shipwrecked"),
        self.next_spawn.hamlet,
        self:GetCount("hamlet"),
        self.mosquito_cap,
        MOSQUITO_CAP_RADIUS)
end

return FloodMosquitoSpawner
