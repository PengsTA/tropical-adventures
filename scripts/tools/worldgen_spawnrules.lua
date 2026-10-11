-- Position rules for procedural world generation. Coordinates and buffers use tiles.
local M = {}
local rules = {}
local location

function M.SetLocation(value)
    local previous = location
    location = value
    return previous
end

function M.Register(prefab, rule)
    assert(type(prefab) == "string" and type(rule) == "table", "Expected a prefab and spawn rule")
    assert(rule.testfn == nil or type(rule.testfn) == "function", "testfn must be a function")
    assert(rule.shore_clearance == nil or (type(rule.shore_clearance) == "number"
        and rule.shore_clearance >= 0 and rule.shore_clearance < math.huge), "Invalid shore clearance")
    assert(rule.surface == nil or rule.surface == "land" or rule.surface == "water", "Invalid spawn surface")
    local saved = rules[prefab] or {}
    for key, value in pairs(rule) do saved[key] = value end
    rules[prefab] = saved
end

local function IsWetland(tile)
    return tile == WORLD_TILES.MANGROVE or tile == WORLD_TILES.LILYPOND
end

function M.Test(prefab, x, y, entities, room_tests)
    if prefab == nil or x == nil or y == nil then return false end
    local tile = WorldSim:GetTile(x, y)
    local water, land = IsOceanTile(tile), IsLandTile(tile)
    if not water and not land then return false end
    local rule = rules[prefab] or {}
    if rule.surface == "water" and not water or rule.surface == "land" and not land then return false end

    local wetland = IsWetland(tile)
    local clearance = rule.shore_clearance
    if clearance == nil then clearance = water and not wetland and 2 or 1 end
    -- Check every tile, including enclosed islands and inlets inside the buffer.
    local radius = math.ceil(clearance)
    for dy = -radius, radius do
        for dx = -radius, radius do
            local nearby = WorldSim:GetTile(x + dx, y + dy)
            if water then
                -- The ocean wrap corridor handles map edges; void is not a shoreline.
                if IsLandTile(nearby) or not wetland and IsWetland(nearby) then return false end
            elseif IsOceanTile(nearby) or location == "forest" and nearby == WORLD_TILES.IMPASSABLE then
                -- Forest void becomes ocean after node population; cave walls do not.
                return false
            end
        end
    end
    if rule.testfn ~= nil and not rule.testfn(x, y, entities) then return false end
    local room_test = room_tests and room_tests[prefab]
    return room_test == nil or not not room_test(x, y, entities)
end

require("datadefs/worldgen_spawnrules")(M)
return M
