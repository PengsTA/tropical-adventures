-- Exceptions to the automatic land (1), wetland (1), and open-ocean (2) tile buffers.
return function(rules)
    local function Buffer(prefabs, clearance, surface)
        for _, prefab in ipairs(prefabs) do
            rules.Register(prefab, { shore_clearance = clearance, surface = surface })
        end
    end

    Buffer({ "crabhole", "rock_limpet", "sanddune", "seashell_beached" }, 0, "land")
    Buffer({ "bullkelp_plant", "wobster_den", "moonglass_wobster_den", "wobster_den_spawner_shore" }, 0, "water")
    Buffer({ "seaweed_planted", "mussel_farm", "lobsterhole", "oceanvine", "oceantree" }, 1, "water")
    Buffer({ "lilypad" }, 3, "water")
    Buffer({ "coralreef", "coral_brain_rock", "octohouse", "octopusking", "ballphinhouse",
        "spidercoralhole", "seastack", "waterygrave", "wreck", "shipwreck", "tar_pool",
        "boatfragment01", "boatfragment02", "boatfragment03", "boatfragment04", "boatfragment05",
        "seastack_spawner_swell", "seastack_spawner_rough", "waterplant_spawner_rough" }, 3, "water")
    Buffer({ "kraken", "whale_bluefinal", "whale_white", "crabking", "crabking_spawner" }, 4, "water")

    for _, prefab in ipairs({ "fishinhole", "rock_coral", "messagebottle", "messagebottleempty", "messagebottle_sw" }) do
        rules.Register(prefab, { surface = "water" })
    end
    rules.Register("spiderden", {
        shore_clearance = 2,
        testfn = function(x, y, entities)
            return SpawnUtil.GetDistToSpawnPoint(x, y, entities) >= 100
        end,
    })
    rules.Register("tidalpool", {
        surface = "land", shore_clearance = 2,
        testfn = function(x, y, entities)
            return SpawnUtil.GetShortestDistToPrefab(x, y, entities, "tidalpool") >= 3 * TILE_SCALE
        end,
    })
    rules.Register("seashell_beached", {
        testfn = function(x, y) return SpawnUtil.IsCloseToWaterTile(x, y, 4) end,
    })
end
