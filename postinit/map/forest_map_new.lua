require("constants")
require("mathutil")

local ta_worldgen = TA_CONFIG.WORLDGEN
local multi = math.sqrt(ta_worldgen.world_size_multi) or 1
local forest_map = require("map/forest_map")
local SpawnRules = require("tools/worldgen_spawnrules")
local active_generation

local old_generatemap = forest_map.Generate
local SKIP_GEN_CHECKS = Upvaluehelper.GetUpvalue(old_generatemap, "SKIP_GEN_CHECKS")
if SKIP_GEN_CHECKS ~= nil and TA_CONFIG.DEVELOP.test_map then
    print("Skipping generation checks for test map")
    Upvaluehelper.SetUpvalue(old_generatemap, true, "SKIP_GEN_CHECKS")
end

-- World sizing and coastline hooks.


if GLOBAL.rawget(GLOBAL, "WorldSim") then
    local worldsim = GLOBAL.getmetatable(GLOBAL.WorldSim).__index
    -- Each native sizing API consumes its own unscaled input once per attempt.

    do
        local OldSetWorldSize = worldsim.SetWorldSize
        worldsim.SetWorldSize = function(self, width, height)
            if active_generation ~= nil then
                if not active_generation.world_size_scaled then
                    active_generation.world_size_scaled = true
                    width, height = math.ceil(multi * width), math.ceil(multi * height)
                end
            end
            return OldSetWorldSize(self, width, height)
        end

        local OldConvertToTileMap = worldsim.ConvertToTileMap
        worldsim.ConvertToTileMap = function(self, length)
            if active_generation ~= nil then
                if not active_generation.tile_map_scaled then
                    active_generation.tile_map_scaled = true
                    length = math.ceil(multi * length)
                end
            end
            return OldConvertToTileMap(self, length)
        end
    end

    -- Coastline separation override.
    if ta_worldgen.coastline then
        worldsim.SeparateIslands = function(self) print("Skipping island separation") end
    end
end

forest_map.Generate = function(prefab, map_width, map_height, tasks, level, level_type, ...)
    local previous_generation = active_generation
    active_generation = {}
    local previous_location = SpawnRules.SetLocation(prefab)
    local ok, save = pcall(old_generatemap, prefab, map_width, map_height, tasks, level, level_type, ...)
    SpawnRules.SetLocation(previous_location)
    active_generation = previous_generation
    if not ok then error(save, 0) end
    if save == nil then return save end
    require("map/ruins_connections").Finalize(save.ents)

    --------------------building porkland cities---------------------------------------------------------------------
    if tableutil.has_all_of_component(level.tasks, { "Edge_of_civilization", "Pigtopia", "Other_edge_of_civilization", "Other_pigtopia" }) then
        local make_cities = require("map/city_builder")
        print("Building porkland cities!")
        local cities, reason = make_cities(save.ents, TOPOLOGY_SAVE, WorldSim, save.map.width, save.map.height,
            deepcopy(level.overrides))
        if cities == nil then
            print("[Tropical Adventures] Retrying map: " .. tostring(reason))
            return nil
        end
        local join_islands = not level.overrides.no_joining_islands
        save.map.tiles, save.map.tiledata, save.map.nav, save.map.adj, save.map.nodeidtilemap =
            WorldSim:GetEncodedMap(join_islands) ----这是存储地形数据的关键
    end

    ----mapwidth,height在其中发生过改变
    -----------------------------------------------------------------------------------------------------------------
    if save.ents then
        for i, v in pairs(require("datadefs/translated_prefabs").translated_prefabs) do
            if save.ents[i] ~= nil then
                save.ents[v] = tableutil.insert_components(save.ents[v], save.ents[i])
                save.ents[i] = nil
            end
        end
    end
    return save
end
