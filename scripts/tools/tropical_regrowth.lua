local Definitions = require("datadefs/tropical_regrowth")
local M = {}
local installed = false

function M.IsHabitat(map, x, y, z, definition)
    if map:GetPlatformAtPoint(x, z) ~= nil then
        return false
    end
    local tile = map:GetTileAtPoint(x, y, z)
    local allowed = false
    for _, name in ipairs(definition.tiles) do
        if WORLD_TILES[name] ~= nil and tile == WORLD_TILES[name] then
            allowed = true
            break
        end
    end
    if not allowed then
        return false
    end
    if definition.water then
        return map:IsOceanTileAtPoint(x, y, z) and map:IsSurroundedByWater(x, y, z, 2)
    end
    return map:CanPlantAtPoint(x, y, z)
end

function M.GetFiveRadius(x, z, definition)
    local map = TheWorld.Map
    if map == nil or not M.IsHabitat(map, x, 0, z, definition) then
        return nil
    end
    local topology = TheWorld.topology
    local node = map:GetNodeIdAtPoint(x, 0, z)
    local id = topology ~= nil and topology.ids ~= nil and topology.ids[node] or nil
    local generated = TheWorld.generated
    local densities = generated ~= nil and generated.densities ~= nil and generated.densities[id] or nil
    local density = densities ~= nil and densities[definition.name] or nil
    if density == nil and densities ~= nil then
        for _, alias in ipairs(definition.aliases) do
            if densities[alias] ~= nil then
                density = densities[alias]
                break
            end
        end
    end
    -- Static layouts and old saves may not contain procedural density records.
    density = density == nil and definition.density or density
    if type(density) ~= "number" or density ~= density or density <= 0 or density >= math.huge then
        return nil
    end
    -- Keep the native five-plant cap without tiny or map-wide search radii.
    return math.max(8, math.min(32, CalculateFiveRadius(density)))
end

function M.CanSpread(inst)
    if inst:HasTag("stump") or inst:HasTag("burnt") or inst:HasTag("INLIMBO") then
        return false
    end
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        return false
    end
    -- Habitat and density checks stay in the native spawn attempt, not each idle poll.
    return Definitions.spreading[inst.prefab] ~= nil
end

function M.Install()
    if installed then return end
    installed = true
    local PlantRegrowth = require("components/plantregrowth")
    local function TimeMultiplier()
        return TUNING.EVERGREEN_REGROWTH_TIME_MULT
    end
    for prefab in pairs(Definitions.spreading) do
        PlantRegrowth.TimeMultipliers[prefab] = TimeMultiplier
    end

    local OriginalFiveRadius = GetFiveRadius
    _G.GetFiveRadius = function(x, z, prefab)
        local definition = Definitions.spreading[prefab]
        if definition ~= nil then
            return M.GetFiveRadius(x, z, definition)
        end
        return OriginalFiveRadius(x, z, prefab)
    end

    local OriginalCanPlace = Map.CanPlacePrefabFilteredAtPoint
    Map.CanPlacePrefabFilteredAtPoint = function(map, x, y, z, prefab)
        local definition = Definitions.spreading[prefab]
        if definition ~= nil and not M.IsHabitat(map, x, y, z, definition) then
            return false
        end
        return OriginalCanPlace(map, x, y, z, prefab)
    end
end

return M
