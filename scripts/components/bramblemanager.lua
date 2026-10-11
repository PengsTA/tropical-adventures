local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")

local SITE_GRID_TILES = 12
local MAX_CANDIDATE_SITES = 32
local THICKETS_PER_LUSH_SEASON = 7
local THICKET_CLEAR_RADIUS = 12

local VALID_TILES = {}
for _, name in ipairs({
    "DEEPRAINFOREST",
    "GASRAINFOREST",
    "GASJUNGLE",
    "RAINFOREST",
    "PLAINS",
    "PAINTED",
    "DIRT",
}) do
    local tile = (WORLD_TILES ~= nil and WORLD_TILES[name]) or GROUND[name]
    if tile ~= nil then
        VALID_TILES[tile] = true
    end
end

local function GetSiteHash(tile_x, tile_z, salt)
    return (tile_x * 73856093 + tile_z * 19349663 + salt * 83492791) % 2147483647
end

local function IsLushSeason()
    return ClimateProfiles.IsHamletLush(TheWorld.state)
end

local function IsValidBrambleSite(x, z)
    local map = TheWorld.Map
    if not map:IsAboveGroundAtPoint(x, 0, z)
        or map:IsInteriorAtPoint(x, 0, z)
        or not map:IsPrimaryRegionAtPoint(x, 0, z, RegionDefs.PRIMARY.hamlet)
        or map:IsSubregionAtPoint(x, 0, z, RegionDefs.SUBREGION.ham_city) then
        return false
    end

    return VALID_TILES[map:GetTileAtPoint(x, 0, z)] == true
end

local function IsSiteClear(x, z)
    for _, entity in ipairs(TheSim:FindEntities(x, 0, z, 4, nil, { "INLIMBO", "FX", "NOCLICK" })) do
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

local BrambleManager = Class(function(self, inst)
    assert(TheWorld.ismastersim, "BrambleManager should not exist on client")

    self.inst = inst
    self.sites = nil
    self.spawned_this_season = false

    inst:WatchWorldState("season", function()
        self:RefreshSeason()
    end)
    inst:DoTaskInTime(0, function()
        self:RefreshSeason()
    end)
end)

function BrambleManager:BuildSites()
    local map = TheWorld.Map
    local width, height = map:GetSize()
    local candidates = {}

    for tile_z = SITE_GRID_TILES / 2, height - SITE_GRID_TILES / 2, SITE_GRID_TILES do
        for tile_x = SITE_GRID_TILES / 2, width - SITE_GRID_TILES / 2, SITE_GRID_TILES do
            local x = (tile_x - width / 2) * TILE_SCALE
            local z = (tile_z - height / 2) * TILE_SCALE
            if IsValidBrambleSite(x, z) then
                candidates[#candidates + 1] = {
                    x = x,
                    z = z,
                    tile_x = tile_x,
                    tile_z = tile_z,
                    score = GetSiteHash(tile_x, tile_z, 0),
                }
            end
        end
    end

    table.sort(candidates, function(first, second)
        return first.score < second.score
    end)

    self.sites = {}
    for index = 1, math.min(#candidates, MAX_CANDIDATE_SITES) do
        local site = candidates[index]
        site.score = nil
        self.sites[#self.sites + 1] = site
    end
end

function BrambleManager:EnsureSites()
    if self.sites == nil then
        self:BuildSites()
    end
end

function BrambleManager:SpawnThickets()
    self:EnsureSites()

    local candidates = {}
    local cycle = TheWorld.state.cycles or 0
    for _, site in ipairs(self.sites) do
        if IsValidBrambleSite(site.x, site.z) and IsSiteClear(site.x, site.z) then
            candidates[#candidates + 1] = {
                site = site,
                score = GetSiteHash(site.tile_x, site.tile_z, cycle),
            }
        end
    end

    table.sort(candidates, function(first, second)
        return first.score < second.score
    end)

    local count = math.min(#candidates, THICKETS_PER_LUSH_SEASON)
    for index = 1, count do
        local site = candidates[index].site
        local bramble = SpawnPrefab("bramble")
        if bramble ~= nil then
            bramble.Transform:SetPosition(site.x, 0, site.z)
        end
    end

    self.spawned_this_season = true
end

function BrambleManager:ClearThickets()
    if self.sites == nil then
        return
    end

    for _, site in ipairs(self.sites) do
        for _, entity in ipairs(TheSim:FindEntities(site.x, 0, site.z, THICKET_CLEAR_RADIUS, { "tropical_bramble" })) do
            if entity:IsValid() then
                entity:Remove()
            end
        end
    end
end

function BrambleManager:RefreshSeason()
    if not TUNING.brambles or not IsLushSeason() then
        self:ClearThickets()
        self.spawned_this_season = false
    elseif not self.spawned_this_season then
        self:SpawnThickets()
    end
end

function BrambleManager:OnSave()
    return {
        sites = self.sites,
        spawned_this_season = self.spawned_this_season,
    }
end

function BrambleManager:OnLoad(data)
    if data ~= nil then
        self.sites = data.sites
        self.spawned_this_season = data.spawned_this_season == true
    end
end

function BrambleManager:GetDebugString()
    return string.format("sites:%d spawned:%s lush:%s", self.sites ~= nil and #self.sites or 0,
        tostring(self.spawned_this_season), tostring(IsLushSeason()))
end

return BrambleManager
