local M = {}

M.DEFAULT_COUNT = 12
M.MIN_SPACING = 50
M.CLEARANCE = 2

local SAMPLES_PER_CELL = 4
local MAX_CELLS_PER_AXIS = 16

local function DistanceSq(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy
end

local function CollectCandidates(world, width, height, padding)
    local span_x, span_y = width - 2 * padding, height - 2 * padding
    if span_x <= 0 or span_y <= 0 then return {} end

    local cell_size = math.max(M.MIN_SPACING / 2,
        math.ceil(math.max(span_x, span_y) / MAX_CELLS_PER_AXIS))
    local cell_columns = math.ceil(span_x / cell_size)
    local cells = {}
    local radius = M.CLEARANCE
    local window = 2 * radius + 1
    local first_x, first_y = padding - radius, padding - radius
    local scan_width = span_x + 2 * radius
    local columns, rows = {}, {}
    for i = 1, scan_width do columns[i] = 0 end

    -- Rolling row sums check the entire boat footprint with one read per tile.
    for y = first_y, height - padding - 1 + radius do
        local slot = (y - first_y) % window + 1
        local row = rows[slot] or { blocked = {}, centres = {} }
        for i = 1, scan_width do
            local x = first_x + i - 1
            local tile = world:GetTile(x, y)
            local water = IsOceanTile(tile) and tile ~= WORLD_TILES.MANGROVE
                and tile ~= WORLD_TILES.LILYPOND
            local blocked = (not water or world:IsTileReserved(x, y)) and 1 or 0
            columns[i] = columns[i] + blocked - (row.blocked[i] or 0)
            row.blocked[i] = blocked
            row.centres[i] = tile == WORLD_TILES.OCEAN_SWELL
        end
        rows[slot] = row

        if y >= first_y + window - 1 then
            local centre_y = y - radius
            local centre_row = rows[(centre_y - first_y) % window + 1]
            local blocked = 0
            for i = 1, window do blocked = blocked + columns[i] end
            for i = radius + 1, scan_width - radius do
                if blocked == 0 and centre_row.centres[i] then
                    local x = first_x + i - 1
                    local cell_id = math.floor((x - padding) / cell_size)
                        + math.floor((centre_y - padding) / cell_size) * cell_columns + 1
                    local cell = cells[cell_id]
                    if cell == nil then
                        cell = { seen = 0 }
                        cells[cell_id] = cell
                    end
                    cell.seen = cell.seen + 1
                    local sample = #cell < SAMPLES_PER_CELL and #cell + 1 or math.random(cell.seen)
                    if sample <= SAMPLES_PER_CELL then cell[sample] = { x = x, y = centre_y } end
                end
                if i < scan_width - radius then
                    blocked = blocked - columns[i - radius] + columns[i + radius + 1]
                end
            end
        end
    end

    local candidates = {}
    for cell_id = 1, cell_columns * math.ceil(span_y / cell_size) do
        for _, point in ipairs(cells[cell_id] or {}) do
            candidates[#candidates + 1] = point
        end
    end
    return candidates
end

local function SelectEndpoints(candidates, count, existing, width, height)
    if #candidates == 0 then return {} end
    for _, point in ipairs(candidates) do
        point.distance = math.huge
        for _, endpoint in ipairs(existing) do
            local occupied = { x = endpoint.x / TILE_SCALE + width / 2,
                y = endpoint.z / TILE_SCALE + height / 2 }
            point.distance = math.min(point.distance, DistanceSq(point, occupied))
        end
    end

    local selected = {}
    local next_index = math.random(#candidates)
    if #existing > 0 then
        for i, point in ipairs(candidates) do
            if point.distance > candidates[next_index].distance then next_index = i end
        end
    end
    while #selected < count and next_index ~= nil do
        local endpoint = candidates[next_index]
        if endpoint.distance < M.MIN_SPACING * M.MIN_SPACING then break end
        endpoint.selected = true
        selected[#selected + 1] = endpoint
        next_index = nil
        -- Maintain nearest-endpoint distances instead of rescanning all selected points.
        for i, point in ipairs(candidates) do
            if not point.selected then
                point.distance = math.min(point.distance, DistanceSq(point, endpoint))
                if next_index == nil or point.distance > candidates[next_index].distance then
                    next_index = i
                end
            end
        end
    end
    if #selected % 2 == 1 then selected[#selected] = nil end
    return selected
end

function M.Generate(world, root, entities, width, height, options)
    options = options or {}
    local count = options.count or M.DEFAULT_COUNT
    local padding = options.padding or 24
    -- Old generators could leave these behind when fewer than two points existed.
    entities.bermudatriangle_MARKER = nil
    if count ~= count or count == math.huge or count < 2 then return 0 end
    count = math.floor(count / 2) * 2
    padding = math.max(M.CLEARANCE, math.floor(padding))

    local existing = entities.bermudatriangle or {}
    local candidates = CollectCandidates(world, width, height, padding)
    local endpoints = SelectEndpoints(candidates, count, existing, width, height)
    local pairs = #endpoints / 2
    if pairs == 0 then return 0 end

    local function SaveEndpoint(point, id, target)
        existing[#existing + 1] = {
            x = (point.x - width / 2) * TILE_SCALE,
            z = (point.y - height / 2) * TILE_SCALE,
            id = id,
            data = { teleporter = { target = target } },
        }
    end
    while #endpoints >= 2 do
        local first = table.remove(endpoints, 1)
        local partner = 1
        for i = 2, #endpoints do
            if DistanceSq(first, endpoints[i]) > DistanceSq(first, endpoints[partner]) then partner = i end
        end
        local second = table.remove(endpoints, partner)
        local id = root.MIN_WORMHOLE_ID
        SaveEndpoint(first, id, id + 1)
        SaveEndpoint(second, id + 1, id)
        root.MIN_WORMHOLE_ID = id + 2
    end
    entities.bermudatriangle = existing
    return pairs
end

return M
