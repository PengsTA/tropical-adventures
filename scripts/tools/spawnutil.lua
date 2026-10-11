-- this file function only for worldgen, in game use main/util.lua functions
SpawnUtil = {}
local SpawnRules = require("tools/worldgen_spawnrules")
SpawnUtil.RegisterSpawnRule = SpawnRules.Register
SpawnUtil.SetWorldgenLocation = SpawnRules.SetLocation

function SpawnUtil.IsShoreTile(tile)
    return IsLandTile(tile) or tile == WORLD_TILES.MANGROVE or tile == WORLD_TILES.LILYPOND
end

------------------这个函数是从util拿过来的
function CheckTileType(tile, check, ...)
    if type(tile) == "table" then
        local x, y, z = GetWorldPosition(tile)
        if type(check) == "function" then
            return check(x, y, z, ...)
        end
        tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    end

    if type(check) == "function" then
        return check(tile, ...)
    elseif type(check) == "table" then
        -- return table.contains(check, tile)  -- ewww no, very inefficent
        return check[tile] ~= nil
    elseif type(check) == "string" then
        return WORLD_TILES[check] == tile
    end

    return tile == check
end

function SpawnUtil.IsSurroundedByTile(x, y, radius, tile)
    radius = math.ceil(radius or 1)
    for dy = -radius, radius do
        for dx = -radius, radius do
            if not CheckTileType(WorldSim:GetTile(x + dx, y + dy), tile) then return false end
        end
    end
    return true
end

function SpawnUtil.IsSurroundedByWaterTile(x, y, radius)
    return SpawnUtil.IsSurroundedByTile(x, y, radius, IsOceanTile)
end

function SpawnUtil.IsCloseToTile(x, y, radius, check)
    radius = math.ceil(radius or 1)
    for dy = -radius, radius do
        for dx = -radius, radius do
            if CheckTileType(WorldSim:GetTile(x + dx, y + dy), check) then return true end
        end
    end
    return false
end

function IsCloseToShoreTile(x, y, radius)
    return SpawnUtil.IsCloseToTile(x, y, radius, SpawnUtil.IsShoreTile)
end

function SpawnUtil.IsCloseToWaterTile(x, y, radius)
    return SpawnUtil.IsCloseToTile(x, y, radius, IsOceanTile)
end

function SpawnUtil.IsCloseToLandTile(x, y, radius)
    return SpawnUtil.IsCloseToTile(x, y, radius, IsLandTile)
end

function SpawnUtil.GetShortestDistToPrefab(x, y, ents, prefab)
    local w, h = WorldSim:GetWorldSize()
    local halfw, halfh = w / 2, h / 2
    local dist = 100000
    if ents ~= nil and ents[prefab] ~= nil then
        for i, spawn in ipairs(ents[prefab]) do
            local sx, sy = spawn.x, spawn.z
            local dx, dy = (x - halfw) * TILE_SCALE - sx, (y - halfh) * TILE_SCALE - sy
            local d = math.sqrt(dx * dx + dy * dy)
            if d < dist then
                dist = d
            end
            -- print(string.format("SpawnUtil.GetShortestDistToPrefab (%d, %d) -> (%d, %d) = %d", x, y, sx, sy, dist))
        end
    end
    return dist
end

function SpawnUtil.GetDistToSpawnPoint(x, y, ents)
    return SpawnUtil.GetShortestDistToPrefab(x, y, ents, "spawnpoint")
end

function SpawnUtil.SpawntestFn(prefab, x, y, ents)
    return SpawnRules.Test(prefab, x, y, ents)
end

-- Mod support
function SpawnUtil.AddWaterCommonSpawn(prefab)
    SpawnRules.Register(prefab, { surface = "water" })
end

function SpawnUtil.AddLandCommonSpawn(prefab)
    SpawnRules.Register(prefab, { surface = "land" })
end

function SpawnUtil.AddEntityCheckFilter(prefab, ground)
    if terrain.filter[prefab] then
        for i, g in ipairs(terrain.filter[prefab]) do
            if g == ground then
                return false
            end
        end
    else
        --print("Warning: no terrain filter ", prefab)
    end
    return true
end

function SpawnUtil.AddEntity(prefab, ent_x, ent_y, entitiesOut, width, height, prefab_list, prefab_data, rand_offset, ...)
    local tile = WorldSim:GetTile(ent_x, ent_y)
    if TileGroupManager:IsImpassableTile(tile) then
        return false
    end

    if not SpawnUtil.AddEntityCheckFilter(prefab, tile) then
        return false
    end

    if not SpawnUtil.AddEntityCheck(prefab, ent_x, ent_y, entitiesOut) then return false end
    PopulateWorld_AddEntity(prefab, ent_x, ent_y, tile, entitiesOut, width, height, prefab_list, prefab_data,
        rand_offset, ...)
    return true
end

function SpawnUtil.AddEntityCheck(prefab, ent_x, ent_y, entitiesOut, spawnFns)
    return SpawnRules.Test(prefab, ent_x, ent_y, entitiesOut, spawnFns)
end

function SpawnUtil.GetLayoutRadius(layout, prefabs)
    assert(layout ~= nil)
    assert(prefabs ~= nil)

    local extents = { xmin = 1000000, ymin = 1000000, xmax = -1000000, ymax = -1000000 }
    for i = 1, #prefabs do
        -- print(string.format("Prefab %s (%4.2f, %4.2f)", tostring(prefabs[i].prefab), prefabs[i].x, prefabs[i].y))
        if prefabs[i].x < extents.xmin then extents.xmin = prefabs[i].x end
        if prefabs[i].x > extents.xmax then extents.xmax = prefabs[i].x end
        if prefabs[i].y < extents.ymin then extents.ymin = prefabs[i].y end
        if prefabs[i].y > extents.ymax then extents.ymax = prefabs[i].y end
    end

    local e_width, e_height = extents.xmax - extents.xmin, extents.ymax - extents.ymin
    local size = math.ceil(layout.scale * math.max(e_width, e_height))

    if layout.ground then
        size = math.max(size, #layout.ground)
    end

    -- print(string.format("Layout %s dims (%4.2f x %4.2f), size %4.2f", layout.name, e_width, e_height, size))
    return size
end

-- for in-game checks, use FindRandomWaterPoints
-- overrides basegame function from RoT, so populating_tile may be a function or nil.
function SpawnUtil.FindRandomWaterPoints(populating_tile, width, height, edge_dist, needed)
    local points = {}
    local points_x = {}
    local points_y = {}
    local incs = { 263, 137, 67, 31, 17, 9, 5, 3, 1 }
    local adj_width, adj_height = width - 2 * edge_dist, height - 2 * edge_dist
    local start_x, start_y = math.random(0, adj_width), math.random(0, adj_height)

    for inc = 1, #incs do
        if #points < needed then
            -- dunno why this was a function
            local i, j = 0, 0
            while j < adj_height and #points < needed do
                local y = ((start_y + j) % adj_height) + edge_dist
                while i < adj_width and #points < needed do
                    local x = ((start_x + i) % adj_width) + edge_dist
                    -- local ground = WorldSim:GetTile(x, y)
                    -- if populating_tile(ground, x, y) then
                    if populating_tile == nil
                        or (type(populating_tile) == "function" and populating_tile(WorldSim:GetTile(x, y), x, y, points))
                        or (type(populating_tile) == "number" and not WorldSim:IsTileReserved(x, y) and populating_tile == WorldSim:GetTile(x, y)) then
                        table.insert(points, { x = x, y = y })
                    end
                    i = i + incs[inc]
                end
                j = j + incs[inc]
                i = 0
            end

            -- print(string.format("%d (of %d) points found", #points, needed))
        end
    end

    points = shuffleArray(points)
    for i = 1, #points do
        table.insert(points_x, points[i].x)
        table.insert(points_y, points[i].y)
    end

    return points_x, points_y
end

function SpawnUtil.SpawnSunkenBoat(world)
    if not world.meta.patcher or not world.meta.patcher.spawnedsunken_boat then -- Put it here for the time being
        local sunken_boat = nil
        for i, node in ipairs(world.topology.nodes) do
            if node.type == NODE_TYPE.Background then
                local x = node.cent[1]
                local z = node.cent[2]

                for r = 15, 60, 15 do
                    local offset = FindValidPositionByFan(0, r, 20, function(o)
                        local pos = Vector3(o.x + x, 0, o.z + z)
                        -- first, we need water
                        if not world.Map:IsOceanTileAtPoint(pos.x, pos.y, pos.z) then
                            return false
                        end
                        -- second, it should be surrounded by water (no rivers plz)
                        local land = FindValidPositionByFan(0, 10, 8, function(o2)
                            return not world.Map:IsOceanTileAtPoint(pos.x + o2.x, 0, pos.z + o2.z)
                        end)
                        if land ~= nil then
                            return false
                        end
                        return true
                    end)
                    if offset ~= nil then
                        -- We found ocean! now walk towards land and put us on the beach.
                        local pos = Vector3(offset.x + x, 0, offset.z + z)

                        local dir = Vector3(-offset.x, -offset.y, -offset.z):Normalize()
                        while math.abs(pos.x - x) > 1 and math.abs(pos.z - z) > 1 do
                            local tile_x, tile_y, tile_z = world.Map:GetTileCenterPoint(pos.x, pos.y, pos.z)
                            if not world.Map:IsOceanTileAtPoint(tile_x, tile_y, tile_z) then
                                -- first clean up the area
                                local ents = TheSim:FindEntities(tile_x - 1, tile_y, tile_z - 1, 6)
                                for _, ent in ipairs(ents) do
                                    ent:DoTaskInTime(0, ent.Remove)
                                end

                                -- then spawn a boat!
                                sunken_boat = SpawnPrefab("sunken_boat")
                                sunken_boat.Transform:SetPosition(tile_x, tile_y, tile_z)
                                print("Spawned the sunken_boat.")
                                break
                            end

                            pos = pos + dir
                        end
                    end
                    if sunken_boat then
                        break
                    end
                end
            end
            if sunken_boat then
                break
            end
        end

        if sunken_boat then
            if world.meta.patcher == nil then
                world.meta.patcher = {}
            end
            world.meta.patcher.spawnedsunken_boat = true

            -- Put some flotsam near the wreck for dramatic effect
            local offsets = {
                Vector3(1, 0, 0),
                Vector3(1, 0, 1),
                Vector3(0, 0, 1),
                Vector3(-1, 0, 1),
                Vector3(-1, 0, 0),
                Vector3(-1, 0, -1),
                Vector3(0, 0, -1),
                Vector3(1, 0, -1),
            }
            shuffleArray(offsets)
            local numspawned = 0
            local pos = Vector3(sunken_boat.Transform:GetWorldPosition())
            for i = 1, #offsets do
                local offset = offsets[i] * 12
                local land = FindValidPositionByFan(0, 6, 8, function(o)
                    local x, y, z = (pos + offset + o):Get()
                    return not IsOceanTile(TheWorld.Map:GetTileAtPoint(x, y, z))
                end)
                if not land then
                    local flotsam = SpawnPrefab("flotsam")
                    flotsam.Transform:SetPosition((pos + offset):Get())
                    flotsam.components.drifter:SetDriftTarget(pos)
                    numspawned = numspawned + 1
                end
                if numspawned == 3 then
                    break
                end
            end
        else
            print("UH OH! We couldn't find a spot in the world for the sunken_boat!")
        end
    end
end

function SpawnUtil.SpawnVolcanoLavaFX(world)
    for _, node in ipairs(world.topology.nodes) do
        if node.type == "VolcanoLava" then
            node.area = node.area or 1
            local ext = ResetextentsForPoly(node.poly)

            local lava = SpawnPrefab("volcanolavafx")
            lava:SetRadius(0.5 * ext.radius)
            lava.Transform:SetPosition(node.cent[1], 0, node.cent[2])
        end
    end
end
