local RegionDefs = require("tools/regiondefs")
local FloodPattern = {
    MIN_VISIBLE_LEVEL = .18,
    -- This covers one client view, while sources outside the view may still
    -- contribute water within the current Manhattan reach.
    PLAYER_TILE_RADIUS = 20,

    -- A tile is flooded when a valid puddle source sits within MAX_REACH
    -- tiles (Manhattan distance). Source placement stays coordinate-derived,
    -- so the server and every client build the same irregular water field
    -- without sending a cell list across the network.
    SOURCE_DENSITY = .025,
    MAX_REACH = 3,
}

-- Each region gets a deterministic but independent source field. The lower
-- Hamlet density keeps its rainy season from covering the whole jungle with
-- the same density used by Shipwrecked.
FloodPattern.ZONES = {
    shipwrecked = {
        subregions = { [RegionDefs.SUBREGION.sw_vanilla] = true },
        source_density = .006,
        max_reach = 3,
        salt = 0,
    },
    hamlet = {
        subregions = {
            [RegionDefs.SUBREGION.ham_rainforest] = true,
            [RegionDefs.SUBREGION.ham_wilds] = true,
        },
        source_density = .005,
        max_reach = 3,
        salt = 71,
    },
}

function FloodPattern.GetZoneConfig(zone)
    if type(zone) == "table" then
        return zone
    end
    return FloodPattern.ZONES[zone] or FloodPattern.ZONES.shipwrecked
end

function FloodPattern.GetMaxReach(zone)
    local config = FloodPattern.GetZoneConfig(zone)
    return config.max_reach or FloodPattern.MAX_REACH
end

function FloodPattern.QuantizeLevel(level)
    return math.floor(math.max(0, math.min(1, level or 0)) * 100 + .5) / 100
end

function FloodPattern.IsValidTile(zone, x, z)
    local map = TheWorld.Map
    return map:IsAboveGroundAtPoint(x, 0, z)
        and not map:IsInteriorAtPoint(x, 0, z)
        and FloodPattern.GetZoneConfig(zone).subregions[
            RegionDefs.GetSubregionId(map:GetSubregionAtPoint(x, 0, z))] == true
end

function FloodPattern.IsBlockedByFloodControls(controls, x, z)
    local count = 0
    for _, control in ipairs(controls) do
        if control:IsValid() then
            local cx, _, cz = control.Transform:GetWorldPosition()
            local dx, dz = cx - x, cz - z
            if dx * dx + dz * dz <= 100 then
                count = count + 1
                if count >= 4 then return true end
            end
        end
    end
    return false
end

-- Reach in tiles grows with the flood level. At reach 0 only the source tile
-- itself is flooded, which matches the old "one tile per source" floor.
function FloodPattern.GetReach(level, zone)
    local config = FloodPattern.GetZoneConfig(zone)
    level = FloodPattern.QuantizeLevel(level)
    return math.floor(level * (config.max_reach or FloodPattern.MAX_REACH) + .5)
end

function FloodPattern.GetTileCenter(x, z)
    local tile_x, _, tile_z = TheWorld.Map:GetTileCenterPoint(x, 0, z)
    return tile_x, tile_z
end

-- Numeric compound key. Coordinates are tile-center world positions, so the
-- floor division maps them to the same integer tile index used by GetTileNoise
-- without allocating a string per lookup.
local TILE_KEY_STRIDE = 1048576

function FloodPattern.GetTileKey(x, z)
    return math.floor(x / TILE_SCALE) * TILE_KEY_STRIDE + math.floor(z / TILE_SCALE)
end

local function GetNoise(tile_x, tile_z, salt)
    local value = math.abs(math.sin(tile_x * 12.9898 + tile_z * 78.233 + salt) * 43758.5453)
    return value - math.floor(value)
end

function FloodPattern.GetTileNoise(x, z, zone)
    local config = FloodPattern.GetZoneConfig(zone)
    return GetNoise(math.floor(x / TILE_SCALE), math.floor(z / TILE_SCALE), config.salt or 0)
end

function FloodPattern.IsPuddleSource(x, z, zone)
    local config = FloodPattern.GetZoneConfig(zone)
    return FloodPattern.GetTileNoise(x, z, config)
        <= (config.source_density or FloodPattern.SOURCE_DENSITY)
end

-- Visit every flooded tile within the render radius by expanding each nearby
-- puddle source into a small diamond of reach-sized water. This replaces the
-- old per-source BFS growth with a closed-form neighbourhood, keeping the same
-- deterministic server/client field at a fraction of the cost.
function FloodPattern.VisitFloodCells(center_x, center_z, tile_radius, level, is_valid_source, is_valid_cell, visit, zone)
    local config = FloodPattern.GetZoneConfig(zone)
    local reach = FloodPattern.GetReach(level, config)
    if FloodPattern.QuantizeLevel(level) < FloodPattern.MIN_VISIBLE_LEVEL then
        return
    end

    local search_radius = tile_radius + reach
    local tile_radius_world = tile_radius * TILE_SCALE
    local visited = {}

    for source_offset_x = -search_radius, search_radius do
        for source_offset_z = -search_radius, search_radius do
            local source_x = center_x + source_offset_x * TILE_SCALE
            local source_z = center_z + source_offset_z * TILE_SCALE
            if FloodPattern.IsPuddleSource(source_x, source_z, config)
                and is_valid_source(source_x, source_z) then
                for cell_offset_x = -reach, reach do
                    local remaining = reach - math.abs(cell_offset_x)
                    for cell_offset_z = -remaining, remaining do
                        local cell_x = source_x + cell_offset_x * TILE_SCALE
                        local cell_z = source_z + cell_offset_z * TILE_SCALE
                        if math.abs(cell_x - center_x) <= tile_radius_world
                            and math.abs(cell_z - center_z) <= tile_radius_world then
                            local key = FloodPattern.GetTileKey(cell_x, cell_z)
                            if visited[key] == nil then
                                visited[key] = true
                                if is_valid_cell(cell_x, cell_z) then visit(cell_x, cell_z) end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Server gameplay must not depend on which players currently have a flood
-- cache around them. A tile is flooded when it is valid terrain and a valid
-- puddle source sits within the current reach, the same field the client
-- renderer expands.
function FloodPattern.IsFloodedAtPoint(x, z, level, is_valid_source, is_valid_cell, zone)
    if FloodPattern.QuantizeLevel(level) < FloodPattern.MIN_VISIBLE_LEVEL then return false end
    local config = FloodPattern.GetZoneConfig(zone)
    local center_x, center_z = FloodPattern.GetTileCenter(x, z)
    if not is_valid_cell(center_x, center_z) then
        return false
    end

    local reach = FloodPattern.GetReach(level, config)
    for source_offset_x = -reach, reach do
        local remaining = reach - math.abs(source_offset_x)
        for source_offset_z = -remaining, remaining do
            local source_x = center_x + source_offset_x * TILE_SCALE
            local source_z = center_z + source_offset_z * TILE_SCALE
            if FloodPattern.IsPuddleSource(source_x, source_z, config)
                and is_valid_source(source_x, source_z) then
                return true
            end
        end
    end
    return false
end

return FloodPattern
