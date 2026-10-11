local M = {}

M.VERSION = 1
M.WATER_TILES = 3
M.GUARD_TILES = 1
M.BAND_TILES = M.GUARD_TILES + M.WATER_TILES
M.MIN_SIZE = 48
M.WRAP_TILES = 3
M.ARRIVAL_TILES = 3.5
M.WARN_TILES = 6
M.FOG_BAND_TILES = 3
M.FOG_OUTSIDE_TILES = 1
M.FOG_VIEW_TILES = 16
M.CHECK_PERIOD = .25
M.COOLDOWN = 3

function M.GetBounds(width, height)
    if math.min(width, height) < M.MIN_SIZE then return nil end
    return { x = width * TILE_SCALE / 2, z = height * TILE_SCALE / 2 }
end

function M.CanGenerate(width, height)
    return TA_CONFIG ~= nil and TA_CONFIG.WORLDGEN.shipwrecked
        and math.min(width, height) >= M.MIN_SIZE or false
end

function M.IsEnabled(world)
    -- MakeWorld renames the entity to "world"; gamelogic retains the map's prefab here.
    return world ~= nil and world.worldprefab == "forest" and world.topology ~= nil
        and world.topology.ta_ocean_wrap == M.VERSION
end

function M.Distance(bounds, x, z)
    return math.min(bounds.x - math.abs(x), bounds.z - math.abs(z))
end

local OFFSETS = { {1,0}, {-1,0}, {0,1}, {0,-1}, {1,1}, {-1,1}, {1,-1}, {-1,-1} }

function M.GenerateBoundary(world, width, height, is_water)
    if not M.CanGenerate(width, height) then return false end
    local patches, displaced = {}, {}
    local function NearbyWater(x, y)
        for ring = 1, 8 do
            for _, offset in ipairs(OFFSETS) do
                local cx, cy = x + offset[1] * ring, y + offset[2] * ring
                if cx >= M.GUARD_TILES and cy >= M.GUARD_TILES
                    and cx < width - M.GUARD_TILES and cy < height - M.GUARD_TILES then
                    local tile = world:GetTile(cx, cy)
                    if is_water(tile) then return tile end
                end
            end
        end
        return WORLD_TILES.OCEAN_COASTAL
    end
    local function Fill(x, y)
        local tile = world:GetTile(x, y)
        local distance = math.min(x, y, width - 1 - x, height - 1 - y)
        local replacement
        if distance < M.GUARD_TILES then
            replacement = WORLD_TILES.IMPASSABLE
        elseif not is_water(tile) then
            replacement = NearbyWater(x, y)
        end
        if replacement ~= nil and replacement ~= tile then
            patches[#patches + 1] = { x, y, replacement }
            if tile ~= WORLD_TILES.IMPASSABLE and not is_water(tile) then
                displaced[y * width + x] = tile
            end
        end
    end
    for y = 0, height - 1 do
        if y < M.BAND_TILES or y >= height - M.BAND_TILES then
            for x = 0, width - 1 do Fill(x, y) end
        else
            for x = 0, M.BAND_TILES - 1 do Fill(x, y) end
            for x = width - M.BAND_TILES, width - 1 do Fill(x, y) end
        end
    end
    -- Read the original neighbours before applying patches, independent of visit order.
    for _, patch in ipairs(patches) do world:SetTile(patch[1], patch[2], patch[3]) end
    return true, displaced
end

-- Only fixed obstacles and obstacle spawners need an empty sailing corridor.
local BLOCKERS = {
    seastack = true, seastack_spawner_swell = true, seastack_spawner_rough = true,
    waterplant = true, waterplant_spawner_rough = true, boat_otterden = true,
    coralreef = true, coral_brain_rock = true, ballphinhouse = true,
    octohouse = true, octopusking = true, spidercoralhole = true,
    wreck = true, waterygrave = true, redbarrel = true, mussel_farm = true,
    boatfragment01 = true, boatfragment02 = true, boatfragment03 = true,
    boatfragment04 = true, boatfragment05 = true,
    whale_bluefinal = true, whale_whitefinal = true,
}

function M.CanPlacePrefab(prefab, x, y, width, height)
    return not BLOCKERS[prefab] or not M.CanGenerate(width, height)
        or math.min(x, y, width - 1 - x, height - 1 - y) >= M.BAND_TILES + 1
end

function M.GetTriggerDistance(radius)
    return math.max(M.WRAP_TILES * TILE_SCALE, M.GUARD_TILES * TILE_SCALE + (radius or 1) + 1)
end

function M.GetDestination(bounds, x, z, radius)
    local trigger = M.GetTriggerDistance(radius)
    local distance = M.Distance(bounds, x, z)
    if distance < 0 or distance > trigger then return nil end
    local arrival = math.max(M.ARRIVAL_TILES * TILE_SCALE, trigger + 1)
    local dx, dz = x, z
    if bounds.x - math.abs(x) <= trigger then
        dx = (x < 0 and 1 or -1) * (bounds.x - arrival)
    end
    if bounds.z - math.abs(z) <= trigger then
        dz = (z < 0 and 1 or -1) * (bounds.z - arrival)
    end
    return dx, dz
end

function M.FindDestination(bounds, x, z, radius, is_clear)
    local dx, dz = M.GetDestination(bounds, x, z, radius)
    if dx == nil then return nil end
    local minimum_distance = M.GetTriggerDistance(radius) + .5
    local function Search(px, pz, minimum)
        local function Valid(cx, cz)
            return M.Distance(bounds, cx, cz) > minimum and is_clear(cx, cz)
        end
        if Valid(px, pz) then return px, pz end
        -- A bounded search handles player-built obstacles without scanning the map.
        for ring = 1, 8 do
            for _, offset in ipairs(OFFSETS) do
                local cx, cz = px + offset[1] * ring * TILE_SCALE, pz + offset[2] * ring * TILE_SCALE
                if Valid(cx, cz) then return cx, cz end
            end
        end
    end
    local cx, cz = Search(dx, dz, minimum_distance)
    if cx ~= nil then return cx, cz end

    -- Islands can reach the visual fog band. Fall back to the narrow water corridor.
    local margin = (M.GUARD_TILES + M.WATER_TILES / 2) * TILE_SCALE
    local trigger = M.GetTriggerDistance(radius)
    if bounds.x - math.abs(x) <= trigger then dx = (x < 0 and 1 or -1) * (bounds.x - margin) end
    if bounds.z - math.abs(z) <= trigger then dz = (z < 0 and 1 or -1) * (bounds.z - margin) end
    return Search(dx, dz, M.GUARD_TILES * TILE_SCALE + (radius or 1) + .5)
end

return M
