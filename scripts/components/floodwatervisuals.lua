local FloodPattern = require("tools/floodpattern")
local RegionDefs = require("tools/regiondefs")

local MIN_VISIBLE_LEVEL = FloodPattern.MIN_VISIBLE_LEVEL
local RENDER_RADIUS = FloodPattern.PLAYER_TILE_RADIUS
local FLOOD_EMITTER_ID = 0

-- Rebuilding the flood field runs on every tile crossing while a player walks.
-- Coalesce those refreshes so the field is rebuilt at most once per interval.
local MIN_REFRESH_INTERVAL = .5

local CENTER = 1
local EAST = 2
local NORTH = 3
local WEST = 4
local SOUTH = 5
local NORTH_EAST = 6
local NORTH_WEST = 7
local SOUTH_WEST = 8
local SOUTH_EAST = 9

local NEIGHBOR_TILES = {
    [CENTER] = { x = 0, z = 0 },
    [WEST] = { x = -1, z = 0 },
    [NORTH_WEST] = { x = -1, z = 1 },
    [NORTH] = { x = 0, z = 1 },
    [NORTH_EAST] = { x = 1, z = 1 },
    [EAST] = { x = 1, z = 0 },
    [SOUTH_EAST] = { x = 1, z = -1 },
    [SOUTH] = { x = 0, z = -1 },
    [SOUTH_WEST] = { x = -1, z = -1 },
}

local function GetFloodLevel(zone)
    local network = TheWorld ~= nil and TheWorld.net or nil
    if network == nil then
        return 0
    elseif zone == "hamlet" and network._tropical_flood_hamletlevel ~= nil then
        return network._tropical_flood_hamletlevel:value() / 100
    elseif zone == "shipwrecked" and network._tropical_flood_level ~= nil then
        return network._tropical_flood_level:value() / 100
    end
    return 0
end

local function GetNeighborMask(directions)
    local neighbors = directions

    if neighbors[WEST] then
        neighbors[NORTH_WEST] = true
        neighbors[SOUTH_WEST] = true
    end
    if neighbors[NORTH] then
        neighbors[NORTH_WEST] = true
        neighbors[NORTH_EAST] = true
    end
    if neighbors[EAST] then
        neighbors[NORTH_EAST] = true
        neighbors[SOUTH_EAST] = true
    end
    if neighbors[SOUTH] then
        neighbors[SOUTH_WEST] = true
        neighbors[SOUTH_EAST] = true
    end

    local mask = 0
    for direction in pairs(neighbors) do
        mask = mask + 2 ^ (direction - 1)
    end
    return neighbors[CENTER] and 1 or 0, mask
end

local FloodWaterVisuals = Class(function(self, inst)
    self.inst = inst
    self.effect = nil
    self.flooded = {}
    self._refreshpending = false
    self._onchange = function()
        self:RequestRefresh()
    end
    self._tilewatcher = inst.components.tilechangewatcher

    inst:ListenForEvent("regionchange_client", self._onchange)
    inst:ListenForEvent("tropicalfloodlevelchanged", self._onchange, TheWorld)
    inst:ListenForEvent("floodcontrolchanged", self._onchange, TheWorld)
    inst:ListenForEvent("onterraform", self._onchange, TheWorld)
    if self._tilewatcher ~= nil then
        self._tilewatcher:ListenToUpdate(self._onchange)
    end
    self._inittask = inst:DoTaskInTime(0, function()
        self._inittask = nil
        self:Refresh()
    end)
end)

function FloodWaterVisuals:RequestRefresh()
    if self._refreshpending then
        return
    end
    self._refreshpending = true
    self._refreshtask = self.inst:DoTaskInTime(MIN_REFRESH_INTERVAL, function()
        self._refreshpending = nil
        self._refreshtask = nil
        self:Refresh()
    end)
end

function FloodWaterVisuals:GetFloodZone()
    if self.inst:HasTag(RegionDefs.INTERIOR_TAG) then
        return nil
    end

    if RegionDefs.HasSubregion(self.inst, RegionDefs.SUBREGION.sw_vanilla) then
        return "shipwrecked"
    elseif RegionDefs.HasSubregion(self.inst, RegionDefs.SUBREGION.ham_rainforest)
        or RegionDefs.HasSubregion(self.inst, RegionDefs.SUBREGION.ham_wilds) then
        return "hamlet"
    end
end

function FloodWaterVisuals:IsInFloodRegion()
    return self:GetFloodZone() ~= nil
end

function FloodWaterVisuals:IsValidRenderTile(x, z)
    if TheWorld.Map:IsInteriorAtPoint(x, 0, z) then
        return false
    end

    return TheWorld.Map:IsAboveGroundAtPoint(x, 0, z)
        or TheWorld.Map:IsOceanAtPoint(x, 0, z)
end

function FloodWaterVisuals:IsFloodFieldTileActive(zone, x, z)
    return FloodPattern.IsValidTile(zone, x, z)
end

function FloodWaterVisuals:GetFloodControls(zone, x, z)
    local radius = (RENDER_RADIUS + FloodPattern.GetMaxReach(zone)) * TILE_SCALE + 10
    return TheSim:FindEntities(x, 0, z, radius, { "removealagamento" })
end

function FloodWaterVisuals:IsBlockedByFloodControls(controls, x, z)
    return FloodPattern.IsBlockedByFloodControls(controls, x, z)
end

function FloodWaterVisuals:IsFloodedAtPoint(x, z)
    local zone = self:GetFloodZone()
    if zone == nil then
        return false
    end

    local tile_x, tile_z = FloodPattern.GetTileCenter(x, z)
    return self.flooded[FloodPattern.GetTileKey(tile_x, tile_z)] ~= nil
end

function FloodWaterVisuals:BuildDesiredTiles(zone, level)
    local desired, flooded = {}, {}
    if level < MIN_VISIBLE_LEVEL or zone == nil then return desired, flooded end

    local x, _, z = self.inst.Transform:GetWorldPosition()
    local center_x, center_z = FloodPattern.GetTileCenter(x, z)
    local controls = self:GetFloodControls(zone, center_x, center_z)
    local valid, unblocked = {}, {}
    local function ValidCell(cx, cz)
        local key = FloodPattern.GetTileKey(cx, cz)
        if valid[key] == nil then valid[key] = self:IsFloodFieldTileActive(zone, cx, cz) end
        return valid[key]
    end
    local function FloodCell(cx, cz)
        local key = FloodPattern.GetTileKey(cx, cz)
        if unblocked[key] == nil then
            unblocked[key] = ValidCell(cx, cz) and not self:IsBlockedByFloodControls(controls, cx, cz)
        end
        return unblocked[key]
    end
    FloodPattern.VisitFloodCells(center_x, center_z, RENDER_RADIUS, level,
        ValidCell, FloodCell, function(cx, cz)
            flooded[FloodPattern.GetTileKey(cx, cz)] = { x = cx, z = cz }
        end, zone)

    -- Only visit the neighborhoods of actual flooded cells, not the full view.
    local render_valid = {}
    for _, cell in pairs(flooded) do
        for direction, offset in pairs(NEIGHBOR_TILES) do
            local wx, wz = cell.x - offset.x * TILE_SCALE, cell.z - offset.z * TILE_SCALE
            local key = FloodPattern.GetTileKey(wx, wz)
            if render_valid[key] == nil then render_valid[key] = self:IsValidRenderTile(wx, wz) end
            if render_valid[key] then
                local tile = desired[key]
                if tile == nil then
                    tile = { x = wx, z = wz, directions = {} }
                    desired[key] = tile
                end
                tile.directions[direction] = true
            end
        end
    end
    local ocean = {}
    local function OceanCell(cx, cz)
        local key = FloodPattern.GetTileKey(cx, cz)
        if ocean[key] == nil then ocean[key] = TheWorld.Map:IsOceanAtPoint(cx, 0, cz) end
        return ocean[key]
    end
    for _, tile in pairs(desired) do
        tile.overhang_type, tile.neighbor_type = GetNeighborMask(tile.directions)
        tile.directions = nil
        tile.ocean_mask = 0
        if TUNING.ocean_style == "tropical" then
            for direction, offset in pairs(NEIGHBOR_TILES) do
                if OceanCell(tile.x + offset.x * TILE_SCALE, tile.z + offset.z * TILE_SCALE) then
                    tile.ocean_mask = tile.ocean_mask + 2 ^ (direction - 1)
                end
            end
        end
    end
    return desired, flooded
end

function FloodWaterVisuals:Refresh()
    local zone = self:GetFloodZone()
    local level = GetFloodLevel(zone)
    if zone == nil or level < MIN_VISIBLE_LEVEL then
        self.flooded = {}
        if self.effect ~= nil then
            self.effect:Remove()
            self.effect = nil
        end
        return
    end

    if self.effect == nil or not self.effect:IsValid() then
        self.effect = SpawnPrefab("floodwater_fx")
        if self.effect == nil then
            return
        end
    end
    self.effect:ClearTile(FLOOD_EMITTER_ID)

    local desired, flooded = self:BuildDesiredTiles(zone, level)
    self.flooded = flooded
    for _, tile in pairs(desired) do
        self.effect:SpawnTile(
            Vector3(tile.x, 0, tile.z),
            tile.overhang_type,
            tile.neighbor_type,
            FLOOD_EMITTER_ID,
            tile.ocean_mask
        )
    end
    if next(desired) ~= nil then
        self.effect.VFXEffect:FastForward(FLOOD_EMITTER_ID, GetTime())
    end
end

function FloodWaterVisuals:OnRemoveFromEntity()
    if self._inittask ~= nil then self._inittask:Cancel(); self._inittask = nil end
    if self._refreshtask ~= nil then
        self._refreshtask:Cancel()
        self._refreshtask = nil
    end
    self.inst:RemoveEventCallback("regionchange_client", self._onchange)
    self.inst:RemoveEventCallback("tropicalfloodlevelchanged", self._onchange, TheWorld)
    self.inst:RemoveEventCallback("floodcontrolchanged", self._onchange, TheWorld)
    self.inst:RemoveEventCallback("onterraform", self._onchange, TheWorld)
    if self._tilewatcher ~= nil then
        self._tilewatcher:UnlistenToUpdate(self._onchange)
        self._tilewatcher = nil
    end
    if self.effect ~= nil and self.effect:IsValid() then
        self.effect:Remove()
    end
    self.effect = nil
    self.flooded = {}
end

return FloodWaterVisuals
