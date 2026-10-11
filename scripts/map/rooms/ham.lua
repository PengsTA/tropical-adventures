local GROUND = GROUND
local RegisterRoom = AddRoom
local function AddRoom(name, room)
    local contents = room.contents or {}
    if (contents.distributeprefabs and contents.distributeprefabs.tree_pillar ~= nil)
        or (contents.countprefabs and contents.countprefabs.tree_pillar ~= nil) then
        room.tags = room.tags or {}
        table.insert(room.tags, "deeprainforest")
    end
    RegisterRoom(name, room)
end



AddRoom("ForceDisconnectedRoomHAM", {
    colour = { r = .45, g = .75, b = .45, a = .50 },
    type = "blank",
    tags = { "ForceDisconnected" },
    value = WORLD_TILES.IMPASSABLE,
    contents = {},
})

AddRoom("Hamlet start", {
    colour = { r = .5, g = 0.6, b = .080, a = .10 },
    value = GROUND.PLAINS,
    tags = { "tropical", "hamlet" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            dungpile = 0.03,
            peagawk = 0.01,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countstaticlayouts = {
            ["start_ham"] = 1,
        },

    }
})


AddRoom("Rockyham", {
    colour = { r = .55, g = .75, b = .75, a = .50 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        countprefabs =
        {
            meteorspawner = 1,
            rock_moon = 1,
            burntground_faded = 1,
        },
        distributepercent = .1,
        distributeprefabs =
        {
            rock1 = 2,
            rock2 = 2,
            rock_ice = 1,
            --					                    tallbirdnest=.1,
            spiderden = .01,
            blue_mushroom = .002,
            grass_tall = 0.3,
        },
    }
})



-------------------------------pinacle----------------------------------
AddRoom("BG_pinacle_base_set", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.ROCKY,
    -- tags = { "tropical","hamlet" },
    contents = {
        countstaticlayouts = {
            ["roc_nest"] = 1,
            -- ["roc_cave"] = 1,
        },
        distributepercent = .15, --.26
        distributeprefabs =
        {
            rock1 = 0.1,
            flint = 0.1,
            roc_nest_tree1 = 0.1,
            roc_nest_tree2 = 0.1,
            roc_nest_branch1 = 0.5,
            roc_nest_branch2 = 0.5,
            roc_nest_bush = 1,
            rocks = 0.5,
            twigs = 1,
            rock2 = 0.1,
            tallbirdnest = 0.2,
        },
        countprefabs =
        {
            flint = 2,
            twigs = 2,
            pig_scepter = 1,
            tumbleweedspawner = 2,
        },
    }
})

AddRoom("BG_pinacle_base", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.ROCKY,
    -- tags = { "tropical","hamlet" },
    contents = {
        distributepercent = .15, --.26
        distributeprefabs =
        {
            rock1 = 0.1,
            flint = 0.1,
            roc_nest_tree1 = 0.1,
            roc_nest_tree2 = 0.1,
            roc_nest_branch1 = 0.5,
            roc_nest_branch2 = 0.5,
            roc_nest_bush = 1,
            rocks = 0.5,
            twigs = 1,
            rock2 = 0.1,
            tallbirdnest = 0.2,

        },
        countprefabs =
        {
            flint = 2,
            twigs = 2,
        },
    }
})


---------------------------------------------------------------city --------------------------------------



local cityContents = {
    distributepercent = 0.1,
    distributeprefabs = {
        rocks = 1,
        grass_ham = 1,
        spoiled_food = 1,
        twigs = 1,
    },
}

AddRoom("BG_city_base", {
    colour = { r = .1, g = 0.1, b = 0.1, a = 0.3 },
    value = WORLD_TILES.SUBURB,
    tags = { "City_Foundation" },
    contents = cityContents
})

AddRoom("city_base_1", {
    colour = { r = .1, g = 0.1, b = 0.1, a = 0.3 },
    value = WORLD_TILES.SUBURB,
    tags = { "City_Foundation" },
    contents = cityContents
})


AddRoom("city_base_2", {
    colour = { r = .1, g = 0.1, b = 0.1, a = 0.3 },
    value = WORLD_TILES.SUBURB,
    tags = { "City_Foundation" },
    contents = cityContents
})


local suburb_contents = {
    distributepercent = 0.1,
    distributeprefabs = {
        rocks = 1,
        grass_ham = 1,
        spoiled_food = 1,
        twigs = 1,
    },
}


AddRoom("BG_suburb_base", {
    colour = { r = .3, g = 0.3, b = 0.3, a = 0.3 },
    value = WORLD_TILES.SUBURB,
    tags = { "City_Foundation", "Suburb" },
    contents = suburb_contents
})

AddRoom("suburb_base_1", {
    colour = { r = .3, g = 0.3, b = 0.3, a = 0.3 },
    value = WORLD_TILES.SUBURB,
    tags = { "City_Foundation", "Suburb" },
    contents = suburb_contents
})

AddRoom("suburb_base_2", {
    colour = { r = .3, g = 0.3, b = 0.3, a = 0.3 },
    value = WORLD_TILES.SUBURB,
    tags = { "City_Foundation", "Suburb" },
    contents = suburb_contents
})

---------------------------------------------------------------cultivated--------------------------------------
local cultivated_contnets = {
    distributepercent = 0.06, -- 0.1
    distributeprefabs = {
        rock1 = 0.01,
        teatree = 0.1,
        chicken = 0.02,
        chickenhouse = 0.002,
    },
}

AddRoom("BG_cultivated_base", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = WORLD_TILES.FIELDS,
    tags = { "Cultivated" },
    contents = cultivated_contnets
})

AddRoom("cultivated_base_1", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = WORLD_TILES.FIELDS,
    tags = { "Cultivated" },
    contents = cultivated_contnets
})

AddRoom("cultivated_base_2", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = WORLD_TILES.FIELDS,
    tags = { "Cultivated" },
    contents = cultivated_contnets
})

AddRoom("piko_land", {
    colour = { r = 1.0, g = 0.0, b = 1.0, a = 0.3 },
    value = WORLD_TILES.FIELDS,
    tags = { "Cultivated" },
    contents = {
        distributepercent = 0.06, -- 0.1
        distributeprefabs = {
            rock1 = 0.01,
            chicken = 0.5,
            chickenhouse = 0.02,
            teatree = 2.0,
        },
        countprefabs = {
            teatree_piko_nest_patch = 1
        },
    }
})


----------------------------------------------------------- painted room--------------------------------------------------------------------------------------------------
----------------------------------------------------------- battlegrounds room--------------------------------------------------------------------------------------------------
AddRoom("BG_battleground_base", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            vampirebatcave_potential = 1,
        },
    }
})

AddRoom("battleground_ribs", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            ancient_robot_ribs = 1,
            vampirebatcave_potential = 1,
            -- maze_cave_roc_entrance = 1,
        },
    }
})
AddRoom("battleground_claw", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            ancient_robot_claw = 1,
            vampirebatcave_potential = 1,
        },
    }
})

AddRoom("battleground_claw1", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            ancient_robot_claw = 1,
            vampirebatcave_potential = 1,
        },
    }
})

AddRoom("battleground_leg", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            ancient_robot_leg = 1,
            vampirebatcave_potential = 1,
        },
    }
})

AddRoom("battleground_leg1", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            ancient_robot_leg = 1,
            vampirebatcave_potential = 1,
        },
    }
})
AddRoom("battleground_head", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.BATTLEGROUND_RAINFOREST_NOISE,
    tags = {},
    contents = {
        --					countstaticlayouts={["CaveEntrance"]=1},
        distributepercent = .22, -- .22, --.26
        distributeprefabs =
        {
            rainforesttree = 0.1,
            flower = 0.7,
            meteor_impact = 0.5,
            charcoal = 0.5,
            rainforesttree_burnt = 1,

            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            ancient_robot_head = 1,
            vampirebatcave_potential = 1,
        },
    }
})

AddRoom("BG_painted_base", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PAINTED,
    tags = {},
    contents = {
        distributepercent = .15, --.26
        distributeprefabs =
        {
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.2,
            thunderbirdnest = 0.1,
            sedimentpuddle = 0.1,
            pangolden = 0.005,
        },
        countprefabs =
        {
            pangolden = 1,
            vampirebatcave_potential = 1,
        },
    }
})
-------------------------------------------room deep florest hamlet-------------------------------------------
AddRoom("deeprainforest_gas", {
    colour = { r = 1, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.GASRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.45, --.45
        distributeprefabs =
        {
            rainforesttree_rot = 4,
            tree_pillar = 0.5,
            nettle = 0.12,
            red_mushroom = 0.3,
            green_mushroom = 0.3,
            blue_mushroom = 0.3,
            --	berrybush = 1,
            --										lightrays_jungle = 1.2,
            poisonmist = 8,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
        },
    }
})

AddRoom("deeprainforest_gas_entrance6", {
    colour = { r = 1, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.GASRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.45, --.45
        distributeprefabs =
        {
            rainforesttree_rot = 4,
            tree_pillar = 0.5,
            nettle = 0.12,
            red_mushroom = 0.3,
            green_mushroom = 0.3,
            blue_mushroom = 0.3,
            --	berrybush = 1,
            --										lightrays_jungle = 1.2,
            poisonmist = 8,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
        },
        countprefabs =
        {
            maze_pig_ruins_entrance6 = 1,
        },
    }
})

AddRoom("deeprainforest_gas_flytrap_grove", {
    colour = { r = 1, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.GASRAINFOREST,
    tags = {},
    contents = {
        countstaticlayouts = {
            ["pig_ruins_head"] = 1,
            ["pig_ruins_artichoke"] = 1,
        },
        distributepercent = 0.5, --.45
        distributeprefabs =
        {
            rainforesttree_rot = 2,
            tree_pillar = 0.5,
            nettle = 0.12,
            red_mushroom = 0.3,
            green_mushroom = 0.3,
            blue_mushroom = 0.3,
            --	berrybush = 1,
            --										lightrays_jungle = 1.2,
            --mistarea = 6,	
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
        },
        countprefabs =
        {
            --					                	mean_flytrap = math.random(10, 15),
            --					                	adult_flytrap = math.random(3, 7),
        },
    }
})

AddRoom("BG_rainforest_base", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.RAINFOREST,
    tags = {},
    contents = {
        distributepercent = .38, --.5
        distributeprefabs =
        {
            rainforesttree = 0.6, --1.4,
            grass_tall = .5,
            sapling_ham = .6,
            flower_rainforest = 0.1,
            flower = 0.05,
            dungpile = 0.03,
            fireflies = 0.05,
            peagawk = 0.01,
            --	randomrelic = 0.008,
            --	randomruin = 0.005,	
            --										randomdust = 0.005,										
            rock_flippable = 0.08,
            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            foliage = 1,
        },
    }
})


AddRoom("rainforest_ruins", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.RAINFOREST,
    tags = {},
    contents = {
        distributepercent = .35, -- .5
        distributeprefabs =
        {
            rainforesttree = .5, --.7,
            grass_tall = 0.5,
            sapling_ham = .6,
            flower_rainforest = 0.1,
            flower = 0.05,
            --	randomrelic = 0.008,
            --	randomruin = 0.005,	
            randomdust = 0.005,
            rock_flippable = 0.08,
            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            vampirebatcave_potential = 1,
            peekhenspawner = 2,
        },
    }
})

AddRoom("rainforest_ruins_entrance", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.RAINFOREST,
    tags = {},
    contents = {
        distributepercent = .35, -- .5
        distributeprefabs =
        {
            rainforesttree = .5, --.7,
            grass_tall = 0.5,
            sapling_ham = .6,
            flower_rainforest = 0.1,
            flower = 0.05,
            --	randomrelic = 0.008,
            --	randomruin = 0.005,	
            randomdust = 0.005,
            rock_flippable = 0.08,
            radish_planted = 0.05,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            peekhenspawner = 2,
        },
    }
})

AddRoom("BG_deeprainforest_base", {
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.5,
        distributeprefabs =
        {
            rainforesttree = 2, --4,
            tree_pillar = 0.5,  --0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            --										hanging_vine_patch = 0.1,	
            pig_ruins_torch = 0.02,
            --										mean_flytrap = 0.05,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },

        countprefabs =
        {
            vampirebatcave_potential = 1,
        },

    }
})

AddRoom("deeprainforest_spider_monkey_nest", {
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 3, --4,
            tree_pillar = 1,    --0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {
            spider_monkey_tree = 1,
            spider_monkey = 1,
            --					                	hanging_vine_patch = 1,
        },
    }
})

AddRoom("deeprainforest_flytrap_grove", {
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        countstaticlayouts = {
            ["nettlegrove"] = function()
                if math.random(1, 10) > 7 then return 1 end
                return 0
            end,
        },
        distributepercent = 0.25,
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1, --0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            randomrelic = 0.02,
            randomruin = 0.02,
            randomdust = 0.02,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {
            --					                	mean_flytrap = math.random(10, 15),
            --					                	adult_flytrap = math.random(3, 7),
            --					                	hanging_vine_patch = math.random(0,2),
        },
    }
})

AddRoom("deeprainforest_flytrap_grove_PigRuinsEntrance5", {
    colour = { r = 0.2, g = 0.6, b = 0.2, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1, --0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {
            --					                	mean_flytrap = math.random(6, 11),
            --					                	adult_flytrap = math.random(2, 6),
            --					                	hanging_vine_patch = math.random(0,2)
        },
    }
})

AddRoom("deeprainforest_fireflygrove", {
    colour = { r = 1, g = 1, b = 0.2, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1, --0.5,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 5,
            --										hanging_vine_patch = 0.1,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {
            fireflies = math.random(5, 10),
        },
    }
})

AddRoom("deeprainforest_ruins_entrance", {
    colour = { r = 1, g = 0.1, b = 0.2, a = 0.5 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {

        },

    }
})

AddRoom("deeprainforest_ruins_entrance2", {
    colour = { r = 1, g = 0.1, b = 0.2, a = 0.5 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {
        },

    }
})

AddRoom("deeprainforest_ruins_exit", {
    colour = { r = 0.2, g = 0.1, b = 1, a = 0.5 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {

        },

    }
})

AddRoom("deeprainforest_ruins_exit2", {
    colour = { r = 0.2, g = 0.1, b = 1, a = 0.5 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        countstaticlayouts = { ["nettlegrove"] = 1 },
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },
        countprefabs =
        {
            -- 	pig_ruins_torch = 3,
            -- 	pig_ruins_exit = 1,
            -- 	pig_ruins_head = 1,					                	
        },

    }
})

AddRoom("deeprainforest_anthill", {
    colour = { r = 1, g = 0, b = 1, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },

        countprefabs =
        {
            anthill = 1,
            --					                	pighead = 4,
        },

    }
})
AddRoom("deeprainforest_mandrakeman", {
    colour = { r = 1, g = 0, b = 1, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        countstaticlayouts = { ["mandraketown"] = 1 },
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },

        countprefabs =
        {
            mandrakehouse = 2
        },

    }
})
AddRoom("deeprainforest_anthill_exit", {
    colour = { r = 1, g = 0, b = 1, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        countstaticlayouts = {
            -- ["pig_ruins_entrance_5"] = GetModConfigData("pigruins")

        },
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },

    }
})

AddRoom("deeprainforest_anthill_exit2", {
    colour = { r = 1, g = 0, b = 1, a = 0.3 },
    value = GROUND.DEEPRAINFOREST,
    tags = {},
    contents = {
        distributepercent = 0.25, --.3
        distributeprefabs =
        {
            rainforesttree = 4,
            tree_pillar = 1,
            nettle = 0.12,
            flower_rainforest = 1,
            --										lightrays_jungle = 1.2,								
            deep_jungle_fern_noise = 1,
            jungle_border_vine = 0.5,
            fireflies = 0.2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
            radish_planted = 0.5,
        },

        countprefabs =
        {
            -- maze_anthillentradarainha = GetModConfigData("anthill"),
            -- underwater_entrance2 = 1,
        },

    }
})

----------------------------------------------------------- plain room--------------------------------------------------------------------------------------------------
AddRoom("BG_plains_inicio", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .25, --.22, --.26
        distributeprefabs =
        {
            clawpalmtree = .25,
            grass_tall = 1,
            flower = 0.05,
            pog = 0.1,
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            asparagus_planted = 0.05,
        },
    }
})

AddRoom("BG_plains_base", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .25, --.22, --.26
        distributeprefabs =
        {
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            dungpile = 0.03,
            peagawk = 0.01,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("BG_plains_base_nocanopy", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        countstaticlayouts = {
            ["pig_ruins_nocanopy"] = 1,
            ["pig_ruins_nocanopy_2"] = 1,
        },
        distributepercent = .25, --.22, --.26
        distributeprefabs =
        {
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            dungpile = 0.03,
            peagawk = 0.01,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("BG_plains_base_nocanopy1", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        countstaticlayouts = {
            ["pugalisk_fountain"] = 1,
        },
        distributepercent = .25, --.22, --.26
        distributeprefabs =
        {
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            dungpile = 0.03,
            peagawk = 0.01,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
            --[[vampirebatcave_entrance_roc = 1,]]
            gravestone = 5,
        },
    }
})

AddRoom("BG_plains_base_nocanopy2", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        countstaticlayouts = {
            ["pig_ruins_nocanopy_3"] = 1,
            ["pig_ruins_nocanopy_4"] = 1,
        },
        distributepercent = .25, --.22, --.26
        distributeprefabs =
        {
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            dungpile = 0.03,
            peagawk = 0.01,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,

            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("BG_plains_base_nocanopy3", {
    colour = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        countstaticlayouts = {
            ["pig_ruins_nocanopy_4"] = 1,
            ["pig_ruins_nocanopy"] = 1,
        },
        distributepercent = .25, --.22, --.26
        distributeprefabs =
        {
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            dungpile = 0.03,
            peagawk = 0.01,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("plains_tallgrass", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .15, -- .15, -- .3
        distributeprefabs =
        {
            clawpalmtree = .25,
            grass_tall = 1,
            flower = 0.05,
            --		randomrelic = 0.0016,
            --randomruin = 0.0025,	
            randomdust = 0.0025,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("plains_ruins", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .25, -- .15, -- .3
        distributeprefabs =
        {
            clawpalmtree = .25,
            grass_tall = 1,
            flower = 0.05,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("plains_ruins_set", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .25, -- .15, -- .3
        distributeprefabs =
        {
            clawpalmtree = .25,
            grass_tall = 1,
            flower = 0.05,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            grass_tall_patch = 2,
            grass_tall_infested = 1,
        },
    }
})

AddRoom("plains_pogs", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .25, -- .15, -- .3
        distributeprefabs =
        {
            clawpalmtree = .25,
            grass_tall = 1,
            flower = 0.05,
            pog = 0.1,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            pog = 2,
        },
    }
})

AddRoom("plains_pogs_ruin", {
    colour = { r = 0.0, g = 1, b = 0.3, a = 0.3 },
    value = GROUND.PLAINS,
    tags = {},
    contents = {
        distributepercent = .25, -- .15, -- .3
        distributeprefabs =
        {
            clawpalmtree = .25,
            grass_tall = 1,
            flower = 0.05,
            pog = 0.1,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            pog = 2,
        },
    }
})





----------------------------------------------Ham caves---------------------------------------------------------------------------
AddRoom("HamLightPlantField", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .4,
        distributeprefabs =
        {
            flower_cave = 1.0,
            flower_cave_double = 0.5,
            flower_cave_triple = 0.5,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,

            pig_ruins_head = 0.02,
            flower_rainforest = 2,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 1,
            deep_jungle_fern_noise_plant2 = 1,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
    }
})

-- plainscave 2
AddRoom("HamLightPlantFieldexit", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .4,
        distributeprefabs =
        {
            flower_cave = 1.0,
            flower_cave_double = 0.5,
            flower_cave_triple = 0.5,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,

            pig_ruins_head = 0.02,
            flower_rainforest = 2,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,
        },
        countprefabs =
        {
            cave_exit_ham1 = 1,
        },
    }
})


-- plainscave 3
AddRoom("HamWormPlantField", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            flower_cave = 0.5,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,
            pig_ruins_head = 0.02,

            pillar_cave_flintless = 0.02,

            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.01,
            asparagus_planted = 0.05,

            wormlight_plant = 0.2,

        },
    }
})

-- plainscave 4 fern
AddRoom("HamFernGully", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .5,
        distributeprefabs =
        {
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,
            pig_ruins_head = 0.02,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.03,
            asparagus_planted = 0.05,


            cave_fern = 2.0,
            wormlight_plant = 0.05,
        },
    }
})

-- plainscave
AddRoom("HamSlurtlePlains", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .4,
        distributeprefabs =
        {
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,
            pig_ruins_head = 0.02,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.03,
            asparagus_planted = 0.05,


            cave_fern = 2.0,
            wormlight_plant = 0.05,
        },
    }
})

-- plainscave
AddRoom("HamMudWithRabbit", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,
            pig_ruins_head = 0.02,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.03,
            asparagus_planted = 0.05,


            cave_fern = 2.0,
            wormlight_plant = 0.05,
        },
    }
})

-- plainscave
AddRoom("HamMudWithRabbitexit", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,
            pig_ruins_head = 0.02,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.03,
            asparagus_planted = 0.05,


            cave_fern = 2.0,
            wormlight_plant = 0.05,

        },
        countprefabs =
        {
            cave_exit_ham2 = 1,
        },
    }
})

-- plainscave
AddRoom("HamBGMud", {
    colour = { r = 0.7, g = 0.5, b = 0.3, a = 0.9 },
    value = GROUND.SINKHOLE,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.02,
            pig_ruins_pig = 0.02,
            pig_ruins_light_beam = 0.02,
            pig_ruins_head = 0.02,
            pillar_cave_flintless = 0.02,
            deep_jungle_fern_noise_plant = 0.5,
            deep_jungle_fern_noise_plant2 = 0.5,
            clawpalmtree = 0.5,
            grass_tall = 1,
            sapling_ham = .3,
            flower = 0.05,
            peagawk = 0.01,
            rock_flippable = 0.08,
            aloe_planted = 0.08,
            pog = 0.03,
            asparagus_planted = 0.05,


            cave_fern = 2.0,
            wormlight_plant = 0.05,
        },
    }
})


-- cave iron
AddRoom("HamBatCave", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = GROUND.ANTFLOOR,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .15,
        distributeprefabs =
        {
            goldnugget = .05,
            flint = 0.05,
            stalagmite_tall = 0.4,
            stalagmite_tall_med = 0.4,
            stalagmite_tall_low = 0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.3,
            --            thunderbirdnest = 0.1,
            sedimentpuddle = 0.2,
            pangolden = 0.02,
            slurtlehole = 0.5,
        }
    }
})

-- cave iron
AddRoom("HamBattyCave", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = GROUND.ANTFLOOR,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            goldnugget = .05,
            flint = 0.05,
            stalagmite_tall = 0.4,
            stalagmite_tall_med = 0.4,
            stalagmite_tall_low = 0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.3,
            --            thunderbirdnest = 0.1,
            sedimentpuddle = 0.2,
            pangolden = 0.1,
            slurtlehole = 0.5,
        }
    }
})
-- cave iron
AddRoom("HamFernyBatCave", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = GROUND.ANTFLOOR,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            goldnugget = .05,
            flint = 0.05,
            stalagmite_tall = 0.4,
            stalagmite_tall_med = 0.4,
            stalagmite_tall_low = 0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.3,
            --            thunderbirdnest = 0.1,
            sedimentpuddle = 0.2,
            pangolden = 0.02,
            slurtlehole = 0.5,
        }
    }
})

-- cave iron
AddRoom("HamFernyBatCaveexit", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = GROUND.ANTFLOOR,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            cave_fern = 0.5,
            goldnugget = .05,
            flint = 0.05,
            stalagmite_tall = 0.4,
            stalagmite_tall_med = 0.4,
            stalagmite_tall_low = 0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.3,
            --            thunderbirdnest = 0.1,
            sedimentpuddle = 0.2,
            pangolden = 0.02,
            slurtlehole = 0.5,
        },
        countprefabs =
        {
            cave_exit_ham3 = 1,
        },
    }
})

-- caveiron
AddRoom("HamBGBatCaveRoom", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = GROUND.ANTFLOOR,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .13,
        distributeprefabs =
        {
            cave_fern = 0.5,
            goldnugget = .05,
            flint = 0.05,
            stalagmite_tall = 0.4,
            stalagmite_tall_med = 0.4,
            stalagmite_tall_low = 0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
            tubertree = 1,
            gnatmound = 0.1,
            rocks = 0.1,
            nitre = 0.1,
            flint = 0.05,
            iron = 0.3,
            --            thunderbirdnest = 0.1,
            sedimentpuddle = 0.2,
            pangolden = 0.02,
            slurtlehole = 0.5,
        },
    }
})

-- fip
AddRoom("HamSlurtleCanyon", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},
    type = GLOBAL.NODE_TYPE.Room,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        distributepercent = .20,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            rock_flippable = 0.3,
            rock_antcave = 0.7,
            sapling_ham = 0.2,
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.2,

            stalagmite_tall = 0.5,
            stalagmite_tall_med = 0.2,
            stalagmite_tall_low = 0.2,
            fissure = 0.01,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            antcombhomecave = 2,
            giantgrubspawner = 1,
            ant_cave_lantern = 2,
        },
    }
})

-- fip
AddRoom("HamBatsAndSlurtles", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},
    type = GLOBAL.NODE_TYPE.Room,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        distributepercent = .20,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            rock_flippable = 0.3,
            rock_antcave = 0.7,
            sapling_ham = 0.2,
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.2,
            stalagmite_tall = 0.5,
            stalagmite_tall_med = 0.2,
            deco_hive_debris = 0.2,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            antcombhomecavenursery = 2,
            giantgrubspawner = 1,
            ant_cave_lantern = 2,
            antchest = 1,
        },
    }
})

-- fip
AddRoom("HamRockyPlains", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},
    type = GLOBAL.NODE_TYPE.Room,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            rock_flippable = 0.3,
            rock_antcave = 0.7,
            antcombhomecave = 0.15,
            sapling_ham = 0.2,
            guano = 0.27,
            goldnugget = .05,
            flint = 0.05,
            stalagmite_tall = 0.4,
            stalagmite_tall_med = 0.4,
            stalagmite_tall_low = 0.4,
            fissure = 0.05,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            antcombhomecave = 2,
            giantgrubspawner = 1,
            ant_cave_lantern = 2,
            pond_cave = 2,
        },
    }
})

-- fip
AddRoom("HamRockyPlainsexit", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},
    type = GLOBAL.NODE_TYPE.Room,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        distributepercent = .20,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            ant_cave_lantern = 0.1,
            rock_flippable = 0.7,
            rock_antcave = 0.3,
            sapling_ham = 0.2,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            antcombhomecave = 1,
            giantgrubspawner = 1,
        },
    }
})

-- fip
AddRoom("HamRockyHatchingGrounds", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},
    type = GLOBAL.NODE_TYPE.Room,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        distributepercent = .30,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            rock_flippable = 0.3,
            rock_antcave = 0.7,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            antcombhomecavenursery = 2,
            giantgrubspawner = 1,
            ant_cave_lantern = 2,
        },
    }
})

-- fip
AddRoom("HamBatsAndRocky", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},
    type = GLOBAL.NODE_TYPE.SeparatedRoom,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents = {
        countstaticlayouts = {
            ["antqueencave"] = 1,
        },
        distributepercent = .35,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            rock_flippable = 0.3,
            rock_antcave = 0.7,
            sapling_ham = 0.2,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            --		antchest = 1,
        },
    }
})


-- fip
AddRoom("HamBGRockyCaveRoom", {
    colour = { r = 0.7, g = 0.7, b = 0.7, a = 0.9 },
    value = GROUND.ANTFLOOR,
    --    tags = {"Hutch_Fishbowl"},	
    type = GLOBAL.NODE_TYPE.Room,
    internal_type = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        distributepercent = .20,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,
            rock_flippable = 0.3,
            rock_antcave = 0.7,
            sapling_ham = 0.2,
            deco_cave_ceiling_drip_2 = 0.1,
        },
        countprefabs =
        {
            antcombhomecave = 2,
            giantgrubspawner = 1,
            ant_cave_lantern = 2,
        },
    }
})




-- Gass MIX MUSH
AddRoom("HamRedMushForest", {
    colour = { r = 0.8, g = 0.1, b = 0.1, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_yelow = 9.0,
            yelow_mushroom = 0.9,

            stalagmite = 0.5,
            pillar_cave = 0.1,
            spiderhole = 0.05,

            pillar_cave = 0.05,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
    }
})

-- Gass MIX MUSH
AddRoom("HamRedSpiderForest", {
    colour = { r = 0.8, g = 0.1, b = 0.4, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_yelow = 9.0,
            yelow_mushroom = 0.9,

            stalagmite = 1.5,
            pillar_cave = 0.2,
            spiderhole = 0.4,

            pillar_cave = 0.05,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
    }
})

-- Gass MIX MUSH
AddRoom("HamRedSpiderForestexit", {
    colour = { r = 0.8, g = 0.1, b = 0.4, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_yelow = 9.0,
            yelow_mushroom = 0.9,

            pillar_cave = 0.2,
            spiderhole = 0.4,
            stalagmite = 0.2,
            pillar_cave = 0.05,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
    }
})

-- Gass MIX MUSH
AddRoom("HamRedMushPillars", {
    colour = { r = 0.8, g = 0.1, b = 0.4, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .15,
        distributeprefabs =
        {
            mushtree_yelow = 6.0,
            yelow_mushroom = 0.9,

            stalagmite = 0.5,
            pillar_cave = 0.5,
            spiderhole = 0.01,

            pillar_cave = 0.05,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
    }
})

-- Gass MIX MUSH
AddRoom("HamStalagmiteForest", {
    colour = { r = 0.8, g = 0.1, b = 0.1, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_yelow = 9.0,
            yelow_mushroom = 0.9,

            stalagmite = 3.5,
            pillar_cave = 1.0,
            spiderhole = 0.15,

            pillar_cave = 0.5,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
    }
})

-- Gass MIX MUSH
AddRoom("HamSpillagmiteMeadow", {
    colour = { r = 0.8, g = 0.1, b = 0.1, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .15,
        distributeprefabs =
        {
            mushtree_yelow = 9.0,
            yelow_mushroom = 0.9,

            stalagmite = 1.5,
            pillar_cave = 0.05,
            spiderhole = 0.45,

            pillar_cave = 0.05,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
        countprefabs =
        {
            maze_pig_ruins_entrance2 = 1,
        },
    }
})

-- Gass MIX MUSH
AddRoom("HamBGRedMush", {
    colour = { r = 0.8, g = 0.1, b = 0.1, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_yelow = 9.0,
            yelow_mushroom = 0.9,

            pillar_cave = 0.05,
            cavelight = 0.6,
            --			poisonmist = 8,
            rock_flippable = 0.05,
            jungle_border_vine = 0.5,
            pig_ruins_torch = 0.2,
            pig_ruins_head = 0.5,
            pig_ruins_pig = 0.5,
            pig_ruins_ant = 0.5,
        },
    }
})

-- Green mush forest
AddRoom("HamGreenMushForest", {
    colour = { r = 0.1, g = 0.8, b = 0.1, a = 0.9 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .35,
        distributeprefabs =
        {
            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
    }
})

-- green
AddRoom("HamGreenMushPonds", {
    colour = { r = 0.1, g = 0.8, b = 0.3, a = 0.9 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            pond = 1,

            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
    }
})

-- Greenmush Sinkhole
AddRoom("HamGreenMushSinkhole", {
    colour = { r = 0.1, g = 0.8, b = 0.3, a = 0.9 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        countstaticlayouts = {
            ["EvergreenSinkhole"] = 1,
        },
        distributepercent = .2,
        distributeprefabs =
        {
            cavelight = 0.05,
            cavelight_small = 0.05,

            grass_ham = 0.1,
            sapling_ham = 0.1,
            twiggytree = 0.04,

            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
    }
})

-- green
AddRoom("HamGreenMushMeadow", {
    colour = { r = 0.1, g = 0.8, b = 0.3, a = 0.9 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            cavelight = 0.05,
            cavelight_small = 0.05,

            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
        countprefabs =
        {
            maze_pig_ruins_entrance = 1,
        },
    }
})

-- green
AddRoom("HamGreenMushRabbits", {
    colour = { r = 0.1, g = 0.8, b = 0.3, a = 0.9 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        countstaticlayouts = {
            ["farm_3"] = 1,
        },
        distributepercent = .2,
        distributeprefabs =
        {
            grass_ham = 0.1,
            sapling_ham = 0.1,
            twiggytree = 0.04,

            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
        countprefabs =
        {
            cavelight = 3,
            cavelight_small = 3,
            cavelight_tiny = 3,
        }
    }
})

-- Green Mush and Sinkhole Noise
AddRoom("HamGreenMushNoise", {
    colour = { r = .36, g = .32, b = .38, a = .50 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
    }
})

--Green
AddRoom("HamBGGreenMush", {
    colour = { r = .36, g = .32, b = .38, a = .50 },
    value = GROUND.RAINFOREST,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .25,
        distributeprefabs =
        {
            mushtree_small = 5.0,
            green_mushroom = 3.0,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            spider_monkey_tree = 1,
            spider_monkey = 1,
            rainforesttree = 6, --4,
            pillar_cave = 1,    --0.5,
            flower_rainforest = 4,
            berrybush_juicy = 2,
            cavelight = 0.6,
            deep_jungle_fern_noise = 4,
            deep_jungle_fern_noise = 2,
            jungle_border_vine = 2,
            fireflies = 0.2,
            hanging_vine_patch = 2,
            pig_ruins_torch = 0.02,
            rock_flippable = 0.1,
        },
    }
})

-- Blue mush forest
AddRoom("HamBlueMushForest", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.MEADOW,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .5,
        distributeprefabs =
        {
            mushtree_tall = 4.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            sapling_ham = 1,
            grass_tall = 3,
            ox = 0.5,
            teatree = 0.8,
            teatree_piko_nest = 0.5, --teatree_piko_nest_patch
        },
    }
})

-- Blue mush forest
AddRoom("HamBlueMushMeadow", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.MEADOW,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_tall = 1.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            sapling_ham = 1,
            grass_tall = 3,
            ox = 0.5,
            teatree = 0.8,
            teatree_piko_nest = 0.5, --teatree_piko_nest_patch
        },
    }
})

-- Blue mush forest
AddRoom("HamBlueSpiderForest", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.MEADOW,
    tags = { "Hutch_Fishbowl" },
    contents = {
        countstaticlayouts = {
            ["mandraketown"] = 1,
        },


        distributepercent = .3,
        distributeprefabs =
        {
            mushtree_tall = 3.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            sapling_ham = 1,
            grass_tall = 3,
            ox = 0.5,
            teatree = 0.8,
            teatree_piko_nest = 0.5, --teatree_piko_nest_patch
        },
        countprefabs =
        {
            cavelight = 3,
            cavelight_small = 3,
            cavelight_tiny = 3,
        }
    }
})

-- Blue mush forest
AddRoom("HamDropperDesolation", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.MEADOW,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .2,
        distributeprefabs =
        {
            mushtree_tall = 1.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            sapling_ham = 1,
            grass_tall = 3,
            ox = 0.5,
            teatree = 0.8,
            teatree_piko_nest = 0.5, --teatree_piko_nest_patch
        },
    }
})

-- Blue mush forest
AddRoom("HamBGBlueMush", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.MEADOW,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .5,
        distributeprefabs =
        {
            mushtree_tall = 5.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            sapling_ham = 1,
            grass_tall = 3,
            ox = 0.5,
            teatree = 0.8,
            teatree_piko_nest = 0.5, --teatree_piko_nest_patch
        },
    }
})


-- vampire
AddRoom("HamSpillagmiteForest", {
    colour = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
    value = GROUND.FUNGUS,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .35,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            deco_cave_ceiling_trim = 0.3,
            deco_cave_beam_room = 0.3,
            stalagmite = 0.3,
            stalagmite_tall = 0.3,
            deco_cave_stalactite = 0.3,
            rocks = 0.3,
            twigs = 1,
            cave_fern = 0.8,
            deco_cave_bat_burrow = 0.2,
            mushtree_medium = 1.0,
            spiderhole = 0.1,
        },
    }
})

-- vampire
AddRoom("HamDropperCanyon", {
    colour = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
    value = GROUND.FUNGUS,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .35,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            deco_cave_ceiling_trim = 0.3,
            deco_cave_beam_room = 0.3,
            stalagmite = 0.3,
            stalagmite_tall = 0.3,
            deco_cave_stalactite = 0.3,
            rocks = 0.3,
            twigs = 1,
            cave_fern = 0.8,
            deco_cave_bat_burrow = 0.2,
            mushtree_medium = 1.0,
            spiderhole = 0.1,
        },
    }
})

-- vampire
AddRoom("HamStalagmitesAndLights", {
    colour = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
    value = GROUND.FUNGUS,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .15,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            deco_cave_ceiling_trim = 0.3,
            deco_cave_beam_room = 0.3,
            stalagmite = 0.3,
            stalagmite_tall = 0.3,
            deco_cave_stalactite = 0.3,
            rocks = 0.3,
            twigs = 1,
            cave_fern = 0.8,
            deco_cave_bat_burrow = 0.2,
            mushtree_medium = 1.0,
            spiderhole = 0.1,
        },
    }
})

-- red
AddRoom("HamSpidersAndBats", {
    colour = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .20,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            roc_nest_tree1 = 0.1,
            roc_nest_tree2 = 0.1,
            roc_nest_branch1 = 0.5,
            roc_nest_branch2 = 0.5,
            roc_nest_bush = 1,
            rocks = 0.5,
            twigs = 1,
            rock2 = 0.1,
            dropperweb = 0.2,
            mushtree_medium = 2.0,
        },
    }
})

-- red
AddRoom("HamThuleciteDebris", {
    colour = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .20,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            roc_nest_tree1 = 0.1,
            roc_nest_tree2 = 0.1,
            roc_nest_branch1 = 0.5,
            roc_nest_branch2 = 0.5,
            roc_nest_bush = 1,
            rocks = 0.5,
            twigs = 1,
            rock2 = 0.1,
            dropperweb = 0.2,
            mushtree_medium = 2.0,
        },
    }
})

-- red
AddRoom("HamBGSpillagmite", {
    colour = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    tags = { "Hutch_Fishbowl" },
    contents = {
        distributepercent = .35,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            roc_nest_tree1 = 0.1,
            roc_nest_tree2 = 0.1,
            roc_nest_branch1 = 0.5,
            roc_nest_branch2 = 0.5,
            roc_nest_bush = 1,
            rocks = 0.5,
            twigs = 1,
            rock2 = 0.1,
            --		   dropperweb= 0.2,
            mushtree_medium = 2.0,
        },
    }
})

-- red não usado
AddRoom("HamCaveExitRoom", {
    colour = { r = .25, g = .28, b = .25, a = .50 },
    value = GROUND.QUAGMIRE_PARKFIELD,
    contents = {
        countstaticlayouts = {
            ["CaveExit"] = 1,
        },
        distributepercent = .2,
        distributeprefabs =
        {
            flower_cave_triple = 0.1,
            pillar_cave_rock = 0.1,

            rock1 = 0.1,
            flint = 0.1,
            roc_nest_tree1 = 0.1,
            roc_nest_tree2 = 0.1,
            roc_nest_branch1 = 0.5,
            roc_nest_branch2 = 0.5,
            roc_nest_bush = 1,
            rocks = 0.5,
            twigs = 1,
            rock2 = 0.1,
            --		   tallbirdnest= 0.2,
            mushtree_medium = 2.0,
        }
    }
})


------cave exit---------------------------------------------------------------------------

AddRoom("caveruinexitroom", {
    colour = { r = .25, g = .28, b = .25, a = .50 },
    value = GROUND.SINKHOLE,
    contents = {
        countstaticlayouts = {
            ["ruins_exit"] = 1,
        },
        distributepercent = .2,
        distributeprefabs =
        {
            cavelight = 0.05,
            cavelight_small = 0.05,
            cavelight_tiny = 0.05,
            flower_cave = 0.5,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            cave_fern = 0.5,
            fireflies = 0.01,

            red_mushroom = 0.1,
            green_mushroom = 0.1,
            blue_mushroom = 0.1,
        }
    }
})

AddRoom("caveruinexitroom2", {
    colour = { r = .25, g = .28, b = .25, a = .50 },
    value = GROUND.SINKHOLE,
    contents = {
        countstaticlayouts = {
            ["ruins_exit2"] = 1,
        },
        distributepercent = .2,
        distributeprefabs =
        {
            cavelight = 0.05,
            cavelight_small = 0.05,
            cavelight_tiny = 0.05,
            flower_cave = 0.5,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            cave_fern = 0.5,
            fireflies = 0.01,

            red_mushroom = 0.1,
            green_mushroom = 0.1,
            blue_mushroom = 0.1,
        }
    }
})

---------------------------------------------------ham archive maze -------------------------

AddRoom("HamArchiveMazeEntrance", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.CAVE_NOISE,
    tags = { "MazeEntrance" },
    contents = {
        distributepercent = 0.6,
        distributeprefabs =
        {
            tree_forest_rot = 0.05,
            lightflier_flower = 0.01,
            cavelightmoon = 0.01,
            cavelightmoon_small = 0.01,
            cavelightmoon_tiny = 0.01,

            stalagmite_tall = 0.03,
            stalagmite_tall_med = 0.03,
            stalagmite_tall_low = 0.03,
            batcave = 0.01,
        },
    }
})

AddRoom("HamCaveGraveyardentrance", {
    colour = { r = 0.1, g = 0.1, b = 0.8, a = 0.9 },
    value = GROUND.MARSH,
    tags = { "Mist" },
    contents = {
        distributepercent = 0.6,
        distributeprefabs =
        {
            tree_forest_rot = 0.05,

            lightflier_flower = 0.01,

            cavelightmoon = 0.01,
            cavelightmoon_small = 0.01,
            cavelightmoon_tiny = 0.01,

            pigghostspawner = 0.005,
            piggravestone1 = 0.02,
            piggravestone2 = 0.02,
        },
    }
})

AddRoom("HamCaveGraveyard", {
    colour = { r = .010, g = .010, b = .10, a = .50 },
    value = GROUND.MARSH,
    tags = { "Mist" },
    contents = {
        countprefabs = {
            tree_forest_rot = 20,
            pigghostspawner = 10,
            goldnugget = function() return math.random(10) end,
            piggravestone1 = function() return 10 + math.random(4) end,
            piggravestone2 = function() return 10 + math.random(4) end,
        }
    }
})
