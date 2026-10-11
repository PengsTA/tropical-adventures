local FloodPattern = require("tools/floodpattern")
local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")

local UPDATE_PERIOD = 2
local MIN_VISIBLE_LEVEL = FloodPattern.MIN_VISIBLE_LEVEL
local FLOOD_SPEED_MULTIPLIER = .85
local FLOOD_SPEED_KEY = "tropical_flood"
local FLOOD_RISE_INTERVAL = TUNING.SEG_TIME
local FLOOD_RISE_STEP = 1 / math.max(1, TUNING.MAX_FLOOD_LEVEL or 15)
local FLOOD_GROW_START = .10

local ZONES = FloodPattern.ZONES

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function GetSeasonProgress()
    return ClimateProfiles.GetProgress(TheWorld.state)
end

local function IsGrowingSeason(zone)
    return (zone == "shipwrecked" or zone == "hamlet")
        and ClimateProfiles.IsShipwreckedMonsoon(TheWorld.state)
end

local function IsRecedingSeason(zone)
    return zone == "shipwrecked"
        and ClimateProfiles.IsShipwreckedDry(TheWorld.state)
        or zone == "hamlet"
            and ClimateProfiles.IsHamletLush(TheWorld.state)
end

local function IsZoneRaining()
    return TheWorld.state.israining == true or TheWorld.state.issnowing == true
end

local FloodManager = Class(function(self, inst)
    self.inst = inst
    self.zones = {}
    self.floodables = setmetatable({}, { __mode = "k" })
    self.updatetask = nil
    self.tick_count = 0

    for zone_name in pairs(ZONES) do
        self.zones[zone_name] = {
            seasonal_level = 0,
            tide_level = 0,
            level = 0,
            mode = "dry",
            cellvalid = {},
            query_cache = {},
            time_since_flood_increase = 0,
            last_network_level = nil,
        }
    end
    -- Retain the original fields for code and old save data that only know
    -- Shipwrecked flooding.
    self.level = 0
    self.mode = "dry"
    self.cells = {} -- Legacy field; flooding is now queried from the shared field.

    local function Refresh()
        self:Refresh()
    end

    inst:WatchWorldState("season", function()
        self:RequestReconcile()
    end)
    inst:WatchWorldState("seasonprogress", function()
        self:RequestReconcile()
    end)
    inst:WatchWorldState("israining", Refresh)
    inst:WatchWorldState("issnowing", Refresh)
    inst:ListenForEvent("onterraform", function() self:InvalidateTerrain() end)
    inst:ListenForEvent("floodcontrolchanged", function() self:InvalidateTerrain() end)
    inst:ListenForEvent("ms_playerjoined", Refresh)
    inst:ListenForEvent("ms_playerleft", Refresh)
    inst:DoTaskInTime(0, Refresh)
end)

function FloodManager:GetTideLevel()
    -- Compatibility API: inland puddles are seasonal, not an ocean tide field.
    return 0
end

function FloodManager:GetZone(zone)
    return self.zones[zone or "shipwrecked"]
end

function FloodManager:GetFloodLevel(zone)
    local state = self:GetZone(zone)
    return state ~= nil and state.level or 0
end

function FloodManager:GetSeasonalTargetLevel(zone_name, state)
    if not TUNING.flood then
        return 0, "disabled"
    end

    local progress = GetSeasonProgress()
    local growing = IsGrowingSeason(zone_name) and progress > FLOOD_GROW_START
    local receding = IsRecedingSeason(zone_name) and progress < .25

    if growing then
        if IsZoneRaining(zone_name) then
            return Clamp((progress - FLOOD_GROW_START) / (1 - FLOOD_GROW_START), 0, 1), "flood_grow"
        end
        return state.seasonal_level, "flood_hold"
    end
    if receding then
        return math.min(state.seasonal_level, Clamp(1 - progress / .15, 0, 1)), "flood_shrink"
    end
    return 0, "dry"
end

function FloodManager:GetTideLevelForZone(zone_name)
    return 0
end

function FloodManager:GetFloodZoneForPlayer(player)
    local aware = player ~= nil and player.components.regionaware or nil
    if aware == nil or aware:IsInInterior() then
        return nil
    end
    local sailor = player.components.sailor
    if player:HasTag("playerghost") or player:GetCurrentPlatform() ~= nil
        or (sailor ~= nil and (sailor:IsSailing() or sailor:IsLoadingBoat())) then
        return nil
    end

    local subregion = aware:GetSubregion()
    for zone_name, config in pairs(ZONES) do
        if config.subregions[RegionDefs.GetSubregionId(subregion)] then
            return zone_name
        end
    end
end

function FloodManager:IsFloodPlayer(player, zone)
    local player_zone = self:GetFloodZoneForPlayer(player)
    return player_zone ~= nil and (zone == nil or player_zone == zone)
end

function FloodManager:HasFloodPlayers(zone)
    for _, player in ipairs(AllPlayers) do
        if player:IsValid() and self:IsFloodPlayer(player, zone) then
            return true
        end
    end
    return false
end

function FloodManager:SyncNetworkLevel(zone_name, state)
    local value = math.floor(Clamp(state.level, 0, 1) * 100 + .5)
    if state.last_network_level == value then
        return
    end
    local network = self.inst.net
    if network == nil then
        return
    end
    if zone_name == "shipwrecked" and network._tropical_flood_level ~= nil then
        network._tropical_flood_level:set(value)
    elseif zone_name == "hamlet" and network._tropical_flood_hamletlevel ~= nil then
        network._tropical_flood_hamletlevel:set(value)
    else
        return
    end
    state.last_network_level = value
end

function FloodManager:IsValidTile(zone_name, state, key, x, z)
    local cached = state.cellvalid[key]
    if cached ~= nil then
        return cached
    end

    local valid = FloodPattern.IsValidTile(zone_name, x, z)
    state.cellvalid[key] = valid
    return valid
end

function FloodManager:GetFloodControls(zone_name, x, z)
    local radius = FloodPattern.GetMaxReach(zone_name) * TILE_SCALE + 10
    return TheSim:FindEntities(x, 0, z, radius, { "removealagamento" })
end

function FloodManager:IsBlockedByFloodControls(controls, x, z)
    return FloodPattern.IsBlockedByFloodControls(controls, x, z)
end

function FloodManager:GetFloodZoneAtPoint(x, z)
    if TheWorld.Map:IsInteriorAtPoint(x, 0, z) then
        return nil
    end
    local subregion = RegionDefs.GetSubregionId(TheWorld.Map:GetSubregionAtPoint(x, 0, z))
    for zone_name, config in pairs(ZONES) do
        if config.subregions[subregion] then
            return zone_name
        end
    end
end

function FloodManager:IsFloodedAtPointForZone(zone_name, x, z)
    local state = self:GetZone(zone_name)
    if state == nil or state.level < MIN_VISIBLE_LEVEL then
        return false
    end

    local tile_x, tile_z = FloodPattern.GetTileCenter(x, z)
    local key = FloodPattern.GetTileKey(tile_x, tile_z)
    local cached = state.query_cache[key]
    if cached ~= nil then
        return cached
    end

    local flood_controls = self:GetFloodControls(zone_name, tile_x, tile_z)
    local flooded = FloodPattern.IsFloodedAtPoint(
        tile_x,
        tile_z,
        state.level,
        function(source_x, source_z)
            local source_key = FloodPattern.GetTileKey(source_x, source_z)
            return self:IsValidTile(zone_name, state, source_key, source_x, source_z)
        end,
        function(cell_x, cell_z)
            local cell_key = FloodPattern.GetTileKey(cell_x, cell_z)
            return self:IsValidTile(zone_name, state, cell_key, cell_x, cell_z)
                and not self:IsBlockedByFloodControls(flood_controls, cell_x, cell_z)
        end,
        zone_name
    )
    state.query_cache[key] = flooded
    return flooded
end

function FloodManager:IsFloodedAtPoint(x, z)
    if self.zones.shipwrecked.level < MIN_VISIBLE_LEVEL
        and self.zones.hamlet.level < MIN_VISIBLE_LEVEL then
        return false
    end
    local zone_name = self:GetFloodZoneAtPoint(x, z)
    return zone_name ~= nil and self:IsFloodedAtPointForZone(zone_name, x, z) or false
end

function FloodManager:OnFlood(x, y, z)
    return self:IsFloodedAtPoint(x, z or y)
end

function FloodManager:RegisterFloodable(inst)
    self.floodables[inst] = true
end

function FloodManager:UnregisterFloodable(inst)
    self.floodables[inst] = nil
end

function FloodManager:SetPlayerFlooded(player, flooded)
    if player:HasTag("tropical_flooded") == flooded then return end
    local locomotor = player.components.locomotor
    if flooded then
        player:AddTag("tropical_flooded")
        if locomotor ~= nil then
            locomotor:SetExternalSpeedMultiplier(player, FLOOD_SPEED_KEY, FLOOD_SPEED_MULTIPLIER)
        end
    else
        player:RemoveTag("tropical_flooded")
        if locomotor ~= nil then
            locomotor:RemoveExternalSpeedMultiplier(player, FLOOD_SPEED_KEY)
        end
    end
end

function FloodManager:UpdatePlayerEffects()
    for _, player in ipairs(AllPlayers) do
        local flooded = false
        if player:IsValid() and self:IsFloodPlayer(player) then
            local x, _, z = player.Transform:GetWorldPosition()
            flooded = self:IsFloodedAtPoint(x, z)
        end
        self:SetPlayerFlooded(player, flooded)
    end
end

function FloodManager:UpdateFloodables()
    for inst in pairs(self.floodables) do
        if inst:IsValid()
            and not inst:IsAsleep()
            and inst.components.floodable ~= nil then
            inst.components.floodable:Refresh()
        end
    end
end

function FloodManager:ClearQueryCaches()
    for _, state in pairs(self.zones) do
        state.query_cache = {}
    end
end

function FloodManager:InvalidateTerrain()
    for _, state in pairs(self.zones) do state.cellvalid = {} end
    self:ClearQueryCaches()
end

-- Full cache clear every N ticks (N * UPDATE_PERIOD seconds). This is only a
-- safety net for rare terrain/sandbag changes; the flood level itself already
-- invalidates caches as soon as it changes.
local CACHE_SAFETY_TICKS = 15

function FloodManager:InvalidateIfStale(level_changed)
    self.tick_count = self.tick_count + 1
    if level_changed or self.tick_count >= CACHE_SAFETY_TICKS then
        self.tick_count = 0
        self:InvalidateTerrain()
    end
end

function FloodManager:UpdateZone(zone_name, state, allow_gradual_growth)
    local target, seasonal_mode = self:GetSeasonalTargetLevel(zone_name, state)
    local previous_level = state.level
    if seasonal_mode == "flood_grow" then
        -- Calendar/load notifications must not simulate elapsed rainfall.
        if allow_gradual_growth then
            state.time_since_flood_increase = state.time_since_flood_increase + UPDATE_PERIOD
            if state.seasonal_level < target and state.time_since_flood_increase >= FLOOD_RISE_INTERVAL then
                state.seasonal_level = math.min(target, state.seasonal_level + FLOOD_RISE_STEP)
                state.time_since_flood_increase = 0
            end
        end
    elseif seasonal_mode ~= "flood_hold" then
        state.seasonal_level = target
        state.time_since_flood_increase = 0
    end

    state.tide_level = 0
    state.level = FloodPattern.QuantizeLevel(state.seasonal_level)
    state.mode = seasonal_mode
    return state.level ~= previous_level
end

function FloodManager:PublishState()
    local sw = self.zones.shipwrecked
    local hamlet = self.zones.hamlet
    self.level = sw.level
    self.mode = sw.mode
    self:SyncNetworkLevel("shipwrecked", sw)
    self:SyncNetworkLevel("hamlet", hamlet)
    if sw.published_level == sw.level and sw.published_mode == sw.mode
        and hamlet.published_level == hamlet.level and hamlet.published_mode == hamlet.mode then
        return
    end
    sw.published_level, sw.published_mode = sw.level, sw.mode
    hamlet.published_level, hamlet.published_mode = hamlet.level, hamlet.mode
    self.inst:PushEvent("tropicalfloodchanged", {
        level = sw.level,
        mode = sw.mode,
        shipwrecked_level = sw.level,
        shipwrecked_mode = sw.mode,
        hamlet_level = hamlet.level,
        hamlet_mode = hamlet.mode,
    })
end

function FloodManager:Tick()
    local level_changed = false
    for zone_name, state in pairs(self.zones) do
        if self:UpdateZone(zone_name, state, true) then
            level_changed = true
        end
    end
    self:InvalidateIfStale(level_changed)
    self:UpdatePlayerEffects()
    self:UpdateFloodables()
    self:PublishState()
end

function FloodManager:ReconcileWorldTime()
    for zone_name, state in pairs(self.zones) do
        self:UpdateZone(zone_name, state, false)
    end
    self:ClearQueryCaches()
    self.tick_count = 0
    self:UpdatePlayerEffects()
    self:UpdateFloodables()
    self:PublishState()
    self:Refresh()
end

function FloodManager:RequestReconcile()
    if self.reconciletask == nil then
        self.reconciletask = self.inst:DoTaskInTime(0, function()
            self.reconciletask = nil
            self:ReconcileWorldTime()
        end)
    end
end

function FloodManager:Refresh()
    if TUNING.flood and self.updatetask == nil then
        self.updatetask = self.inst:DoPeriodicTask(UPDATE_PERIOD, function()
            self:Tick()
        end, 0)
    end
end

function FloodManager:ClearCells()
    self.cells = {}
    self:ClearQueryCaches()
end

function FloodManager:OnSave()
    local data = { zones = {} }
    for zone_name, state in pairs(self.zones) do
        data.zones[zone_name] = {
            level = state.level,
            seasonal_level = state.seasonal_level,
            mode = state.mode,
            time_since_flood_increase = state.time_since_flood_increase,
        }
    end
    -- Keep the old top-level fields so updating an existing save is safe.
    data.level = self.zones.shipwrecked.level
    data.mode = self.zones.shipwrecked.mode
    data.time_since_flood_increase = self.zones.shipwrecked.time_since_flood_increase
    return data
end

function FloodManager:OnLoad(data)
    data = data or {}
    for zone_name, state in pairs(self.zones) do
        local saved = data.zones ~= nil and data.zones[zone_name] or nil
        if saved == nil and zone_name == "shipwrecked" then
            saved = data
        end
        if saved ~= nil then
            -- Queries remain dry until the fully loaded calendar is reconciled.
            state.level = 0
            state.seasonal_level = Clamp(saved.seasonal_level
                or (saved.mode ~= "tides" and saved.level) or 0, 0, 1)
            state.mode = saved.mode or state.mode
            state.time_since_flood_increase = saved.time_since_flood_increase or state.time_since_flood_increase
        end
    end
    -- Component OnLoad order is unspecified; wait for the calendar to load.
    self:RequestReconcile()
end

function FloodManager:OnRemoveEntity()
    if self.reconciletask ~= nil then self.reconciletask:Cancel(); self.reconciletask = nil end
    if self.updatetask ~= nil then
        self.updatetask:Cancel()
        self.updatetask = nil
    end
    self:ClearCells()
    for _, state in pairs(self.zones) do state.level = 0; state.seasonal_level = 0 end
    for _, player in ipairs(AllPlayers) do
        if player:IsValid() then
            self:SetPlayerFlooded(player, false)
        end
    end
    self:UpdateFloodables()
end

function FloodManager:GetDebugString()
    local text = {}
    for zone_name, state in pairs(self.zones) do
        text[#text + 1] = string.format("%s:%s/%0.2f (seasonal:%0.2f, tide:%0.2f)",
            zone_name,
            state.mode,
            state.level,
            state.seasonal_level,
            state.tide_level)
    end
    return table.concat(text, ", ")
end

return FloodManager
