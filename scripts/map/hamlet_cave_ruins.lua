local M = {}

local EXITS = {
    SINGLE_NORTH = { "one", "NORTH" },
    SINGLE_EAST = { "one", "EAST" },
    SINGLE_SOUTH = { "one", "SOUTH" },
    SINGLE_WEST = { "one", "WEST" },
    L_NORTH = { "two", "NORTH" },
    L_EAST = { "two", "EAST" },
    L_SOUTH = { "two", "SOUTH" },
    L_WEST = { "two", "WEST" },
    TUNNEL_NS = { "long", "NORTH" },
    TUNNEL_EW = { "long", "EAST" },
    THREE_WAY_N = { "three", "NORTH" },
    THREE_WAY_E = { "three", "EAST" },
    THREE_WAY_S = { "three", "SOUTH" },
    THREE_WAY_W = { "three", "WEST" },
    FOUR_WAY = { "four", "NORTH" },
}

local function Add(layout, prefab, x, y, data)
    layout[prefab] = layout[prefab] or {}
    table.insert(layout[prefab], { x = x, y = y, properties = data and { data = data } or nil })
end

local function AddPots(layout, y)
    for _, x in ipairs({ -2, -1.5, 1.5, 2 }) do
        Add(layout, "smashingpot", x, y)
    end
end

local function Doorways(shape)
    local doors = { { 0, -1 } }
    if shape == "long" or shape == "three" or shape == "four" then doors[#doors + 1] = { 0, 1 } end
    if shape == "two" or shape == "three" or shape == "four" then doors[#doors + 1] = { 1, 0 } end
    if shape == "four" then doors[#doors + 1] = { -1, 0 } end
    return doors
end

local function AddDoorways(layout, theme, shape)
    for _, door in ipairs(Doorways(shape)) do
        local dx, dy = door[1], door[2]
        local x, y = dx * 3.5, dy * 3.5
        Add(layout, "ta_ruins_connection", x, y, {
            connector = true,
            theme = theme,
            savedrotation = { rotation = math.atan2(-dy, dx) * 180 / math.pi }
        })
        -- Stone jambs remain inside the room flanking the threshold.
        for _, side in ipairs({ -.875, -.625, -.375, .375, .625, .875 }) do
            Add(layout, "wall_pig_ruins", dx * 2.25 + dy * side, dy * 2.25 - dx * side, { gridnudge = true })
        end
    end
end

local function AddCache(layout, relic)
    -- A breakable side chamber; the main corridor stays open.
    Add(layout, relic or "pig_ruins_idol", 0, 1.75, { ruins_vault = true })
    for x = -.75, .75, .25 do
        Add(layout, "wall_pig_ruins", x, 1, { gridnudge = true })
        Add(layout, "wall_pig_ruins", x, 2.5, { gridnudge = true })
    end
    for y = 1.25, 2.25, .25 do
        if y ~= 1.75 then
            Add(layout, "wall_pig_ruins", -.75, y, { gridnudge = true })
            Add(layout, "wall_pig_ruins", .75, y, { gridnudge = true })
        end
    end
end

local function GuardTreasures(layout, theme)
    local found = false
    for _, prefab in ipairs({ "pig_ruins_idol", "pig_ruins_head", "pig_ruins_pig", "pig_ruins_ant", "pig_ruins_plaque",
        "pig_ruins_sow", "pig_ruins_truffle", "pig_ruins_artichoke", "shelves_ruins", "ta_ruins_pheromone_chest" }) do
        for _, item in ipairs(layout[prefab] or {}) do
            found = true
            if item.properties and item.properties.data then item.properties.data.trggerdarttraps = nil end
            Add(layout, "ta_ruins_treasure_guard", item.x, item.y, {
                target = prefab,
                roomdistance = math.sqrt(item.x * item.x + item.y * item.y) * 4,
                style = item.properties and item.properties.data and item.properties.data.ruins_vault and "vault"
                    or (theme == "spear" or theme == "blue" and prefab == "pig_ruins_artichoke") and "spike" or nil,
                savedrotation = { rotation = math.atan2(item.y, -item.x) * 180 / math.pi }
            })
        end
    end
    -- Hazard rooms retain their existing urn reward instead of adding extra relics.
    if not found and layout.smashingpot then
        local pot = layout.smashingpot[1]
        Add(layout, "ta_ruins_treasure_guard", pot.x, pot.y, {
            target = "smashingpot",
            roomdistance = math.sqrt(pot.x * pot.x + pot.y * pot.y) * 4,
            savedrotation = { rotation = math.atan2(pot.y, -pot.x) * 180 / math.pi }
        })
    end
end

local function Contents(theme, shape)
    local layout = {}
    if theme == "treasury" or theme == "sow" then
        Add(layout, "pig_ruins_idol", 2, 2)
        Add(layout, "pig_ruins_head", -2, 2)
        Add(layout, "pig_ruins_torch", -2, -2)
        AddCache(layout, theme == "sow" and "pig_ruins_sow" or "pig_ruins_truffle")
        AddPots(layout, -1.5)
    elseif theme == "clock" then
        Add(layout, "aporkalypse_clock", 0, 0)
        Add(layout, "deco_ruins_beam", -2, -2)
        Add(layout, "deco_ruins_beam", 2, -2)
        Add(layout, "deco_ruins_beam", -2, 2)
        Add(layout, "deco_ruins_beam", 2, 2)
        Add(layout, "pig_ruins_pig", 0, -2, { trggerdarttraps = true })
        Add(layout, "pig_ruins_plaque", 0, 2)
    elseif theme == "blackwell" then
        Add(layout, "deco_ruins_endswell", 0, 1.5)
        Add(layout, "pig_ruins_light_beam", 0, 1.5, { localtrap = true, ta_cave_beam = true })
        Add(layout, "deco_ruins_beam", -2, 0)
        Add(layout, "deco_ruins_beam", 2, 0)
        AddPots(layout, -1.5)
    elseif theme == "store" then
        Add(layout, "shelves_ruins", -1.5, 1.5)
        Add(layout, "shelves_ruins", 0, 1.5)
        Add(layout, "shelves_ruins", 1.5, 1.5)
        Add(layout, "scorpion", -1.0, -1.5)
        Add(layout, "scorpion", 0, -1.5)
        Add(layout, "scorpion", 1.0, -1.5)
        Add(layout, "smashingpot", -2, -0.5)
        Add(layout, "smashingpot", 2, -0.5)
        AddPots(layout, -1.5)
        if shape == "one" then AddCache(layout, "pig_ruins_idol") end
    elseif theme == "overgrown" or theme == "vine" then
        Add(layout, "pig_ruins_light_beam", 0, 0, { localtrap = true, ta_cave_beam = true })
        Add(layout, "snake_amphibious", -1.5, -1.5)
        Add(layout, "snake_amphibious", 1.5, 1.5)
        Add(layout, "snake_amphibious", 0, 1.25)
        Add(layout, "cave_fern", -2, -2)
        Add(layout, "cave_fern", 2, 2)
        Add(layout, "deco_ruins_beam_broken", 1.5, 1.5)
        Add(layout, "smashingpot", -1.5, -1.5)
        Add(layout, "smashingpot", 1.5, 1.5)
    elseif theme == "spear" then
        Add(layout, "pig_ruins_plaque", -2.25, 0)
        Add(layout, "pig_ruins_head", 2.25, 0)
        Add(layout, "pig_ruins_torch", -0.5, -2.25)
        Add(layout, "pig_ruins_torch", 0.5, 2.25)
        -- Measured cross gauntlet of 9 autonomous periodic timing spear traps:
        Add(layout, "ta_ruins_spear_trap", 0, 0, { periodic = true, initial_delay = 0.0, up_time = 1.2, down_time = 3.6 })
        for idx, offset in ipairs({ -1.5, -0.75, 0.75, 1.5 }) do
            local delay_x = 0.6 * idx
            local delay_y = 0.6 * idx + 0.3
            Add(layout, "ta_ruins_spear_trap", offset, 0,
                { periodic = true, initial_delay = delay_x, up_time = 1.2, down_time = 3.6 })
            Add(layout, "ta_ruins_spear_trap", 0, offset,
                { periodic = true, initial_delay = delay_y, up_time = 1.2, down_time = 3.6 })
        end
    elseif theme == "dart" then
        Add(layout, "deco_ruins_beam", -1.25, -1.25)
        Add(layout, "deco_ruins_beam", 1.25, -1.25)
        Add(layout, "deco_ruins_beam", -1.25, 1.25)
        Add(layout, "deco_ruins_beam", 1.25, 1.25)
        Add(layout, "pig_ruins_torch", -2.25, -2.25)
        Add(layout, "pig_ruins_plaque", 1.5, -1.5)
        AddPots(layout, -1.5)
    elseif theme == "bat" then
        Add(layout, "snake_amphibious", -1.5, 0)
        Add(layout, "snake_amphibious", 1.5, 0)
        Add(layout, "snake_amphibious", 0, 1.25)
        Add(layout, "deco_ruins_beam_broken", -1.5, -1.5)
        Add(layout, "deco_ruins_beam_broken", 1.5, 1.5)
        Add(layout, "cave_fern", -1.5, 1.5)
        Add(layout, "cave_fern", 1.5, -1.5)
        Add(layout, "smashingpot", -1.5, 0)
        Add(layout, "smashingpot", 1.5, 0)
        AddPots(layout, -1.5)
    elseif theme == "ghost" then
        Add(layout, "pigghost", 0, 0)
        Add(layout, "pigghost", -1.25, 0.75)
        Add(layout, "pigghost", 1.25, 0.75)
        Add(layout, "shelves_ruins", -1.5, 1.5)
        Add(layout, "shelves_ruins", 1.5, 1.5)
        Add(layout, "pig_ruins_torch", -1.5, -1.5)
        Add(layout, "pig_ruins_torch", 1.5, -1.5)
        Add(layout, "pig_ruins_plaque", 0, -1.5)
    elseif theme == "statue" then
        Add(layout, "pig_ruins_pig", 0, 1.5, { trggerdarttraps = true })
        Add(layout, "pig_ruins_ant", -1.5, 1.5, { trggerdarttraps = true })
        Add(layout, "pig_ruins_head", 1.5, 1.5, { trggerdarttraps = true })
        Add(layout, "pig_ruins_torch", -2, 1.5)
        Add(layout, "pig_ruins_torch", 2, 1.5)
        AddPots(layout, -1.5)
    elseif theme == "barricade" then
        Add(layout, "deco_ruins_beam_broken", -1.5, -1.5)
        Add(layout, "deco_ruins_beam_broken", 1.5, 1.5)
        Add(layout, "deco_ruins_beam", -1.5, 1.5)
        Add(layout, "deco_ruins_beam", 1.5, -1.5)
        Add(layout, "scorpion", -1.0, 0)
        Add(layout, "scorpion", 1.0, 0)
        Add(layout, "scorpion", 0, -1.0)
        Add(layout, "smashingpot", -1.5, 0)
        Add(layout, "smashingpot", 1.5, 0)
    elseif theme == "blue" then
        Add(layout, "pig_ruins_artichoke", 0, 1.5, { trggerdarttraps = true })
        Add(layout, "pig_ruins_plaque", 0, 2.25)
        Add(layout, "pig_ruins_torch", -1, 1.75)
        Add(layout, "pig_ruins_torch", 1, 1.75)
        Add(layout, "deco_ruins_beam_blue", -2, -1.5)
        Add(layout, "deco_ruins_beam_blue", 2, -1.5)
        Add(layout, "deco_ruins_beam_blue", -2, 1.5)
        Add(layout, "deco_ruins_beam_blue", 2, 1.5)
        Add(layout, "deco_ruins_beam_broken_blue", -1.5, 0)
        Add(layout, "deco_ruins_beam_broken_blue", 1.5, 0)
        AddPots(layout, -1.5)
    else
        Add(layout, "pig_ruins_idol", -2, 2)
        Add(layout, "pig_ruins_plaque", 2, 2)
        AddPots(layout, -1.5)
    end
    GuardTreasures(layout, theme)
    AddDoorways(layout, theme, shape)
    return layout
end

local function Ground(shape, theme)
    local ground = {}
    for y = 1, 8 do
        ground[y] = {}
        for x = 1, 8 do
            local inside = x > 1 and x < 8 and y > 1 and y < 8
            local ns = x == 4 or x == 5
            local ew = y == 4 or y == 5
            local north = y == 1 and ns
            local south = y == 8 and ns and (shape == "long" or shape == "three" or shape == "four")
            local east = x == 8 and ew and (shape == "two" or shape == "three" or shape == "four")
            local west = x == 1 and ew and shape == "four"
            if inside and theme == "spear" then
                inside = ns or ew
            elseif inside and (theme == "overgrown" or theme == "vine") then
                inside = ns or ew or (x <= 3 and y <= 3) or (x >= 6 and y >= 6)
            elseif inside and theme == "barricade" then
                inside = x > 2 and x < 7 and y > 2 and y < 7 or ns or ew
            elseif inside and theme == "store" then
                inside = not ((x == 2 or x == 7) and (y == 2 or y == 7))
            elseif inside and theme == "dart" then
                inside = not ((x == 2 or x == 7) and (y == 2 or y == 7) and not (x == 2 and y == 2))
            end
            if x > 1 and x < 8 and y > 1 and y < 8 then
                -- Wider stone thresholds connect each interior footprint to its exits.
                inside = inside or (x >= 3 and x <= 6 and (y <= 3 or
                        (y >= 6 and (shape == "long" or shape == "three" or shape == "four"))))
                    or (y >= 3 and y <= 6 and ((x >= 6 and (shape == "two" or shape == "three" or shape == "four"))
                        or (x <= 3 and shape == "four")))
            end
            ground[y][x] = (inside or north or south or east or west) and 2 or 1
        end
    end
    return ground
end

function M.BuildLayouts(theme, special, ground_tile)
    local layouts = {}
    for exit, config in pairs(EXITS) do
        if not special or config[1] == "one" then
            layouts[exit] = {
                type = LAYOUT.STATIC,
                scale = 1,
                ground_types = { WORLD_TILES.IMPASSABLE, ground_tile or WORLD_TILES.PIGRUINS },
                ground = Ground(config[1], theme),
                layout = Contents(theme, config[1]),
                force_rotation = LAYOUT_ROTATION[config[2]],
                start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
                fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
            }
        end
    end
    return layouts
end

function M.BuildSetpiece(theme)
    local layout = {}
    Add(layout, "deco_ruins_beam_broken", -1, 1)
    Add(layout, "pig_ruins_head", 1, 1)
    Add(layout, "pig_ruins_plaque", -1, -1)
    Add(layout, "smashingpot", 1, -1)
    Add(layout, "smashingpot", 0, -1)
    if theme == "whitewell" then
        layout.pig_ruins_head = nil
        Add(layout, "deco_ruins_fountain", 0, 0)
        layout.smashingpot = nil
        AddPots(layout, -1.5)
        Add(layout, "pig_ruins_torch", -2, 0)
        Add(layout, "pig_ruins_torch", 2, 0)
        Add(layout, "ancient_herald_spawner", 0, 2)
    elseif theme == "pheromone" then
        Add(layout, "ta_ruins_pheromone_chest", 0, 1.5)
        layout.ta_ruins_pheromone_chest[1].properties = { scenario = "ta_ruins_pheromone" }
        Add(layout, "ta_ruins_spear_trap", 0, -2.25, { periodic = true, initial_delay = 0.5 })
        Add(layout, "antcombhomecave", 2, 1.5)
        Add(layout, "pig_ruins_ant", -2, 1.5)
    end
    GuardTreasures(layout, theme)
    return { type = LAYOUT.STATIC, scale = 1, layout = layout }
end

function M.Register()
    local layouts = require("map/maze_layouts").AllLayouts
    local themes = { "spear", "dart", "store", "overgrown", "barricade", "vine", "bat", "ghost", "statue", "blue" }
    for _, theme in ipairs(themes) do
        layouts["ta_hamlet_ruins_" .. theme] = M.BuildLayouts(theme)
        layouts["ta_hamlet_clock_" .. theme] = M.BuildLayouts(theme, nil, WORLD_TILES.PIGRUINS_BLUE)
    end
    layouts.ta_hamlet_ruins_blackwell = M.BuildLayouts("blackwell", true)
    layouts.ta_hamlet_ruins_treasury = M.BuildLayouts("treasury", true)
    -- Upgrade the existing clock temple without adding another clock.
    layouts.hamlet_hallway = M.BuildLayouts("spear", nil, WORLD_TILES.PIGRUINS_BLUE)
    layouts.hamlet_hallway_two = M.BuildLayouts("dart", nil, WORLD_TILES.PIGRUINS_BLUE)
    layouts.hamlet_start = M.BuildLayouts("sow", true, WORLD_TILES.PIGRUINS_BLUE)
    layouts.hamlet_end = M.BuildLayouts("clock", true, WORLD_TILES.PIGRUINS_BLUE)
    layouts.hamlet_keyroom = M.BuildLayouts("store", true, WORLD_TILES.PIGRUINS_BLUE)
    local setpieces = require("map/layouts").Layouts
    setpieces.TaHamRuinsDebris = M.BuildSetpiece()
    setpieces.TaHamRuinsWhiteWell = M.BuildSetpiece("whitewell")
    setpieces.TaHamRuinsPheromone = M.BuildSetpiece("pheromone")
end

return M
