local UPDATE_PERIOD = .5
local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")
local STORM_WAIT_MIN = TUNING.TOTAL_DAY_TIME
local STORM_WAIT_MAX = 4 * TUNING.TOTAL_DAY_TIME
local HAIL_INTERVAL = 1
local HAIL_CELL_SIZE = 32
local TEASE_START_MIN = .3
local TEASE_START_MAX = .75

local function RandomRange(min, max)
    return min + math.random() * (max - min)
end

local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function GetWorldTimeSeconds()
    local state = TheWorld.state
    return ((state.cycles or 0) + (state.time or 0)) * TUNING.TOTAL_DAY_TIME
end

local function GetStormCurve(progress, start_percent, end_percent)
    local span = end_percent - start_percent
    if span <= 0 or progress < start_percent or progress > end_percent then
        return 0
    end

    return math.sin(PI * Clamp((progress - start_percent) / span, 0, 1))
end

local HurricaneManager = Class(function(self, inst)
    assert(TheWorld.ismastersim, "HurricaneManager should not exist on client")

    self.inst = inst
    self.active = false
    self.tease = false
    self.start_time = nil
    self.duration = nil
    self.next_storm_time = nil
    self.moisture = 0
    self.moisture_limit = RandomRange(STORM_WAIT_MIN, STORM_WAIT_MAX)
    self.tease_start = nil
    self.tease_completed = false
    self.storm_strength = 0
    self.hail_rate = 0
    self.wind_enabled = false
    self.next_lightning_time = nil
    self.next_hail = {}
    self.last_world_time = GetWorldTimeSeconds()

    inst:WatchWorldState("season", function()
        self:ReconcileSeason(true)
    end)
    inst:WatchWorldState("seasonprogress", function()
        self:ReconcileSeason(false)
    end)

    self.task = inst:DoPeriodicTask(UPDATE_PERIOD, function()
        self:Update()
    end)
    self:ReconcileSeason(true)
end)

function HurricaneManager:IsHurricaneSeason()
    return TheWorld ~= nil and ClimateProfiles.IsShipwreckedHurricane(TheWorld.state)
end

function HurricaneManager:IsMildSeason()
    return TheWorld ~= nil and ClimateProfiles.IsShipwreckedMild(TheWorld.state)
end

function HurricaneManager:IsActive()
    return self.active
end

function HurricaneManager:IsTease()
    return self.active and self.tease
end

function HurricaneManager:IsWindActive()
    return self.active and self.wind_enabled
end

function HurricaneManager:GetStormStrength()
    return self.storm_strength
end

function HurricaneManager:GetHailRate()
    return self.hail_rate
end

function HurricaneManager:GetProgress()
    if not self.active or self.start_time == nil or self.duration == nil or self.duration <= 0 then
        return 0
    end
    return Clamp((GetWorldTimeSeconds() - self.start_time) / self.duration, 0, 1)
end

function HurricaneManager:GetEligiblePlayers()
    local players = {}
    for _, player in ipairs(AllPlayers) do
        local regionaware = player.components.regionaware
        if player:IsValid()
            and not player:HasTag("playerghost")
            and regionaware ~= nil
            and not regionaware:IsInInterior()
            and regionaware:IsInSubregion(RegionDefs.SUBREGION.sw_vanilla) then
            table.insert(players, player)
        end
    end
    return players
end

local function IsDue(schedule, key, now, interval)
    local due = schedule[key]
    if due == nil then
        schedule[key] = now + math.random() * interval
        return false
    elseif now < due then
        return false
    end

    schedule[key] = now + interval
    return true
end

local function GetHailCellKey(player)
    local x, _, z = player.Transform:GetWorldPosition()
    return math.floor(x / HAIL_CELL_SIZE) .. ":" .. math.floor(z / HAIL_CELL_SIZE)
end

local function SpawnHailForPlayer(player)
    local x, _, z = player.Transform:GetWorldPosition()
    local hail = SpawnPrefab("hail_ice")
    if hail ~= nil then
        local hail_x = x + math.random(-15, 15)
        local hail_z = z + math.random(-15, 15)
        if hail.StartFalling ~= nil then
            hail:StartFalling(hail_x, 35, hail_z)
        else
            hail.Transform:SetPosition(hail_x, 35, hail_z)
        end
    end
end

function HurricaneManager:UpdateHail(now, players)
    if not TUNING.hail or self.hail_rate <= 0 then
        return
    end

    local hail_cells = {}
    for _, player in ipairs(players) do
        local cell_key = GetHailCellKey(player)
        if hail_cells[cell_key] == nil then
            hail_cells[cell_key] = player
        end
    end

    for cell_key, player in pairs(hail_cells) do
        if IsDue(self.next_hail, cell_key, now, HAIL_INTERVAL)
            and math.random() < .05 * self.hail_rate then
            SpawnHailForPlayer(player)
        end
    end
end

function HurricaneManager:SyncNetworkState()
    local network = TheWorld ~= nil and TheWorld.net or nil
    if network == nil or network._tropical_hurricane_active == nil then
        return
    end

    local storm_strength = math.floor(Clamp(self.storm_strength, 0, 1) * 100 + .5)
    local hail_rate = TUNING.hail and math.floor(Clamp(self.hail_rate, 0, 1) * 100 + .5) or 0
    if network._tropical_hurricane_active:value() ~= self.active then
        network._tropical_hurricane_active:set(self.active)
    end
    if network._tropical_hurricane_tease:value() ~= self.tease then
        network._tropical_hurricane_tease:set(self.tease)
    end
    if network._tropical_hurricane_stormstrength:value() ~= storm_strength then
        network._tropical_hurricane_stormstrength:set(storm_strength)
    end
    if network._tropical_hurricane_hailrate:value() ~= hail_rate then
        network._tropical_hurricane_hailrate:set(hail_rate)
    end
    if network._tropical_hurricane_windactive:value() ~= self.wind_enabled then
        network._tropical_hurricane_windactive:set(self.wind_enabled)
    end
end

function HurricaneManager:ScheduleHurricaneStorm(now)
    self.moisture = 0
    self.moisture_limit = RandomRange(STORM_WAIT_MIN, STORM_WAIT_MAX)
    self.next_storm_time = now + self.moisture_limit
end

function HurricaneManager:StartStorm(tease)
    if self.active then
        return
    end

    self.active = true
    self.tease = tease == true
    self.start_time = GetWorldTimeSeconds()
    self.duration = self.tease and TUNING.HURRICANE_TEASE_LENGTH
        or RandomRange(TUNING.HURRICANE_LENGTH_MIN, TUNING.HURRICANE_LENGTH_MAX)
    self.next_lightning_time = self.start_time + RandomRange(4, 8)
    self:UpdateRates()
    self:SyncNetworkState()
end

function HurricaneManager:StopStorm()
    if not self.active then
        return
    end

    self.active = false
    self.tease = false
    self.start_time = nil
    self.duration = nil
    self.next_lightning_time = nil
    self.storm_strength = 0
    self.hail_rate = 0
    self.wind_enabled = false
    self.next_hail = {}
    self:ScheduleHurricaneStorm(GetWorldTimeSeconds())
    self:SyncNetworkState()
end

function HurricaneManager:UpdateRates()
    if not self.active then
        self.storm_strength = 0
        self.hail_rate = 0
        self.wind_enabled = false
        return
    end

    local progress = self:GetProgress()
    local storm_curve = GetStormCurve(progress, TUNING.HURRICANE_PERCENT_RAIN_START, TUNING.HURRICANE_PERCENT_RAIN_END)
    self.storm_strength = TUNING.HURRICANE_RAIN_SCALE * storm_curve
        + .1 * math.sin(8 * PI * Clamp((progress - TUNING.HURRICANE_PERCENT_RAIN_START)
            / (TUNING.HURRICANE_PERCENT_RAIN_END - TUNING.HURRICANE_PERCENT_RAIN_START), 0, 1))
    self.storm_strength = Clamp(self.storm_strength, 0, 1)

    if self.tease then
        self.hail_rate = 0
    else
        self.hail_rate = Clamp(TUNING.HURRICANE_HAIL_SCALE
            * GetStormCurve(progress, TUNING.HURRICANE_PERCENT_HAIL_START, TUNING.HURRICANE_PERCENT_HAIL_END), 0, 1)
    end

    self.wind_enabled = progress >= TUNING.HURRICANE_PERCENT_WIND_START
        and progress <= TUNING.HURRICANE_PERCENT_WIND_END
end

function HurricaneManager:UpdateLightning(now)
    if self.tease or self.next_lightning_time == nil then
        return
    end

    local progress = self:GetProgress()
    if progress < TUNING.HURRICANE_PERCENT_LIGHTNING_START
        or progress > TUNING.HURRICANE_PERCENT_LIGHTNING_END
        or now < self.next_lightning_time then
        return
    end

    local lightning_progress = Clamp((progress - TUNING.HURRICANE_PERCENT_LIGHTNING_START)
        / (TUNING.HURRICANE_PERCENT_LIGHTNING_END - TUNING.HURRICANE_PERCENT_LIGHTNING_START), 0, 1)
    local lightning_base = .4 * math.cos(2 * PI * lightning_progress) + .6
    self.next_lightning_time = now + RandomRange(2 * lightning_base + 2, 4 * lightning_base + 4)

    local players = self:GetEligiblePlayers()
    if #players == 0 then
        return
    end

    if self.storm_strength > .75 * TUNING.HURRICANE_RAIN_SCALE
        and math.random() < TUNING.HURRICANE_LIGHTNING_STRIKE_CHANCE then
        local player = players[math.random(#players)]
        local x, _, z = player.Transform:GetWorldPosition()
        local radius = math.random(2, 10)
        local angle = math.random() * 2 * PI
        TheWorld:PushEvent("ms_sendlightningstrike", Vector3(x + radius * math.cos(angle), 0, z + radius * math.sin(angle)))
    else
        local network = TheWorld.net
        if network ~= nil and network._tropical_hurricane_thunder ~= nil then
            network._tropical_hurricane_thunder:set((network._tropical_hurricane_thunder:value() + 1) % 255)
        end
    end
end

function HurricaneManager:ReconcileSeason(reset_timing)
    local now = GetWorldTimeSeconds()
    if not self:IsHurricaneSeason() and not self:IsMildSeason() then
        self:StopStorm()
        self.tease_start = nil
        self.tease_completed = false
        return
    end

    if self:IsMildSeason() and reset_timing then
        self.tease_start = RandomRange(TEASE_START_MIN, TEASE_START_MAX)
        self.tease_completed = false
    end

    if self:IsMildSeason()
        and ClimateProfiles.GetProgress(TheWorld.state) < (self.tease_start or TEASE_START_MIN) then
        -- Discard teasers started by DST's offset opening weather curve,
        -- including active or completed teasers restored from older saves.
        if self.active and self.tease then
            self:StopStorm()
        end
        self.tease_completed = false
    end

    if self:IsHurricaneSeason() and reset_timing and not self.active then
        self:ScheduleHurricaneStorm(now)
    end
end

function HurricaneManager:Update()
    local now = GetWorldTimeSeconds()
    local world_dt = now - self.last_world_time
    self.last_world_time = now

    if world_dt < 0 then
        self:StopStorm()
        self:ReconcileSeason(true)
        return
    end

    -- Console season/day changes move world time in a single jump. Do not
    -- replay a missed storm after that jump; begin a fresh local moisture
    -- cycle in the resulting season instead.
    if world_dt > 10 then
        self:StopStorm()
        if self:IsHurricaneSeason() then
            self:ScheduleHurricaneStorm(now)
        elseif self:IsMildSeason() then
            self.tease_completed = true
        end
        return
    end

    self:ReconcileSeason(false)
    if not self:IsHurricaneSeason() and not self:IsMildSeason() then
        return
    end

    if self.active then
        if (self.tease and not self:IsMildSeason()) or (not self.tease and not self:IsHurricaneSeason()) then
            self:StopStorm()
            return
        end

        self:UpdateRates()
        local players = self:GetEligiblePlayers()
        self:UpdateHail(now, players)
        self:UpdateLightning(now)
        if self:GetProgress() >= 1 then
            self:StopStorm()
            return
        end
        self:SyncNetworkState()
        return
    end

    if self:IsHurricaneSeason() then
        self.moisture = self.moisture + world_dt
        if self.next_storm_time == nil then
            self:ScheduleHurricaneStorm(now)
        end
        if now >= self.next_storm_time then
            self:StartStorm(false)
        end
    elseif self:IsMildSeason()
        and not self.tease_completed
        and self.tease_start ~= nil
        and ClimateProfiles.GetProgress(TheWorld.state) >= self.tease_start then
        self.tease_completed = true
        self:StartStorm(true)
    end
end

function HurricaneManager:GetTemperatureModifier()
    if not self.active or self.tease then
        return 0
    end

    return TUNING.TROPICAL_HURRICANE_TEMP * math.sin(PI * self:GetProgress())
end

function HurricaneManager:OnSave()
    local now = GetWorldTimeSeconds()
    return {
        active = self.active,
        tease = self.tease,
        elapsed = self.active and math.max(0, now - self.start_time) or nil,
        duration = self.duration,
        next_storm_delay = self.next_storm_time ~= nil and math.max(0, self.next_storm_time - now) or nil,
        moisture = self.moisture,
        moisture_limit = self.moisture_limit,
        tease_start = self.tease_start,
        tease_completed = self.tease_completed,
    }
end

function HurricaneManager:OnLoad(data)
    data = data or {}
    local now = GetWorldTimeSeconds()
    self.tease_start = data.tease_start
    self.tease_completed = data.tease_completed == true
    self.moisture = data.moisture or 0
    self.moisture_limit = data.moisture_limit or RandomRange(STORM_WAIT_MIN, STORM_WAIT_MAX)
    self.next_storm_time = data.next_storm_delay ~= nil and now + data.next_storm_delay or nil

    if data.active and data.duration ~= nil and data.elapsed ~= nil
        and ((data.tease and self:IsMildSeason()) or (not data.tease and self:IsHurricaneSeason())) then
        self.active = true
        self.tease = data.tease == true
        self.duration = data.duration
        self.start_time = now - data.elapsed
        self.next_lightning_time = now + RandomRange(2, 8)
        self:UpdateRates()
    else
        self:ReconcileSeason(true)
    end

    self:ReconcileSeason(false)
    self.last_world_time = now
    self:SyncNetworkState()
end

function HurricaneManager:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function HurricaneManager:GetDebugString()
    return string.format("active:%s, tease:%s, progress:%0.2f, storm:%0.2f, hail:%0.2f",
        tostring(self.active), tostring(self.tease), self:GetProgress(), self.storm_strength, self.hail_rate)
end

return HurricaneManager
