local TECH = GLOBAL.TECH

---将a配方参照b配方位置重排
---@param a string 被排配方名
---@param b string 参照配方名
---@param filter_name string 配方分类名
---@param offset number 偏移量
local function SortRecipe(a, b, filter_name, offset)
	local filter = CRAFTING_FILTERS[filter_name]
	if filter and filter.recipes then
		for sortvalue, product in ipairs(filter.recipes) do
			if product == a then
				table.remove(filter.recipes, sortvalue)
				break
			end
		end

		local target_position = #filter.recipes + 1
		for sortvalue, product in ipairs(filter.recipes) do
			if product == b then
				target_position = sortvalue + offset
				break
			end
		end
		table.insert(filter.recipes, target_position, a)
	end
end

---将a配方重排到b配方之前
---@param a string 被排配方名
---@param b string 参照配方名
---@param filter_name string 配方分类名
local function SortBefore(a, b, filter_name)
	SortRecipe(a, b, filter_name, 0)
end

---将a配方重排到b配方之后
---@param a string 被排配方名
---@param b string 参照配方名
---@param filter_name string 配方分类名
local function SortAfter(a, b, filter_name)
	SortRecipe(a, b, filter_name, 1)
end


-- @author: Peng
--防止配方名称冲突
local old_addrecipe2 = AddRecipe2
AddRecipe2 = function(name, ingredients, tech, config, filters)
	-- if not filters then
	-- 	print("[WARNING] AddRecipe2: Recipe no filter: " .. name)
	-- end
	if not AllRecipes[name] then
		old_addrecipe2(name, ingredients, tech, config, filters)

		-- Handle sorting directly in AddRecipe2
		if config then
			if config.sort_before then
				for _, sort_config in ipairs(config.sort_before) do
					SortBefore(name, sort_config.recipe, sort_config.filter)
				end
			end
			if config.sort_after then
				for _, sort_config in ipairs(config.sort_after) do
					SortAfter(name, sort_config.recipe, sort_config.filter)
				end
			end
		end
	else
		local newname = name .. "_other"
		STRINGS.NAMES[string.upper(newname)] = (STRINGS.NAMES[string.upper(name)] or STRINGS.NAMES.UNKNOWN)
		if not config then config = {} end
		config.product = config.product or name
		AddRecipe2(newname, ingredients, tech, config, filters)
	end
end



---------新物品
AddRecipe2("pugaliskfountain_made",
	{ Ingredient("cutstone", 6), Ingredient("moonrocknugget", 10), Ingredient("bluegem", 2) },
	TECH.LOST, ----TECH.CITY_ONE,
	{

		-- nounlock = true,
		min_spacing = 3.2,
		placer = "pugaliskfountain_made_placer",
		image = "pugalisk_fountain.tex"
	},
	{ "STRUCTURES", "LEGACY", "SUMMER" })

AddRecipe2("seaworthy",
	{ Ingredient("nightmarefuel", 4), Ingredient("livinglog", 4), Ingredient("sunken_boat_trinket_4", 1),
		Ingredient("transistor", 4), Ingredient("gears", 4) },
	TECH.MAGIC_THREE,
	{
		min_spacing = 3.2,
		placer = "seaworthy_placer",
		atlas = "images/inventoryimages/inventory_shipwrecked.xml",
		image = "shipwrecked_entrance.tex",
	},
	{ "STRUCTURES", "MAGIC" })

AddRecipe2("skyworthy",
	{ Ingredient("nightmarefuel", 4), Ingredient("livinglog", 4), Ingredient("trinket_giftshop_4", 1),
		Ingredient("transistor", 4), Ingredient("gears", 4) },
	TECH.MAGIC_THREE,
	{
		min_spacing = 3.2,
		placer = "skyworthy_placer",
		atlas = "images/inventoryimages/inventory_hamlet.xml",
		image = "portal_ham.tex",
	},
	{ "STRUCTURES", "MAGIC" })

AddRecipe2("armorvortexcloak", { Ingredient("ancient_remnant", 5), Ingredient("armor_sanity", 1) }, TECH.LOST, {

	image = "armorvortexcloak.tex",
	sort_after = {
		{ recipe = "dreadstonehat", filter = "ARMOUR" },
		{ recipe = "dreadstonehat", filter = "MAGIC" },
		{ recipe = "seedpouch",     filter = "CONTAINERS" }
	}
}, { "ARMOUR", "MAGIC", "CONTAINERS" })

AddRecipe2("armorvoidcloak",
	{ Ingredient("armorvortexcloak", 1), Ingredient("horrorfuel", 4), Ingredient("voidcloth", 4),
		Ingredient("shadowheart", 1) }, TECH.SHADOWFORGING_TWO, {
		nounlock = true,

		image = "armorvoidcloak.tex",
		sort_after = {
			{ recipe = "voidclothhat", filter = "CRAFTING_STATION" }
		}
	}, { "CRAFTING_STATION" })
AddRecipe2("living_artifact", { Ingredient("infused_iron", 6), Ingredient("waterdrop", 1) }, TECH.LOST,
	{
		sort_after = {
			{ recipe = "armorvortexcloak", filter = "MAGIC" }
		}
	}, { "MAGIC", "ARMOUR" })
AddRecipe2("honeychest",
	{ Ingredient("chitin", 6), Ingredient("beeswax", 1), Ingredient("honey", 3) }, TECH.LOST,
	{

		min_spacing = 2,
		placer = "honeychest_placer"
	}, { "STRUCTURES", "CONTAINERS", "COOKING", "GARDENING" })

-- Character recipe with tag
-- WX78 Items for Tropical
AddRecipe2("wx78module_movespeed_sw",
	{ Ingredient("scandata", 2), Ingredient("crab", 1) }, TECH.ROBOTMODULECRAFT_ONE, {
		builder_tag = "upgrademoduleowner",
		product = "wx78module_movespeed",
		sort_after = {
			{ recipe = "wx78module_movespeed", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })

AddRecipe2("wx78module_movespeed_ham",
	{ Ingredient("scandata", 2), Ingredient("piko", 1) }, TECH.ROBOTMODULECRAFT_ONE, {
		builder_tag = "upgrademoduleowner",
		product = "wx78module_movespeed",
		sort_after = {
			{ recipe = "wx78module_movespeed_sw", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })

AddRecipe2("wx78module_maxhunger_sw",
	{ Ingredient("scandata", 3), Ingredient("shark_gills", 1), Ingredient("wx78module_maxhunger1", 1) },
	TECH.ROBOTMODULECRAFT_ONE, {
		builder_tag = "upgrademoduleowner",
		product = "wx78module_maxhunger",
		sort_after = {
			{ recipe = "wx78module_maxhunger", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })

AddRecipe2("wx78module_taser_ham",
	{ Ingredient("scandata", 5), Ingredient("feather_thunder", 1) }, TECH.ROBOTMODULECRAFT_ONE, {
		builder_tag = "upgrademoduleowner",
		product = "wx78module_taser",
		sort_after = {
			{ recipe = "wx78module_taser", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })

-- AddRecipe2("reno_window_greenhouse", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
-- 	{  nounlock = true },
-- 	{ "INTERIOR" })
-- AddRecipe2("wildborehouse",
-- 	{ Ingredient("pigskin", 4), Ingredient("palmleaf", 5), Ingredient("bamboo", 8) }, TECH.SCIENCE_TWO,
-- 	{ placer = "wildborehouse_placer" }, { "STRUCTURES" })
-----------------这个为什么不需要图片

AddRecipe2("loot_pumper",
	{ Ingredient("gears", 1), Ingredient("alloy", 2), Ingredient("transistor", 2) }, TECH.SCIENCE_TWO,
	{ min_spacing = 3.2, placer = "loot_pumper_placer", image = "loot_pump.tex" }, { "PROTOTYPERS", "STRUCTURES" })




-- if GetModConfigData("frost_island") ~= 5 then
-- 	AddRecipe2("wildbeaver_house",
-- 		{ Ingredient("beaverskin", 4), Ingredient("boards", 4), Ingredient("cutstone", 3) }, TECH.SCIENCE_TWO,
-- 		{ placer = "wildbeaver_house_placer" }, { "STRUCTURES" })
-- end

-- if GetModConfigData("Shipwrecked_plus") == true or GetModConfigData("Shipwreckedworld_plus") == true then
-- 	AddRecipe2("pandahouse", { Ingredient("pandaskin", 4), Ingredient("boards", 4), Ingredient("cutstone", 3) },
-- 		TECH.SCIENCE_TWO, { placer = "pandahouse_placer" }, { "STRUCTURES" })
-- end

-- if GetModConfigData("gorgeisland") == true or GetModConfigData("Shipwreckedworld_plus") == true then
-- 	AddRecipe2("galinheiro",
-- 		{ Ingredient("seeds", 6), Ingredient("boards", 4), Ingredient("feather_chicken", 2, cm_atlas) },
-- 		TECH.SCIENCE_TWO, { placer = "galinheiro_placer", atlas = cm_atlas }, { "STRUCTURES" })
-- end


--CHARACTER--
AddRecipe2("surfboard_item", { Ingredient("boards", 1), Ingredient("seashell", 1) }, TECH.NONE,
	{
		builder_tag = "walani",
		image = "surfboard_item.tex",
		sort_after = {
			{ recipe = "wx78_scanner_item", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })
AddRecipe2("porto_woodlegsboat",
	{ Ingredient("boards", 4), Ingredient("dubloon", 4), Ingredient("boatcannon", 1) }, TECH.NONE,
	{
		builder_tag = "woodlegs",
		sort_after = {
			{ recipe = "surfboard_item", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })
AddRecipe2("dubloon", { Ingredient("goldnugget", 1) }, TECH.NONE,
	{
		builder_tag = "woodlegs",
		sort_after = {
			{ recipe = "porto_woodlegsboat", filter = "CHARACTER" }
		},
		numtogive = 2
	}, { "CHARACTER" })


AddRecipe2("woodlegshat",
	{ Ingredient("boneshard", 4), Ingredient("fabric", 3), Ingredient("dubloon", 10) },
	TECH.NONE, { builder_tag = "woodlegs" }, { "CHARACTER" })

AddRecipe2("poisonbalm", { Ingredient("livinglog", 1), Ingredient("venomgland", 1) }, TECH.NONE,
	{
		builder_tag = "plantkin",
		sort_after = {
			{ recipe = "livinglog", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })

AddRecipe2("mermhouse_fisher_crafted",
	{ Ingredient("boards", 5), Ingredient("cutreeds", 3), Ingredient("oceanfish_small_61_inv", 2) },
	TECH.SCIENCE_ONE, {
		builder_tag = "merm_builder",
		placer = "mermhouse_fisher_crafted_placer",
		testfn = function(pt, rot)
			local ground_tile = GLOBAL.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
			return ground_tile and (ground_tile == GROUND.MARSH or ground_tile == GROUND.TIDALMARSH)
		end,
		sort_after = {
			{ recipe = "mermwatchtower", filter = "CHARACTER" }
		},
	}, { "CHARACTER" })
AddRecipe2("mermhouse_tropical_crafted",
	{ Ingredient("boards", 5), Ingredient("cutreeds", 3), Ingredient("oceanfish_small_61_inv", 2) },
	TECH.SCIENCE_ONE, {
		builder_tag = "merm_builder",
		placer = "mermhouse_tropical_crafted_placer",
		testfn = function(pt, rot)
			local ground_tile = GLOBAL.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
			return ground_tile and (ground_tile == GROUND.MARSH or ground_tile == GROUND.TIDALMARSH)
		end,
	}, { "CHARACTER" })
AddRecipe2("mermhouse_crafted", { Ingredient("boards", 4), Ingredient("cutreeds", 3), Ingredient("pondfish", 2) },
	TECH.SCIENCE_ONE,
	{
		builder_tag = "merm_builder",
		placer = "mermhouse_crafted_placer",
		testfn = function(pt, rot)
			local ground_tile = GLOBAL.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
			return ground_tile and (ground_tile == GROUND.MARSH or ground_tile == GROUND.TIDALMARSH)
		end
	}, { "CHARACTER" })
AddRecipe2("mermthrone_construction", { Ingredient("boards", 5), Ingredient("rope", 5) }, TECH.SCIENCE_ONE,
	{
		builder_tag = "merm_builder",
		placer = "mermthrone_construction_placer",
		testfn = function(pt, rot)
			local ground_tile = GLOBAL.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
			return ground_tile and (ground_tile == GROUND.MARSH or ground_tile == GROUND.TIDALMARSH)
		end
	}, { "CHARACTER" })
AddRecipe2("mermwatchtower", { Ingredient("boards", 5), Ingredient("tentaclespots", 1), Ingredient("spear", 2) },
	TECH.SCIENCE_TWO,
	{
		builder_tag = "merm_builder",
		placer = "mermwatchtower_placer",
		testfn = function(pt, rot)
			local ground_tile = GLOBAL.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
			return ground_tile and (ground_tile == GROUND.MARSH or ground_tile == GROUND.TIDALMARSH)
		end
	}, { "CHARACTER" })

--OBSIDIAN STATION--
AddRecipe2("obsidianaxe",
	{ Ingredient("axe", 1), Ingredient("obsidian", 2), Ingredient("dragoonheart", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })
AddRecipe2("obsidianmachete",
	{ Ingredient("machete", 1), Ingredient("obsidian", 3), Ingredient("dragoonheart", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })
AddRecipe2("spear_obsidian",
	{ Ingredient("spear", 1), Ingredient("obsidian", 3), Ingredient("dragoonheart", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })
AddRecipe2("volcanostaff",
	{ Ingredient("firestaff", 1), Ingredient("obsidian", 4), Ingredient("dragoonheart", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })
AddRecipe2("armorobsidian",
	{ Ingredient("armorwood", 1), Ingredient("obsidian", 5), Ingredient("dragoonheart", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })
AddRecipe2("obsidiancoconade",
	{ Ingredient("coconade", 3), Ingredient("obsidian", 3), Ingredient("dragoonheart", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true, numtogive = 3 }, { "CRAFTING_STATION" })
AddRecipe2("book_meteor", { Ingredient("papyrus", 2), Ingredient("obsidian", 2) }, TECH.SCIENCE_TWO,
	{
		builder_tag = "bookbuilder",
		sort_after = {
			{ recipe = "book_sleep", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })

-- AddRecipe2("book_gardening", { Ingredient("papyrus", 2), Ingredient("seeds", 1), Ingredient("poop", 1) },
-- 	TECH.SCIENCE_TWO, { builder_tag = "bookbuilder", }, { "CHARACTER" })

AddRecipe2("wind_conch",
	{ Ingredient("obsidian", 4), Ingredient("purplegem", 1), Ingredient("magic_seal", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })
AddRecipe2("sail_stick",
	{ Ingredient("obsidian", 2), Ingredient("nightmarefuel", 3), Ingredient("magic_seal", 1) },
	TECH.OBSIDIAN_TWO, { nounlock = true }, { "CRAFTING_STATION" })

--OTHER--
AddRecipe2("machete", { Ingredient("flint", 3), Ingredient("twigs", 1) }, TECH.NONE, {
	sort_after = {
		{ recipe = "axe", filter = "TOOLS" }
	}
}, { "TOOLS" })
AddRecipe2("goldenmachete", { Ingredient("twigs", 4), Ingredient("goldnugget", 2) }, TECH.SCIENCE_TWO, {
	sort_after = {
		{ recipe = "goldenaxe", filter = "TOOLS" }
	}
}, { "TOOLS" })
AddRecipe2("telescope", { Ingredient("goldnugget", 1), Ingredient("pigskin", 1), Ingredient("messagebottleempty_sw", 1) },
	TECH.SEAFARING_TWO, {
		sort_after = {
			{ recipe = "compass", filter = "TOOLS" }
		}
	}, { "TOOLS" })
AddRecipe2("supertelescope", { Ingredient("telescope", 1), Ingredient("goldnugget", 1), Ingredient("tigereye", 1) },
	TECH.SEAFARING_TWO, {
		sort_after = {
			{ recipe = "telescope", filter = "TOOLS" }
		}
	}, { "TOOLS" })
AddRecipe2("monkeyball", { Ingredient("cave_banana", 1), Ingredient("snakeskin", 2), Ingredient("rope", 2) },
	TECH.SCIENCE_ONE, {
		sort_after = {
			{ recipe = "megaflare", filter = "TOOLS" }
		}
	}, { "TOOLS" })
AddRecipe2("chiminea", { Ingredient("log", 2), Ingredient("limestone", 3), Ingredient("sand", 2) },
	TECH.NONE, { placer = "chiminea_placer" }, { "LIGHT", "COOKING" })
AddRecipe2("bottlelantern", { Ingredient("messagebottleempty_sw", 1), Ingredient("bioluminescence", 2) },
	TECH.SCIENCE_TWO, {}, { "LIGHT" })
AddRecipe2("boat_lantern",
	{ Ingredient("messagebottleempty_sw", 1), Ingredient("twigs", 2), Ingredient("bioluminescence", 1) },
	TECH.SCIENCE_TWO, {
		sort_after = {
			{ recipe = "boat_torch", filter = "LIGHT" }
		}
	}, { "LIGHT", "NAUTICAL" })
AddRecipe2("boat_torch", { Ingredient("torch", 1), Ingredient("twigs", 2) }, TECH.ONE, {
	sort_after = {
		{ recipe = "coldfirepit", filter = "LIGHT" }
	}
}, { "LIGHT", "NAUTICAL" })
AddRecipe2("porto_sea_chiminea", { Ingredient("sand", 4), Ingredient("tar", 6), Ingredient("limestone", 6) },
	TECH.SCIENCE_ONE, { image = "sea_chiminea.tex" }, { "LIGHT" })
AddRecipe2("tarlamp", { Ingredient("seashell", 1), Ingredient("tar", 1) }, TECH.SCIENCE_ONE, {}, { "LIGHT" })
AddRecipe2("obsidianfirepit", { Ingredient("log", 3), Ingredient("obsidian", 8) }, TECH.SCIENCE_TWO,
	{ placer = "obsidianfirepit_placer" }, { "LIGHT", "COOKING" })
AddRecipe2("porto_researchlab5",
	{ Ingredient("limestone", 4), Ingredient("sand", 2), Ingredient("transistor", 2) },
	TECH.SCIENCE_ONE, { image = "researchlab5.tex" }, { "PROTOTYPERS" })
AddRecipe2("icemaker", { Ingredient("heatrock", 1), Ingredient("bamboo", 5), Ingredient("transistor", 2) },
	TECH.SCIENCE_TWO, { placer = "icemaker_placer" }, { "PROTOTYPERS" })
AddRecipe2("quackendrill", { Ingredient("quackenbeak", 1), Ingredient("gears", 1), Ingredient("transistor", 1) },
	TECH.SCIENCE_TWO, {}, { "PROTOTYPERS" })
AddRecipe2("fabric", { Ingredient("bamboo", 3) }, TECH.SCIENCE_ONE, {}, { "REFINE" })
AddRecipe2("messagebottleempty_sw", { Ingredient("sand", 3) }, TECH.SCIENCE_TWO, {}, { "REFINE" })
AddRecipe2("limestone", { Ingredient("coral", 3) }, TECH.SCIENCE_ONE, {}, { "REFINE" })
AddRecipe2("nubbin", { Ingredient("limestone", 3), Ingredient("corallarve", 1) }, TECH.SCIENCE_ONE,
	{}, { "REFINE" })
AddRecipe2("ice", { Ingredient("hail_ice", 4) }, TECH.SCIENCE_TWO, {}, { "REFINE" })
AddRecipe2("goldnugget", { Ingredient("dubloon", 3) }, TECH.SCIENCE_ONE, {}, { "REFINE" })
AddRecipe2("spear_poison", { Ingredient("spear", 1), Ingredient("venomgland", 1) }, TECH.SCIENCE_ONE,
	{}, { "WEAPONS" })
AddRecipe2("cutlass", { Ingredient("goldnugget", 2), Ingredient("twigs", 1), Ingredient("swordfish_dead", 1) },
	TECH.SCIENCE_TWO, {}, { "WEAPONS" })
AddRecipe2("coconade", { Ingredient("coconut", 1), Ingredient("gunpowder", 1), Ingredient("rope", 1) },
	TECH.SCIENCE_ONE, {}, { "WEAPONS" })
AddRecipe2("spear_launcher", { Ingredient("bamboo", 3), Ingredient("jellyfish", 1) }, TECH.SCIENCE_TWO,
	{}, { "WEAPONS" })
AddRecipe2("blowdart_poison",
	{ Ingredient("cutreeds", 2), Ingredient("venomgland", 1), Ingredient("feather_crow", 1) }, TECH.SCIENCE_ONE,
	{}, { "WEAPONS" })
AddRecipe2("armorseashell",
	{ Ingredient("seashell", 10), Ingredient("rope", 1), Ingredient("seaweed", 2) }, TECH.SCIENCE_TWO,
	{}, { "ARMOUR" })
AddRecipe2("bell", { Ingredient("glommerwings", 1), Ingredient("glommerflower", 1) }, TECH.MAGIC_TWO,
	{
		sort_after = {
			{ recipe = "ox_flute", filter = "MAGIC" }
		}
	}, { "MAGIC" })
AddRecipe2("oxhat", { Ingredient("rope", 1), Ingredient("seashell", 4), Ingredient("ox_horn", 1) },
	TECH.SCIENCE_ONE, {
		sort_after = {
			{ recipe = "footballhat", filter = "ARMOUR" }
		}
	}, { "ARMOUR" })
AddRecipe2("armorcactus", { Ingredient("needlespear", 3), Ingredient("armorwood", 1) }, TECH.SCIENCE_TWO,
	{
		sort_after = {
			{ recipe = "armorlimestone", filter = "ARMOUR" }
		}
	}, { "ARMOUR" })
AddRecipe2("snakeskinhat", { Ingredient("boneshard", 1), Ingredient("snakeskin", 1), Ingredient("strawhat", 1) },
	TECH.SCIENCE_TWO, {
		sort_after = {
			{ recipe = "rainhat", filter = "CLOTHING" },
			{ recipe = "rainhat", filter = "RAIN" }
		}
	}, { "CLOTHING", "RAIN" })
AddRecipe2("armor_snakeskin",
	{ Ingredient("boneshard", 2), Ingredient("snakeskin", 2), Ingredient("vine", 1) }, TECH
	.SCIENCE_TWO, {
		sort_after = {
			{ recipe = "raincoat", filter = "CLOTHING" },
			{ recipe = "raincoat", filter = "RAIN" },
			{ recipe = "raincoat", filter = "WINTER" }
		}
	}, { "CLOTHING", "RAIN", "WINTER" })
AddRecipe2("palmleaf_umbrella", { Ingredient("twigs", 4), Ingredient("petals", 6), Ingredient("palmleaf", 3) },
	TECH.NONE, {}, { "CLOTHING", "RAIN" })
AddRecipe2("double_umbrellahat",
	{ Ingredient("umbrella", 1), Ingredient("shark_gills", 2), Ingredient("strawhat", 2) }, TECH.SCIENCE_TWO,
	{}, { "CLOTHING", "RAIN" })
AddRecipe2("aerodynamichat",
	{ Ingredient("coconut", 1), Ingredient("shark_fin", 1), Ingredient("vine", 2) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })
AddRecipe2("thatchpack", { Ingredient("palmleaf", 6) }, TECH.NONE, {}, { "CLOTHING" })
AddRecipe2("piratehat", { Ingredient("boneshard", 2), Ingredient("rope", 1), Ingredient("silk", 2) }, TECH.SCIENCE_TWO,
	{}, { "CLOTHING" })
AddRecipe2("captainhat", { Ingredient("boneshard", 1), Ingredient("seaweed", 1), Ingredient("strawhat", 1) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })

AddRecipe2("tarsuit",
	{ Ingredient("tar", 4), Ingredient("fabric", 2), Ingredient("palmleaf", 2) },
	TECH.SCIENCE_ONE, {}, { "CLOTHING", "RAIN" })
AddRecipe2("blubbersuit",
	{ Ingredient("blubber", 4), Ingredient("fabric", 2), Ingredient("palmleaf", 2) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING", "RAIN" })
AddRecipe2("brainjellyhat",
	{ Ingredient("coral_brain", 1), Ingredient("jellyfish", 1), Ingredient("rope", 2) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })
AddRecipe2("shark_teethhat", { Ingredient("shark_tooth", 5), Ingredient("goldnugget", 1) }, TECH.SCIENCE_ONE, nil,
	{ "CLOTHING" })
AddRecipe2("armor_windbreaker",
	{ Ingredient("blubber", 2), Ingredient("fabric", 1), Ingredient("rope", 1) }, TECH.SCIENCE_TWO,
	{}, { "CLOTHING", "WINTER" }) -- CHECK  THIS
AddRecipe2("gashat",
	{ Ingredient("coral", 2), Ingredient("messagebottleempty_sw", 2), Ingredient("jellyfish", 1) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })
AddRecipe2("antivenom",
	{ Ingredient("venomgland", 1), Ingredient("coral", 2), Ingredient("seaweed", 2) },
	TECH.SCIENCE_ONE, {}, { "RESTORATION" })
AddRecipe2("ox_flute", { Ingredient("ox_horn", 1), Ingredient("nightmarefuel", 2), Ingredient("rope", 1) },
	TECH.MAGIC_TWO, {}, { "MAGIC" })
AddRecipe2("turf_snakeskinfloor", { Ingredient("snakeskin", 2), Ingredient("fabric", 1) },
	TECH.SCIENCE_TWO, { numtogive = 4 }, { "DECOR" })
AddRecipe2("sand_castle",
	{ Ingredient("sand", 4), Ingredient("palmleaf", 2), Ingredient("seashell", 3) }, TECH
	.NONE, {
		placer = "sand_castle_placer",
		sort_after = {
			{ recipe = "sisturn",  filter = "STRUCTURES" },
			{ recipe = "endtable", filter = "DECOR" }
		}
	}, { "STRUCTURES", "DECOR" })
-- AddRecipe2("turf_road", { Ingredient("cutstone", 1), Ingredient("flint", 2) }, TECH.SCIENCE_TWO, { numtogive = 4 },
-- 	{ "DECOR" })
-- if GetModConfigData("kindofworld") == 10 then --WHAT?
-- 	AddRecipe2("turf_road", { Ingredient("boards", 1), Ingredient("turf_magmafield", 1) }, TECH.SCIENCE_TWO,
-- 		{ numtogive = 4 }, { "DECOR" })
-- end

AddRecipe2("dragoonden",
	{ Ingredient("dragoonheart", 1), Ingredient("rocks", 5), Ingredient("obsidian", 4) },
	TECH.SCIENCE_TWO, {
		placer = "dragoonden_placer",
		sort_after = {
			{ recipe = "rabbithouse", filter = "STRUCTURES" }
		}
	}, { "STRUCTURES" })
AddRecipe2("wildborehouse",
	{ Ingredient("pigskin", 4), Ingredient("palmleaf", 5), Ingredient("bamboo", 8) }, TECH.SCIENCE_TWO,
	{
		placer = "wildborehouse_placer",
		image = "wildborehouse_craft.tex",
		sort_after = {
			{ recipe = "pighouse", filter = "STRUCTURES" }
		}
	}, { "STRUCTURES" })
AddRecipe2("primeapebarrel", { Ingredient("twigs", 10), Ingredient("cave_banana", 3), Ingredient("poop", 4) },
	TECH.SCIENCE_TWO, {
		placer = "primeapebarrel_placer",
		sort_after = {
			{ recipe = "porto_ballphinhouse", filter = "STRUCTURES" }
		}
	}, { "STRUCTURES" })
AddRecipe2("porto_ballphinhouse",
	{ Ingredient("limestone", 4), Ingredient("seaweed", 4), Ingredient("dorsalfin", 2) },
	TECH.SCIENCE_ONE, {
		image = "ballphinhouse_craft.tex",
		sort_after = {
			{ recipe = "wildborehouse", filter = "STRUCTURES" }
		}
	}, { "STRUCTURES" })
AddRecipe2("sandbag_item", { Ingredient("fabric", 2), Ingredient("sand", 3) }, TECH.SCIENCE_TWO,
	{ numtogive = 4 }, { "STRUCTURES" })
AddRecipe2("doydoynest", { Ingredient("twigs", 8), Ingredient("doydoyfeather", 2), Ingredient("poop", 4) },
	TECH.SCIENCE_TWO, { placer = "doydoynest_placer" }, { "STRUCTURES" })
AddRecipe2("wall_limestone_item", { Ingredient("limestone", 2) }, TECH.SCIENCE_TWO, {

	numtogive = 4
}, { "STRUCTURES" })
AddRecipe2("wall_enforcedlimestone_item", { Ingredient("limestone", 2), Ingredient("seaweed", 4) },
	TECH.SCIENCE_ONE, { numtogive = 4 }, { "STRUCTURES" })
AddRecipe2("seasack",
	{ Ingredient("seaweed", 5), Ingredient("vine", 2), Ingredient("shark_gills", 1) },
	TECH.SCIENCE_TWO, {}, { "CONTAINERS" })
AddRecipe2("porto_waterchest", { Ingredient("boards", 4), Ingredient("tar", 1) }, TECH.SCIENCE_ONE,
	{}, { "CONTAINERS" })
AddRecipe2("mussel_stick",
	{ Ingredient("bamboo", 2), Ingredient("vine", 1), Ingredient("seaweed", 1) },
	TECH.SCIENCE_ONE, {}, { "GARDENING" })
AddRecipe2("mussel_bed", { Ingredient("mussel", 1), Ingredient("coral", 1) }, TECH.SCIENCE_ONE,
	{}, { "GARDENING" })
AddRecipe2("porto_fish_farm", { Ingredient("silk", 2), Ingredient("rope", 2), Ingredient("coconut", 4) },
	TECH.SCIENCE_ONE, { image = "fish_farm.tex" }, { "GARDENING" })
AddRecipe2("tropicalfan", { Ingredient("cutreeds", 2), Ingredient("rope", 2), Ingredient("doydoyfeather", 5) },
	TECH.SCIENCE_TWO, {
		sort_after = {
			{ recipe = "featherfan", filter = "SUMMER" },
			{ recipe = "featherfan", filter = "CLOTHING" }
		}
	}, { "SUMMER", "CLOTHING" })
AddRecipe2("palmleaf_hut",
	{ Ingredient("palmleaf", 4), Ingredient("bamboo", 4), Ingredient("rope", 3) },
	TECH.SCIENCE_TWO, {
		placer = "palmleaf_hut_placer",
		sort_before = {
			{ recipe = "lightning_rod", filter = "RAIN" }
		},
		sort_after = {
			{ recipe = "siestahut", filter = "STRUCTURES" },
			{ recipe = "siestahut", filter = "SUMMER" }
		}
	}, { "SUMMER", "RAIN", "STRUCTURES" })


AddRecipe2("slow_farmplot", { Ingredient("cutgrass", 8), Ingredient("poop", 4), Ingredient("log", 4) }, TECH.SCIENCE_ONE,
	{
		min_spacing = 3.2,
		placer = "slow_farmplot_placer",
		image = "slow_farmplot.tex",
		sort_after = {
			{ recipe = "seedpouch", filter = "GARDENING" }
		}
	}, { "GARDENING" })
AddRecipe2("fast_farmplot", { Ingredient("cutgrass", 10), Ingredient("poop", 6), Ingredient("rocks", 4) },
	TECH.SCIENCE_ONE, {
		min_spacing = 3.2,
		placer = "fast_farmplot_placer",
		image = "fast_farmplot.tex",
		sort_after = {
			{ recipe = "slow_farmplot", filter = "GARDENING" }
		}
	}, { "GARDENING" })

AddRecipe2("chickenhouse", { Ingredient("seeds", 6), Ingredient("boards", 4), Ingredient("feather_chicken", 2) },
	TECH.SCIENCE_TWO, { placer = "chickenhouse_placer", }, { "STRUCTURES" })
--SEAFARING--
AddRecipe2("boatmetal_item", { Ingredient("alloy", 4), Ingredient("iron", 4) }, TECH.SEAFARING_TWO,
	{}, { "SEAFARING" })
AddRecipe2("porto_lograft_old", { Ingredient("log", 6), Ingredient("cutgrass", 4) }, TECH.NONE, {},
	{ "NAUTICAL" })
AddRecipe2("porto_raft_old", { Ingredient("bamboo", 4), Ingredient("vine", 3) }, TECH.NONE,
	{}, { "NAUTICAL" })


-- AddRecipe2("porto_lograft", { Ingredient("log", 6), Ingredient("cutgrass", 4) }, TECH.NONE, {  },
-- 	{ "SEAFARING" })
-- AddRecipe2("porto_raft", { Ingredient("bamboo", 4), Ingredient("vine", 3) }, TECH.NONE,
-- 	{  }, { "SEAFARING" })

AddRecipe2("porto_rowboat", { Ingredient("boards", 3), Ingredient("vine", 4) }, TECH.SEAFARING_ONE,
	{}, { "NAUTICAL" })
AddRecipe2("boatrepairkit", { Ingredient("boards", 2), Ingredient("stinger", 2), Ingredient("rope", 2) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("porto_cargoboat", { Ingredient("boards", 6), Ingredient("rope", 3) }, TECH.SEAFARING_ONE, {},
	{ "NAUTICAL" })
AddRecipe2("porto_armouredboat", { Ingredient("boards", 6), Ingredient("rope", 3), Ingredient("seashell", 10) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("porto_encrustedboat", { Ingredient("boards", 6), Ingredient("limestone", 4), Ingredient("rope", 3) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("sail",
	{ Ingredient("bamboo", 2), Ingredient("vine", 2), Ingredient("palmleaf", 4) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("feathersail",
	{ Ingredient("bamboo", 2), Ingredient("rope", 4), Ingredient("doydoyfeather", 4) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("clothsail", { Ingredient("bamboo", 2), Ingredient("fabric", 2), Ingredient("rope", 2) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("snakeskinsail", { Ingredient("log", 4), Ingredient("rope", 2), Ingredient("snakeskin", 2) },
	TECH.SEAFARING_ONE, {}, { "NAUTICAL" })
AddRecipe2("ironwind",
	{ Ingredient("turbine_blades", 1), Ingredient("transistor", 1), Ingredient("goldnugget", 2) },
	TECH.SEAFARING_TWO, {}, { "NAUTICAL" })
AddRecipe2("malbatrossail",
	{ Ingredient("driftwood_log", 4), Ingredient("rope", 2), Ingredient("malbatross_feather", 4) },
	TECH.SEAFARING_TWO, {}, { "NAUTICAL" })
AddRecipe2("boatcannon", { Ingredient("coconut", 6), Ingredient("log", 5), Ingredient("gunpowder", 4) },
	TECH.SEAFARING_TWO, {}, { "NAUTICAL" })
AddRecipe2("obsidian_boatcannon",
	{ Ingredient("obsidian", 6), Ingredient("log", 5), Ingredient("gunpowder", 4) },
	TECH.SEAFARING_TWO, {
		sort_after = {
			{ recipe = "obsidiancoconade", filter = "OBSIDIAN" }
		}
	}, { "NAUTICAL", "OBSIDIAN" })
AddRecipe2("trawlnet", { Ingredient("bamboo", 2), Ingredient("rope", 3) }, TECH.SEAFARING_TWO,
	{
		sort_after = {
			{ recipe = "malbatrossail", filter = "NAUTICAL" },
		}
	},
	{ "NAUTICAL" })
AddRecipe2("armor_lifejacket",
	{ Ingredient("fabric", 2), Ingredient("vine", 2), Ingredient("messagebottleempty_sw", 2) },
	TECH.SEAFARING_TWO, {
		sort_after = {
			{ recipe = "armor_windbreaker", filter = "CLOTHING" }
		}
	}, { "NAUTICAL", "CLOTHING" })
AddRecipe2("seatrap",
	{ Ingredient("palmleaf", 4), Ingredient("messagebottleempty_sw", 2),
		Ingredient("jellyfish", 1) }, TECH.SEAFARING_TWO, {
		sort_after = {
			{ recipe = "birdtrap", filter = "TOOLS" },
			{ recipe = "birdtrap", filter = "GARDENING" }
		}
	}, { "NAUTICAL", "TOOLS", "GARDENING" })
AddRecipe2("porto_buoy",
	{ Ingredient("messagebottleempty_sw", 1), Ingredient("bamboo", 4),
		Ingredient("bioluminescence", 2) }, TECH.SEAFARING_TWO, {
		image = "buoy.tex",
		sort_before = {
			{ recipe = "nightlight", filter = "STRUCTURES" }
		},
		sort_after = {
			{ recipe = "boat_lantern", filter = "LIGHT" }
		}
	}, { "LIGHT", "NAUTICAL", "STRUCTURES" })
AddRecipe2("quackeringram",
	{ Ingredient("quackenbeak", 1), Ingredient("bamboo", 4), Ingredient("rope", 4) },
	TECH.SEAFARING_TWO,
	{
		sort_after = {
			{ recipe = "boatcannon", filter = "NAUTICAL" },
		}
	},
	{ "NAUTICAL" })
AddRecipe2("porto_tar_extractor",
	{ Ingredient("coconut", 2), Ingredient("bamboo", 4), Ingredient("limestone", 4) },
	TECH.SEAFARING_TWO, {
		image = "tar_extractor.tex",
		sort_after = {
			{ recipe = "icemaker", filter = "STRUCTURES" }
		}
	}, { "NAUTICAL", "STRUCTURES" })
AddRecipe2("porto_sea_yard", { Ingredient("limestone", 6), Ingredient("tar", 6), Ingredient("log", 4) },
	TECH.SEAFARING_TWO, {
		image = "sea_yard.tex",
		sort_after = {
			{ recipe = "porto_tar_extractor", filter = "STRUCTURES" }
		}
	}, { "NAUTICAL", "STRUCTURES" })

--HAMLET--
-- if GetModConfigData("Hamlet") ~= 5 or GetModConfigData("startlocation") == 15 or GetModConfigData("kindofworld") == 5 then --GetModConfigData("painted_sands")
AddRecipe2("shears", { Ingredient("twigs", 2), Ingredient("iron", 2) }, TECH.SCIENCE_ONE,
	{
		sort_after = {
			{ recipe = "goldenpitchfork", filter = "TOOLS" }
		}
	},
	{ "TOOLS" })
AddRecipe2("bugrepellent", { Ingredient("tuber_crop", 6), Ingredient("venus_stalk", 1) },
	TECH.SCIENCE_ONE, {
		sort_after = {
			{ recipe = "reskin_tool", filter = "TOOLS" }
		}
	}, { "TOOLS" })
AddRecipe2("clawpalmtree_cone", { Ingredient("cork", 1), Ingredient("poop", 1) }, TECH.SCIENCE_ONE, {
}, { "REFINE" })
AddRecipe2("venomgland", { Ingredient("froglegs_poison", 3) }, TECH.SCIENCE_TWO, {
}, { "REFINE" })
AddRecipe2("goldpan", { Ingredient("iron", 2), Ingredient("hammer", 1) }, TECH.SCIENCE_ONE, {
		sort_after = {
			{ recipe = "bugrepellent", filter = "TOOLS" }
		}
	},
	{ "TOOLS", "LEGACY" })
AddRecipe2("bathat", { Ingredient("pigskin", 2), Ingredient("batwing", 1), Ingredient("compass", 1) },
	TECH.SCIENCE_TWO, {
		sort_after = {
			{ recipe = "molehat", filter = "LIGHT" }
		}
	}, { "LIGHT" })
AddRecipe2("candlehat", { Ingredient("cork", 4), Ingredient("iron", 2) }, TECH.SCIENCE_ONE,
	{
		sort_after = {
			{ recipe = "cotl_tabernacle_level1", filter = "LIGHT" }
		}
	}, { "LIGHT" })
AddRecipe2("glass_shards", { Ingredient("sand", 3) }, TECH.SCIENCE_ONE, {}, { "REFINE" })
AddRecipe2("goldnugget", { Ingredient("gold_dust", 6) }, TECH.SCIENCE_ONE, {}, { "REFINE" })
AddRecipe2("shard_sword",
	{ Ingredient("glass_shards", 3), Ingredient("nightmarefuel", 2), Ingredient("twigs", 2) },
	TECH.MAGIC_TWO, {}, { "MAGIC" })
AddRecipe2("shard_beak", { Ingredient("glass_shards", 3), Ingredient("crow", 1), Ingredient("twigs", 2) },
	TECH.MAGIC_TWO, {}, { "MAGIC" })
AddRecipe2("armor_weevole", { Ingredient("weevole_carapace", 4), Ingredient("chitin", 2) },
	TECH.SCIENCE_TWO, {}, { "ARMOUR" })
AddRecipe2("antsuit", { Ingredient("chitin", 5), Ingredient("armorwood", 1) }, TECH.SCIENCE_ONE,
	{}, { "ARMOUR" })
AddRecipe2("antmaskhat", { Ingredient("chitin", 5), Ingredient("footballhat", 1) }, TECH.SCIENCE_ONE,
	{}, { "ARMOUR" })
AddRecipe2("metalplatehat", { Ingredient("alloy", 3), Ingredient("cork", 3) }, TECH.SCIENCE_ONE,
	{}, { "ARMOUR" })
AddRecipe2("armor_metalplate", { Ingredient("alloy", 3), Ingredient("hammer", 1) }, TECH.SCIENCE_ONE,
	{}, { "ARMOUR" })
AddRecipe2("halberd", { Ingredient("alloy", 1), Ingredient("twigs", 2) }, TECH.SCIENCE_ONE, {},
	{ "WEAPONS" })
AddRecipe2("cork_bat", { Ingredient("cork", 3), Ingredient("boards", 1) }, TECH.SCIENCE_ONE, {},
	{ "WEAPONS" })
AddRecipe2("blunderbuss", { Ingredient("oinc10", 1), Ingredient("boards", 2), Ingredient("gears", 1) },
	TECH.SCIENCE_ONE, {}, { "WEAPONS" })
AddRecipe2("corkchest", { Ingredient("cork", 2), Ingredient("rope", 1) }, TECH.SCIENCE_ONE,
	{ min_spacing = 1, placer = "corkchest_placer" }, { "CONTAINERS" })
AddRecipe2("roottrunk_child",
	{ Ingredient("bramble_bulb", 1), Ingredient("venus_stalk", 2), Ingredient("boards", 2) },
	TECH.SCIENCE_ONE, { min_spacing = 1, placer = "roottrunk_child_placer" }, { "CONTAINERS" })
AddRecipe2("basefan", { Ingredient("alloy", 2), Ingredient("transistor", 2), Ingredient("gears", 1) },
	TECH.SCIENCE_TWO, { placer = "basefan_placer" }, { "PROTOTYPERS" })
AddRecipe2("sprinkler", { Ingredient("alloy", 2), Ingredient("bluegem", 1), Ingredient("ice", 6) },
	TECH.SCIENCE_TWO, { placer = "sprinkler1_placer" }, { "GARDENING" })
AddRecipe2("smelter", { Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1) },
	TECH.SCIENCE_TWO, { placer = "smetler_placer" }, { "PROTOTYPERS" })
AddRecipe2("ballpein_hammer", { Ingredient("iron", 2), Ingredient("twigs", 1) }, TECH.SCIENCE_ONE,
	{
		sort_after = {
			{ recipe = "goldpan", filter = "TOOLS" }
		}
	}, { "TOOLS", "LEGACY" })
AddRecipe2("magnifying_glass", { Ingredient("iron", 1), Ingredient("twigs", 1), Ingredient("bluegem", 1) },
	TECH.SCIENCE_TWO, {
		sort_after = {
			{ recipe = "ballpein_hammer", filter = "TOOLS" }
		}
	}, { "TOOLS", "LEGACY" })
AddRecipe2("disguisehat", { Ingredient("twigs", 2), Ingredient("pigskin", 1), Ingredient("beardhair", 1) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })
AddRecipe2("pithhat",
	{ Ingredient("fabric", 1), Ingredient("vine", 3), Ingredient("cork", 6) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })
AddRecipe2("thunderhat",
	{ Ingredient("feather_thunder", 1), Ingredient("goldnugget", 1), Ingredient("cork", 2) },
	TECH.SCIENCE_TWO, {}, { "CLOTHING" })
AddRecipe2("gasmaskhat",
	{ Ingredient("peagawkfeather", 4), Ingredient("fabric", 1), Ingredient("pigskin", 1) },
	TECH.SCIENCE_ONE, {}, { "CLOTHING" })
AddRecipe2("corkboatitem", { Ingredient("rope", 1), Ingredient("cork", 4) }, TECH.NONE, {},
	{ "NAUTICAL" })

AddRecipe2("bonestaff", { Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2) },
	TECH.LOST, {}, { "TOOLS", "WEAPONS", "MAGIC" })
-- end


AddRecipe2("antler",
	{ Ingredient("hippo_antler", 1), Ingredient("bill_quill", 3), Ingredient("flint", 1) },
	TECH.SCIENCE_TWO, {}, { "TOOLS" })

AddRecipe2("antler_corrupted", { Ingredient("antler", 1), Ingredient("nightmarefuel", 2) }, TECH.MAGIC_TWO, {},
	{ "TOOLS", "MAGIC" })


AddRecipe2("piratihatitator",
	{ Ingredient("parrot", 1), Ingredient("boards", 4), Ingredient("piratehat", 1) }, TECH.SCIENCE_ONE,
	{
		placer = "piratihatitator_placer",
		sort_after = {
			{ recipe = "researchlab4", filter = "PROTOTYPERS" },
			{ recipe = "researchlab4", filter = "MAGIC" },
			{ recipe = "researchlab4", filter = "STRUCTURES" }
		}
	}, { "PROTOTYPERS", "MAGIC", "STRUCTURES" })

AddRecipe2("hogusporkusator",
	{ Ingredient("pigskin", 4), Ingredient("boards", 4), Ingredient("feather_robin_winter", 4) },
	TECH.SCIENCE_ONE, {
		placer = "hogusporkusator_placer",
		sort_after = {
			{ recipe = "piratihatitator", filter = "PROTOTYPERS" },
			{ recipe = "piratihatitator", filter = "MAGIC" },
			{ recipe = "piratihatitator", filter = "STRUCTURES" }
		}
	}, { "PROTOTYPERS", "MAGIC", "STRUCTURES" })

--CITY----------------------------


-- AddRecipe2("city_hammer", { Ingredient("iron", 2), Ingredient("twigs", 1) }, TECH.CITY_ONE,
AddRecipe2("mutator_tropical", { Ingredient("mutator_warrior", 1), Ingredient("venomgland", 3) }, TECH.NONE,
	{
		builder_tag = "wurt",
		sort_after = {
			{ recipe = "mutator_warrior", filter = "CHARACTER" }
		}
	}, { "CHARACTER" })
-- 	{ --[[nounlock = true]] }, { "HAMLET" })
AddRecipe2("securitycontract", { Ingredient("oinc", 10) }, TECH.CITY_ONE, { nounlock = false },
	{ "HAMLET" })
AddRecipe2("city_lamp", { Ingredient("alloy", 1), Ingredient("transistor", 1), Ingredient("lantern", 1) },
	TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "city_lamp_placer", image = "city_lamp.tex" },
	{ "HAMLET" })
AddRecipe2("playerhouse_city",
	{ Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("oinc", 30) }, TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "playerhouse_city_placer",
		image = "pig_house_sale.tex",
		no_deconstruction = true,
		--[[build_mode = BUILDMODE.WATER]]
	},
	{ "HAMLET" })
AddRecipe2("pighouse_city", { Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 3.2, placer = "pighouse_city_placer", image = "pighouse_city.tex" },
	{ "HAMLET" })
AddRecipe2("pig_shop_deli", { Ingredient("boards", 4), Ingredient("honeyham", 1), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 3.2, placer = "pig_shop_deli_placer", image = "pig_shop_deli.tex" },
	{ "HAMLET" })
AddRecipe2("pig_shop_general", { Ingredient("boards", 4), Ingredient("axe", 3), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "pig_shop_general_placer",
		image = "pig_shop_general.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_hoofspa", { Ingredient("boards", 4), Ingredient("bandage", 3), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_hoofspa_placer",
		image = "pig_shop_hoofspa.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_produce", { Ingredient("boards", 4), Ingredient("eggplant", 3), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_produce_placer",
		image = "pig_shop_produce.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_florist", { Ingredient("boards", 4), Ingredient("petals", 12), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_florist_placer",
		image = "pig_shop_florist.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_antiquities",
	{ Ingredient("boards", 4), Ingredient("ballpein_hammer", 3), Ingredient("pigskin", 4) }, TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_antiquities_placer",
		image = "pig_shop_antiquities.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_arcane",
	{ Ingredient("boards", 4), Ingredient("nightmarefuel", 1), Ingredient("pigskin", 4) }, TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_arcane_placer",
		image =
		"pig_shop_arcane.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_weapons", { Ingredient("boards", 4), Ingredient("spear", 3), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_weapons_placer",
		image = "pig_shop_weapons.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_academy", { Ingredient("boards", 4), Ingredient("cutstone", 3), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_academy_placer",
		image = "pig_shop_academy.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_hatshop", { Ingredient("boards", 4), Ingredient("tophat", 2), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "pig_shop_hatshop_placer",
		image = "pig_shop_hatshop.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_bank",
	{ Ingredient("cutstone", 4), Ingredient("oinc", 100), Ingredient("pigskin", 4) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 3.2, placer = "pig_shop_bank_placer", image = "pig_shop_bank.tex" },
	{ "HAMLET" })
AddRecipe2("pig_shop_tinker", { Ingredient("magnifying_glass", 2), Ingredient("pigskin", 4) },
	TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "pig_shop_tinker_placer",
		image =
		"pig_shop_tinker.tex"
	}, { "HAMLET" })
AddRecipe2("pig_shop_cityhall_player",
	{ Ingredient("boards", 4), Ingredient("goldnugget", 4), Ingredient("pigskin", 4) }, TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 3.2,
		placer = "pig_shop_cityhall_placer",
		image = "pig_shop_cityhall.tex"
	}, { "HAMLET" })
AddRecipe2("pig_guard_tower", { Ingredient("cutstone", 3), Ingredient("halberd", 1), Ingredient("pigskin", 4) },
	TECH.CITY_ONE, { nounlock = false, min_spacing = 3.2, placer = "pig_guard_tower_placer" },
	{ "HAMLET" })
AddRecipe2("hedge_block_item", { Ingredient("clippings", 9), Ingredient("nitre", 1) }, TECH.CITY_ONE, {
	nounlock = false,
	numtogive = 3,
}, { "HAMLET" })
AddRecipe2("hedge_cone_item", { Ingredient("clippings", 9), Ingredient("nitre", 1) }, TECH.CITY_ONE, {
	nounlock = false,
	numtogive = 3,
}, { "HAMLET" })
AddRecipe2("hedge_layered_item", { Ingredient("clippings", 9), Ingredient("nitre", 1) }, TECH.CITY_ONE, {
	nounlock = false,
	numtogive = 3,
}, { "HAMLET" })
AddRecipe2("pig_guard_tower_palace",
	{ Ingredient("cutstone", 5), Ingredient("halberd", 1), Ingredient("pigskin", 4) }, TECH.CITY_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "pig_guard_tower_palace_placer",
		image = "pig_royal_tower.tex"
	}, { "HAMLET" })
AddRecipe2("lawnornament_1", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_1_placer", image = "lawnornament_1.tex" },
	{ "HAMLET" })
AddRecipe2("lawnornament_2", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_2_placer", image = "lawnornament_2.tex" },
	{ "HAMLET" })
AddRecipe2("lawnornament_3", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_3_placer", image = "lawnornament_3.tex" },
	{ "HAMLET" })
AddRecipe2("lawnornament_4", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_4_placer", image = "lawnornament_4.tex" },
	{ "HAMLET" })
AddRecipe2("lawnornament_5", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_5_placer", image = "lawnornament_5.tex" },
	{ "HAMLET" })
AddRecipe2("lawnornament_6", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_6_placer", image = "lawnornament_6.tex" },
	{ "HAMLET" })
AddRecipe2("lawnornament_7", { Ingredient("cutstone", 2), Ingredient("oinc", 7) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "lawnornament_7_placer", image = "lawnornament_7.tex" },
	{ "HAMLET" })
AddRecipe2("topiary_1", { Ingredient("oinc", 10) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "topiary_1_placer", image = "topiary_1.tex" },
	{ "HAMLET" })
AddRecipe2("topiary_2", { Ingredient("oinc", 10) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "topiary_2_placer", image = "topiary_2.tex" },
	{ "HAMLET" })
AddRecipe2("topiary_3", { Ingredient("oinc", 12) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "topiary_3_placer", image = "topiary_3.tex" },
	{ "HAMLET" })
AddRecipe2("topiary_4", { Ingredient("oinc", 12) }, TECH.CITY_ONE,
	{ nounlock = false, min_spacing = 1, placer = "topiary_4_placer", image = "topiary_4.tex" },
	{ "HAMLET" })
AddRecipe2("turf_foundation", { Ingredient("cutstone", 1) }, TECH.CITY_ONE, {
	nounlock = false, numtogive = 4 }, { "HAMLET" })
AddRecipe2("turf_cobbleroad", { Ingredient("cutstone", 2), Ingredient("boards", 1) }, TECH.CITY_ONE,
	{ nounlock = false, numtogive = 4 }, { "HAMLET" })
AddRecipe2("turf_checkeredlawn", { Ingredient("cutgrass", 2), Ingredient("nitre", 1) }, TECH.CITY_ONE,
	{ nounlock = false, numtogive = 4, image = "turf_lawn.tex" }, { "HAMLET" })
AddRecipe2("turf_pigruins", { Ingredient("cutstone", 4), Ingredient("rocks", 2) }, TECH.CITY_TWO,
	{ nounlock = false, numtogive = 4, }, { "HAMLET" })
--TURFS--
AddRecipe2("turf_magmafield", { Ingredient("rocks", 2), Ingredient("ash", 1) }, TECH.TURFCRAFTING_ONE,
	{ numtogive = 4 }, { "DECOR" })
AddRecipe2("turf_ash", { Ingredient("ash", 3) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
AddRecipe2("turf_jungle", { Ingredient("bamboo", 1), Ingredient("cutgrass", 1) }, TECH.TURFCRAFTING_ONE,
	{ numtogive = 4 }, { "DECOR" })
AddRecipe2("turf_volcano", { Ingredient("nitre", 2), Ingredient("ash", 1) }, TECH.TURFCRAFTING_ONE,
	{ numtogive = 4 }, { "DECOR" })
AddRecipe2("turf_tidalmarsh", { Ingredient("cutgrass", 2), Ingredient("nitre", 1) }, TECH.TURFCRAFTING_ONE,
	{ numtogive = 4 }, { "DECOR" })
AddRecipe2("turf_meadow", { Ingredient("cutgrass", 2) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 },
	{ "DECOR" })
AddRecipe2("turf_beach", { Ingredient("sand", 2) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 },
	{ "DECOR" })
-- AddRecipe2("turf_fields", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_suburb", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_gasjungle", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_checkeredlawn", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_deeprainforest", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_rainforest", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_pigruins", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_antfloor", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_batfloor", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_battleground", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_painted", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_plains", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })
-- AddRecipe2("turf_beardrug", { Ingredient("oinc", 1) }, TECH.TURFCRAFTING_ONE, { numtogive = 4 }, { "DECOR" })



--INTERIOR--

AddRecipe2("player_house_cottage_craft", { Ingredient("oinc", 20) }, TECH.HOME_ONE, {}, { "INTERIOR" })
AddRecipe2("player_house_tudor_craft", { Ingredient("oinc", 20) }, TECH.HOME_ONE, {}, { "INTERIOR" })
AddRecipe2("player_house_gothic_craft", { Ingredient("oinc", 20) }, TECH.HOME_ONE, {}, { "INTERIOR" })
AddRecipe2("player_house_brick_craft", { Ingredient("oinc", 20) }, TECH.HOME_ONE, {}, { "INTERIOR" })
AddRecipe2("player_house_turret_craft", { Ingredient("oinc", 20) }, TECH.HOME_ONE, {}, { "INTERIOR" })
AddRecipe2("player_house_villa_craft", { Ingredient("oinc", 30) }, TECH.HOME_ONE, {}, { "INTERIOR" })
AddRecipe2("player_house_manor_craft", { Ingredient("oinc", 30) }, TECH.HOME_ONE, {}, { "INTERIOR" })

-- Ported from the 31addtest house-extension flow. A permit is offered to an
-- unlinked interior door to create and connect the adjacent room.
AddRecipe2("construction_permit", { Ingredient("oinc", 50) }, TECH.HOME_ONE,
	{ nounlock = true, no_deconstruction = true }, { "INTERIOR" })

AddRecipe2("demolition_permit", { Ingredient("oinc", 25) }, TECH.HOME_ONE,
	{ nounlock = true, no_deconstruction = true }, { "INTERIOR" })

AddRecipe2("packing_permit", { Ingredient("oinc", 25) }, TECH.HOME_ONE,
	{ nounlock = true, no_deconstruction = true }, { "INTERIOR" })




AddRecipe2("stone_door", { Ingredient("oinc", 25) }, TECH.HOME_ONE,
	{

		nounlock = true,
		image = "stone_door.tex",
		min_spacing = 1,
		placer = "stone_door_placer",
		build_mode = "insidedoor"
	},
	{ "INTERIOR" })
AddRecipe2("plate_door", { Ingredient("oinc", 25) }, TECH.HOME_ONE,
	{

		nounlock = true,
		image = "plate_door.tex",
		min_spacing = 1,
		placer = "plate_door_placer",
		build_mode = "insidedoor"
	}, { "INTERIOR" })
AddRecipe2("organic_door", { Ingredient("oinc", 25) }, TECH.HOME_ONE,
	{

		nounlock = true,
		image = "organic_door.tex",
		min_spacing = 1,
		placer = "organic_door_placer",
		build_mode = "insidedoor"
	}, { "INTERIOR" })
AddRecipe2("round_door", { Ingredient("oinc", 25) }, TECH.HOME_ONE,
	{

		nounlock = true,
		image = "round_door.tex",
		min_spacing = 1,
		placer = "round_door_placer",
		build_mode = "insidedoor"
	}, { "INTERIOR" })

local function AddInteriorExpansionDoorRecipe(name, cost)
	if AllRecipes[name] ~= nil then
		return
	end
	AddRecipe2(name, { Ingredient("oinc", cost) }, TECH.HOME_ONE,
		{
			nounlock = true,
			min_spacing = 1,
			placer = name .. "_placer",
			build_mode = "insidedoor",
		}, { "INTERIOR" })
end

AddInteriorExpansionDoorRecipe("wood_door", 10)
AddInteriorExpansionDoorRecipe("iron_door", 15)
AddInteriorExpansionDoorRecipe("curtain_door", 15)
AddInteriorExpansionDoorRecipe("pillar_door", 20)


AddRecipe2("interior_floor_wood", { Ingredient("oinc", 5) }, TECH.HOME_ONE, { nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_floor_check", { Ingredient("oinc", 7) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_floor_plaid_tile", { Ingredient("oinc", 10) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_floor_sheet_metal", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_floor_transitional", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_floor_woodpanels", { Ingredient("oinc", 10) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_floor_herringbone", { Ingredient("oinc", 12) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_floor_hexagon", { Ingredient("oinc", 12) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_floor_hoof_curvy", { Ingredient("oinc", 12) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_floor_octagon", { Ingredient("oinc", 12) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })

AddRecipe2("interior_wall_checkered_metal", { Ingredient("oinc", 1) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_wall_circles", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_wall_marble", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_wall_sunflower", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_wall_wood", { Ingredient("oinc", 10) }, TECH.HOME_ONE, { nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_wall_mayorsoffice", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_wall_harlequin", { Ingredient("oinc", 4) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_wall_fullwall_moulding", { Ingredient("oinc", 4) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })
AddRecipe2("interior_wall_floral", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("interior_wall_upholstered", { Ingredient("oinc", 10) }, TECH.HOME_ONE,
	{ nounlock = true }, { "INTERIOR" })



----------------------new windows------------------
local function AddWallSectionRecipe(name, oincvalue, data)
	local presetoincvalue = oincvalue or 5
	local prefabname = ((name:find("wallornament") or name:find("antiquities")) and ("deco_" .. name)) or name
	AddRecipe2(prefabname,
		{ Ingredient("oinc", presetoincvalue) }, TECH.HOME_ONE,
		{

			nounlock = true,
			build_mode = data and data.buildmode or "wallsection",
			min_spacing = 0,
			placer = prefabname .. "_placer",
			image = "reno_" .. name .. ".tex"
		},
		{ "INTERIOR" })
end

-- AddWallSectionRecipe("window_round", 3) ----------------这俩没制作栏贴图
-- AddWallSectionRecipe("window_round_curtains_nails", 4)
local WALL_SECTION_RECIPES = {
	{ "window_round_burlap", 4 },
	{ "window_small_peaked", 3 },
	{ "window_small_peaked_curtain", 4 },
	{ "window_large_square", 4 },
	{ "window_large_square_curtain", 5 },
	{ "window_tall", 4 },
	{ "window_tall_curtain", 5 },
	{ "window_greenhouse", 8 },
	{ "wallornament_axe", 5 },
	{ "wallornament_photo", 2 },
	{ "wallornament_embroidery_hoop", 3 },
	{ "wallornament_mosaic", 4 },
	{ "wallornament_wreath", 4 },
	{ "wallornament_hunt", 5 },
	{ "wallornament_periodic_table", 5 },
	{ "wallornament_gears_art", 8 },
	{ "wallornament_cape", 5 },
	{ "wallornament_no_smoking", 3 },
	{ "wallornament_black_cat", 5 },
	{ "antiquities_wallfish", 5 },
	{ "antiquities_beefalo", 10 },
	{ "wallornament_fulllength_mirror", 10 },
}

for _, recipe in ipairs(WALL_SECTION_RECIPES) do
	AddWallSectionRecipe(recipe[1], recipe[2])
end
-- AddRecipe2("reno_antiquities_beefalo", { Ingredient("oinc", 10) }, TECH.HOME_ONE, {

-- AddWallSectionRecipe("wallornament_chalkboard") -----这些没有制作栏贴图
-- AddWallSectionRecipe("wallornament_whiteboard")
-- AddWallSectionRecipe("wallornament_fulllength_mirror")
-- AddWallSectionRecipe("wallornament_cage")
-- AddWallSectionRecipe("wallornament_shield03")
-- AddWallSectionRecipe("wallornament_shield02")
-- AddWallSectionRecipe("wallornament_shield")
-- AddWallSectionRecipe("wallornament_spears")
-- AddWallSectionRecipe("wallornament_violet")





local function AddLightRecipe(name, oincvalue)
	local presetoincvalue = oincvalue or 5
	local prefabname = "swinging_" .. name
	AddRecipe2(prefabname,
		{ Ingredient("oinc", presetoincvalue) }, TECH.HOME_ONE,
		{

			nounlock = true,
			build_mode = "interior",
			min_spacing = 0,
			placer = prefabname .. "_placer",
			image = "reno_" .. name .. ".tex"
		},
		{ "INTERIOR" })
end

local CEILING_LIGHT_RECIPES = {
	{ "light_basic_bulb", 4 },
	{ "light_basic_metal", 4 },
	{ "light_chandalier_candles", 5 },
	{ "light_rope_1", 5 },
	{ "light_rope_2", 5 },
	{ "light_floral_bulb", 8 },
	{ "light_pendant_cherries", 5 },
	{ "light_floral_scallop", 3 },
	{ "light_floral_bloomer", 5 },
	{ "light_tophat", 2 },
	{ "light_derby", 10 },
}

for _, recipe in ipairs(CEILING_LIGHT_RECIPES) do
	AddLightRecipe(recipe[1], recipe[2])
end



AddRecipe2("reno_cornerbeam_wood", { Ingredient("oinc", 1) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("reno_cornerbeam_millinery", { Ingredient("oinc", 1) }, TECH.HOME_ONE, {

	nounlock = true
}, { "INTERIOR" })
AddRecipe2("reno_cornerbeam_round", { Ingredient("oinc", 1) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })
AddRecipe2("reno_cornerbeam_marble", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = true },
	{ "INTERIOR" })

local function AddShelfRecipe(name, oincvalue)
	local presetoincvalue = oincvalue or 5
	local prefabname = ((name:find("wallornament") or name:find("antiquities")) and ("deco_" .. name)) or name
	AddRecipe2(prefabname,
		{ Ingredient("oinc", presetoincvalue) }, TECH.HOME_ONE,
		{

			nounlock = false,
			-- build_mode = data and data.buildmode or "wallsection",
			min_spacing = 3.2,
			placer = prefabname .. "_placer",
			image = "reno_" .. name .. ".tex"
		},
		{ "INTERIOR" })
end

local SHELF_RECIPES = {
	{ "shelves_wood", 2 },
	{ "shelves_basic", 2 },
	{ "shelves_floating", 5 },
	{ "shelves_marble", 5 },
	{ "shelves_glass", 5 },
	{ "shelves_ladder", 5 },
	{ "shelves_hutch", 5 },
	{ "shelves_industrial", 5 },
	{ "shelves_adjustable", 5 },
	{ "shelves_fridge", 5 },
	{ "shelves_cinderblocks", 5 },
	{ "shelves_midcentury", 5 },
	{ "shelves_wallmount", 5 },
	{ "shelves_aframe", 5 },
	{ "shelves_crates", 5 },
	{ "shelves_pipe", 5 },
	{ "shelves_hattree", 5 },
	{ "shelves_pallet", 5 },
}

for _, recipe in ipairs(SHELF_RECIPES) do
	AddShelfRecipe(recipe[1], recipe[2])
end
-- AddShelfRecipe("shelves_hooks")
-- AddShelfRecipe("shelves_displaycase")
-- AddShelfRecipe("shelves_displaycase_metal")

AddRecipe2("deco_lamp_fringe", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_fringe_placer",
		image =
		"reno_lamp_fringe.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_stainglass", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_stainglass_placer",
		image = "reno_lamp_stainglass.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_downbridge", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_downbridge_placer",
		image = "reno_lamp_downbridge.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_2embroidered", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_2embroidered_placer",
		image = "reno_lamp_2embroidered.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_ceramic", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_ceramic_placer",
		image = "reno_lamp_ceramic.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_glass", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_glass_placer",
		image =
		"reno_lamp_glass.tex"
	},
	{ "INTERIOR" })
AddRecipe2("deco_lamp_2fringes", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_2fringes_placer",
		image = "reno_lamp_2fringes.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_candelabra", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_candelabra_placer",
		image = "reno_lamp_candelabra.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_elizabethan", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_elizabethan_placer",
		image = "reno_lamp_elizabethan.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_gothic", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_gothic_placer",
		image =
		"reno_lamp_gothic.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_orb", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "deco_lamp_orb_placer", image = "reno_lamp_orb.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_lamp_bellshade", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_bellshade_placer",
		image = "reno_lamp_bellshade.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_crystals", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_crystals_placer",
		image = "reno_lamp_crystals.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_upturn", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_upturn_placer",
		image =
		"reno_lamp_upturn.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_2upturns", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_2upturns_placer",
		image = "reno_lamp_2upturns.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_spool", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_spool_placer",
		image =
		"reno_lamp_spool.tex"
	},
	{ "INTERIOR" })
AddRecipe2("deco_lamp_edison", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_edison_placer",
		image =
		"reno_lamp_edison.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_adjustable", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_adjustable_placer",
		image = "reno_lamp_adjustable.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_rightangles", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_rightangles_placer",
		image = "reno_lamp_rightangles.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_lamp_hoofspa", { Ingredient("oinc", 8) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_lamp_hoofspa_placer",
		image = "reno_lamp_hoofspa.tex"
	}, { "INTERIOR" })

AddRecipe2("deco_table_round", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_table_round_placer",
		image =
		"reno_table_round.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_table_banker", { Ingredient("oinc", 4) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_table_banker_placer",
		image = "reno_table_banker.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_table_diy", { Ingredient("oinc", 3) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "deco_table_diy_placer", image = "reno_table_diy.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_table_raw", { Ingredient("oinc", 1) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "deco_table_raw_placer", image = "reno_table_raw.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_table_crate", { Ingredient("oinc", 1) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_table_crate_placer",
		image =
		"reno_table_crate.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_table_chess", { Ingredient("oinc", 1) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_table_chess_placer",
		image =
		"reno_table_chess.tex"
	}, { "INTERIOR" })

AddRecipe2("deco_plantholder_basic", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_basic_placer",
		image = "reno_plantholder_basic.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_wip", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_wip_placer",
		image = "reno_plantholder_wip.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_fancy", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_fancy_placer",
		image = "reno_plantholder_fancy.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_bonsai", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_bonsai_placer",
		image = "reno_plantholder_bonsai.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_dishgarden", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_dishgarden_placer",
		image = "reno_plantholder_dishgarden.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_philodendron", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_philodendron_placer",
		image = "reno_plantholder_philodendron.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_orchid", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_orchid_placer",
		image = "reno_plantholder_orchid.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_draceana", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_draceana_placer",
		image = "reno_plantholder_draceana.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_xerographica", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_xerographica_placer",
		image = "reno_plantholder_xerographica.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_birdcage", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_birdcage_placer",
		image = "reno_plantholder_birdcage.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_palm", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_palm_placer",
		image = "reno_plantholder_palm.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_zz", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_zz_placer",
		image = "reno_plantholder_zz.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_fernstand", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_fernstand_placer",
		image = "reno_plantholder_fernstand.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_fern", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_fern_placer",
		image = "reno_plantholder_fern.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_terrarium", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_terrarium_placer",
		image = "reno_plantholder_terrarium.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_plantpet", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_plantpet_placer",
		image = "reno_plantholder_plantpet.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_traps", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_traps_placer",
		image = "reno_plantholder_traps.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_plantholder_pitchers", { Ingredient("oinc", 6) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "deco_plantholder_pitchers_placer",
		image = "reno_plantholder_pitchers.tex"
	}, { "INTERIOR" })

AddRecipe2("deco_chair_classic", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "chair_classic_placer",
		image =
		"reno_chair_classic.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_chair_corner", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "chair_corner_placer", image = "reno_chair_corner.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_chair_bench", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "chair_bench_placer", image = "reno_chair_bench.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_chair_horned", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "chair_horned_placer", image = "reno_chair_horned.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_chair_footrest", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "chair_footrest_placer",
		image = "reno_chair_footrest.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_chair_lounge", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "chair_lounge_placer", image = "reno_chair_lounge.tex" },
	{ "INTERIOR" })
AddRecipe2("deco_chair_massager", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "chair_massager_placer",
		image = "reno_chair_massager.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_chair_stuffed", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "chair_stuffed_placer",
		image =
		"reno_chair_stuffed.tex"
	}, { "INTERIOR" })
AddRecipe2("deco_chair_rocking", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 1,
		placer = "chair_rocking_placer",
		image =
		"reno_chair_rocking.tex"
	}, { "INTERIOR" })

local INTERIOR_DECOR_RECIPES = {
	{
		prefab = "deco_chaise",
		ingredients = { Ingredient("oinc", 2) },
		placer = "deco_chaise_placer",
		image = "reno_chair_chaise.tex",
	},
	{
		prefab = "deco_chair_ottoman",
		ingredients = { Ingredient("oinc", 2) },
		placer = "chair_ottoman_placer",
		image = "reno_chair_ottoman.tex",
	},
	{
		prefab = "deco_plantholder_marble",
		ingredients = { Ingredient("oinc", 6) },
		placer = "deco_plantholder_marble_placer",
		image = "reno_plantholder_marble.tex",
	},
	{
		prefab = "deco_plantholder_winterfeasttreeofsadness",
		ingredients = { Ingredient("oinc", 2), Ingredient("twigs", 1) },
		placer = "deco_plantholder_winterfeasttreeofsadness_placer",
		image = "reno_plantholder_winterfeasttreeofsadness.tex",
	},
	{
		prefab = "deco_plantholder_winterfeasttree",
		ingredients = { Ingredient("oinc", 50) },
		placer = "deco_plantholder_winterfeasttree_placer",
		image = "reno_lamp_festivetree.tex",
	},
}

for _, recipe in ipairs(INTERIOR_DECOR_RECIPES) do
	AddRecipe2(recipe.prefab, recipe.ingredients, TECH.HOME_ONE,
		{
			nounlock = false,
			min_spacing = 1,
			placer = recipe.placer,
			image = recipe.image,
		},
		{ "INTERIOR" })
end



AddRecipe2("rug_round", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_round_placer", image = "reno_rug_round.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_square", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_square_placer", image = "reno_rug_square.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_oval", { Ingredient("oinc", 2) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_oval_placer", image = "reno_rug_oval.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_rectangle", { Ingredient("oinc", 3) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 0,
		placer = "rug_rectangle_placer",
		image =
		"reno_rug_rectangle.tex"
	}, { "INTERIOR" })
AddRecipe2("rug_fur", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_fur_placer", image = "reno_rug_fur.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_hedgehog", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_hedgehog_placer", image = "reno_rug_hedgehog.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_porcupuss", { Ingredient("oinc", 10) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 0,
		placer = "rug_porcupuss_placer",
		image =
		"reno_rug_porcupuss.tex"
	}, { "INTERIOR" })
AddRecipe2("rug_hoofprint", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 0,
		placer = "rug_hoofprint_placer",
		image =
		"reno_rug_hoofprint.tex"
	}, { "INTERIOR" })
AddRecipe2("rug_octagon", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_octagon_placer", image = "reno_rug_octagon.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_swirl", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_swirl_placer", image = "reno_rug_swirl.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_catcoon", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_catcoon_placer", image = "reno_rug_catcoon.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_rubbermat", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{

		nounlock = false,
		min_spacing = 0,
		placer = "rug_rubbermat_placer",
		image = "reno_rug_rubbermat.tex"
	}, { "INTERIOR" })
AddRecipe2("rug_web", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_web_placer", image = "reno_rug_web.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_metal", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_metal_placer", image = "reno_rug_metal.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_wormhole", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_wormhole_placer", image = "reno_rug_wormhole.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_braid", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_braid_placer", image = "reno_rug_braid.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_beard", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_beard_placer", image = "reno_rug_beard.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_nailbed", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_nailbed_placer", image = "reno_rug_nailbed.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_crime", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_crime_placer", image = "reno_rug_crime.tex" },
	{ "INTERIOR" })
AddRecipe2("rug_tiles", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 0, placer = "rug_tiles_placer", image = "reno_rug_tiles.tex" },
	{ "INTERIOR" })

GLOBAL.CONSTRUCTION_PLANS["collapsed_honeychest"] = { Ingredient("chitin", 3), Ingredient("beeswax", 1), Ingredient(
	"honey", 2), Ingredient("alterguardianhatshard", 1) }
GLOBAL.CONSTRUCTION_PLANS["pugaliskfountain_made"] = { Ingredient("ice", 10), Ingredient("waterdrop", 1) }
GLOBAL.CONSTRUCTION_PLANS["seaworthy_broken"] = { Ingredient("transistor", 4), Ingredient("gears", 4) }
GLOBAL.CONSTRUCTION_PLANS["seaworthy"] = GLOBAL.CONSTRUCTION_PLANS["seaworthy_broken"]
GLOBAL.CONSTRUCTION_PLANS["ligamundosw"] = GLOBAL.CONSTRUCTION_PLANS["seaworthy_broken"]
GLOBAL.CONSTRUCTION_PLANS["skyworthy_broken"] = { Ingredient("transistor", 4), Ingredient("gears", 4) }
GLOBAL.CONSTRUCTION_PLANS["skyworthy"] = GLOBAL.CONSTRUCTION_PLANS["skyworthy_broken"]

AddRecipe2("bed0", { Ingredient("oinc", 5) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed0_placer" },
	{ "INTERIOR" })
AddRecipe2("bed1", { Ingredient("oinc", 7) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed1_placer" },
	{ "INTERIOR" })
AddRecipe2("bed2", { Ingredient("oinc", 10) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed2_placer" }, { "INTERIOR" })
AddRecipe2("bed3", { Ingredient("oinc", 12) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed3_placer" }, { "INTERIOR" })
AddRecipe2("bed4", { Ingredient("oinc", 14) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed4_placer" }, { "INTERIOR" })
AddRecipe2("bed5", { Ingredient("oinc", 16) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed5_placer" }, { "INTERIOR" })
AddRecipe2("bed6", { Ingredient("oinc", 18) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed6_placer" }, { "INTERIOR" })
AddRecipe2("bed7", { Ingredient("oinc", 20) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed7_placer" }, { "INTERIOR" })
AddRecipe2("bed8", { Ingredient("oinc", 22) }, TECH.HOME_ONE,
	{ nounlock = false, min_spacing = 1, placer = "bed8_placer" }, { "INTERIOR" })

-- Sort

-- Extend recipes
-- CHARACTER with skill
-- WILSON
AddCharacterRecipe("transmute_bamboo", { Ingredient("cutgrass", 2) }, TECH.NONE,
	{
		product = "bamboo",
		builder_skill = "wilson_alchemy_1",
		description = "transmute_bamboo",
		sort_after = {
			{ recipe = "transmute_twigs", filter = "CHARACTER" }
		}
	})
AddCharacterRecipe("transmute_cutgrass_tro", { Ingredient("bamboo", 1) }, TECH.NONE,
	{
		product = "cutgrass",
		builder_skill = "wilson_alchemy_1",
		description = "transmute_cutgrass_tro",
		sort_after = {
			{ recipe = "transmute_bamboo", filter = "CHARACTER" }
		}
	})
AddCharacterRecipe("transmute_vine", { Ingredient("twigs", 2) }, TECH.NONE,
	{
		product = "vine",
		builder_skill = "wilson_alchemy_1",
		description = "transmute_vine",
		sort_after = {
			{ recipe = "transmute_cutgrass_tro", filter = "CHARACTER" }
		}
	})
AddCharacterRecipe("transmute_twigs_tro", { Ingredient("vine", 1) }, TECH.NONE,
	{
		product = "twigs",
		builder_skill = "wilson_alchemy_1",
		description = "transmute_twings_tro",
		sort_after = {
			{ recipe = "transmute_vine", filter = "CHARACTER" }
		}
	})
AddCharacterRecipe("transmute_cork", { Ingredient("driftwood_log", 2) }, TECH.NONE,
	{
		product = "cork",
		builder_skill = "wilson_alchemy_1",
		description = "transmute_cork",
		sort_after = {
			{ recipe = "transmute_twigs_tro", filter = "CHARACTER" }
		}
	})
AddCharacterRecipe("transmute_driftwood_log_tro", { Ingredient("cork", 2) }, TECH.NONE,
	{
		product = "driftwood_log",
		builder_skill = "wilson_alchemy_1",
		description = "transmute_driftwood_log_tro",
		sort_after = {
			{ recipe = "transmute_cork", filter = "CHARACTER" }
		}
	})

AddCharacterRecipe("wormwood_seaweed_stalk",
	{ Ingredient(CHARACTER_INGREDIENT.HEALTH, 10), Ingredient("spoiled_food", 3), Ingredient("kelp", 8) }, TECH.NONE,
	{
		builder_skill = "wormwood_juicyberrybushcrafting",
		product = "seaweed_stalk",
		sg_state = "form_log",
		actionstr = "GROW",
		allowautopick = true,
		no_deconstruction = true,
		description = "wormwood_seaweed_stalk",
		sort_after = {
			{ recipe = "wormwood_juicyberrybush", filter = "CHARACTER" }
		}
	})
