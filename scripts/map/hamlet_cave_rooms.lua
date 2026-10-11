AddRoom("TaHamRuinsCollapsed", {
    colour = { r = .5, g = .4, b = .2, a = .8 }, value = WORLD_TILES.CAVE,
    contents = {
        countstaticlayouts = { TaHamRuinsDebris = 1 },
        distributepercent = .12,
        distributeprefabs = { stalagmite = .2, rocks = .3, flint = .1, cave_fern = .2, batcave = .02 },
    },
})

AddRoom("TaHamRuinsOvergrown", {
    colour = { r = .3, g = .5, b = .2, a = .8 }, value = WORLD_TILES.MUD,
    contents = {
        countstaticlayouts = { TaHamRuinsDebris = 1 },
        distributepercent = .15,
        distributeprefabs = { cave_fern = .6, mushtree_small = .1, flower_cave = .15, scorpion = .02 },
    },
})

AddRoom("TaHamRuinsEntrance", {
    colour = { r = .5, g = .4, b = .2, a = .8 }, value = WORLD_TILES.CAVE,
    tags = { "ForceConnected", "MazeEntrance", "RoadPoison" },
    contents = {
        countstaticlayouts = { TaHamRuinsDebris = 1 },
        distributepercent = .08,
        distributeprefabs = { cave_fern = .3, stalagmite = .1, flower_cave = .1 },
    },
})

AddRoom("TaHamRuinsWhiteWell", {
    colour = { r = .6, g = .5, b = .3, a = .8 }, value = WORLD_TILES.PIGRUINS,
    contents = {
        countstaticlayouts = { TaHamRuinsWhiteWell = 1 },
        distributepercent = .06, distributeprefabs = { cave_fern = .3, rocks = .1 },
    },
})

AddRoom("TaHamRuinsPheromone", {
    colour = { r = .4, g = .5, b = .2, a = .8 }, value = WORLD_TILES.PIGRUINS,
    contents = {
        countstaticlayouts = { TaHamRuinsPheromone = 1 },
        distributepercent = .06, distributeprefabs = { cave_fern = .3, stalagmite = .1 },
    },
})

AddRoom("TaHamRuinsMaze", {
    colour = { r = .5, g = .35, b = .15, a = .8 }, value = WORLD_TILES.FAKE_GROUND,
    tags = { "Maze", "RoadPoison", "ta_ruins_maze" },
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
})

AddTask("TaHamRuinsOutskirts", {
    locks = { LOCKS.HAM_CAVE2 }, keys_given = { KEYS.HAM_RUINS },
    room_choices = { TaHamRuinsCollapsed = 1, TaHamRuinsOvergrown = 1, TaHamRuinsWhiteWell = 1, TaHamRuinsPheromone = 1 },
    background_room = "TaHamRuinsCollapsed", room_bg = WORLD_TILES.CAVE,
    required_prefabs = { "deco_ruins_fountain", "ta_ruins_pheromone_chest", "ancient_herald_spawner" },
    colour = { r = .5, g = .4, b = .2, a = .8 },
})

AddTask("TaHamRuinsLabyrinth", {
    locks = { LOCKS.HAM_RUINS }, keys_given = {},
    room_tags = { "nocavein" }, entrance_room = "TaHamRuinsEntrance",
    room_choices = { TaHamRuinsMaze = 4 },
    background_room = "TaHamRuinsMaze", room_bg = WORLD_TILES.FAKE_GROUND,
    maze_tile_size = 8,
    required_prefabs = { "deco_ruins_endswell", "pig_ruins_truffle" },
    maze_tiles = {
        rooms = {
            "ta_hamlet_ruins_spear",
            "ta_hamlet_ruins_dart",
            "ta_hamlet_ruins_vine",
            "ta_hamlet_ruins_bat",
            "ta_hamlet_ruins_ghost",
            "ta_hamlet_ruins_statue",
            "ta_hamlet_ruins_store",
            "ta_hamlet_ruins_overgrown",
            "ta_hamlet_ruins_barricade",
            "ta_hamlet_ruins_blue",
        },
        bosses = { "ta_hamlet_ruins_spear", "ta_hamlet_ruins_dart" },
        special = { start = { "ta_hamlet_ruins_blackwell" }, finish = { "ta_hamlet_ruins_treasury" } },
        bridge_ground = WORLD_TILES.PIGRUINS,
    },
    cove_room_chance = 0, cove_room_max_edges = 0,
    colour = { r = .6, g = .4, b = .15, a = .9 },
})
