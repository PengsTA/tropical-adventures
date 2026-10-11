local RegionDefs = require("tools/regiondefs")
local ClimateProfiles = require("tools/climateprofiles")

local function GetGlobalPrecipitationRate()
    local state = TheWorld.state
    return (state.israining or state.issnowing)
        and math.max(0, state.precipitationrate or 0)
        or 0
end

-- Continuous world states such as precipitationrate change every frame while
-- rain ramps up or down. Coalesce those bursts so the per-player climate is
-- rebuilt (and net vars pushed) at most once per interval instead of per frame.
local MIN_REFRESH_INTERVAL = .25

local function ClimateChanged(previous, current)
    return previous == nil
        or previous.profile ~= current.profile
        or previous.phase ~= current.phase
        or previous.is_winter_rain ~= current.is_winter_rain
        or previous.pollen_rate ~= current.pollen_rate
        or previous.fog_rate ~= current.fog_rate
        or previous.is_hamlet_rainy ~= current.is_hamlet_rainy
end

local RegionalClimate = Class(function(self, inst)
    self.inst = inst
    self.climate = nil
    self.dirty = true
    self.refreshtask = nil
    self._last_refresh_time = nil

    local function MarkDirty()
        self:MarkDirty()
    end

    inst:ListenForEvent("regionchange", MarkDirty)
    inst:WatchWorldState("issnowing", MarkDirty)
    inst:WatchWorldState("ispollendust", MarkDirty)
    inst:WatchWorldState("pollendustrate", MarkDirty)
    inst:WatchWorldState("isfoggy", MarkDirty)
    inst:WatchWorldState("fograte", MarkDirty)
    inst:WatchWorldState("israining", MarkDirty)
    inst:WatchWorldState("precipitationrate", MarkDirty)
    inst:WatchWorldState("season", MarkDirty)
    inst:WatchWorldState("seasonprogress", MarkDirty)

    inst:DoTaskInTime(0, function()
        self:Refresh()
    end)
end)

function RegionalClimate:BuildClimate()
    local regionaware = self.inst.components.regionaware
    local primary = regionaware ~= nil and regionaware:GetPrimaryRegion() or "dst"
    local subregion = regionaware ~= nil and regionaware:GetSubregion() or "dst_mainland"
    local is_tropical = RegionDefs.IsTropicalPrimary(primary)
    local is_shipwrecked = primary == "shipwrecked"
    local is_hamlet = primary == "hamlet"
    local is_interior = regionaware ~= nil and regionaware:IsInInterior() or false
    local state = TheWorld.state
    local progress = ClimateProfiles.GetProgress(state)
    local pollen_source = state.ispollendust and (state.pollendustrate or 0) or 0
    local fog_source = state.isfoggy and (state.fograte or 0) or 0
    local profile = ClimateProfiles.GetProfile(primary, state)
    local pollen_rate = TUNING.hayfever and is_hamlet and not is_interior and pollen_source or 0
    local fog_rate = TUNING.fog and is_hamlet and not is_interior and fog_source or 0
    local converts_snow_to_rain = not is_interior
        and ((is_shipwrecked and subregion == "sw_vanilla") or is_hamlet)

    return {
        primary = primary,
        subregion = subregion,
        is_interior = is_interior,
        is_shipwrecked = is_shipwrecked,
        is_hamlet = is_hamlet,
        profile = profile,
        progress = progress,
        phase = ClimateProfiles.GetPhase(progress),
        -- Kept under the old net variable name for compatibility. It means
        -- that this exterior region renders the single global snowfall as rain.
        is_winter_rain = converts_snow_to_rain and state.issnowing,
        pollen_rate = pollen_rate,
        fog_rate = fog_rate,
        is_hamlet_rainy = is_hamlet and ClimateProfiles.IsShipwreckedMonsoon(state),
    }
end

function RegionalClimate:SyncClassified(previous, current)
    local classified = self.inst.player_classified
    if classified ~= nil and classified._regionalclimate_iswinterrain ~= nil then
        if previous == nil or previous.is_winter_rain ~= current.is_winter_rain then
            classified._regionalclimate_iswinterrain:set(current.is_winter_rain)
        end
        if previous == nil or previous.profile ~= current.profile then
            classified._regionalclimate_profile:set(ClimateProfiles.PROFILE_IDS[current.profile] or 1)
        end
        if previous == nil or previous.phase ~= current.phase then
            classified._regionalclimate_phase:set(ClimateProfiles.PHASE_IDS[current.phase] or 1)
        end
    end
end

function RegionalClimate:MarkDirty()
    self.dirty = true
    if self.refreshtask == nil then
        local now = GetTime()
        local elapsed = self._last_refresh_time ~= nil and now - self._last_refresh_time or MIN_REFRESH_INTERVAL
        local delay = math.max(0, MIN_REFRESH_INTERVAL - elapsed)
        self.refreshtask = self.inst:DoTaskInTime(delay, function()
            self.refreshtask = nil
            if self.dirty then
                self._last_refresh_time = GetTime()
                self:Refresh()
            end
        end)
    end
end

function RegionalClimate:Refresh()
    if not self.dirty and self.climate ~= nil then
        return self.climate
    end

    local previous = self.climate
    local current = self:BuildClimate()
    self.climate = current
    self.dirty = false
    self:SyncClassified(previous, current)

    if ClimateChanged(previous, current) then
        self.inst:PushEvent("regionalclimatechanged", {
            previous = previous,
            current = current,
        })
    end

    return current
end

function RegionalClimate:GetClimate()
    if self.climate == nil then
        self.dirty = true
    end
    return self.dirty and self:Refresh() or self.climate
end

function RegionalClimate:IsTropical()
    local regionaware = self.inst.components.regionaware
    return regionaware ~= nil and RegionDefs.IsTropicalPrimary(regionaware:GetPrimaryRegion()) or false
end

function RegionalClimate:IsWinterRain()
    return self:GetClimate().is_winter_rain
end

function RegionalClimate:GetSeasonProfile()
    return self:GetClimate().profile
end

function RegionalClimate:GetSeasonProgress()
    return self:GetClimate().progress
end

function RegionalClimate:GetSeasonPhase()
    return self:GetClimate().phase
end

function RegionalClimate:IsHamletRainy()
    return self:GetClimate().is_hamlet_rainy
end

function RegionalClimate:GetPrecipitationRate()
    local climate = self:GetClimate()
    if climate.is_interior then
        return 0
    elseif climate.is_shipwrecked then
        if climate.subregion ~= "sw_vanilla" then
            return 0
        end
        return GetGlobalPrecipitationRate()
    elseif climate.is_hamlet then
        return GetGlobalPrecipitationRate()
    end

    return nil
end

function RegionalClimate:IsPrecipitating()
    return (self:GetPrecipitationRate() or 0) > 0
end

function RegionalClimate:IsPollenActive()
    return self:GetPollenRate() > 0
end

function RegionalClimate:GetPollenRate()
    return self:GetClimate().pollen_rate
end

function RegionalClimate:IsFogActive()
    return self:GetFogRate() > 0
end

function RegionalClimate:GetFogRate()
    return self:GetClimate().fog_rate
end

function RegionalClimate:GetTemperatureModifier()
    local regionaware = self.inst.components.regionaware
    if regionaware ~= nil and regionaware:IsInSubregion("sw_volcano") then
        return 40
    elseif self:IsTropical() then
        local modifier = math.max(10 - TheWorld.state.temperature, 0) + 5
        if regionaware ~= nil
            and regionaware:IsInSubregion("sw_vanilla")
            and not regionaware:IsInInterior() then
            local hurricane = TheWorld.components.hurricanemanager
            local monsoon = TheWorld.components.monsoonmanager
            if hurricane ~= nil then
                modifier = modifier + hurricane:GetTemperatureModifier()
            end
            if monsoon ~= nil then
                modifier = modifier + TUNING.TROPICAL_HURRICANE_WIND_TEMP * monsoon:GetStrength()
            end
        end
        return modifier
    end
end

function RegionalClimate.IsVanillaClimateAllowedAtPoint(x, y, z)
    return TheWorld.Map:IsDSTRegionAtPoint(x, y, z)
end

function RegionalClimate:OnRemoveEntity()
    if self.refreshtask ~= nil then
        self.refreshtask:Cancel()
        self.refreshtask = nil
    end
end

function RegionalClimate:GetDebugString()
    local climate = self:GetClimate()
    return string.format("profile:%s/%s, tropical:%s, snowasrain:%s, precip:%0.2f, pollen:%0.2f, fog:%0.2f",
        climate.profile,
        climate.phase,
        tostring(self:IsTropical()),
        tostring(climate.is_winter_rain),
        self:GetPrecipitationRate() or 0,
        climate.pollen_rate,
        climate.fog_rate)
end

return RegionalClimate
