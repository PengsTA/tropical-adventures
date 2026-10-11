if TUNING.shipwrecked then
    AddRoomPreInit("OceanCoastalShore", function(room)
        -- room.contents.distributeprefabs.lobsterhole = 1
    end)

    AddRoomPreInit("OceanCoastal", function(room)
        tableutil.insert_indexes(room.contents.distributeprefabs, {
            messagebottle_sw = 0.1,
            seaweed_planted = 3,
            mussel_farm = 2,
            lobsterhole = 1 / 2,
            ballphinhouse = .1 / 2,
            solofish_spawner = 1 / 2,
            jellyfish_spawner = 1 / 2,
            rainbowjellyfish_spawner = 0.25 / 2,
            bioluminescence_spawner = 0.1
        })
        tableutil.insert_indexes(room.contents.countprefabs, {
            mermboat = 3
        })
    end)

    AddRoomPreInit("OceanSwell", function(room)
        tableutil.insert_indexes(room.contents.distributeprefabs, {
            messagebottle_sw = 0.1,
            ballphinhouse = 5,
            --  fishinhole = 5,
            -- jellyfish_spawner = 4 * 2,
            -- rainbowjellyfish_spawner = 1 * 2,
            -- solofish_spawner = 12 * 2,
            redbarrel = 1,
            -- barrel_gunpowder = 2,
            seagullspawner = 6,
            -- stungray_spawner = 8,
            oceanfog = 2,
            tar_pool = 1,
            bioluminescence_spawner = 5
        })

        room.contents.countprefabs = {
            oceanfish_shoalspawner = 3

        }

        -- tableutil.insert_indexes(room.contents.countstaticlayouts,
        --     {
        --         coralpool1 = 3,
        --         coralpool2 = 3,
        --         coralpool3 = 2,
        --         octopuskinghome = 1,
        --         mangrove1 = 2,
        --         mangrove2 = 1,
        --         wreck = 1,
        --         wreck2 = 1,
        --         kraken = 1,
        --     })
    end)

    AddRoomPreInit("OceanRough", function(room)
        tableutil.insert_indexes(room.contents.distributeprefabs, {
            --  fishinhole = 0.5,
            -- solofish_spawner = 0.2,
            -- ballphin_spawner = 0.2,
            -- swordfish_spawner = 0.2,
            redbarrel = 0.1,
            -- barrel_gunpowder = 1, -- redbarrel = 1,
            bioluminescence_spawner = .5,
            oceanfog = 0.1
        })
        room.contents.countprefabs = {
            luggagechest_spawner = 4,
            rawling = 1
        }
    end)

    AddRoomPreInit("OceanHazardous", function(room)
        room.contents.distributepercent = 0.3
        tableutil.insert_indexes(room.contents.distributeprefabs, {
            --  fishinhole = 3,
            waterygrave = 5,
            wreck = 4,
            seaweed_planted = 3,

            pirateghost = 4,
            redbarrel = 2,
            bishopwaterfixo = .5,
            rookwater = .5,
            knightboat = .5,

            luggagechest_spawner = .3,
            boatfragment01 = 1,
            boatfragment02 = 1,
            boatfragment03 = 1,
            whale_bluefinal = 1

        })
        room.contents.countprefabs = {
            kraken = 1
        }
    end)

    AddRoomPreInit("OceanBrinepool", function(room)
        tableutil.insert_indexes(room.contents.distributeprefabs, {

            coralreef = 0.5,
            ballphinhouse = .3,
            octohouse = .1,
            seaweed_planted = .5,
            spidercoralhole = 0.1,
            fishinhole = 0.5
            -- rock_coral = 1,
            -- ballphinhouse = .1,
            -- seaweed_planted = .3,
            -- jellyfish_planted = .3,
            -- rainbowjellyfish_planted = 0.2,
            -- solofish_spawner = .3,
        })
        room.contents.countprefabs = {
            coral_brain_rock = math.random(3, 5),
            octopusking = 1
        }
    end)
end
