local spreading = {}

local function Plant(name, tiles, water, product, aliases, family)
    local definition = {
        name = name,
        tiles = tiles,
        water = water == true,
        product = product or name,
        searchtag = "ta_regrowth_" .. (family or name),
        density = .2,
        aliases = aliases or {},
    }
    spreading[name] = definition
    for _, alias in ipairs(definition.aliases) do
        spreading[alias] = definition
    end
end

local function Tree(name, tiles, water, aliases)
    Plant(name, tiles, water, name .. "_short", aliases or {
        name .. "_short", name .. "_normal", name .. "_tall",
    })
end

Tree("jungletree", { "JUNGLE", "TIDALMARSH", "MAGMAFIELD" })
Tree("palmtree", { "BEACH" })
Tree("tree_mangrove", { "MANGROVE" }, true)
Tree("teatree", { "FIELDS" }, false, {
    "teatree_short", "teatree_normal", "teatree_tall", "teatree_piko_nest",
})
Tree("rainforesttree", { "RAINFOREST", "DEEPRAINFOREST", "DEEPRAINFOREST_NOCANOPY",
    "BATTLEGROUND_RAINFOREST_NOISE" }, false, {
    "rainforesttree_short", "rainforestree_normal", "rainforesttree_tall",
})
Tree("rainforesttree_rot", { "GASRAINFOREST" }, false, {
    "rainforesttree_rot_short", "rainforestree_rot_normal", "rainforesttree_rot_tall",
})
Tree("clawpalmtree", { "PLAINS", "SINKHOLE" })
Plant("tubertree", { "PAINTED", "ANTFLOOR" })

Plant("bambootree", { "JUNGLE" }, false, nil, { "bambootreebig" })
Plant("bush_vine", { "JUNGLE" })
Plant("coffeebush", { "VOLCANO", "VOLCANO_NOISE", "VOLCANO_ROCK", "ASH", "MAGMAFIELD" })
Plant("elephantcactus", { "VOLCANO", "VOLCANO_NOISE", "VOLCANO_ROCK", "ASH", "MAGMAFIELD" },
    false, nil, { "elephantcactus_active" })
Plant("nettle", { "DEEPRAINFOREST", "DEEPRAINFOREST_NOCANOPY", "GASRAINFOREST" })
Plant("grass_tall", { "PLAINS", "RAINFOREST", "SINKHOLE" })

Plant("seaweed_planted", { "OCEAN_SHALLOW", "OCEAN_SHALLOW_SHORE", "OCEAN_MEDIUM",
    "OCEAN_DEEP", "OCEAN_CORAL", "OCEAN_COASTAL", "OCEAN_COASTAL_SHORE", "OCEAN_SWELL",
    "OCEAN_ROUGH", "OCEAN_WATERLOG" }, true)
Plant("lotus", { "LILYPOND" }, true)
Plant("reeds_water", { "LILYPOND" }, true)
Plant("grasswater", { "LILYPOND", "MANGROVE" }, true)
Plant("watercress_planted", { "LILYPOND" }, true)
Plant("seataro_planted", { "MANGROVE" }, true)
Plant("seacucumber_planted", { "MANGROVE" }, true)
Plant("oceanbambootree", { "MANGROVE" }, true, nil, { "oceanbambootreebig" }, "bambootree")
Plant("oceanbush_vine", { "MANGROVE" }, true, nil, nil, "bush_vine")
Plant("grass_tallwater", { "LILYPOND", "MANGROVE" }, true, nil, nil, "grass_tall")

return {
    spreading = spreading,
    harvested = {
        -- Reported prefabs already emit beginregrowth before removing themselves.
        sweet_potato_planted = { reported = true },
        aloe_planted = {},
        asparagus_planted = {},
        radish_planted = {},
        turnip_planted = {},
        onion_planted = { reported = true },
        fennel_planted = { reported = true },
        grotto_parsnip_planted = { reported = true },
        flower_rainforest = { flower = true },
    },
}
