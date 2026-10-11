local wiki_string
local wiki_about

if TUNING.LANGUAGE_CHINESE then
    wiki_string = modrequire("languages/wiki/wiki_ch")
    wiki_about = modrequire("languages/wiki/about_ch")
else
    wiki_string = modrequire("languages/wiki/wiki_en")
    wiki_about = modrequire("languages/wiki/about_en")
end

local wiki_desc = wiki_string.WikiDesc
local wiki_terms = wiki_string.WikiTerms
local wiki_about = wiki_about.WikiAbout

local dstgen_atlas = "images/worldgen_customization.xml"
local dstset_atlas = "images/worldsettings_customization.xml"
local dst_atlas = "images/customisation.xml"
local sw_atlas = "images/hud/customization_shipwrecked.xml"
local ham_atlas = "images/hud/customization_porkland.xml"

local desc_contents = {

    ------------------------------------------------
    -- 机制
    ------------------------------------------------

    ["generation"] = {
        world = {
            priority = 1,
            y_offset = 200,
            desc_tex = "blank_world.tex",
            desc_atlas = sw_atlas,
        },

        seasons = {
            priority = 2,
            y_offset = 200,
            desc_tex = "blank_world.tex",
            desc_atlas = dst_atlas,
        },

        bundled_structure = {
            priority = 3,
            y_offset = 200,
            -- desc_tex = "blank_world.tex",
            -- desc_atlas = dst_atlas,
        },

        house_extension = {
            priority = 3.5,
            y_offset = 200,
            desc_tex = "curtain_door.tex",
            -- desc_atlas = "images/quagmire_recipebook.xml",
            related_items = { "construction_permit", "demolition_permit", "curtain_door", "wood_door", "hammer" },
        },

        ruins = {
            priority = 4,
            desc_build = "pig_ruins_entrance_build",
            desc_bank = "pig_ruins_entrance",
            desc_anim = "hit_low",
            resize = 0.5,
            speed = 0.2,
            y_offset = 10,
            desc_tex = "small_ruins.tex",
            desc_atlas = ham_atlas,

        },

        anthill = {
            priority = 4.5,
            desc_build = "ant_hill_entrance",
            desc_bank = "ant_hill_entrance",
            desc_anim = "idle",
            resize = 0.4,
            -- speed = 1,
            y_offset = 0,
            desc_tex = "mant_comb_homes.tex",
            desc_atlas = ham_atlas,

        },

        volcano = {
            priority = 5,
            desc_build = "volcano",
            desc_bank = "volcano",
            desc_anim = "erupt",
            resize = 0.15,
            y_offset = -70,
            desc_atlas = sw_atlas,
            related_items = { "volcano_altar", "obsidian", "dragoonheart", "coffeebeans" },
        },

        floods = {
            priority = 6,
            desc_build = "flood",
            desc_bank = "flood",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -30,
            desc_tex = "sandbag_item.tex",
            desc_atlas = "images/inventoryimages/inventory_shipwrecked.xml",
            related_items = { "sandbag_item", "mosquito_poison" },
        },

        waves = {
            priority = 7,
            y_offset = 200,
            desc_tex = "waves.tex",
            desc_atlas = sw_atlas,
        },

        aporkalypse = {
            priority = 8,
            y_offset = 200,
            desc_atlas = ham_atlas,
        },

        bermudatriangle = {
            priority = 9,
            desc_build = "bermudatriangle",
            desc_bank = "bermudatriangle",
            desc_anim = "idle_loop",
            resize = 0.35,
            y_offset = -40,
            desc_tex = "bermudatriangle.tex",
            desc_atlas = sw_atlas,
        },

        ocean_boundary = {
            priority = 10,
            y_offset = 200,
            desc_tex = "waves.tex",
            desc_atlas = sw_atlas,
        },
    },



    ------------------------------------------------
    -- 雕塑建筑
    ------------------------------------------------

    ["structures"] = {
        pugalisk_fountain = {
            priority = 1,
            desc_build = "python_fountain_lunar",
            desc_bank = "fountain",
            desc_anim = "flow_loop",
            resize = 0.4,
            y_offset = -50,
            -- type = "雕塑",
            -- recipe = {{"opalpreciousgem", 1}, {"featherhat", 1}, {"marble", 3}}
        },

        playerhouse_city = {
            priority = 11,
            desc_build = "pig_house_sale",
            desc_bank = "pig_house_sale",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            -- desc_tex = "small_ruins.tex"
            related_items = { "construction_permit", "demolition_permit", "curtain_door", "wood_door" },
        },

        pig_palace = {
            priority = 12,
            desc_build = "palace",
            desc_bank = "palace",
            desc_anim = "idle",
            resize = 0.3,
            y_offset = -120,
            related_items = {
                "pedestal_key", "key_to_city", "city_hammer", "TRINKET_GIFTSHOP_4",
                "TRINKET_GIFTSHOP_3", "TRINKET_GIFTSHOP_1",
                --MOONROCKSEED
            },
        },



        pig_shop_deli = {
            priority = 15,
            desc_build = "pig_shop_deli",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "ratatouille", "monsterlasagna", "pumpkincookie", "stuffedeggplant",
                "frogglebunwich", "honeynuggets", "perogies", "waffles",
                "meatballs", "honeyham", "turkeydinner", "dragonpie"
            },
        },
        pig_shop_general = {
            priority = 16,
            desc_build = "pig_shop_general",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "pitchfork", "shovel", "pickaxe", "axe", "flint",
                "machete", "minerhat", "razor", "backpack", "umbrella",
                "hammer", "fabric", "bugnet", "fishingrod"
            },
        },
        pig_shop_hoofspa = {
            priority = 17,
            desc_build = "pig_shop_hoofspa",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "blue_cap", "green_cap", "bandage", "healingsalve",
                "antivenom", "coffeebeans", "lifeinjector"
            },
        },
        pig_shop_produce = {
            priority = 18,
            desc_build = "pig_shop_produce",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "berries", "radish", "sweet_potato", "carrot", "drumstick",
                "eggplant", "corn", "pumpkin", "meat", "pomegranate",
                "cave_banana", "coconut", "froglegs", "watermelon",
                "berries_juicy", "garlic", "onion", "pepper", "potato", "tomato"
            },
        },
        pig_shop_florist = {
            priority = 19,
            desc_build = "pig_shop_florist",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "corn_seeds", "eggplant_seeds", "garlic_seeds", "onion_seeds",
                "pepper_seeds", "pumpkin_seeds", "dragonfruit_seeds", "durian_seeds",
                "pomegranate_seeds", "watermelon_seeds", "flowerhat", "acorn",
                "pinecone", "dug_berrybush2", "dug_berrybush"
            },
        },
        pig_shop_antiquities = {
            priority = 20,
            desc_build = "pig_shop_antiquities",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "silk", "gears", "mandrake", "wormlight", "deerclops_eyeball",
                "walrus_tusk", "bearger_fur", "goose_feather", "dragon_scales",
                "houndstooth", "bamboo", "horn", "coontail", "lightninggoathorn", "ox_horn"
            },
        },
        pig_shop_academy = {
            priority = 21,
            desc_build = "pig_shop_accademia",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "townportaltalisman", "malbatross_feather", "trunk_summer",
                "deer_antler", "shark_gills", "gnarwail_horn", "shark_fin", "steelwool"
            },
        },
        pig_shop_arcane = {
            priority = 22,
            desc_build = "pig_shop_arcane",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "icestaff", "firestaff", "amulet", "blueamulet",
                "purpleamulet", "livinglog", "armorslurper", "nightsword",
                "armor_sanity", "onemanband"
            },
        },
        pig_shop_weapons = {
            priority = 23,
            desc_build = "pig_shop_weapons",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "spear", "halberd", "cutlass", "trap_teeth", "birdtrap",
                "trap", "coconade", "blowdart_pipe", "blowdart_sleep", "boomerang"
            },
        },
        pig_shop_hatshop = {
            priority = 24,
            desc_build = "pig_shop_millinery",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "winterhat", "tophat", "earmuffshat", "walrushat",
                "peagawkfeatherhat", "molehat", "catcoonhat", "captainhat",
                "antmaskhat", "featherhat", "strawhat", "beefalohat",
                "pithhat", "thunderhat", "metalplatehat", "sewing_kit"
            },
        },
        pig_shop_bank = {
            priority = 25,
            desc_build = "pig_shop_bank",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "goldenbar", "goldnugget", "dubloon", "oinc10", "oinc100", "lucky_goldnugget", "nitre"
            },
        },
        pig_shop_tinker = {
            priority = 26,
            desc_build = "pig_shop_tinker",
            desc_bank = "pig_shop",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -60,
            related_items = {
                "dragonflyfurnace", "pugalisk_fountain",
                "blue_mushroomhat", "red_mushroomhat",
                "green_mushroomhat", "bundlewrap",
                "trident", "honeychest",
                "townportal", "antlionhat"
            },
        },
        pig_shop_cityhall = {
            priority = 13,
            desc_build = "pig_cityhall",
            desc_bank = "pig_cityhall",
            desc_anim = "idle",
            resize = 0.5,
            y_offset = -150,
            related_items = {
                "deed", "securitycontract"
            },
        },

        seaworthy = {
            priority = 28,
            desc_build = "portal_shipwrecked_build",
            desc_bank = "boatportal",
            desc_anim = "idle_on",
            resize = 0.4,
            y_offset = -50,
            desc_atlas = "images/inventoryimages/inventory_shipwrecked.xml",
            desc_tex = "shipwrecked_entrance.tex",
            related_items = { "nightmarefuel", "livinglog", "sunken_boat_trinket_4", "transistor", "gears" },
        },

        skyworthy = {
            priority = 29,
            desc_build = "portal_hamlet_build",
            desc_bank = "hamportal",
            desc_anim = "idle_on",
            resize = 0.4,
            y_offset = -50,
            desc_atlas = "images/inventoryimages/inventory_hamlet.xml",
            desc_tex = "portal_ham.tex",
            related_items = { "nightmarefuel", "livinglog", "trinket_giftshop_4", "transistor", "gears" },
        },

        sprinkler = {
            priority = 30,
            desc_build = "sprinkler",
            desc_bank = "sprinkler",
            desc_anim = "idle_off",
            resize = 0.5,
            y_offset = -40,
            desc_tex = "sprinkler.tex",
            related_items = { "ice", "alloy", "bluegem" },
        },

        volcano_altar = {
            priority = 31,
            desc_build = "volcano_altar",
            desc_bank = "volcano_altar",
            desc_anim = "idle_close",
            resize = 0.4,
            y_offset = -50,
            desc_tex = "volcano_altar.tex",
            related_items = { "obsidian", "monstermeat", "bird_egg" },
        },
    },

    ------------------------------------------------
    -- 生物+群落
    ------------------------------------------------

    ["mobs"] = {


        kraken = {
            priority = 1,
            friendly = false,
            location = "spring in tropical region",
            desc_build = "quacken",
            desc_bank = "quacken",
            desc_anim = "idle_loop",
            resize = 0.4,
            speed = 0.5,
            y_offset = -80,
            desc_atlas = sw_atlas,
            related_items = { "sunken_boat_trinket_4" },

            -- desc_tex = "mant_queen.tex"
        },

        twister = {
            priority = 2,
            friendly = false,
            location = "spring in tropical region",
            desc_build = "twister_build",
            desc_bank = "twister",
            desc_anim = "idle_loop",
            resize = 0.5,
            speed = 0.5,
            y_offset = -50,
            desc_atlas = sw_atlas,

            -- desc_tex = "mant_queen.tex"
        },

        pugalisk = {
            priority = 3,
            friendly = false,
            location = "snake island",
            desc_build = "python_test",
            desc_bank = "giant_snake",
            desc_anim = "head_idle_loop",
            facing = "fixed",
            resize = 0.7,
            speed = 0.7,
            y_offset = -35,
            desc_atlas = ham_atlas,

        },

        ancient_herald = {
            priority = 4,
            friendly = false,
            location = "spring in tropical region",
            desc_build = "ancient_spirit",
            desc_bank = "ancient_spirit",
            desc_anim = "idle",
            facing = "fixed",
            resize = 0.7,
            speed = 0.5,
            y_offset = -60,
            desc_tex = "quagmire_recipe_menu_block.tex",
            desc_atlas = "images/quagmire_recipebook.xml",

            -- desc_tex = "mant_queen.tex"
        },

        firetwister = {
            priority = 5,
            friendly = false,
            location = "volcano region",
            desc_build = "twister_build",
            desc_bank = "twister",
            desc_anim = "idle_loop",
            animcolor = { 255 / 255, 100 / 255, 0 / 255, 1 },
            resize = 0.5,
            speed = 0.5,
            y_offset = -50,

            desc_tex = "twister.tex",
            desc_atlas = sw_atlas,
        },

        slipstor = {
            priority = 6,
            friendly = false,
            location = "spring in tropical region",
            desc_build = "slipstor_build",
            desc_bank = "slipstor",
            desc_anim = "idle_loop",
            resize = 0.9,
            speed = 0.5,
            y_offset = -50,
            desc_tex = "quagmire_recipe_menu_block.tex",
            desc_atlas = "images/quagmire_recipebook.xml",

            -- desc_tex = "mant_queen.tex"
        },

        wildboreking = {
            priority = 7,
            friendly = false,
            location = "spring in tropical region",
            desc_build = "pigkingext",
            desc_bank = "pigkingext",
            desc_anim = "idle",
            resize = 0.8,
            speed = 0.5,
            y_offset = -80,
            desc_tex = "quagmire_recipe_menu_block.tex",
            desc_atlas = "images/quagmire_recipebook.xml",

            -- desc_tex = "mant_queen.tex"
        },

        pigman_mayor = {
            priority = 10.1,
            desc_build = "pig_mayor",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "goldnugget", "goldenbar", "stonebar", "lucky_goldnugget", "dubloon" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_queen = {
            priority = 10.2,
            desc_build = "pig_queen",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "pigcrownhat", "pig_scepter", "relic_4", "relic_5", "opalpreciousgem" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },


        pigman_beautician = {
            priority = 10.3,
            desc_build = "pig_beautician",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "feather_crow", "feather_robin", "feather_robin_winter", "peagawkfeather", "doydoyfeather", "feather_thunder", "feather_canary" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_florist = {
            priority = 11,
            desc_build = "pig_florist",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "petals", "petals_evil", "succulent_picked", "foliage" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_erudite = {
            priority = 12,
            desc_build = "pig_erudite",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "nightmarefuel" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_hatmaker = {
            priority = 13,
            desc_build = "pig_hatmaker",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "silk" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_storeowner = {
            priority = 14,
            desc_build = "pig_storeowner",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "clippings" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_banker = {
            priority = 15,
            desc_build = "pig_banker",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "redgem", "bluegem", "purplegem", "greengem", "orangegem", "yellowgem" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_collector = {
            priority = 16,
            desc_build = "pig_collector",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "stinger", "silk", "mosquitosack", "chitin", "venus_stalk", "venomgland", "spidergland", "lotus_flower", "bill_quill", "trinket_1", "trinket_2", "trinket_3", "trinket_4", "trinket_5" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_hunter = {
            priority = 17,
            desc_build = "pig_hunter",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "houndstooth", "stinger", "hippo_antler" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },


        pigman_mechanic = {
            priority = 19,
            desc_build = "pig_mechanic",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "boards", "rope", "cutstone", "papyrus" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_professor = {
            priority = 20,
            desc_build = "pig_professor",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "relic_1", "relic_2", "relic_3" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_usher = {
            priority = 21,
            desc_build = "pig_usher",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "honey", "jammypreserves", "icecream", "pumpkincookie", "waffles", "berries" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_farmer = {
            priority = 22,
            desc_build = "pig_farmer",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "cutgrass", "twigs" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },

        pigman_miner = {
            priority = 23,
            desc_build = "pig_miner",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "rocks" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
        },



        pigman_royalguard = {
            priority = 25,
            desc_build = "pig_royalguard",
            desc_bank = "townspig",
            desc_anim = "idle_loop",
            resize = 1,
            y_offset = -50,
            related_items = { "spear", "spear_wathgrithr", "securitycontract" },
            oversymbolfn = function(item_anim)
                item_anim:GetAnimState():Hide("ARM_carry")
            end,
            desc_tex = "quagmire_recipe_menu_block.tex",
            desc_atlas = "images/quagmire_recipebook.xml",
        },

        tigershark = {
            priority = 28,
            friendly = false,
            desc_build = "tigershark_ground_build",
            desc_bank = "tigershark",
            desc_anim = "idle",
            resize = 0.35,
            speed = 0.6,
            y_offset = -60,
            desc_tex = "tigershark.tex",
            related_items = { "shark_gills", "fish" },
        },

        doydoy = {
            priority = 29,
            friendly = true,
            desc_build = "doydoy_adult_build",
            desc_bank = "doydoy",
            desc_anim = "idle",
            resize = 0.6,
            speed = 0.8,
            y_offset = -40,
            desc_tex = "doydoy.tex",
            related_items = { "doydoyegg", "doydoyfeather", "doydoynest" },
        },
    },

    ------------------------------------------------
    -- 道具+科技
    ------------------------------------------------

    ["items"] = {
        ship = {
            priority = 1,
            type = "道具",
            desc_build = "rowboat_cargo_build",
            desc_bank = "rowboat",
            desc_anim = "run_loop",
            y_offset = 30,
            resize = 0.8,
            desc_tex = "cargoboat.tex",
            related_items = { "boatrepairkit", "boatlantern", "boatcannon", "sail", "trawlnet", "quackeringram" },
        },

        boat = {
            priority = 2,
            type = "道具",

            y_offset = 200,
            desc_tex = "boat.tex",
        },

        trawlnet = {
            priority = 4,
            type = "道具",
            desc_build = "swap_trawlnet",
            desc_bank = "trawlnet",
            desc_anim = "idle",
            resize = 0.9,
            desc_tex = "trawlnet.tex",
            related_items = { "lobster", "jellyfish", "rainbowjellyfish", "oceanfish_small_1_inv", "bullkelp_root", "seaweed_stalk" },
        },

        smelter = {
            priority = 5,
            type = "道具",
            desc_build = "smelter",
            desc_bank = "smelter",
            desc_anim = "idle_empty",
            facing = "fixed",
            y_offset = -10,
            resize = 0.8,
        },

        quackeringram = {
            priority = 6,
            type = "道具",
            desc_build = "swap_quackeringram",
            desc_bank = "quackeringram",
            desc_anim = "idle",
            resize = 0.7,
            y_offset = 0,
            desc_tex = "quackeringram.tex",
            related_items = { "horn", "gears" },
        },

        boatcannon = {
            priority = 7,
            type = "道具",
            desc_build = "swap_cannon",
            desc_bank = "cannon",
            desc_anim = "idle",
            resize = 0.7,
            y_offset = 0,
            desc_tex = "boatcannon.tex",
            related_items = { "obsidian_boatcannon", "gunpowder" },
        },

        boatlantern = {
            priority = 8,
            type = "道具",
            desc_build = "swap_lantern_boat",
            desc_bank = "lantern_boat",
            desc_anim = "idle",
            resize = 0.8,
            y_offset = 0,
            desc_tex = "boatlantern.tex",
            related_items = { "boattorch", "bottlelantern" },
        },

        sail = {
            priority = 9,
            type = "道具",
            desc_build = "swap_sail",
            desc_bank = "sail",
            desc_anim = "idle",
            resize = 0.8,
            y_offset = 0,
            desc_tex = "sail.tex",
            related_items = { "clothsail", "snakeskinsail", "feathersail", "ironwind" },
        },

        key_to_city = {
            priority = 10,
            type = "道具",
            y_offset = 200,
            desc_tex = "key_to_city.tex",
            related_items = { "city_hammer", "playerhouse_city" },
        },

        city_hammer = {
            priority = 11,
            type = "道具",
            y_offset = 200,
            desc_tex = "city_hammer.tex",
            related_items = { "key_to_city", "hammer" },
        },
    },


}



for n, k in pairs(desc_contents) do
    if n ~= "about" then
        for u, v in pairs(k) do
            v.priority = v.priority or 99
            v.x_offset = v.x_offset or 0
            v.y_offset = v.y_offset or 0

            local desc_info = wiki_desc[n] and wiki_desc[n][u] or nil
            if desc_info then
                v.location = v.location or desc_info.location or "unknown"
                v.description = desc_info.intro or "unknown"
                v.name = desc_info.name or nil
            end
        end
    end
end

return {
    wiki_desc = desc_contents,
    wiki_terms = wiki_terms,
    wiki_about = wiki_about,
}
