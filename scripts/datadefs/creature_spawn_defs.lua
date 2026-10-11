local SCHOOL_AREA = { TINY = 1, SMALL = 3, MEDIUM = 6, LARGE = 10, }

local CREATURES   =
{
    hanging_vine_patch = {
        prefab = "hanging_vine_patch",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.LARGE,
    },

    lightrays_jungle = {
        prefab = "lightrays_jungle",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.TINY,
    },

    mean_flytrap = {
        prefab = "mean_flytrap",
        schoolmin = 2,
        schoolmax = 4,
        schoolrange = SCHOOL_AREA.SMALL,
    },

    adult_flytrap = {
        prefab = "adult_flytrap",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.SMALL,
    },

    zeb = {
        prefab = "zeb",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.MEDIUM,
    },

    jellyfish_planted = {
        prefab = "jellyfish_planted",
        schoolmin = 2,
        schoolmax = 5,
        schoolrange = SCHOOL_AREA.SMALL,
    },
    whirlpool = {
        prefab = "whirlpool",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.TINY,
    },

    solofish = {
        prefab = "solofish",
        schoolmin = 2,
        schoolmax = 3,
        schoolrange = SCHOOL_AREA.SMALL,
    },
    rainbowjellyfish_planted = {
        prefab = "rainbowjellyfish_planted",
        schoolmin = 2,
        schoolmax = 5,
        schoolrange = SCHOOL_AREA.SMALL,
    },
    ballphin = {
        prefab = "ballphin2",
        schoolmin = 1,
        schoolmax = 3,
        schoolrange = SCHOOL_AREA.SMALL,
    },

    stungray = {
        prefab = "stungray",
        schoolmin = 2,
        schoolmax = 6,
        schoolrange = SCHOOL_AREA.SMALL,
    },

    bioluminescence = {
        prefab = "bioluminescence",
        schoolmin = 2,
        schoolmax = 6,
        schoolrange = SCHOOL_AREA.SMALL,
    },

    swordfish = {
        prefab = "swordfish",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.TINY,
    },

    knightboat = {
        prefab = "knightboat",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.SMALL,
    },

    bishopwater = {
        prefab = "bishopwater",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.TINY,
    },

    rookwater = {
        prefab = "rookwater",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.TINY,
    },

    -- luggagechest_spawner = {
    --     prefab = "luggagechest_spawner",
    --     checkname = "luggagechest",
    --     schoolmin = 1,
    --     schoolmax = 1,
    --     schoolrange = SCHOOL_AREA.TINY,
    -- },

    -- crocodog_spawner = {
    --     prefab = "crocodog_spawner",
    --     schoolmin = 1,
    --     schoolmax = 3,
    --     schoolrange = SCHOOL_AREA.TINY,
    -- },

    sharx = {
        prefab = "sharx",
        schoolmin = 1,
        schoolmax = 3,
        schoolrange = SCHOOL_AREA.TINY,
    },

    oceanfog = {
        prefab = "oceanfog",
        schoolmin = 1,
        schoolmax = 1,
        schoolrange = SCHOOL_AREA.TINY,
    },


}

local TILES       =
{
    [GROUND.DEEPRAINFOREST] =
    {
        hanging_vine_patch = 1,
        mean_flytrap = 1,
        adult_flytrap = 0.5,
        lightrays_jungle = 1,
    },
    [GROUND.GASRAINFOREST] =
    {
        mean_flytrap = 1,
        adult_flytrap = 0.5,
        lightrays_jungle = 1,
    },
    [GROUND.PLAINS] =
    {
        zeb = 0.1,
    },
    [GROUND.OCEAN_COASTAL] =
    {
        jellyfish_planted = 1,
        solofish = 1,
        rainbowjellyfish_planted = 0.25,
        ballphin = 0.1,
    },

    [GROUND.OCEAN_SWELL] =
    {
        jellyfish_planted = 1,
        rainbowjellyfish_planted = 0.25,
        bioluminescence = 2,
        solofish = 4,
        stungray = 1,
        whirlpool = 0.2,
    },

    [GROUND.OCEAN_ROUGH] =
    {
        ballphin             = 2,
        swordfish            = 2,
        solofish             = 2,
        bioluminescence      = 3,
        oceanfog             = 1,
        luggagechest_spawner = 0.4,
        sharx                = 0.8,
        whirlpool            = 0.25,

    },

    [GROUND.OCEAN_HAZARDOUS] =
    {
        solofish    = 0.25,
        swordfish   = 0.5,
        rookwater   = 0.5,
        bishopwater = 0.5,
        knightboat  = 0.5,
        whirlpool   = 0.25,
    },

    [GROUND.OCEAN_WATERLOG] =
    {
        solofish = 0.5,
    },

    [GROUND.OCEAN_CORAL] =
    {
        bioluminescence = 1,
        oceanfog = 0.5,
        luggagechest_spawner = 0.25,
        ballphin = 0.25,
        jellyfish_planted = 1,
        rainbowjellyfish_planted = 1,
        solofish = 1,

    },

    [GROUND.OCEAN_SHIPGRAVEYARD] =
    {
        solofish    = 0.25,
        swordfish   = 0.5,
        rookwater   = 0.5,
        bishopwater = 0.5,
        knightboat  = 0.5,
        whirlpool   = 0.25,
    },

}


return { creatures = CREATURES, tiles = TILES }
