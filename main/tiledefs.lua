-- 异名内容 SNAKESKINFLOOR  CHECKEREDLAWN
-- 新增内容 BATFLOOR ANTFLOOR

local NoiseFunctions = require("noisetilefunctions")
local GroundTiles = require("worldtiledefs")
local ChangeTileRenderOrder = ChangeTileRenderOrder
local AddTile = AddTile

local WORLD_TILES = WORLD_TILES
local GROUND = GROUND


local SHALLOW_SHORE_OCEAN_COLOR =
{
    primary_color = { 220, 240, 255, 60 },
    secondary_color = { 21, 96, 110, 140 },
    secondary_color_dusk = { 0, 0, 0, 50 },
    minimap_color = { 23, 51, 62, 102 },
}

local SHALLOW_OCEAN_COLOR =
{
    primary_color = { 0, 255, 255, 100 }, --{ 20, 255, 150, 255 },--255是全白   透明度调成0就是完全透明（基底颜色且没有纹理）
    secondary_color = { 25, 123, 167, 100 },
    secondary_color_dusk = { 10, 120, 125, 120 },
    minimap_color = { 23, 51, 62, 102 },
}

local MEDIUM_OCEAN_COLOR =
{
    primary_color = { 150, 255, 255, 18 },
    secondary_color = { 0, 45, 80, 220 },
    secondary_color_dusk = { 9, 52, 57, 150 },
    minimap_color = { 14, 34, 61, 204 },
}

local DEEP_OCEAN_COLOR =
{
    primary_color = { 10, 200, 220, 30 },
    secondary_color = { 1, 20, 45, 230 },
    secondary_color_dusk = { 5, 20, 25, 230 },
    minimap_color = { 19, 20, 40, 230 },
}

local SHIPGRAVEYARD_OCEAN_COLOR =
{
    primary_color = { 255, 255, 255, 25 },
    secondary_color = { 0, 8, 18, 51 },
    secondary_color_dusk = { 0, 0, 0, 150 },
    minimap_color = { 8, 8, 14, 51 },
}

local MANGROVE_OCEAN_COLOR =
{
    primary_color = { 5, 185, 220, 60 },
    secondary_color = { 5, 20, 45, 200 },
    secondary_color_dusk = { 5, 15, 20, 200 },
    minimap_color = { 40, 87, 93, 51 },
}

local CORAL_OCEAN_COLOR =
{
    primary_color = { 220, 255, 255, 28 },
    secondary_color = { 25, 123, 167, 100 },
    secondary_color_dusk = { 10, 120, 125, 120 },
    minimap_color = { 40, 87, 93, 51 },
}

local LILYPOND_SHORE_OCEAN_COLOR =
{
    primary_color = { 5, 185, 220, 60 },
    secondary_color = { 5, 20, 45, 200 },
    secondary_color_dusk = { 5, 15, 20, 200 },
    minimap_color = { 40, 87, 93, 51 },
}

local WAVETINTS =
{
    shallow = { 0.8, 0.9, 1 },
    rough = { 0.65, 0.84, 0.94 },
    swell = { 0.65, 0.84, 0.94 },
    brinepool = { 0.65, 0.92, 0.94 },
    hazardous = { 0.40, 0.50, 0.62 },
    waterlog = { 1, 1, 1 },
    lilypond = { 1, 1, 1 },
}

GLOBAL.setfenv(1, GLOBAL) --这个是让所有的全局变量挂在global上

local AddNewTile = function(tile, range, tile_data, ground_tile_def, minimap_tile_def, turf_def)
    if WORLD_TILES[tile] then
        return
    end

    AddTile(tile, range, tile_data, ground_tile_def, minimap_tile_def, turf_def)
end

local is_worldgen = rawget(_G, "WORLDGEN_MAIN") ~= nil

if not is_worldgen then
    TileGroups.TAOceanTiles = TileGroupManager:AddTileGroup()
end


local TileRanges =
{
    LAND = "LAND",
    SW_LAND = "SW_LAND",
    HAM_LAND = "HAM_LAND",
    NOISE = "NOISE",
    OCEAN = "OCEAN",
    TRO_OCEAN = "TRO_OCEAN",
    IMPASSABLE = "IMPASSABLE",
}


tro_tiledefs = {


    -------------------以下为水体地皮---------------------
    MANGROVE = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Mangrove",
            old_static_id = 106,
        },
        ground_tile_def  = {
            name = "sw/water_medium",
            noise_texture = "sw/water_mangrove",
            flashpoint_modifier = 250,
            ocean_depth = "SHALLOW",
            colors = MANGROVE_OCEAN_COLOR,
            is_shoreline = true,
            nogroundoverlays = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_mangrove",
        },
    },


    LILYPOND = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Lilypond",
            old_static_id = 107,
        },
        ground_tile_def  = {
            name = "sw/water_medium", ----- "water_medium"
            noise_texture = "ham/water_lilypond",
            flashpoint_modifier = 250,
            ocean_depth = "SHALLOW",
            colors = LILYPOND_SHORE_OCEAN_COLOR, ----有了这个就会有边缘的瀑布效果--而且不能改颜色？
            wavetint = WAVETINTS.waterlog,
            is_shoreline = true,
            nogroundoverlays = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_water_lilypond",
        },
    },

    OCEAN_CORAL = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Coral",
            old_static_id = 104,
        },
        ground_tile_def  = {
            name = "sw/water_medium",
            noise_texture = "sw/water_coral", --   "ground_water_coral",
            flashpoint_modifier = 250,
            ocean_depth = "SHALLOW",
            colors = CORAL_OCEAN_COLOR,
            is_shoreline = true,
            nogroundoverlays = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_coral",
        },
    },

    OCEAN_SHALLOW_SHORE = { --was called OCEAN_SHORE in sw, kept for ambientsound
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Shallow Shore",
            old_static_id = 101,
        },
        ground_tile_def  = {
            name = "sw/water_shallow",
            noise_texture = "sw/water_shallow",
            flashpoint_modifier = 250,
            is_shoreline = true,
            nogroundoverlays = true,
            ocean_depth = "SHALLOW",
            colors = SHALLOW_SHORE_OCEAN_COLOR,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_shallow",
        },
    },
    OCEAN_SHALLOW = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Shallow",
            old_static_id = 101,
        },
        ground_tile_def  = {
            name = "sw/water_shallow",
            noise_texture = "sw/water_shallow",
            flashpoint_modifier = 250,
            nogroundoverlays = true,
            ocean_depth = "SHALLOW",
            colors = SHALLOW_OCEAN_COLOR,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_shallow",
        },
    },


    OCEAN_MEDIUM = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Medium",
            old_static_id = 102,
        },
        ground_tile_def  = {
            name = "sw/water_medium",
            noise_texture = "sw/water_medium",
            flashpoint_modifier = 250,
            nogroundoverlays = true,
            ocean_depth = "DEEP",
            colors = MEDIUM_OCEAN_COLOR,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_medium",
        },
    },
    OCEAN_DEEP = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Deep",
            old_static_id = 103,
        },
        ground_tile_def  = {
            name = "sw/water_deep",
            noise_texture = "sw/water_deep",
            flashpoint_modifier = 250,
            nogroundoverlays = true,
            ocean_depth = "VERY_DEEP",
            colors = DEEP_OCEAN_COLOR,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_deep",
        },
    },
    OCEAN_SHIPGRAVEYARD = {
        tile_range       = TileRanges.TRO_OCEAN,
        tile_data        = {
            ground_name = "Ship Grave",
            old_static_id = 105,
        },
        ground_tile_def  = {
            name = "sw/water_deep",
            noise_texture = "sw/water_graveyard",
            flashpoint_modifier = 250,
            nogroundoverlays = true,
            ocean_depth = "BASIC",
            colors = SHIPGRAVEYARD_OCEAN_COLOR,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_water_graveyard",
        },
    },

    ---------------------以下为海难陆地地皮------------------------------
    BEACH = { ------------物品栏贴图不对
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Beach",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "sw/beach",
            noise_texture = "sw/ground_beach",
            runsound = "dontstarve/movement/run_sand",
            walksound = "dontstarve/movement/walk_sand",
            flashpoint_modifier = 0,
            cannotbedug = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_beach",
        },
        turf_def         = {
            name = "beach",
            bank_build = "turf_sw",
        }, --------------应该没有turf
    },

    JUNGLE = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Jungle",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "sw/jungle",
            noise_texture = "sw/ground_jungle",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            -- snowsound = "dontstarve/movement/run_ice",
            -- mudsound = "dontstarve/movement/run_mud",
            flashpoint_modifier = 0,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_jungle",
        },
        turf_def         = {
            name = "jungle",
            bank_build = "turf_sw",
        },
    },

    SWAMP = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Swamp",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "sw/swamp",
            noise_texture = "sw/ground_swamp",
            runsound = "dontstarve/movement/run_marsh",
            walksound = "dontstarve/movement/walk_marsh",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_swamp",
        },
        turf_def         = {
            name = "swamp",
        },
    },

    MAGMAFIELD = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Magmafield",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "cave",
            noise_texture = "sw/ground_magmafield",
            runsound = "dontstarve/movement/run_rock",
            walksound = "dontstarve/movement/walk_rock",
            -- runsound = "dontstarve/movement/run_slate",
            -- walksound = "dontstarve/movement/walk_slate",
            snowsound = "dontstarve/movement/run_ice",
            flashpoint_modifier = 0,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_magmafield",
        },
        turf_def         = {
            name = "magmafield",
            bank_build = "turf_sw",
        },
    },

    TIDALMARSH = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Tidal Marsh",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "sw/tidalmarsh",
            noise_texture = "sw/ground_tidalmarsh",
            runsound = "dontstarve/movement/run_marsh",
            walksound = "dontstarve/movement/walk_marsh",
            flashpoint_modifier = 0,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_tidalmarsh",
        },
        turf_def         = {
            name = "tidalmarsh",
            bank_build = "turf_sw",
        },
    },

    MEADOW = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Meadow",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "sw/jungle",
            noise_texture = "sw/ground_meadow",
            runsound = "dontstarve/movement/run_tallgrass",
            walksound = "dontstarve/movement/walk_tallgrass",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_meadow",
        },
        turf_def         = {
            name = "meadow",
            bank_build = "turf_sw",
        },
    },

    VOLCANO = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Lava Rock",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "cave",
            noise_texture = "sw/ground_volcano",
            runsound = "dontstarve/movement/run_rock",
            walksound = "dontstarve/movement/walk_rock",
            snowsound = "dontstarve/movement/run_ice",
            flashpoint_modifier = 0,
            hard = true,
            cannotbedug = false, ----不能挖
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_volcano",
        },
        turf_def         = {
            name = "volcano",
            bank_build = "turf_sw",
        },
    },


    ASH = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Ash",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "cave",
            noise_texture = "sw/ground_ash",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "dontstarve/movement/run_ice",
            flashpoint_modifier = 0,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_ash",
        },
        turf_def         = {
            name = "ash",
            bank_build = "turf_sw",
        },
    },

    VOLCANO_ROCK = { -------------有地皮动画但是没贴图
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Volcano Rock",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "rocky",
            noise_texture = "sw/ground_volcano_rock",
            runsound = "dontstarve/movement/run_rock",
            walksound = "dontstarve/movement/walk_rock",
            flashpoint_modifier = 0,
            hard = true, ----不可种植
            cannotbedug = true,

        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_volcano_rock",
        },

        turf_def         = {
            name = "volcano_rock",
            bank_build = "turf_sw",
        },
    },



    SNAKESKINFLOOR = {
        tile_range       = TileRanges.SW_LAND,
        tile_data        = {
            ground_name = "Snakeskin Carpet",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "carpet",
            noise_texture = "sw/ground_snakeskinfloor",
            runsound = "dontstarve/movement/run_carpet",
            walksound = "dontstarve/movement/walk_carpet",
            flashpoint_modifier = 0,
            flooring = true,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "sw/mini_ground_snakeskinfloor",
        },
        turf_def         = {
            name = "snakeskinfloor",
            bank_build = "turf_sw",
        },
    },

    -------------------------------
    -- IMPASSABLE
    -- (render order doesnt matter)
    -------------------------------

    -- VOLCANO_LAVA = {
    --     tile_range = TileRanges.IMPASSABLE,
    --     tile_data = {
    --         ground_name = "Lava",
    --     },
    --     minimap_tile_def = {
    --         name = "map_edge",
    --         noise_texture = "sw/mini_lava_noise",
    --     },
    -- },

    -------------------------------
    -- NOISE
    -- (only for worldgen)
    -------------------------------

    VOLCANO_NOISE = {
        tile_range = function(noise)
            if noise < 0.5 then
                return WORLD_TILES.VOLCANO
            end
            return WORLD_TILES.VOLCANO_ROCK
        end,
    },

    BATTLEGROUND_RAINFOREST_NOISE = {
        tile_range = function(noise)
            if noise < 0.5 then
                return WORLD_TILES.DIRT
            end
            return WORLD_TILES.RAINFOREST
        end,
    },


    --------------------------以下为哈姆陆地地皮---------------------
    PLAINS = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Plains",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/jungle",
            noise_texture = "ham/ground_plains",
            runsound = "dontstarve/movement/run_tallgrass",
            walksound = "dontstarve/movement/walk_tallgrass",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_plains",
        },
        turf_def = {
            name = "plains",
            bank_build = "turf_ham",
        },
    },


    DEEPRAINFOREST = {
        tile_range       = TileRanges.HAM_LAND,
        tile_data        = {
            ground_name = "Jungle Deep",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "ham/jungle_deep",
            noise_texture = "ham/ground_deeprainforest",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
            flashpoint_modifier = 0,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_deeprainforest",
        },
        turf_def         = {
            name = "deeprainforest",
            bank_build = "turf_ham",
        },
    },

    DEEPRAINFOREST_NOCANOPY = {
        tile_range       = TileRanges.HAM_LAND,
        tile_data        = {
            ground_name = "Jungle Deep Nocanopy",
            old_static_id = 33,
        },
        ground_tile_def  = {
            name = "ham/jungle_deep",
            noise_texture = "ham/ground_deeprainforest_nocanopy",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
            flashpoint_modifier = 0,
            cannotbedug = true, ----不能挖
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_deeprainforest_nocanopy",
        },
        -- turf_def         = {
        --     name = "deeprainforest_nocanopy",
        --     anim = "deeprainforest",
        --     bank_build = "turf_ham",
        -- },
    },

    RAINFOREST = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Rain Forest",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/rain_forest",
            noise_texture = "ham/ground_rainforest",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
            flashpoint_modifier = 0,

        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_rainforest",
        },
        turf_def = {
            name = "rainforest",
            bank_build = "turf_ham",
        },
    },

    PAINTED = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Painted",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/swamp",
            noise_texture = "ham/ground_painted",
            runsound = "dontstarve/movement/run_sand",
            walksound = "dontstarve/movement/walk_sand",
            mudsound = "run_sand"
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_painted",
        },
        turf_def = {
            name = "painted",
            bank_build = "turf_ham",
        },
    },

    BATTLEGROUND = { --------BATTLEGROUND
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Battleground",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/jungle_deep",
            noise_texture = "ham/ground_battlegrounds",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_battlegrounds"
        },
        turf_def = {
            name = "battleground",
            anim = "battlegrounds",
            bank_build = "turf_ham",
        },
    },

    PIGRUINS = { ------------古代废墟地皮
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Pigruins",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/blocky",
            noise_texture = "ham/ground_pigruins",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_pigruins"
        },
        turf_def = {
            name = "pigruins",
            bank_build = "turf_ham",
        },
    },

    PIGRUINS_BLUE = { ------------蓝色古代废墟地皮
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Pigruins Blue",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/blocky",
            noise_texture = "ham/ground_pigruins_blue",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            cannotbedug = true
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_pigruins"
        },
        turf_def = {
            name = "pigruins_blue",
            anim = "pigruins",
            bank_build = "turf_ham",
        },
    },

    GASRAINFOREST = { ------------毒瘴雨林地皮
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Gas Jungle",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/jungle_deep",
            noise_texture = "ham/ground_gasrainforest",
            runsound = "dontstarve/movement/run_moss",
            walksound = "dontstarve/movement/walk_moss",
            --cannotbedug = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_gasrainforest",
        },
        turf_def = {
            name = "gasrainforest",
            anim = "gasrainforest",
            bank_build = "turf_ham",
        },
    },


    FIELDS = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "fields",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/jungle",
            noise_texture = "ham/ground_fields",
            runsound = "dontstarve/movement/run_woods",
            walksound = "dontstarve/movement/walk_woods",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_fields",
        },
        turf_def = {
            name = "fields",
            bank_build = "turf_ham",
        },
    },

    CHECKEREDLAWN = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Lawn",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/pebble",
            noise_texture = "ham/ground_lawn",
            runsound = "dontstarve/movement/run_grass",
            walksound = "dontstarve/movement/walk_grass",
            -- runsound = "run_grass",
            -- walksound = "walk_grass",
            flashpoint_modifier = 0,
            flooring = true,
            hard = false,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_lawn",
        },

        turf_def = {
            name = "checkeredlawn",
            anim = "lawn",
            bank_build = "turf_ham",
        },
    },



    SUBURB = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Suburb",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/deciduous",
            noise_texture = "ham/ground_moss",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_moss",
        },
        turf_def = {
            name = "suburb",
            anim = "moss",
            bank_build = "turf_ham",
        },
    },

    FOUNDATION = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Foundation",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/blocky",
            noise_texture = "ham/ground_foundation",
            runsound = "dontstarve/movement/run_marble",
            walksound = "dontstarve/movement/walk_marble",
            snowsound = "run_ice",
            flashpoint_modifier = 0,
            flooring = true,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_foundation",
        },
        turf_def = {
            name = "foundation",
            bank_build = "turf_ham",
        },
    },


    COBBLEROAD = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Cobbleroad",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "ham/stoneroad",
            noise_texture = "ham/ground_cobbleroad",
            runsound = "dontstarve/movement/run_marble",
            walksound = "dontstarve/movement/walk_marble",
            snowsound = "run_ice",
            flashpoint_modifier = 0,
            flooring = true,
            hard = true,
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_cobbleroad",
        },
        turf_def = {
            name = "cobbleroad",
            bank_build = "turf_ham",
        },
    },


    ANTFLOOR = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Antcave",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "cave",
            noise_texture = "ham/ground_antcave",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            -- cannotbedug = true
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_antcave"
        },
        turf_def = {
            name = "antfloor",
            anim = "antcave",
            bank_build = "turf_ham",
        },
    },

    BATFLOOR = {
        tile_range = TileRanges.HAM_LAND,
        tile_data = {
            ground_name = "Batcave",
            old_static_id = 33,
        },
        ground_tile_def = {
            name = "cave",
            noise_texture = "ham/ground_batcave",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "run_ice",
            cannotbedug = true
        },
        minimap_tile_def = {
            name = "map_edge",
            noise_texture = "ham/mini_ground_batcave"
        },
        turf_def = {
            name = "batfloor",
            anim = "batcave",
            bank_build = "turf_ham",
        },
    },

}


TRO_OCEAN_TILES = {}
SW_LAND_TILES = {}
HAM_LAND_TILES = {}
TRO_LAND_TILES = {}

for tile, def in pairs(tro_tiledefs) do
    local range = def.tile_range
    if range == TileRanges.TRO_OCEAN then
        range = TileRanges.OCEAN
    elseif range == TileRanges.SW_LAND or range == TileRanges.HAM_LAND then
        range = TileRanges.LAND
    elseif type(range) == "function" then
        range = TileRanges.NOISE
    end

    -- if def.ground_tile_def and type(def.ground_tile_def) == "table" then
    --     def.ground_tile_def.-- colors = def.ground_tile_def.colors or DEFAULT_OCEAN_COLOR
    -- end


    AddNewTile(tile, range, def.tile_data, def.ground_tile_def, def.minimap_tile_def, def.turf_def)

    local tile_id = WORLD_TILES[tile]
    if def.tile_range == TileRanges.TRO_OCEAN then
        if not is_worldgen then
            -- TileGroupManager:AddInvalidTile(TileGroups.TransparentOceanTiles, tile_id)
            -- -- TileGroupManager:AddValidTile(TileGroups.OceanTiles, tile_id)
            -- TileGroupManager:AddValidTile(TileGroups.TAOceanTiles, tile_id)
        end
        TRO_OCEAN_TILES[tile_id] = true
    elseif def.tile_range == TileRanges.OCEAN then
        if not is_worldgen then
            -- TileGroupManager:AddInvalidTile(TileGroups.TransparentOceanTiles, tile_id)
            -- TileGroupManager:AddValidTile(TileGroups.Legacy_OceanTiles, tile_id)
            -- TileGroupManager:AddValidTile(TileGroups.TAOceanTiles, tile_id)
        end
        TRO_OCEAN_TILES[tile_id] = true
    elseif def.tile_range == TileRanges.SW_LAND then
        SW_LAND_TILES[tile_id] = true
        TRO_LAND_TILES[tile_id] = true
    elseif def.tile_range == TileRanges.HAM_LAND then
        HAM_LAND_TILES[tile_id] = true
        TRO_LAND_TILES[tile_id] = true
    elseif type(def.tile_range) == "function" then
        NoiseFunctions[tile_id] = def.tile_range
    end
end



-- ID 1 is for impassable
-- in ds, tile priority after the desert tile
ChangeTileRenderOrder(WORLD_TILES.MEADOW, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.TIDALMARSH, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.MAGMAFIELD, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.JUNGLE, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.ASH, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.VOLCANO, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.VOLCANO_ROCK, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.BEACH, WORLD_TILES.DESERT_DIRT, true)

ChangeTileRenderOrder(WORLD_TILES.GASRAINFOREST, WORLD_TILES.MUD, true) --GASJUNGLE
ChangeTileRenderOrder(WORLD_TILES.DEEPRAINFOREST, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.RAINFOREST, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.PLAINS, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.SUBURB, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.FIELDS, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.PAINTED, WORLD_TILES.MUD, true)
ChangeTileRenderOrder(WORLD_TILES.PIGRUINS, WORLD_TILES.DESERT_DIRT, true)
ChangeTileRenderOrder(WORLD_TILES.PIGRUINS_BLUE, WORLD_TILES.DESERT_DIRT, true)

-- --Priority turf
ChangeTileRenderOrder(WORLD_TILES.SNAKESKINFLOOR, WORLD_TILES.CARPET, false)
-- ChangeTileRenderOrder(WORLD_TILES.BEARDRUG, WORLD_TILES.CARPET, false)

ChangeTileRenderOrder(WORLD_TILES.COBBLEROAD, WORLD_TILES.WOODFLOOR, true)
ChangeTileRenderOrder(WORLD_TILES.CHECKEREDLAWN, WORLD_TILES.WOODFLOOR, true)
ChangeTileRenderOrder(WORLD_TILES.FOUNDATION, WORLD_TILES.WOODFLOOR, true)

-----ocean turf -------如果是联机海水就不能设置高优先级
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_SHALLOW, WORLD_TILES.OCEAN_COASTAL, false)
-- ChangeTileRenderOrder(WORLD_TILES.LILYPOND, WORLD_TILES.OCEAN_COASTAL, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_CORAL, WORLD_TILES.OCEAN_COASTAL, false)
-- ChangeTileRenderOrder(WORLD_TILES.MANGROVE, WORLD_TILES.OCEAN_COASTAL, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_COASTAL, WORLD_TILES.OCEAN_COASTAL, false)---这种海洋地皮不可能在陆地地皮上面

ChangeTileRenderOrder(WORLD_TILES.LILYPOND, WORLD_TILES.OCEAN_COASTAL, false)
ChangeTileRenderOrder(WORLD_TILES.OCEAN_CORAL, WORLD_TILES.OCEAN_COASTAL, false)
ChangeTileRenderOrder(WORLD_TILES.MANGROVE, WORLD_TILES.OCEAN_COASTAL, false)
-- -- ChangeTileRenderOrder(WORLD_TILES.OCEAN_COASTAL, WORLD_TILES.CARPET2, true)---这种海洋地皮不可能在陆地地皮上面
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_SHALLOW, WORLD_TILES.MONKEY_DOCK, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_SHALLOW_SHORE, WORLD_TILES.MONKEY_DOCK, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_MEDIUM, WORLD_TILES.MONKEY_DOCK, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_DEEP, WORLD_TILES.MONKEY_DOCK, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_CORAL, WORLD_TILES.MONKEY_DOCK, false)
-- ChangeTileRenderOrder(WORLD_TILES.OCEAN_SHIPGRAVEYARD, WORLD_TILES.MONKEY_DOCK, false)




for tile, def in pairs(tro_tiledefs) do
    if GROUND[tile] == nil then
        GROUND[tile] = WORLD_TILES[tile]
    end
end
