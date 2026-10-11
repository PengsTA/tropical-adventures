-------------add tags



local forest_rooms = {
    [1] = "BG_rainforest_base",
    [2] = "BG_deeprainforest_base"
}

local plains_rooms = {
    [1] = "BG_plains_base"
}

local rock_rooms = {
    [1] = "BG_painted_base"
}

local field_rooms = {
    [1] = "BG_cultivated_base", -----这个没有应用啊
    [2] = "cultivated_base_1",
    [3] = "cultivated_base_2"
}

if TUNING.ham_start then
    for i, room in ipairs(forest_rooms) do
        AddRoomPreInit(room, function(room)
            table.insert(room.tags, "Terrarium_Spawner")
            table.insert(room.tags, "StatueHarp_HedgeSpawner")
        end)
    end

    for i, room in ipairs(plains_rooms) do
        AddRoomPreInit(room, function(room)
            table.insert(room.tags, "CharlieStage_Spawner")
        end)
    end

    for i, room in ipairs(rock_rooms) do
        AddRoomPreInit(room, function(room)
            table.insert(room.tags, "Junkyard_Spawner")
        end)
    end

    for i, room in ipairs(field_rooms) do
        AddRoomPreInit(room, function(room)
            table.insert(room.tags, "Balatro_Spawner")
            table.insert(room.tags, "StagehandGarden")
        end)
    end
end







AddTask("Pincale", {
    locks = { LOCKS.ROCKS },
    -- keys_given = { KEYS.TRINKETS, KEYS.STONE, KEYS.WOOD, KEYS.TIER1 },
    -- locks = {},
    -- keys_given = {},
    -- region_id = "mainland",
    room_choices = {
        ["BG_pinacle_base_set"] = 1,
        ["BG_pinacle_base"] = 1,
    },
    room_bg = GROUND.ROCKY,
    background_room = "BG_pinacle_base",
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})


------------------------------------------------------------------------HAMLET continental tasks----------------------------------------------------------------------	
AddTask("Plains_start", {
    locks = LOCKS.NONE,
    keys_given = { KEYS.JUNGLE_DEPTH_1 },
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["BG_plains_base"] = 1,
        ["Hamlet start"] = 1,
        ["plains_pogs_ruin"] = 1,
    },
    room_bg = GROUND.PLAINS,
    background_room = "BG_plains_base",
    crosslink_factor = 1,

    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Plains", {
    locks = { LOCKS.JUNGLE_DEPTH_1 },
    keys_given = { KEYS.JUNGLE_DEPTH_1 },
    level_set_piece_blocker = true,
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    -- room_tags = { "RoadPoison", "moonhunt", "nohunt", "nohasslers", "lunacyarea", "not_mainland" },
    room_choices = {
        ["BG_plains_base"] = 1,
        ["Lilypond"] = math.random(2, 3),
        -- ["Ham start"] = 1,
        -- ["plains_tallgrass"] = math.random(2, 3),
        ["plains_pogs_ruin"] = 2, -----这个和"plains_pogs"完全一致
    },
    room_bg = GROUND.PLAINS,
    background_room = "BG_plains_base",
    -- cove_room_name = "rainforest_ruins",
    -- make_loop = true,
    crosslink_factor = 6, --大概是跨过空room的连接数 交联级数？穿过某个node的次数？
    -- cove_room_chance = 1,  --加边界房间把中心房间围起来 但是coveroom的个数不能多于room个数
    -- cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Plains_ruins", {
    locks = { LOCKS.JUNGLE_DEPTH_1 },
    keys_given = { KEYS.JUNGLE_DEPTH_2, },
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["plains_ruins"] = 1,
        ["plains_ruins_set"] = 1,
        ["plains_pogs"] = 1,
    },
    room_bg = GROUND.PLAINS,
    background_room = "BG_plains_base",
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Rainforest_ruins", {
    locks = { LOCKS.JUNGLE_DEPTH_1 },
    keys_given = { KEYS.JUNGLE_DEPTH_2, },
    level_set_piece_blocker = true,
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "rainforest", "tropical", "nohunt", "nohasslers", "not_mainland" },
    -- room_tags = { "RoadPoison", "moonhunt", "nohunt", "nohasslers", "lunacyarea", "not_mainland" },
    room_choices = {
        ["rainforest_ruins"] = 2,
        ["rainforest_ruins_entrance"] = 1,
        ["Lilypond"] = 2,
    },
    room_bg = GROUND.RAINFOREST,
    background_room = "BG_rainforest_base",
    -- cove_room_name = "rainforest_ruins",
    -- make_loop = true,
    crosslink_factor = 3, --大概是跨过空room的连接数 交联级数？穿过某个node的次数？
    -- cove_room_chance = 1,  --加边界房间把中心房间围起来 但是coveroom的个数不能多于room个数
    -- cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})


---------------------	
AddTask("Painted_sands", {
    -- locks = { LOCKS.PAINTED },
    -- keys_given = {  },
    locks = { LOCKS.JUNGLE_DEPTH_2 },
    keys_given = { KEYS.JUNGLE_DEPTH_2, },
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["BG_battleground_base"] = 1,
        ["battleground_ribs"] = 1,
        ["battleground_claw"] = 1,
        ["battleground_leg"] = 1,
        ["battleground_claw1"] = 1,
        ["battleground_leg1"] = 1,
        ["battleground_head"] = 1,
        ["BG_painted_base"] = 4,
    },
    room_bg = GROUND.PLAINS,
    background_room = "BG_painted_base",
    crosslink_factor = 3,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})
-----------------------------------------

-------------------------
-- AddTask("Edge_of_civilization", {
--     -- locks = { LOCKS.EDGE },
--     -- keys_given = { KEYS.CITY_1,  },
--     locks = { LOCKS.JUNGLE_DEPTH_1 },
--     keys_given = { KEYS.CITY_1 },
--     region_id = "hamlet",
--     room_tags = { "RoadPoison","hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
--     room_choices = {
--         ["cultivated_base_1"] = 1,
--         ["cultivated_base_2"] = 1,
--         --			["cultivated_base_3"] = 1,
--         ["cultivated_base_4"] = 1,
--         ["cultivated_base_5"] = 1,
--         ["piko_land"] = 1,
--     },
--     room_bg = GROUND.FIELDS,
--     background_room = "BG_cultivated_base",
--     crosslink_factor = 3,
--     colour = { r = 1, g = 1, b = 1, a = 0.3 }
-- })

-- AddTask("Pigcity", {
--     locks = { LOCKS.CITY_1 },
--     keys_given = {},
--     region_id = "hamlet",
--     room_tags = { "RoadPoison", "RoadPoison","hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
--     room_choices = {
--         ["city_base_1_set"] = 1,
--         ["city_base"] = 2,
--     },
--     room_bg = GROUND.SUBURB,
--     -- entrance_room = "city_base",
--     background_room = "BG_suburb_base",
--     cove_room_name = "city_base",
--     make_loop = true,
--     crosslink_factor = 10, --大概是跨过空room的连接数 交联级数？穿过某个node的次数？
--     cove_room_chance = 1,  --加边界房间把中心房间围起来 但是coveroom的个数不能多于room个数
--     cove_room_max_edges = 10,
--     colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 }
-- })


AddTask("Edge_of_civilization", {
    locks = LOCKS.JUNGLE_DEPTH_2,
    keys_given = KEYS.CIVILIZATION_1,
    region_id = "hamlet",
    room_tags = { "City1", "civilized", "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["cultivated_base_1"] = math.random(3, 5),
        ["piko_land"] = math.random(2, 3),
    },
    room_bg = WORLD_TILES.FIELDS,
    background_room = "cultivated_base_1",
    cove_room_name = "cultivated_base_1",
    make_loop = true,
    crosslink_factor = 10,
    cove_room_chance = 1,
    cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})


AddTask("Pigtopia", {
    locks = LOCKS.CIVILIZATION_1,
    keys_given = KEYS.CIVILIZATION_2,
    level_set_piece_blocker = true,
    region_id = "hamlet",
    room_tags = { "City1", "civilized", "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["city_base_1"] = math.random(5, 7),
        -- ["suburb_base_1"] = math.random(2, 3),
    },
    room_bg = WORLD_TILES.SUBURB,
    background_room = "suburb_base_1",
    cove_room_name = "suburb_base_1",
    make_loop = true,
    crosslink_factor = 10,
    cove_room_chance = 1,
    cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Pigtopia_capital", {
    locks = LOCKS.CIVILIZATION_2,
    keys_given = KEYS.ISLAND_2,
    level_set_piece_blocker = true,
    region_id = "hamlet",
    room_tags = { "City1", "civilized", "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["city_base_1"] = math.random(3, 4),
    },
    room_bg = WORLD_TILES.SUBURB,
    background_room = "suburb_base_1",
    cove_room_name = "suburb_base_1",
    make_loop = true,
    crosslink_factor = 10,
    cove_room_chance = 1,
    cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})



AddTask("Ham_blank1", {
    locks = { LOCKS.HAM_BLANK },
    keys_given = { KEYS.CITY_2 },
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices =
    {
        ["ForceDisconnectedRoomHAM"] = 10,
    },
    entrance_room = "ForceDisconnectedRoomHAM",
    room_bg = GROUND.IMPASSABLE,
    background_room = "ForceDisconnectedRoomHAM",
    colour = { r = 0.6, g = 0.6, b = 0.0, a = 1 },
})

AddTask("Ham_blank2", {
    locks = { LOCKS.HAM_BLANK },
    keys_given = { KEYS.SNAKE },
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices =
    {
        ["ForceDisconnectedRoomHAM"] = 10,
    },
    entrance_room = "ForceDisconnectedRoomHAM",
    room_bg = GROUND.IMPASSABLE,
    background_room = "ForceDisconnectedRoomHAM",
    colour = { r = 0.6, g = 0.6, b = 0.0, a = 1 },
})


-- AddTask("Pigcity2", {
--     locks = { LOCKS.CITY_2 },
--     keys_given = { KEYS.DEEPRAINFOREST_CITY2 },
--     region_id = "hamlet_palace",
--     room_tags = { "RoadPoison", "RoadPoison","hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
--     room_choices = {
--         ["city_base_2_set"] = 1,
--         ["city_base"] = 2,
--     },
--     room_bg = GROUND.SUBURB,
--     entrance_room = "city_base",
--     background_room = "BG_suburb_base",
--     cove_room_name = "city_base",
--     make_loop = true,
--     crosslink_factor = 10, --大概是跨过空room的连接数 交联级数？穿过某个node的次数？
--     cove_room_chance = 1,  --加边界房间把中心房间围起来 但是coveroom的个数不能多于room个数
--     cove_room_max_edges = 10,
--     colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 }
-- })

AddTask("Other_edge_of_civilization", {
    locks = LOCKS.OTHER_JUNGLE_DEPTH_1,
    keys_given = KEYS.OTHER_CIVILIZATION_1,
    region_id = "hamlet_palace",
    room_tags = { "City2", "civilized", "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["cultivated_base_2"] = math.random(2, 3),
        ["piko_land"] = math.random(1, 2),
    },
    room_bg = WORLD_TILES.FIELDS,
    background_room = "cultivated_base_2",
    cove_room_name = "cultivated_base_2",
    make_loop = true,
    crosslink_factor = 10,
    cove_room_chance = 1,
    cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Other_pigtopia", {
    locks = LOCKS.OTHER_CIVILIZATION_1,
    keys_given = KEYS.OTHER_CIVILIZATION_2,
    level_set_piece_blocker = true,
    region_id = "hamlet_palace",
    room_tags = { "City2", "civilized", "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["city_base_2"] = math.random(5, 7),
        -- ["suburb_base_2"] = math.random(2, 3),
    },
    room_bg = WORLD_TILES.SUBURB,
    background_room = "suburb_base_2",
    cove_room_name = "suburb_base_2",
    make_loop = true,
    crosslink_factor = 10,
    cove_room_chance = 1,
    cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Other_pigtopia_capital", {
    locks = LOCKS.OTHER_CIVILIZATION_2,
    keys_given = KEYS.ISLAND_3,
    level_set_piece_blocker = true,
    region_id = "hamlet_palace",
    room_tags = { "City2", "civilized", "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["city_base_2"] = math.random(3, 4),
    },
    room_bg = WORLD_TILES.SUBURB,
    background_room = "suburb_base_2",
    cove_room_name = "suburb_base_2",
    make_loop = true,
    crosslink_factor = 10,
    cove_room_chance = 1,
    cove_room_max_edges = 10,
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})


AddTask("Edge_of_the_unknown", {
    -- locks = {},
    -- keys_given = { KEYS.JUNGLE_DEPTH_2 },
    locks = { LOCKS.SNAKE },
    keys_given = { KEYS.LOST_JUNGLE, KEYS.DEEPRAINFOREST_SNAKE },
    level_set_piece_blocker = true,
    region_id = "hamlet_snake",
    room_tags = { "RoadPoison", "hamlet", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["BG_plains_base"] = 2,
        ["BG_plains_base_nocanopy1"] = 1,
        ["Lilypond"] = math.random(2, 3),
    },
    room_bg = GROUND.PLAINS,
    background_room = "BG_plains_base",
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})

AddTask("Deep_lost_ruins_gas", {
    -- locks = { LOCKS.DEEPRAINFOREST },
    -- keys_given = {},
    locks = { LOCKS.LOST_JUNGLE },
    keys_given = {},
    region_id = "hamlet_snake",
    room_tags = { "RoadPoison", "hamlet", "rainforest", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["deeprainforest_gas"] = math.random(2, 3),
        ["deeprainforest_gas_flytrap_grove"] = math.random(2),
        -- ["deeprainforest_gas_entrance6"] = 1,
    },
    room_bg = GROUND.GASRAINFOREST,
    background_room = "deeprainforest_gas",
    crosslink_factor = 3,
    colour = { r = 0.8, g = 0.6, b = 0.2, a = 0.3 }
})



AddTask("Deep_rainforest", {
    -- locks = { LOCKS.DEEPRAINFOREST },
    -- keys_given = {  },
    locks = { LOCKS.JUNGLE_DEPTH_1 },
    keys_given = {},
    region_id = "hamlet",
    room_tags = { "RoadPoison", "hamlet", "rainforest", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["BG_rainforest_base"] = math.random(2, 3),
        ["BG_deeprainforest_base"] = 1,
        ["deeprainforest_spider_monkey_nest"] = 1,
        ["deeprainforest_fireflygrove"] = math.random(1, 1),
        ["deeprainforest_flytrap_grove"] = math.random(1, 2),
        -- ["deeprainforest_anthill_exit2"] = 1,
    },
    room_bg = GROUND.DEEPRAINFOREST,
    background_room = "BG_deeprainforest_base",
    crosslink_factor = 3,
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 }
})

AddTask("Deep_rainforest_2", {
    -- locks = { LOCKS.DEEPRAINFOREST },
    -- keys_given = {  },
    locks = { LOCKS.DEEPRAINFOREST_CITY2 },
    region_id = "hamlet_palace",
    room_tags = { "RoadPoison", "hamlet", "rainforest", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["BG_deeprainforest_base"] = 1,
        ["deeprainforest_spider_monkey_nest"] = 1,
        ["deeprainforest_fireflygrove"] = 1,
        ["deeprainforest_flytrap_grove"] = 1,
        -- ["deeprainforest_anthill_exit"] = 1,
        -- ["deeprainforest_ruins_entrance2"] = 1,
        ["deeprainforest_mandrakeman"] = 1, -----------------------
    },
    room_bg = GROUND.DEEPRAINFOREST,
    background_room = "BG_deeprainforest_base",
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 }
})

AddTask("Deep_rainforest_3", {
    -- locks = {},
    -- keys_given = { KEYS.CIVILIZATION_2 },
    locks = { LOCKS.DEEPRAINFOREST_SNAKE },
    -- keys_given = { KEYS.JUNGLE_DEPTH_1,  },
    region_id = "hamlet_snake",
    room_tags = { "RoadPoison", "hamlet", "rainforest", "tropical", "nohunt", "nohasslers", "not_mainland" },
    room_choices = {
        ["BG_deeprainforest_base"] = 2,
        ["deeprainforest_fireflygrove"] = 1,
        ["deeprainforest_flytrap_grove"] = 1,
        -- ["deeprainforest_ruins_exit"] = 1,
    },
    room_bg = GROUND.DEEPRAINFOREST,
    background_room = "BG_deeprainforest_base",
    crosslink_factor = 3,
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 }
})




--------------------------------------separahamcave--------------------------------------------------------
AddTask("separahamcave", {
    ----region_id = "hamlet",
    locks = { LOCKS.SACRED, },
    keys_given = KEYS.LAND_DIVIDE_5,
    room_choices = {
        ["ForceDisconnectedRoomHAM"] = 10,
    },
    entrance_room = "ForceDisconnectedRoomHAM",
    room_bg = GROUND.VOLCANO,
    background_room = "ForceDisconnectedRoomHAM",
    colour = { r = 1, g = 1, b = 1, a = 0.3 }
})


AddTask("HamMudWorld", {
    ----region_id = "hamlet",
    locks = { LOCKS.HAM_CAVE },
    keys_given = { KEYS.HAM_ANT }, -- KEYS.ISLAND1, KEYS.ISLAND2,
    -- region_id = "hamlet_cave",
    room_choices = {
        ["HamLightPlantField"] = 1,
        ["HamLightPlantFieldexit"] = 1, --exit1
        -- ["HamMudWithRabbitexit"] = 1,   --exit2
        ["HamWormPlantField"] = 1,
        ["HamFernGully"] = 1,
        ["HamSlurtlePlains"] = 1,
        ["HamMudWithRabbit"] = 1,
        ["PitRoom"] = 1,
    },
    entrance_room = "HamArchiveMazeEntrance",
    background_room = "HamBGMud",
    room_bg = GROUND.MUD,
    colour = { r = 0.6, g = 0.4, b = 0.0, a = 0.9 },
})

AddTask("HamMudCave", {
    ----region_id = "hamlet",
    locks = { LOCKS.HAM_CAVE2 },     --LOCKS.ISLAND1, LOCKS.ISLAND2
    keys_given = { KEYS.HAM_CAVE2 }, --KEYS.ISLAND1, KEYS.ISLAND3
    room_choices = {
        ["HamWormPlantField"] = 1,
        ["HamSlurtlePlains"] = 1,
        ["HamMudWithRabbit"] = 1,
        ["HamMudWithRabbitexit"] = 1, --exit2
        ["PitRoom"] = 1,
    },
    background_room = "HamBGBatCaveRoom",
    room_bg = GROUND.MUD,
    colour = { r = 0.7, g = 0.5, b = 0.0, a = 0.9 },
})

AddTask("HamMudLights", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND2 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND3 },
    room_choices = {
        ["HamLightPlantField"] = 3,
        ["HamWormPlantField"] = 1,
        ["PitRoom"] = 1,
    },
    background_room = "HamWormPlantField",
    room_bg = GROUND.MUD,
    colour = { r = 0.7, g = 0.5, b = 0.0, a = 0.9 },
})

AddTask("HamMudPit", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND2 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND3 },
    room_choices = {
        ["SlurtlePlains"] = 1,
        ["PitRoom"] = 2,
    },
    background_room = "HamFernGully",
    room_bg = GROUND.MUD,
    colour = { r = 0.6, g = 0.4, b = 0.0, a = 0.9 },
})

------------------------------------------------------------
-- Main Caves Branches
------------------------------------------------------------
-- Big Bat Cave
AddTask("HamBigBatCave", {
    ----region_id = "hamlet",
    locks = { LOCKS.HAM_CAVE2 },
    keys_given = { KEYS.HAM_MAZE },
    room_choices = {
        ["HamBatCave"] = 3,
        ["HamBattyCave"] = 1,
        ["HamFernyBatCave"] = 1,
        ["HamFernyBatCaveexit"] = 1,
        ["PitRoom"] = 2,
    },
    background_room = "HamBGBatCaveRoom",
    room_bg = GROUND.CAVE,
    colour = { r = 0.8, g = 0.8, b = 0.8, a = 0.9 },
})

-- Rocky Land
AddTask("HamRockyLand", {
    ----region_id = "hamlet",
    locks = { LOCKS.HAM_ANT },       --LOCKS.ISLAND1, LOCKS.ISLAND3
    keys_given = { KEYS.HAM_CAVE2 }, -- KEYS.ISLAND1, KEYS.ISLAND4, KEYS.ISLAND7
    room_choices = {
        ["HamSlurtleCanyon"] = 1,
        ["HamBatsAndSlurtles"] = 1,
        ["HamRockyPlains"] = 1,
        ["HamRockyPlainsexit"] = 1, ---sem saida
        ["HamRockyHatchingGrounds"] = 1,
        ["HamBatsAndRocky"] = 1,
        ["PitRoom"] = 1,
    },
    background_room = "HamBGRockyCaveRoom",
    room_bg = GROUND.CAVE,
    colour = { r = 0.5, g = 0.5, b = 0.5, a = 0.9 },
})

----------------------------------

-- Red Forest
AddTask("HamRedForest", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND3 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND4 },
    room_choices = {
        ["HamRedMushForest"] = 2,
        ["HamRedSpiderForest"] = 1,
        ["HamRedSpiderForestexit"] = 1, ---sem saida
        ["HamRedMushPillars"] = 1,
        ["HamStalagmiteForest"] = 1,
        ["HamSpillagmiteMeadow"] = 1,
        ["PitRoom"] = 1,
    },
    background_room = "HamBGRedMush",
    room_bg = GROUND.QUAGMIRE_PARKFIELD,
    colour = { r = 1.0, g = 0.5, b = 0.5, a = 0.9 },
})


---------------------------------------cave exit -------------------------------------------------
AddTask("caveruinsexit", {
    ----region_id = "hamlet",
    locks = { LOCKS.ENTRANCE_INNER },
    keys_given = {},
    room_choices = {
        ["caveruinexitroom"] = 1,
    },
    background_room = "BGSinkhole",
    room_bg = GROUND.SINKHOLE,
    colour = { r = 1, g = 0, b = 1, a = 1 },
})

AddTask("caveruinsexit2", {
    ----region_id = "hamlet",
    locks = { LOCKS.ENTRANCE_OUTER },
    keys_given = {},
    room_choices = {
        ["caveruinexitroom2"] = 1,
    },
    background_room = "BGSinkhole",
    room_bg = GROUND.SINKHOLE,
    colour = { r = 1, g = 0, b = 1, a = 1 },
})

-- Green Forest
AddTask("HamGreenForest", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND3 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND4 },
    room_choices = {
        ["HamGreenMushForest"] = 2,
        ["HamGreenMushPonds"] = 1,
        ["HamGreenMushSinkhole"] = 1,
        ["HamGreenMushMeadow"] = 1,
        ["HamGreenMushRabbits"] = 1,
        ["HamGreenMushNoise"] = 1,
        ["PitRoom"] = 1,
    },
    background_room = "HamBGGreenMush",
    room_bg = GROUND.QUAGMIRE_PARKFIELD,
    colour = { r = 0.5, g = 1.0, b = 0.5, a = 0.9 },
})

-- Blue Forest
AddTask("HamBlueForest", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND3 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND4, KEYS.ISLAND5 },
    room_choices = {
        ["HamBlueMushForest"] = 3,
        ["HamBlueMushMeadow"] = 2,
        ["HamBlueSpiderForest"] = 1,
        ["HamDropperDesolation"] = 1,
        ["PitRoom"] = 1,
    },
    background_room = "HamBGBlueMush",
    room_bg = GROUND.QUAGMIRE_PARKFIELD,
    colour = { r = 0.5, g = 0.5, b = 1.0, a = 0.9 },
})

--------------------ham pigmaze--------------------------

AddTask("HamMoonCaveForest", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND5 },
    keys_given = { KEYS.ISLAND6 },
    room_tags = { "nocavein" },
    room_choices = {
        ["HamCaveGraveyard"] = 1,
        ["HamCaveGraveyardentrance"] = 1,
    },
    background_room = "HamCaveGraveyard",
    room_bg = GROUND.FUNGUSMOON,
    colour = { r = 0.3, g = 0.3, b = 0.3, a = 0.9 },
})

AddTask("HamArchiveMaze", {
    locks = { LOCKS.HAM_MAZE },
    keys_given = {},
    required_prefabs = { "aporkalypse_clock", "pig_ruins_sow" },
    room_tags = { "nocavein" },
    entrance_room = "TaHamRuinsEntrance",
    room_choices =
    {
        ["TaHamRuinsMaze"] = 8,
    },
    room_bg = GROUND.FAKE_GROUND,
    maze_tiles = {
        rooms = {
            "hamlet_hallway",
            "hamlet_hallway_two",
            "ta_hamlet_clock_vine",
            "ta_hamlet_clock_bat",
            "ta_hamlet_clock_ghost",
            "ta_hamlet_clock_statue",
            "ta_hamlet_clock_store",
            "ta_hamlet_clock_overgrown",
            "ta_hamlet_clock_barricade",
        },
        bosses = { "hamlet_hallway", "hamlet_hallway_two" },
        special = { finish = { "hamlet_end" }, start = { "hamlet_start" } },
        bridge_ground = WORLD_TILES.PIGRUINS_BLUE
    },
    background_room = "TaHamRuinsMaze",
    cove_room_chance = 0,
    cove_room_max_edges = 0,
    make_loop = true,
    colour = { r = 1, g = 0, b = 0.0, a = 1 },
})


AddTask("HamSpillagmiteCaverns", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND3 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND4 },
    room_choices = {
        ["HamSpidersAndBats"] = 1,
        ["HamThuleciteDebris"] = 1,
        ["PitRoom"] = 1,
    },
    background_room = "HamBGSpillagmite",
    room_bg = GROUND.UNDERROCK,
    colour = { r = 0.3, g = 0.3, b = 0.3, a = 0.9 },
})

AddTask("HamSpillagmiteCaverns1", {
    ----region_id = "hamlet",
    locks = { LOCKS.ISLAND1, LOCKS.ISLAND3 },
    keys_given = { KEYS.ISLAND1, KEYS.ISLAND4 },
    room_choices = {
        ["HamSpillagmiteForest"] = 1,
        ["HamDropperCanyon"] = 1,
        ["HamStalagmitesAndLights"] = 1,
    },
    background_room = "HamSpillagmiteForest",
    room_bg = GROUND.FUNGUS,
    colour = { r = 0.3, g = 0.3, b = 0.3, a = 0.9 },
})
