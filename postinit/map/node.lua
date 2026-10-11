require("map/graphnode")

local function WithContext(self, context, fn, ...)
    local previous = self.ta_spawn_context
    self.ta_spawn_context = context
    local ok, result = pcall(fn, self, ...)
    self.ta_spawn_context = previous
    if not ok then error(result, 0) end
    return result
end

local function ContentsAt(context, tile)
    if context.background ~= nil then
        local room = context.per_terrain and context.background[tile] or context.background
        return room and room.contents
    end
    return context.contents
end

Node.AddEntity = function(self, prefab, points_x, points_y, current_pos_idx, entitiesOut, width, height, prefab_list,
                          prefab_data, rand_offset)
    local context = self.ta_spawn_context
    local function Try(index)
        local x, y = points_x[index], points_y[index]
        if prefab == nil or x == nil or y == nil then return false end
        local tile = WorldSim:GetTile(x, y)
        if not IsValidNodeTile(tile) then return false end
        if context ~= nil and not context.layout then
            if WorldSim:IsTileReserved(x, y) then return false end
            if (not context.retry or context.apply_filters) and not SpawnUtil.AddEntityCheckFilter(prefab, tile) then
                return false
            end
            local contents = ContentsAt(context, tile)
            if not SpawnUtil.AddEntityCheck(prefab, x, y, entitiesOut, contents and contents.prefabspawnfn) then
                return false
            end
        end
        PopulateWorld_AddEntity(prefab, x, y, tile, entitiesOut, width, height, prefab_list, prefab_data, rand_offset)
        return true
    end

    if Try(current_pos_idx) then return true end
    if context ~= nil and context.retry then
        -- Counted and extra content may use another free point in this same site.
        local candidates = context.candidates
        for i = 1, candidates and #candidates or #points_x do
            local index = candidates and candidates[i] or i
            if index ~= current_pos_idx and Try(index) then return true end
        end
        print("[Tropical Adventures] No suitable node position:", self.id, prefab)
    end
    return false
end

local PopulateVoronoi = Node.PopulateVoronoi
Node.PopulateVoronoi = function(self, spawnFn, ...)
    local contents = self.data.terrain_contents
    local context = { contents = contents, retry = true, apply_filters = contents and contents.countprefabs_uses_filters }
    local checked_spawn = setmetatable({}, { __index = spawnFn })
    checked_spawn.pickspawnprefab = function(...)
        context.retry = false
        return spawnFn.pickspawnprefab(...)
    end
    return WithContext(self, context, PopulateVoronoi, checked_spawn, ...)
end

local PopulateChildren = Node.PopulateChildren
Node.PopulateChildren = function(self, spawnFn, entities, width, height, background, per_terrain, ...)
    local context = { background = background, per_terrain = per_terrain }
    return WithContext(self, context, PopulateChildren, spawnFn, entities, width, height, background, per_terrain, ...)
end

local PopulateExtra = Node.PopulateExtra
Node.PopulateExtra = function(self, choices, spawnFn, data)
    local parent = self.ta_spawn_context or {}
    local context = { contents = parent.contents, background = parent.background, per_terrain = parent.per_terrain,
        candidates = data.idx_left, retry = true, apply_filters = true }
    return WithContext(self, context, PopulateExtra, choices, spawnFn, data)
end

local ConvertGround = Node.ConvertGround
Node.ConvertGround = function(self, ...)
    -- Layouts have their own footprint checks and must be placed as a whole.
    return WithContext(self, { layout = true }, ConvertGround, ...)
end
