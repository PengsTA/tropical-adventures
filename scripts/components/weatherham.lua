local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")

local function CalculateSeasonRate(progress)
    if progress < 0.2 then
        return math.max(0, progress / 0.2)
    elseif progress > 0.8 then
        return math.max(0, (1 - progress) / 0.2)
    end
    return 1
end

local function CalculateFogRate(state)
    local threshold = TUNING.FOG_MOISTURE_RATE or 0
    local moisture_ceil = state.moistureceil or 0
    local moisture_strength = threshold > 0
        and math.max(0, math.min(1, (moisture_ceil - threshold) / threshold))
        or 1
    local rain_strength = (state.israining or state.issnowing)
        and math.max(0, math.min(1, state.precipitationrate or 0))
        or 0
    -- Humid-season mist never disappears merely because the current rain
    -- pulse stopped. Rain thickens it, while the moisture ceiling gives the
    -- world-level baseline used by every player in the region.
    return math.max(0, math.min(1, .05 + moisture_strength * .45 + rain_strength * .5))
end

return Class(function(self, inst)
    local FOG_STATES = {
        inactive = false,
        active = true,
    }
    local POLLEN_STATES = {
        inactive = false,
        active = true,
    }
    local POLLEN_PARTICLES_PER_SECOND = 20
    local POLLEN_TICK_TIME = TheSim:GetTickTime()

    self.inst = inst

    local _world = TheWorld
    local _state = _world.state
    local _ismastersim = _world.ismastersim
    local _activatedplayer = nil
    local _seasonprogress = _state.seasonprogress or 0
    local _lastweather = nil

    local _hasfx = not TheNet:IsDedicated()
    local _pollendustfx = _hasfx and SpawnPrefab("pollendust") or nil

    local _fogstate = net_bool(inst.GUID, "weatherham._fogstate", "weatherham.fogstatedirty")
    local _fograte = net_float(inst.GUID, "weatherham._fograte", "weatherham.fogratedirty")
    local _pollenduststate = net_bool(inst.GUID, "weather._pollenduststate", "weatherham.pollenduststatedirty")
    local _pollendustrate = net_float(inst.GUID, "weather._pollendustrate", "weatherham.pollendustratedirty")

    local function PushWeather()
        local data = {
            fogstate = _fogstate:value(),
            fograte = _fograte:value(),
            pollenduststate = _pollenduststate:value(),
            pollendustrate = _pollendustrate:value(),
        }
        if _lastweather == nil
            or _lastweather.fogstate ~= data.fogstate
            or _lastweather.fograte ~= data.fograte
            or _lastweather.pollenduststate ~= data.pollenduststate
            or _lastweather.pollendustrate ~= data.pollendustrate then
            _lastweather = data
            _world:PushEvent("hamweathertick", data)
        end
    end

    local function UpdatePollenFx()
        if not _hasfx then
            return
        end

        local player = _activatedplayer
        local rate = 0
        if _world._ta_config_ready and player ~= nil
            and not player:HasTag(RegionDefs.INTERIOR_TAG)
            and RegionDefs.HasPrimaryRegion(player, RegionDefs.PRIMARY.hamlet) then
            rate = _pollendustrate:value()
        end
        _pollendustfx.particles_per_tick = rate * POLLEN_PARTICLES_PER_SECOND * POLLEN_TICK_TIME
        if rate <= 0 then
            _pollendustfx.num_particles_to_emit = 0
        end
    end

    local function UpdateWeatherState()
        if not _ismastersim then
            return
        end

        if TUNING.fog
            and ClimateProfiles.IsHamletHumid(_state)
            and _state.moistureceil > TUNING.FOG_MOISTURE_RATE then
            _fogstate:set(FOG_STATES.active)
            _fograte:set(CalculateFogRate(_state))
        else
            _fogstate:set(FOG_STATES.inactive)
            _fograte:set(0)
        end

        if TUNING.hayfever and ClimateProfiles.IsHamletLush(_state) then
            _pollenduststate:set(POLLEN_STATES.active)
            _pollendustrate:set(CalculateSeasonRate(_seasonprogress))
        else
            _pollenduststate:set(POLLEN_STATES.inactive)
            _pollendustrate:set(0)
        end

        PushWeather()
        UpdatePollenFx()
    end

    local function OnSeasonTick(_, data)
        _seasonprogress = data ~= nil and data.progress or _seasonprogress
        if _ismastersim then
            UpdateWeatherState()
        end
        UpdatePollenFx()
    end

    local function OnSeasonProgressChanged(_, progress)
        _seasonprogress = progress or _state.seasonprogress or _seasonprogress
        UpdateWeatherState()
    end

    local function OnPlayerRegionChanged()
        UpdatePollenFx()
    end

    function self:Refresh()
        _lastweather = nil
        UpdateWeatherState()
        PushWeather()
        UpdatePollenFx()
    end

    inst:ListenForEvent("taconfigready", function() self:Refresh() end, _world)

    local function OnPlayerActivated(_, player)
        _activatedplayer = player
        if _hasfx then
            _pollendustfx.entity:SetParent(player.entity)
            _pollendustfx.particles_per_tick = 0
            _pollendustfx.num_particles_to_emit = 0
            player:ListenForEvent("regionchange_client", OnPlayerRegionChanged)
            self:OnPostInit()
            UpdatePollenFx()
        end
    end

    local function OnPlayerDeactivated(_, player)
        if _activatedplayer == player then
            _activatedplayer = nil
        end
        if _hasfx then
            player:RemoveEventCallback("regionchange_client", OnPlayerRegionChanged)
            _pollendustfx.entity:SetParent(nil)
            _pollendustfx.particles_per_tick = 0
            _pollendustfx.num_particles_to_emit = 0
        end
    end

    _fogstate:set(FOG_STATES.inactive)
    _fograte:set(0)
    _pollenduststate:set(POLLEN_STATES.inactive)
    _pollendustrate:set(0)

    if _hasfx then
        _pollendustfx.particles_per_tick = 0
        function self:OnPostInit()
            _pollendustfx:PostInit()
        end

        function self:OnRemoveEntity()
            if _activatedplayer ~= nil then
                _activatedplayer:RemoveEventCallback("regionchange_client", OnPlayerRegionChanged)
            end
            if _pollendustfx.entity:IsValid() then
                _pollendustfx:Remove()
            end
        end
    end

    inst:ListenForEvent("seasontick", OnSeasonTick, _world)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated, _world)

    if _ismastersim then
        inst:WatchWorldState("season", UpdateWeatherState)
        inst:WatchWorldState("seasonprogress", OnSeasonProgressChanged)
        inst:WatchWorldState("moistureceil", UpdateWeatherState)
        inst:WatchWorldState("israining", UpdateWeatherState)
        inst:WatchWorldState("issnowing", UpdateWeatherState)
        inst:WatchWorldState("precipitationrate", UpdateWeatherState)

        function self:OnSave()
            return {
                fog = _fogstate:value(),
                fograte = _fograte:value(),
                pollendust = _pollenduststate:value(),
                pollendustrate = _pollendustrate:value(),
            }
        end

        function self:OnLoad(data)
            data = data or {}
            _fogstate:set(data.fog or FOG_STATES.inactive)
            _fograte:set(data.fograte or 0)
            _pollenduststate:set(data.pollendust or POLLEN_STATES.inactive)
            _pollendustrate:set(data.pollendustrate or 0)
            PushWeather()
        end
    else
        inst:ListenForEvent("weatherham.fogstatedirty", PushWeather)
        inst:ListenForEvent("weatherham.fogratedirty", PushWeather)
        local function OnPollenDirty()
            PushWeather()
            UpdatePollenFx()
        end
        inst:ListenForEvent("weatherham.pollenduststatedirty", OnPollenDirty)
        inst:ListenForEvent("weatherham.pollendustratedirty", OnPollenDirty)
    end

    inst:DoTaskInTime(0, function()
        if _ismastersim then
            UpdateWeatherState()
        else
            PushWeather()
        end
        UpdatePollenFx()
    end)
end)
