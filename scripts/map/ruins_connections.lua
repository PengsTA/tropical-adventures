local M = {}

local TYPES = { "vine", "rubble", "spear", "dart", "gate", "open" }
local FAVORITES = {
    vine = "vine", overgrown = "vine", barricade = "rubble", store = "rubble",
    spear = "spear", dart = "dart", ghost = "dart", blue = "gate",
    statue = "gate", treasury = "gate", sow = "gate", clock = "gate",
}

local function Key(x, z)
    return math.floor(x * 10 + .5) .. ":" .. math.floor(z * 10 + .5)
end

function M.Normal(data)
    local angle = ((data.savedrotation and data.savedrotation.rotation) or 0) * math.pi / 180
    return math.floor(math.cos(angle) + .5), math.floor(-math.sin(angle) + .5)
end

function M.FinalizeTreasures(ents)
    if not ents or not ents.ta_ruins_treasure_guard then return end
    local groups, result = {}, {}
    for _, record in ipairs(ents.ta_ruins_treasure_guard) do
        local data = record.data
        if data.roomdistance then
            local angle = data.savedrotation.rotation * math.pi / 180
            local cx = math.floor(record.x + math.cos(angle) * data.roomdistance + .5)
            local cz = math.floor(record.z - math.sin(angle) * data.roomdistance + .5)
            local key = Key(cx, cz)
            local group = groups[key]
            if not group then
                group = { record = record, targets = {}, x = cx, z = cz }
                groups[key] = group
                result[#result + 1] = group
            end
            group.targets[#group.targets + 1] = { prefab = data.target, x = record.x, z = record.z }
            if data.style == "vault" or data.style == "spike" and group.record.data.style ~= "vault" then
                group.record = record
            end
        else
            result[#result + 1] = { record = record }
        end
    end
    local records = {}
    for _, group in ipairs(result) do
        local record = group.record
        if group.targets then
            local dx, dz = group.x - record.x, group.z - record.z
            record.data.rotation = math.abs(dx) > math.abs(dz) and (dx > 0 and 0 or 180) or (dz > 0 and -90 or 90)
            record.data.targets = group.targets
            record.data.roomdistance = nil
        end
        records[#records + 1] = record
    end
    ents.ta_ruins_treasure_guard = records
end

function M.Align(map, x, z, rotation)
    if not map.GetTileCenterPoint then return x, z, 8 end
    local nx, nz = M.Normal({ savedrotation = { rotation = rotation } })
    -- Measure the inside boundary tile without snapping the row off its seam.
    local cx, _, cz = map:GetTileCenterPoint(x - nx * 2, 0, z - nz * 2)
    if cx == nil or cz == nil then return x, z, 8 end
    local low, high = 0, 0
    local function Floor(across)
        local px, pz = cx - nz * across, cz + nx * across
        local tile = map:GetTileAtPoint(px, 0, pz)
        return tile == WORLD_TILES.PIGRUINS or tile == WORLD_TILES.PIGRUINS_BLUE
    end
    if not Floor(0) then return x, z, 8 end
    for step = 1, 3 do if Floor(-step * 4) then low = -step * 4 else break end end
    for step = 1, 3 do if Floor(step * 4) then high = step * 4 else break end end
    local across = -(cx - x) * nz + (cz - z) * nx + (low + high) / 2
    return x - nz * across, z + nx * across, high - low + 4
end

-- Native layout rotation has already transformed savedrotation at this point.
function M.Finalize(ents, random)
    M.FinalizeTreasures(ents)
    if not ents or not ents.ta_ruins_connection then return end
    local first = ents.ta_ruins_connection[1]
    if first and first.data and first.data.finalized then return end
    random = random or math.random
    local edges, ordered = {}, {}
    for _, record in ipairs(ents.ta_ruins_connection) do
        record.data = record.data or {}
        -- Positioned native layouts offset objects half a tile from floor centres.
        -- Recover the floor centre before calculating the shared room seam.
        record.x, record.z = record.x + 2, record.z + 2
        local nx, nz = M.Normal(record.data)
        local key = Key(record.x + nx * 2, record.z + nz * 2)
        local edge = edges[key]
        if not edge then
            edge = { record = record, rooms = {}, themes = {} }
            edges[key] = edge
            ordered[#ordered + 1] = edge
        end
        edge.rooms[#edge.rooms + 1] = Key(record.x - nx * 14, record.z - nz * 14)
        edge.themes[#edge.themes + 1] = record.data.theme
    end
    table.sort(ordered, function(a, b)
        return a.record.x == b.record.x and a.record.z < b.record.z or a.record.x < b.record.x
    end)
    local result, used = {}, {}
    for _, edge in ipairs(ordered) do
        local choices, total = {}, 0
        for _, kind in ipairs(TYPES) do
            local repeated = false
            for _, room in ipairs(edge.rooms) do
                if used[room] and used[room][kind] then repeated = true end
            end
            if not repeated then
                local weight = kind == "open" and 1 or 2
                for _, theme in ipairs(edge.themes) do
                    if FAVORITES[theme] == kind then weight = weight + 3 end
                end
                total = total + weight
                choices[#choices + 1] = { kind, total }
            end
        end
        -- Two four-way rooms can exhaust the six choices around a shared edge.
        local kind = "open"
        if total > 0 then
            local roll = random() * total
            for _, choice in ipairs(choices) do
                if roll < choice[2] then kind = choice[1]; break end
            end
        end
        for _, room in ipairs(edge.rooms) do
            used[room] = used[room] or {}
            used[room][kind] = true
        end
        edge.record.data.kind = kind
        edge.record.data.finalized = true
        local nx, nz = M.Normal(edge.record.data)
        edge.record.x, edge.record.z = edge.record.x + nx * 2, edge.record.z + nz * 2
        edge.record.y = 0
        result[#result + 1] = edge.record
    end
    ents.ta_ruins_connection = result
end

return M
