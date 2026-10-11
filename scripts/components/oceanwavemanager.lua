local RegionDefs = require("tools/regiondefs")

local UPDATE_PERIOD = 1
local ENTRY_GRACE_TIME = 4
local MAX_WAVES_NEAR_PLAYER = 8
local WAVE_QUERY_RADIUS = 36
local WAVE_SEPARATION = 4
local PLATFORM_EXCLUSION = 8
local NOWAVES_EXCLUSION = 10
local LANE_SPACING = 12
local LANE_FORWARD_RANGE = 18
local LANE_LATERAL_RANGE = 4
local SPAWN_ATTEMPTS = 8
local WAVES_PER_UPDATE = 2
local NORMAL_WAVE_SPEED = 2
local ROGUE_WAVE_SPEED = 6
local ROGUE_WAVE_SPEED_MULTIPLIER = 3
local WAVE_IDLE_TIME = 5
local FULL_MOON_ROGUE_CHANCE = .15
local DEFAULT_CURRENT_ANGLE = 67.5

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function IsOceanPlayer(player)
    if player == nil or not player:IsValid() or player:HasTag("playerghost") then
        return false
    end

    local x, y, z = player.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return TheWorld.Map:IsOceanAtPoint(x, y, z, true)
        and not TileGroupManager:IsShallowOceanTile(tile)
end

local function GetOceanMotion()
    local ocean = TheWorld.components.ocean
    local angle = ocean ~= nil and ocean.GetCurrentAngle ~= nil and ocean:GetCurrentAngle() or DEFAULT_CURRENT_ANGLE
    local speed = ocean ~= nil and ocean.GetCurrentSpeed ~= nil and ocean:GetCurrentSpeed() or 1
    speed = math.max(0, speed or 0)

    local radians = angle * DEGREES
    return {
        rotation = -angle,
        x = math.cos(radians),
        z = math.sin(radians),
        speed = math.max(NORMAL_WAVE_SPEED, NORMAL_WAVE_SPEED * speed),
    }
end

local function GetStormStrengthForPlayer(player)
    local hurricane = TheWorld.components.hurricanemanager
    local regionaware = player.components.regionaware
    if hurricane ~= nil
        and hurricane:IsWindActive()
        and regionaware ~= nil
        and not regionaware:IsInInterior()
        and regionaware:IsInSubregion(RegionDefs.SUBREGION.sw_vanilla) then
        return hurricane:GetStormStrength()
    end
    return 0
end

local function IsWaveSpawnPointValid(x, z)
    return TheWorld.Map:IsOceanAtPoint(x, 0, z, false)
        and #TheSim:FindEntities(x, 0, z, WAVE_SEPARATION, { "tropical_wave" }) == 0
        and #TheSim:FindEntities(x, 0, z, PLATFORM_EXCLUSION, { "walkableplatform" }) == 0
        and #TheSim:FindEntities(x, 0, z, NOWAVES_EXCLUSION, { "nowaves" }) == 0
end

local function FindWaveSpawnPoint(player, motion)
    local x, y, z = player.Transform:GetWorldPosition()
    local anchor_x = math.floor(x / LANE_SPACING) * LANE_SPACING
    local anchor_z = math.floor(z / LANE_SPACING) * LANE_SPACING

    for _ = 1, SPAWN_ATTEMPTS do
        local forward = math.random(-LANE_FORWARD_RANGE, LANE_FORWARD_RANGE) * 2
        local lateral = math.random(-LANE_LATERAL_RANGE, LANE_LATERAL_RANGE) * LANE_SPACING
        local wave_x = anchor_x + forward * motion.x + lateral * motion.z
        local wave_z = anchor_z + forward * motion.z - lateral * motion.x
        if IsWaveSpawnPointValid(wave_x, wave_z) then
            return wave_x, y, wave_z
        end
    end
end

local OceanWaveManager = Class(function(self, inst)
    assert(TheWorld.ismastersim, "OceanWaveManager should not exist on client")

    self.inst = inst
    self.ocean_entry_time = setmetatable({}, { __mode = "k" })
    self.task = inst:DoPeriodicTask(UPDATE_PERIOD, function()
        self:UpdateWaves()
    end, UPDATE_PERIOD)
end)

function OceanWaveManager:SpawnWaveForPlayer(player, motion, storm_strength)
    local player_x, player_y, player_z = player.Transform:GetWorldPosition()
    if #TheSim:FindEntities(player_x, player_y, player_z, WAVE_QUERY_RADIUS, { "tropical_wave" }) >= MAX_WAVES_NEAR_PLAYER then
        return false
    end

    local x, y, z = FindWaveSpawnPoint(player, motion)
    if x == nil then
        return false
    end

    local full_moon = TheWorld.state.moonphase == "full"
    local rogue_chance = full_moon and FULL_MOON_ROGUE_CHANCE or 0
    if storm_strength > 0 then
        rogue_chance = math.max(rogue_chance, math.min(.65, .2 + storm_strength * .9))
    end

    local is_rogue = math.random() < rogue_chance
    local wave = SpawnPrefab(is_rogue and "rogue_wave" or "wave_ripple")
    if wave == nil then
        return false
    end

    local speed = motion.speed * (storm_strength > 0 and (1 + .25 * storm_strength) or 1)
    if is_rogue then
        speed = math.max(ROGUE_WAVE_SPEED, speed * ROGUE_WAVE_SPEED_MULTIPLIER)
    end

    wave.Transform:SetPosition(x, y, z)
    wave.Transform:SetRotation(motion.rotation)
    wave.idle_time = WAVE_IDLE_TIME
    wave.Physics:SetMotorVel(speed, 0, 0)
    return true
end

function OceanWaveManager:UpdateWaves()
    if not TUNING.waves then
        return
    end

    local now = GetTime()
    local motion = GetOceanMotion()
    if motion.speed <= 0 then
        return
    end

    for _, player in ipairs(AllPlayers) do
        if IsOceanPlayer(player) then
            local entered_at = self.ocean_entry_time[player]
            if entered_at == nil then
                self.ocean_entry_time[player] = now
            elseif now - entered_at >= ENTRY_GRACE_TIME then
                local storm_strength = GetStormStrengthForPlayer(player)
                for _ = 1, WAVES_PER_UPDATE do
                    if not self:SpawnWaveForPlayer(player, motion, storm_strength) then
                        break
                    end
                end
            end
        else
            self.ocean_entry_time[player] = nil
        end
    end
end

function OceanWaveManager:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function OceanWaveManager:GetDebugString()
    local tracked = 0
    for _ in pairs(self.ocean_entry_time) do
        tracked = tracked + 1
    end
    return string.format("ocean_players:%d", tracked)
end

return OceanWaveManager
