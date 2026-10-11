---------------------------- new recipe tab for obsidian tools ---------------------
local require = require
local TechTree = require("techtree")

local tab_atlas = "images/ui/tabs.xml"


table.insert(TechTree.AVAILABLE_TECH, "OBSIDIAN")
table.insert(TechTree.AVAILABLE_TECH, "CITY")
table.insert(TechTree.AVAILABLE_TECH, "HOME")

TechTree.Create = function(t)
	t = t or {}
	for i, v in ipairs(TechTree.AVAILABLE_TECH) do
		t[v] = t[v] or 0
	end
	return t
end

TECH.NONE.OBSIDIAN = 0
TECH.OBSIDIAN_ONE = { OBSIDIAN = 1 }
TECH.OBSIDIAN_TWO = { OBSIDIAN = 2 }

TECH.NONE.CITY = 0
TECH.CITY_ONE = { CITY = 1 }
TECH.CITY_TWO = { CITY = 2 }

TECH.NONE.HOME = 0
TECH.HOME_ONE = { HOME = 1 }
TECH.HOME_TWO = { HOME = 2 }



--------------------------------------------------------------------------
--[[ 解锁等级中加入自己的部分 ]]
--------------------------------------------------------------------------

for k, v in pairs(TUNING.PROTOTYPER_TREES) do
	v.OBSIDIAN = 0
	v.CITY = 0
	v.HOME = 0
end


TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE = TechTree.Create({ OBSIDIAN = 1, })
TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO = TechTree.Create({ OBSIDIAN = 2, })

TUNING.PROTOTYPER_TREES.CITY_ONE = TechTree.Create({ CITY = 1, })
TUNING.PROTOTYPER_TREES.CITY_TWO = TechTree.Create({ CITY = 2, })

TUNING.PROTOTYPER_TREES.HOME_ONE = TechTree.Create({ HOME = 1, })
TUNING.PROTOTYPER_TREES.HOME_TWO = TechTree.Create({ HOME = 2, })


TUNING.PROTOTYPER_TREES.SEA_SCIENCE = TechTree.Create({ SCIENCE = 2, SEAFARING = 2 })

for i, v in pairs(AllRecipes) do
	if v.level.OBSIDIAN == nil then v.level.OBSIDIAN = 0 end
	if v.level.CITY == nil then v.level.CITY = 0 end
	if v.level.HOME == nil then v.level.HOME = 0 end
end



AddPrototyperDef("obsidian_workbench",
	{ action_str = "FORGE", icon_image = "tab_volcano.tex", icon_atlas = tab_atlas, is_crafting_station = true })
AddPrototyperDef("key_to_city", { icon_image = "tab_city.tex", icon_atlas = tab_atlas })
AddPrototyperDef("researchlab5", { icon_image = "station_science.tex", icon_atlas = CRAFTING_ICONS_ATLAS })

----action_str 是动作文本，和制作栏界面按钮没关系，需修改recipe.actionstr
---------------------

-- PROTOTYPER_DEFS.researchlab5 = PROTOTYPER_DEFS.researchlab2
PROTOTYPER_DEFS.piratihatitator = PROTOTYPER_DEFS.researchlab4
PROTOTYPER_DEFS.hogusporkusator = PROTOTYPER_DEFS.researchlab4



AddRecipeFilter({ name = "NAUTICAL", atlas = tab_atlas, image = "tab_nautical.tex" })
AddRecipeFilter({ name = "HAMLET", atlas = tab_atlas, image = "tab_city.tex" })
AddRecipeFilter({ name = "INTERIOR", atlas = tab_atlas, image = "tab_home_decor.tex" })
AddRecipeFilter({ name = "LEGACY", atlas = tab_atlas, image = "tab_archaeology.tex" })
