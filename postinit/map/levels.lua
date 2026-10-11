local ta_worldgen = TA_CONFIG.WORLDGEN

-----------海上布景---------------会显著加快地形生成
if true then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            if not level.ocean_prefill_setpieces then
                level.ocean_prefill_setpieces = {}
            end

            level.ocean_prefill_setpieces["MonkeyIsland"] =
                function() return WorldSim:GetWorldSize() >= 425 and 1 or 0 end
            level.ocean_prefill_setpieces["HermitcrabIsland"] = 1
            level.ocean_prefill_setpieces["MonkeyIslandSmall"] =
                function() return WorldSim:GetWorldSize() < 425 and 1 or 0 end
            level.ocean_prefill_setpieces["OceanWhirlBigPortal"] = 1
            -- level.ocean_prefill_setpieces["CrabKing"] = 1

            level.ocean_population = tableutil.insert_components(level.ocean_population, {
                "OceanBrinepool",
            })
        end
    end)

    AddRoomPreInit("OceanRough", function(room)
        if ta_worldgen.ocean_content == false then
            tableutil.remove_components(room.required_prefabs, {
                "hermithouse_construction1", "monkeyqueen", "oceanwhirlbigportal",
            })
        end
        tableutil.remove_indexes(room.contents.countstaticlayouts, {
            "HermitcrabIsland",
            "MonkeyIsland",
            "MonkeyIslandSmall",
            "OceanWhirlBigPortal"

        })

        ---delete  ["HermitcrabIsland"] = 1, 	["MonkeyIsland"] = 1,
    end)

    AddRoomPreInit("OceanSwell", function(room)
        -- room.required_prefabs = {}
        -- room.contents.countstaticlayouts = {} ---- delete ["CrabKing"] = 1
    end)
end

---------------------联机大陆调整--------------------------
if ta_worldgen.together == false then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            tableutil.remove_components(
                level.tasks,
                {
                    "Make a pick",
                    "Dig that rock",
                    "Great Plains",
                    "Squeltch",
                    "Beeeees!",
                    "Speak to the king",
                    "Forest hunters",
                    "Badlands",
                    "For a nice walk",
                    "Lightning Bluff",

                }
            )

            level.numoptionaltasks = 0
            tableutil.remove_indexes(
                level.set_pieces,
                {
                    "ResurrectionStone",
                    "WormholeGrass",
                    "MooseNest",
                    "CaveEntrance",
                }
            )

            -- tableutil.remove_components(
            --     level.required_prefabs,
            --     {
            --         "gravestone",
            --         "sculpture_rook",
            --         "sculpture_bishop",
            --         "sculpture_knight",
            --         "terrariumchest",
            --         "charlie_stage_post",
            --         "statueharp_hedgespawner",
            --         "balatro_machine",
            --     }
            -- )
            -- level.required_setpieces = {}
            level.numrandom_set_pieces = 0

            -- level.random_set_pieces = {}
            -- level.ordered_story_setpieces = {}
            -- level.overrides.layout_mode = "LinkNodesByKeys"
            -- level.numrandom_set_pieces = 0
            -- level.overrides.keep_disconnected_tiles = true
        end
    end)

    -- AddTaskSetPreInitAny(function(taskset)
    --     if taskset.location == "forest" then
    --         tableutil.remove_components(
    --             taskset.required_prefabs,
    --             {
    --                 "gravestone",
    --                 "sculpture_rook",
    --                 "sculpture_bishop",
    --                 "sculpture_knight",
    --                 "terrariumchest",
    --                 "charlie_stage_post",
    --                 "statueharp_hedgespawner",
    --                 "balatro_machine",
    --             }
    --         )
    --     end
    -- end)
end

if ta_worldgen.ocean_content == false then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            tableutil.remove_components(
                level.tasks,
                {
                    "MoonIsland_IslandShards",
                    "MoonIsland_Beach",
                    "MoonIsland_Forest",
                    "MoonIsland_Baths",
                    "MoonIsland_Mine",
                }
            )
            tableutil.remove_indexes(
                level.set_pieces,
                {
                    "MoonAltarRockGlass",
                    "MoonAltarRockIdol",
                    "MoonAltarRockSeed",
                    "BathbombedHotspring",
                    "MoonFissures",
                }
            )

            tableutil.remove_indexes(
                level.ocean_prefill_setpieces,
                {
                    "BrinePool1",
                    "BrinePool2",
                    "BrinePool3",
                    "Waterlogged1",
                    "MonkeyIsland",
                    "HermitcrabIsland",
                    "MonkeyIslandSmall",
                    "OceanWhirlBigPortal",
                }
            )

            -- level.required_setpieces = {}

            -- level.random_set_pieces = {}
            -- level.ordered_story_setpieces = {}
            -- level.overrides.layout_mode = "LinkNodesByKeys"
            -- level.numrandom_set_pieces = 0
            -- level.overrides.keep_disconnected_tiles = true
        end
    end)
end

if ta_worldgen.rog == "fixed" then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            level.numoptionaltasks = 0
            level.optionaltasks = {}
            if ta_worldgen.rog == "fixed" then
                table.insert(level.tasks, "Killer bees!")
                table.insert(level.tasks, "The hunters")
                table.insert(level.tasks, "Befriend the pigs")
                table.insert(level.tasks, "Frogs and bugs")
                table.insert(level.tasks, "Kill the spiders")
                -- "Befriend the pigs",
                -- "Kill the spiders",---蜘蛛矿区
                -- "Killer bees!",
                -- "Make a Beehat", ---蜜蜂矿场？
                -- "The hunters",
                -- "Magic meadow", ----有池塘
                -- "Frogs and bugs", --青蛙和蜜蜂？
                -- "Mole Colony Deciduous",---第二桦树林
                -- "Mole Colony Rocks",---大矿区
                -- "MooseBreedingTask",
            end
        end
    end)
end

if ta_worldgen.cave_content == "part" then
    AddLevelPreInitAny(function(level)
        if level.location == "cave" then
            local exit_tasks = {
                "CaveExitTask1",
                "CaveExitTask2",
                "CaveExitTask3",
                "CaveExitTask4",
                "CaveExitTask5",
                "CaveExitTask6",
                "CaveExitTask7",
                "CaveExitTask8",
                "CaveExitTask9",
                "CaveExitTask10",
            }
            tableutil.remove_components(level.tasks, exit_tasks)
            tableutil.remove_components(level.optionaltasks, exit_tasks)
            tableutil.remove_components(level.valid_start_tasks, exit_tasks)
            if level.valid_start_tasks ~= nil and #level.valid_start_tasks == 0 then
                level.valid_start_tasks = nil
            end
            if level.optionaltasks ~= nil and level.numoptionaltasks ~= nil then
                level.numoptionaltasks = math.min(level.numoptionaltasks, #level.optionaltasks)
            end
        end
    end)
end

------------------------海难----------------------------
if ta_worldgen.shipwrecked then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            table.insert(level.tasks, "HomeIsland")
            table.insert(level.tasks, "RockyGold")       --火山矿区  ["MagmaGold"] = 2,  ["MagmaGoldBoon"] = 1,
            table.insert(level.tasks, "BoreKing")        --野猪王  ["PigVillagesw"] = 1,      ["JungleDenseBerries"] = 1,  ["BeachShark"] = 1,
            table.insert(level.tasks, "RockyTallJungle") --火山矿  ["MagmaTallBird"] = 1,  ["MagmaGoldBoon"] = 1,
            table.insert(level.tasks, "BeachSkull")      --骷髅岛 ["JungleRockSkull"] = 1, random
            table.insert(level.tasks, "MagmaJungle")     -- 猴子 ["MagmaForest"] = 1, -- MR went from 1-3    ["JungleDense"] = 1,    ["JunglePigs"] = 1,没有猪

            table.insert(level.tasks, "JungleMarshy")    --热带沼泽和沙滩
            table.insert(level.tasks, "JungleBushy")     --沙滩和丛林，纯随机
            table.insert(level.tasks, "JungleBeachy")    --热带丛林+纯随机
            table.insert(level.tasks, "JungleMonkey")    --猴子  ["JungleMonkeyHell"] = 2,

            table.insert(level.tasks, "BeachMarshy")     --纯随机 沙滩和沼泽
            table.insert(level.tasks, "MoonRocky")       --月石矿
            table.insert(level.tasks, "TigerSharky")     -- Tiger shark island.
            table.insert(level.tasks, "Verdent")         --绿草地  ["Beaverkinghome"] = 1,    ["Beaverkingcity"] = 1, beaver是什么东西
            table.insert(level.tasks, "Casino")          --["BeachPalmCasino"] = 1, 抽奖机
            table.insert(level.tasks, "BeachBeachy")     --随机  [salasbeach[math.random(1, 24)]] = 1,  ["BeachShark"] = 1,又是啥玩意
            table.insert(level.tasks, "BeachPiggy")      --猪人沙滩
            table.insert(level.tasks, "DoyDoyM")         ---doydoyM
            table.insert(level.tasks, "DoyDoyF")         ---doydoyF

            table.insert(level.tasks, "Volcano ground")  --火山  ["VolcanoAsh"] = 1,       ["Volcano"] = 1,    ["VolcanoObsidian"] = 1,

            table.insert(level.tasks, "A_BLANK1")
            table.insert(level.tasks, "A_BLANK2")
            table.insert(level.tasks, "A_BLANK3")
            table.insert(level.tasks, "A_BLANK4")
            table.insert(level.tasks, "A_BLANK5")
            table.insert(level.tasks, "A_BLANK6")
            table.insert(level.tasks, "A_BLANK7")
            table.insert(level.tasks, "A_BLANK8")
            table.insert(level.tasks, "A_BLANK9")
            table.insert(level.tasks, "A_BLANK10")
            table.insert(level.tasks, "A_BLANK11")
            table.insert(level.tasks, "A_BLANK12")

            level.ocean_population = tableutil.insert_components(level.ocean_population, {
                "OceanBrinepool",
            })
            level.required_prefabs = tableutil.insert_components(
                level.required_prefabs,
                {
                    "packim_fishbone",
                    "tigershark_spawnpoint",
                    "slipstor",
                    "octopusking",
                    "mermhouse_fisher",
                    "doydoy",
                    "doydoy",
                    "doydoybaby",
                    -- "volcano_altar",
                    "obsidian_workbench",
                    "wildboreking",
                    "firetwister",
                }
            )

            level.numrandom_set_pieces = level.numrandom_set_pieces + 5
        end
    end)
end

-----------------哈姆雷特-------------------------------------
if ta_worldgen.hamlet then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            table.insert(level.tasks, "Plains")               --island3 高草地形，类似牛场
            table.insert(level.tasks, "Rainforest_ruins")
            table.insert(level.tasks, "Painted_sands")        --废铁机器人和铁矿区, 有cave_entrance_roc，但是太大了
            table.insert(level.tasks, "Deep_rainforest")      ----有蚁穴

            table.insert(level.tasks, "Edge_of_civilization") --城郊地区
            table.insert(level.tasks, "Pigtopia")
            -- table.insert(level.tasks, "Pigtopia_capital")

            table.insert(level.tasks, "Other_edge_of_civilization")
            table.insert(level.tasks, "Other_pigtopia")
            -- table.insert(level.tasks, "Other_pigtopia_capital")
            table.insert(level.tasks, "Deep_rainforest_2")   ----有荨麻，遗迹入口  entrance_5  --并入曼达拉

            table.insert(level.tasks, "Edge_of_the_unknown") --pugalisk_fountain 蛇岛 ---大鸟岛入口？vampirebatcave_entrance_roc
            table.insert(level.tasks, "Deep_rainforest_3")
            table.insert(level.tasks, "Deep_lost_ruins_gas") --毒气森林 有entrance_6

            table.insert(level.tasks, "Pincale")

            level.set_pieces["cave_entranceham1"] = { count = 1, tasks = { "Deep_rainforest" } }
            level.set_pieces["cave_entranceham2"] = { count = 1, tasks = { "Deep_rainforest_2" } }
            level.set_pieces["cave_entranceham3"] = { count = 1, tasks = { "Deep_lost_ruins_gas" } }

            level.required_prefabs = tableutil.insert_components(
                level.required_prefabs,
                {
                    "pugalisk_fountain",
                    "roc_nest",
                    "ancient_robot_ribs",
                    "ancient_robot_head",
                    "ancient_robot_claw",
                    "ancient_robot_claw",
                    "ancient_robot_leg",
                    "ancient_robot_leg",

                }
            )

            level.numrandom_set_pieces = level.numrandom_set_pieces + 4
        end
    end)
end

if ta_worldgen.ruins then
    AddLevelPreInitAny(function(level)
        if level.location == "cave" then
            table.insert(level.tasks, "HamMudWorld")   ---地下版的出生地，但是爪树 "HamLightPlantFieldexit"--exit1 "HamArchiveMaze"
            table.insert(level.tasks, "HamRockyLand")  --"HamBatsAndRocky"有蚁后
            table.insert(level.tasks, "HamMudCave")    --同质化严重  "HamMudWithRabbitexit" 有exit2
            table.insert(level.tasks, "HamBigBatCave") ----exit3
            table.insert(level.tasks, "HamArchiveMaze")
            table.insert(level.tasks, "TaHamRuinsOutskirts")
            table.insert(level.tasks, "TaHamRuinsLabyrinth")
        end
    end)
end

-----------------------出生地调整-----------------------------
if ta_worldgen.sw_start then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            -- table.insert(level.tasks, "HomeIsland_start")
            level.overrides.start_location = "SWStart"
            level.valid_start_tasks = { "HomeIsland" }
        end
    end)

    -- AddTaskPreInitAny(function(task) -----大理石雕像的对应调整
    --     if not tableutil.has_component(task.room_tags, "shipwrecked") then
    --         task.level_set_piece_blocker = true
    --     end
    -- end)
elseif ta_worldgen.ham_start then
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            -- table.insert(level.tasks, "Plains_start")
            level.overrides.start_location = "HamStart"
            level.valid_start_tasks = { "Plains" }
        end
    end)
    -- AddTaskPreInitAny(function(task)
    --     if not tableutil.has_component(task.room_tags, "hamlet") then
    --         task.level_set_piece_blocker = true
    --     end
    -- end)
end



---------------------测试模式------------
if TA_CONFIG.DEVELOP.test_map and true then
    AddTask("Make a new pick", {
        locks = LOCKS.NONE,
        tags = { "nohunt", "nohasslers", "civilized" },
        keys_given = { KEYS.PICKAXE, KEYS.AXE, KEYS.GRASS, KEYS.WOOD, KEYS.TIER1 },
        room_choices = {
            ["Blank"] = 1,
        },
        room_bg = WORLD_TILES.GRASS,
        background_room = "Blank",
        colour = { r = 0, g = 1, b = 0, a = 1 }
    })

    AddLevelPreInitAny(function(level)
        if level.location == "cave" then
            level.overrides.keep_disconnected_tiles = true

            level.tasks = { "CaveExitTask1" }
            -- table.insert(level.tasks, "HamArchiveMaze")
            level.numoptionaltasks = 0
            level.optionaltasks = {}

            level.set_pieces = {}
        end


        if level.location == "forest" then
            level.tasks = { "Make a new pick" }
            level.overrides.start_location = "BlankStart"
            level.valid_start_tasks = { "Make a new pick" }

            level.numoptionaltasks = 0
            level.set_pieces = {} --用新的地形但不执行这一行就会报错，因为这是要在特定地形插入彩蛋
            level.set_pieces["CaveEntrance"] = { count = 1, tasks = { "Make a new pick" } }
            level.overrides = {}
            level.overrides.layout_mode = "LinkNodesByKeys"
            level.required_setpieces = {}

            level.random_set_pieces = {}
            level.ordered_story_setpieces = {}
            level.numrandom_set_pieces = 0

            level.ocean_population = nil       --海洋生态 礁石 海带之类的 还有奶奶岛,帝王蟹和猴岛
            level.ocean_prefill_setpieces = {} -- 巨树和盐矿的layout

            level.overrides.keep_disconnected_tiles = true
            level.overrides.roads = "never"
            level.overrides.birds = "never"  --没鸟
            level.overrides.has_ocean = true --没海  ----如果设置了有海的话会清除所有非地面地皮然后根据规则重新生成
            level.required_prefabs = {}      -----这个是为了检测是否有必要的prefabs
        end
    end)
end
