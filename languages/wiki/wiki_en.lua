local WikiDesc = {
    -- Mechanics
    generation = {
        world = {
            name = "World Settings",
            intro = [[This mod only retains the [Shipwrecked] and [Hamlet] portions.
                    Players can experience vanilla DST content, Shipwrecked,
                    and Hamlet content simultaneously in the same world ([No world-hopping required]).
                    ----------------
                    The world's default starting area is [Hamlet].
                    Marble setpieces will spawn randomly across the entire map.
                    Other content, such as the Stagehand (Stageplay), Junkyard, and Balatro machine, will spawn in the starting location's area.
                    ----------------
                    When generating a world via the client, please adjust settings through the [Forest & Caves tab].
                    For dedicated servers, please [generate the world via the client] first, then upload the save to the server.]]
        },
        seasons = {
            name = "Seasons",
            intro =
            [[Seasons change according to the [Region]. The Reign of Giants region features Autumn, Winter, Spring, and Summer.
                    The Shipwrecked region features Mild, Hurricane, Monsoon, and Dry seasons.
                    The Hamlet region features Temperate, Humid, and Lush seasons.
                    ----------------
                    [Filters], [Music], and other effects will switch dynamically based on the region and season.]]
        },

        bundled_structure = {
            intro = [[Pack the [playerhouse_city] or other [Shops] with internal spaces
                    into a [bundled_structure] by [Hammering] them.
                    The [bundled_structure] will preserve all items inside the building.
                    ----------------
                    Simply place the [bundled_structure] back on the ground to restore the property, allowing for easy relocation.
                    Note: This action [cannot cross between different worlds].
            ]]
        },

        house_extension = {
            name = "House Extension",
            intro = [[Inside a [playerhouse_city], craft various interior doors (such as [wood_door], [curtain_door], [iron_door], and [stone_door]) using [oinc] under [Interior Technology].
                    ----------------
                    【Multi-Directional Expansion】: Doors can be constructed on any room wall (back wall, left wall, right wall, or front wall to exit outside). No longer restricted to a single back-wall branch, rooms can now be expanded in all directions across a 2D coordinate grid.
                    ----------------
                    【Expansion & Inheritance】:
                    1. Room Linking: If an adjacent room already exists in that direction, the newly built door automatically establishes a bidirectional link.
                    2. New Room: If unlinked, give a [construction_permit] to the door to expand into a new room.
                    3. Dynamic Inheritance: Newly generated extension rooms dynamically inherit the main house's shell dimensions (width & depth), wall/floor surface styles, layout perimeter, and dedicated interior camera profile, seamlessly matching the master room rather than using a cramped fixed preset.
                    ----------------
                    【Demolition & Renovation】:
                    1. Native Fixtures Demolition: All natively generated furniture, shelves, and wall ornaments inside player houses can be dismantled directly with a standard [hammer] without permits to free up DIY renovation space; shelves will safely drop stored items without loss upon destruction.
                    2. Room Demolition: To dismantle an entire leaf extension room, offer a [demolition_permit] to the room center beacon. The room will collapse safely and players inside will be relocated to the connected room. Doors can also be hammered down.
                    ----------------
                    【Minimap & Visuals】: The interior minimap aligns seamlessly with the HUD frame and progressively reveals rooms as you explore them. Each room retains isolated camera angles, and wall decorations (paintings, wall fish, windows) feature precise depth sorting and adjustable placement heights.]]
        },
        volcano = {
            name = "Volcano & Eruptions",
            intro = [[The Volcano exists as an [independent island] in deep ocean waters. Its interior features the Volcano Altar, obsidian deposits, cacti, and rare [coffeebeans] plants.
                    ----------------
                    【High Temperatures】: Ambient heat inside the Volcano is significantly higher than other regions; overheating protection is essential.
                    ----------------
                    【Dry Season Activity & Warnings】: During the Shipwrecked [Dry Season], the Volcano enters an active cycle. Pre-eruption phases trigger earth tremors, ash fall, and smoke warnings.
                    ----------------
                    【Dragonegg Meteor Rain】: Once fully erupting, burning dragonegg meteors rain down from the sky, inflicting massive destructive area damage, igniting flammable objects, and leaving lava pools or dragoon hatchlings.
                    ----------------
                    【Altar Appeasement】: Offerings of eggs, [obsidian], and monster meat at the [volcano_altar] (Volcano Altar) delay eruptions and soothe the Volcano; avoid offering unlisted junk.]]
        },
        waves = {
            name = "Waves",
            intro = [[Waves will rock the [Ship], but better vessels and [Bumpers] will reduce the impact.
                    For specific wave-breaking efficiency of various boats and bumpers, see the [Boats (Multiplayer)] section.]]
        },

        floods = {
            name = "Flooding & Puddles",
            intro = [[A primary seasonal survival hazard during the Shipwrecked and Hamlet Monsoon/Rainy seasons.
                    ----------------
                    【Puddle Expansion】: Persistent seasonal rainfall causes puddles to form on low ground and continuously expand across the land until the late rainy season.
                    ----------------
                    【Hazardous Effects】:
                    1. Movement Slowdown & Wetness: Walking through floodwater inflicts a severe movement speed penalty and rapidly spikes player wetness.
                    2. Structure Malfunction: Flooded structures—including Crock Pots, Science Machines, Ice Boxes, and Smelters—short-circuit, smoke, and temporarily cease functioning.
                    3. Poison Mosquitoes: Flooded waters continuously breed hostile [mosquito_poison], posing a severe poisonous swarm threat.
                    ----------------
                    【Defense & Recession】: Building [sandbag_item] (Sandbags) along camp perimeters blocks floodwater from encroaching into base structures. Once the rainy season ends, floodwater gradually dries up and submerged facilities resume operation.]]
        },
        ruins = {
            name = "Ruins",
            intro = [[The Ruins are no longer room-based mazes on the surface. Instead, they [Generate Underground]
                    overhauled into an expansive subterranean labyrinth similar to the Ancient [Archive].
                    ----------------
                    An [ancient_herald] spawns beside the wishing well at the Ruins entrance every 15 days.
                    The labyrinth features corridors, crossroads, guard chambers, and secret treasure rooms filled with dart statues (linked with basalt mining triggers, depleted visuals), spear traps, and sleeping pressure plates, leading deep into the [aporkalypse_clock]. Teleportation through walls is restricted.
                    ----------------
                    The [CAVE_EXIT] near the Ruins leads to [Snake Island (also Poison Island)].
                    The underground Hamlet region connects to the [Green Mushroom Forest] of the DST caves.]]
        },

        anthill = {
            name = "Anthill",
            intro = [[The Anthill is no longer a surface-generated room maze, but an area within the caves.
                    ----------------
                    The [CAVE_EXIT] near the Anthill leads to the [Palace City].
                    It connects to the [Green Mushroom Forest] via the underground Hamlet region.]]
        },

        aporkalypse = {
            name = "Aporkalypse",
            intro = [[By default, the Aporkalypse begins when the world reaches Day 120.
                    During the Aporkalypse, the entire world turns blood-red.
                    [Underground], [ancient_herald] and [vampirebat] will spawn periodically; [Surface] will only spawn [vampirebat].
                    ----------------
                    The [aporkalypse_clock] is located deep within the [Hamlet Ruins Maze] in the caves.
                    Turn the [aporkalypse_clock] to stop the Aporkalypse.
                    ----------------
                    Now it is compatible with [Don't Starve Alone].]]
        },

        bermudatriangle = {
            name = "Bermuda Triangle",
            intro = [[Paired mysterious oceanic vortexes spawned in deep ocean waters.
                    ----------------
                    Sailing through with a [solo boat] or jumping in smoothly teleports you to the paired vortex across the sea with thunder and wave audio.
                    Includes entity validity checks and dismount safeguards, eliminating falling into deep water and drowning.]]
        },

        ocean_boundary = {
            name = "Ocean Boundary Wrapping",
            intro = [[Faithfully restores the classic Shipwrecked planetary circumnavigation mechanism.
                    ----------------
                    Whether piloting a solo boat or a multiplayer ship, sailing to the world edge triggers offshore fog and camera transitions, seamlessly wrapping to the opposite edge of the map.]]
        },
    },

    -- Structures (Including all shops)
    structures = {
        pugalisk_fountain = {
            intro = [[During a [Full Moon], if no [pugalisk] is currently alive in the world,
                    moonlight will refill the [pugalisk_fountain].
                    Once a player takes the [waterdrop] from the [pugalisk_fountain], it will spawn a [pugalisk].
                    ----------------
                    [waterdrop] can be planted and provides Sanity restoration.
                    ----------------
                    Defeating the [pugalisk] will drop the crafting blueprint for the [pugalisk_fountain].
                    ----------------
                    Man-made [pugalisk_fountain] structures are more powerful, offering cooling,
                    lightning and rain protection, and Sanity restoration.]]
        },
        pig_palace = {
            intro = [[The [pigman_queen] in the main hall can trade for the [pedestal_key].
                    The [pedestal_key] can be used at display cases in the side halls to exchange for rare items.
                    Examples include [key_to_city], [city_hammer], and [TRINKET_GIFTSHOP_4].]]
        },
        pig_shop_cityhall = {
            intro =
            [[[pigman_mayor] acts as a trading NPC, accepting [goldnugget], [oinc], [dubloon], and other materials.
                    ----------------
                    Inside the City Hall, you can also exchange for items like [deed] and [securitycontract] via display cases.]]
        },
        playerhouse_city = {
            intro = [[Inside, you can craft items via [Interior Tech] to upgrade the house's decor and appearance. You can also construct doors on walls for [house_extension] (House Extension).]]
        },
        pig_shop_deli = {
            intro = [[Sells high-end cuisine, including [ratatouille], [meatballs], and the expensive [dragonpie].
                    ----------------
                    An excellent place to stock up on cost-effective food.]]
        },
        pig_shop_general = {
            intro = [[Provides basic tools. Sells [axe], [pickaxe], [minerhat], and [umbrella].
                    ----------------
                    Also sells common household supplies like [fabric] and [flint].]]
        },
        pig_shop_hoofspa = {
            intro = [[The town pharmacy. Offers [healingsalve], [bandage], and [antivenom].
                    ----------------
                    If you have enough money, you can even buy a [lifeinjector].]]
        },
        pig_shop_produce = {
            intro = [[Sells fresh ingredients such as [meat], [eggplant], [pumpkin], and [watermelon].
                    ----------------
                    Perfect for taking back to camp to use in the Crock Pot.]]
        },
        pig_shop_florist = {
            intro = [[Sells plant seeds and vegetation, including [corn_seeds], [pumpkin_seeds], and [dug_berrybush].
                    ----------------
                    Also provides [flowerhat] and various decorative plants.]]
        },
        pig_shop_antiquities = {
            intro = [[The most precious shop in Hamlet. Sells [gears], [mandrake], and [deerclops_eyeball].
                    ----------------
                    You can even directly purchase boss drops like [dragon_scales].]]
        },
        pig_shop_academy = {
            intro = [[A place of learning. Sells [malbatross_feather], [trunk_summer], and [shark_fin].
                    ----------------
                    This is your source of materials for researching high-tier tech like the [townportaltalisman].]]
        },
        pig_shop_arcane = {
            intro = [[Sells magical items, including [icestaff], [firestaff], and [nightsword].
                    ----------------
                    Also provides [blueamulet] and the essential [livinglog].]]
        },
        pig_shop_weapons = {
            intro = [[Sells various armaments, including [halberd], [cutlass], and [blowdart_pipe].
                    ----------------
                    [coconade] and various [trap] items are also best-sellers here.]]
        },
        pig_shop_hatshop = {
            intro = [[The fashion center. Sells [tophat], [beefalohat], and the rare [walrushat].
                    ----------------
                    The [sewing_kit] is a must-have for any gentleman to maintain their dignity.]]
        },
        pig_shop_bank = {
            intro = [[The currency center. Responsible for currency exchange and selling some minerals.
                    ----------------
                    The [pigman_banker] oversees all the wealth.]]
        },
        pig_shop_tinker = {
            intro = [[The Blueprint Shop. Sells various rare blueprints.]]
        },
        seaworthy = {
            name = "Seaworthy",
            intro = [[Cross-world marine transit device. Repairing a broken Seaworthy requires 4 [transistor] and 4 [gears].
                    ----------------
                    Building from scratch requires 4 [nightmarefuel], 4 [livinglog], 1 [sunken_boat_trinket_4], 4 [transistor] and 4 [gears]. The defeated Quacken's [krakenchest] always contains one [sunken_boat_trinket_4].
                    ----------------
                    Hammering a broken chair returns 4 [nightmarefuel], 4 [livinglog], 1 [sunken_boat_trinket_4] and any contributed upgrade materials. Hammering a repaired chair returns all crafting materials.
                    ----------------
                    Sit and right-click to open the navigation menu and warp instantly between known world points. Consumes only a small amount of sanity with smooth screen fades.]]
        },
        skyworthy = {
            name = "Skyworthy",
            intro = [[Cross-world aerial transit device. Repairing a broken Skyworthy requires 4 [transistor] and 4 [gears].
                    ----------------
                    Building from scratch requires 4 [nightmarefuel], 4 [livinglog], 1 [trinket_giftshop_4], 4 [transistor] and 4 [gears].
                    ----------------
                    Hammering a broken chair returns 4 [nightmarefuel], 4 [livinglog], 1 [trinket_giftshop_4] and any contributed upgrade materials. Hammering a repaired chair returns all crafting materials.
                    ----------------
                    Sit and right-click to open the transit menu and teleport between the mainland, Hamlet, and other known nodes. Consumes only a small amount of sanity with smooth screen fades.]]
        },
        sprinkler = {
            name = "Sprinkler",
            intro = [[Hamlet agricultural irrigation facility. Consumes fuel to spray cool water mist across a wide radius.
                    ----------------
                    Effectively prevents crops and plants from withering in hot seasons, and rapidly rejuvenates withered plants back to life.]]
        },
        volcano_altar = {
            name = "Volcano Altar",
            intro = [[Ancient altar of snackrifice situated inside the Volcano.
                    ----------------
                    During the dry season, offering eggs, [obsidian], or [monstermeat] soothes the volcano and postpones eruptions. Offering unlisted junk enrages the altar, triggering earthquakes and falling rocks.]]
        },
    },

    -- Mobs
    mobs = {
        firetwister = { intro = [[Spawns in the Volcano region. A fire-elemental variant of the [twister].]] },
        twister = { intro = [[A seasonal threat in the Hamlet and Shipwrecked regions.]] },
        slipstor = { intro = [[A peculiar creature found in the Jungle region.]] },
        wildboreking = { intro = [[Similar to the [pigking]; trades for gold but is aggressive.]] },
        ancient_herald = {
            name = "Ancient Herald",
            intro = [[Harbinger of the Aporkalypse.
                    ----------------
                    In addition to invading during the Aporkalypse, a dedicated spawner at the cave Hamlet ruins entrance wishing well summons an Ancient Herald every 15 days.
                    ----------------
                    Defeating it drops the crafting blueprint for the [ARMORVORTEXCLOAK] (Vortex Cloak), shadow rags, and nightmare fuel.]]
        },
        pugalisk = {
            intro = [[During a Full Moon, it spawns from the [pugalisk_fountain].
                    ----------------
                    Defeating it drops the blueprint for the [pugalisk_fountain].]]
        },
        kraken = {
            intro = [[A deep-sea behemoth. The first [messagebottle_sw] you open can locate its nest.
                    ----------------
                    Its reward [krakenchest] always contains one [sunken_boat_trinket_4], used to build a Seaworthy from scratch.]]
        },

        pigman_mayor = {
            intro = [[The administrator. Purchases gold products like [goldnugget] and [goldenbar].]]
        },
        pigman_queen = {
            intro = [[The supreme ruler. Highly interested in the [pigcrownhat], [pig_scepter], and [relic_4].]]
        },
        pigman_beautician = {
            intro = [[Has an obsessive love for feathers. You can sell [peagawkfeather] and [feather_robin] to her.]]
        },
        pigman_florist = {
            intro = [[An environmentalist. Purchases [petals], [foliage], and [succulent_picked].]]
        },
        pigman_erudite = {
            intro = [[An occultist. Specializes in purchasing [nightmarefuel].]]
        },
        pigman_hatmaker = {
            intro = [[Needs large amounts of [silk] to craft various marvelous hats.]]
        },
        pigman_storeowner = {
            intro = [[Frugal and diligent. Will buy [clippings] obtained from trimming city greenery.]]
        },
        pigman_banker = {
            intro = [[High-end trader. Purchases various expensive gems like [redgem] and [bluegem].]]
        },
        pigman_collector = {
            intro = [[Enjoys collecting toys like [trinket_1], as well as [stinger] and [spidergland].]]
        },
        pigman_hunter = {
            intro = [[A brave hunter. Will buy [houndstooth] and [hippo_antler].]]
        },
        pigman_professor = {
            intro = [[Antiquities expert. You can bring him cultural relics like [relic_1] excavated from the Ruins.]]
        },
        pigman_usher = {
            intro = [[Loves sweets. Purchases [honey], [jammypreserves], and [waffles].]]
        },
        pigman_farmer = {
            intro = [[Collector of basic resources. Purchases [cutgrass] and [twigs].]]
        },
        pigman_miner = {
            intro = [[Ore enthusiast. Earn rewards by selling [rocks] to him.]]
        },
        pigman_mechanic = {
            intro = [[Master of engineering. Purchases processed [boards], [cutstone], and [rope].]]
        },
        pigman_royalguard = {
            intro = [[Guardian of order. Can be hired as a bodyguard using a [securitycontract].]]
        },
        tigershark = {
            name = "Tiger Shark",
            intro = [[Classic apex amphibious predator from Shipwrecked.
                    ----------------
                    During monsoon season, it nests at the Tiger Shark Pool to rear [sharkitten] cubs. Features dual combat forms: underwater lunges and terrestrial body slams.
                    World-scope respawn tracking. Defeating it drops raw fish, tiger shark skins, and feathers.]]
        },
        doydoy = {
            name = "Doydoy",
            intro = [[Endangered exotic bird native to Shipwrecked.
                    ----------------
                    Features genetic gender inheritance and mating mechanics. Breeding willingness increases as the population declines, but with fewer than 2 left they face extinction.
                    Nests and lays eggs over time. Protect eggs from carnivores.]]
        },
    },

    -- Items
    items = {
        ship = {
            name = "Solo Boats",
            intro = [[Personal vessels rebuilt from the ground up for DST.
                    Place a boat on water and board directly; containers and equipment are managed via the boat container.
                    ----------------
                    【Dual Equipment Slots】: Stern slot supports sails, propellers, and [trawlnet]; bow slot supports [boatlantern], [boatcannon], and the [quackeringram].
                    ----------------
                    【Durability & Repair】: Recorded in boathealth; repairable with Boat Repair Kits, Winona's Tape, Sewing Kits, and the Sea Yard.
                    ----------------
                    【Safety Protection】: Rebuilt sailor/sailable logic completely fixes drowning bugs during reconnects and save loading. Cleans up save data on dismount to prevent ghost boats; supports ocean boundary wrapping and [bermudatriangle] teleportation.]]
        },
        boat = {
            name = "Boat (Multiplayer)",
            intro = [[A vehicle for cooperative sailing. Can be equipped with [Bumpers] to resist wave impact.
                    ----------------
                    DST Boats: [boat], [boat_pirate], [boat_ancient], and [boatmetal] reduce wave impact by 30%, 30%, 40%, and 90% respectively.
                    ----------------
                    Bumpers: [BOAT_BUMPER_KELP], [BOAT_BUMPER_SHELL], [BOAT_BUMPER_YOTD], and [BOAT_BUMPER_CRABKING] reduce impact from the installed direction by 60%, 80%, 80%, and 100% respectively.]]
        },
        trawlnet = {
            name = "Trawl Net",
            intro = [[Stern slot equipment for solo boats. Scans behind the boat during travel and gathers targets into net storage.
                    ----------------
                    【Diverse Catches】: Gathers floating items, ocean fish, fish shoals, lobsters, jellyfish, rainbow jellyfish, seaweed stalks, bull kelp roots, and trawlable objects.
                    ----------------
                    【Capacity & Balance】: Catches 1 item per scan cycle with a brief cooldown. Fullness applies up to a 20% speed penalty. Automatically drops as a floating [trawlnetdropped] container at 9 items. World migration and unequip safeguards.]]
        },
        smelter = {
            name = "Smelter",
            intro = [[An advanced facility for smelting [iron], [goldnugget], or refining ores.
                    Smelting recipes can be viewed through the [Smart Cooking] mod.]]
        },
        quackeringram = {
            name = "Quacken Ram",
            intro = [[Bow ramming equipment for solo boats, crafted from a Quacken beak and gears.
                    ----------------
                    Ramming waves or hostile creatures inflicts massive damage and knockback, granting the pilot a momentary speed boost. Consumes durability per hit.]]
        },
        boatcannon = {
            name = "Boat Cannon",
            intro = [[Bow-mounted naval ordnance for solo boats.
                    ----------------
                    Right-click to aim and fire cannonballs across water at foes for area explosive damage. Also features an obsidian cannon variant with incendiary blasts.]]
        },
        boatlantern = {
            name = "Boat Lantern",
            intro = [[Bow lighting equipment for solo boats.
                    ----------------
                    Provides mobile illumination during night and cave navigation, freeing up hand slots. Can be refueled. Also includes a basic [boattorch] variant.]]
        },
        sail = {
            name = "Sails",
            intro = [[Stern propulsion equipment for solo boats.
                    ----------------
                    Includes Thatch Sail, Cloth Sail, Snakeskin Sail, Feather Sail, and the [ironwind] propeller. Significantly boosts sailing speed and tailwind acceleration.]]
        },
        key_to_city = {
            name = "Key to the City",
            intro = [[Hamlet urban planning badge obtained from the Palace display cases.
                    ----------------
                    Grants mayoral construction privileges, allowing players to build pig town shops, houses, lampposts, and guard watchtowers outdoors.]]
        },
        city_hammer = {
            name = "City Hammer",
            intro = [[Municipal demolition tool paired with the Key to the City.
                    ----------------
                    Used to safely dismantle player-built town structures and reclaim construction materials.]]
        },
    },
}

local WikiTerms = {
    -- Terms
    type = "Type",
    recipe = "Recipe",
    unable_to_craft = "Unable to Craft",
    friendly = "Friendly",
    hostile = "Hostile",
    location = "Location",
    desc = "Description",
    attitude = "Faction",
    unknown = "Unknown",
    about = "Announcement",
    generation = "Mechanics",
    structures = "Structures",
    mobs = "Creatures",
    items = "Items",
    related = "Related Items",
    -----------
    mod_background = "Dev Background",
    mod_progress = "Update Log",
    mod_about = "Tropical Adventure | Ship of Theseus",
    mod_preview = "Foreword",
    mod_sponser = "Donate & Support US !!",
    mod_sponser_list = "Sponser List",

    --------
    click_to_read = "Click to view 'Tropical Adventure' Wiki",
    drag = "drag",
    reset = "reset",
    zoom = "zoom",
}

return {
    WikiDesc = WikiDesc,
    WikiTerms = WikiTerms,
}
