require "cooking"
require "spicedfoods"
local foods = require "preparedfoods"
-- if foods.butterflymuffin then
--     local posttest = foods.butterflymuffin.test
--     foods.butterflymuffin.test = function(cooker, names, tags)
--         return names.butterfly_tropical_wings and not tags.meat and tags.veggie or posttest(cooker, names, tags)
--     end
-- end
if foods.californiaroll then
    local posttest = foods.californiaroll.test
    foods.californiaroll.test = function(cooker, names, tags)
        return ((names.kelp or 0) + (names.kelp_cooked or 0) + (names.kelp_dried or 0) + (names.seaweed or 0)) == 2 and
            (tags.fish and tags.fish >= 1) or posttest(cooker, names, tags)
    end
end
if foods.lobsterbisque then
    local posttest = foods.lobsterbisque.test
    foods.lobsterbisque.test = function(cooker, names, tags)
        return names.lobster_land and tags.frozen or posttest(cooker, names, tags)
    end
end
if foods.lobsterdinner then
    local posttest = foods.lobsterdinner.test
    foods.lobsterdinner.test = function(cooker, names, tags)
        return
            names.lobster_land and names.butter and (tags.meat and tags.meat <= 1) and (tags.fish and tags.fish <= 1) and
            not tags.frozen or posttest(cooker, names, tags)
    end
end

local foodsGrandDef = require("datadefs/preparedfoods_tro")


local globalcookerrecipes = require("cooking").recipes
local duplicated_recipes = {}
local _AddCookerRecipe = AddCookerRecipe


-------------这个方法是对原有的重复食谱进行修改
local AddCookerRecipe = function(cooker, recipe)
    -- if globalcookerrecipes then
    --     print("find global")
    --     if globalcookerrecipes[cooker] then
    --         print("not find global cooker")
    --         if globalcookerrecipes[cooker][recipe.name] then
    --             print("find global cooker recipes")
    --         end
    --     end
    -- end
    if not globalcookerrecipes or not globalcookerrecipes[cooker] or not globalcookerrecipes[cooker][recipe.name] then
        _AddCookerRecipe(cooker, recipe)
    else
        duplicated_recipes[recipe.name] = true
        local old_recipe = globalcookerrecipes[cooker][recipe.name]
        local oldtest = old_recipe.test
        local newtest = recipe.test
        old_recipe.test = function(cooker, names, tags)
            return (newtest(cooker, names, tags) or oldtest(cooker, names, tags))
        end

        for i, v in pairs(recipe) do
            local oldv = old_recipe[i]
            if oldv == nil then
                old_recipe[i] = v
                -- elseif oldv ~= v then
                --     if type(v) == "function" and type(oldv) == "function" then
                --         old_recipe[i] = function(...) return pcall(v(...) or oldv(...)) end
                --     end
            end
        end

        -- old_recipe.name = recipe.name
        -- old_recipe.imagename = recipe.name
        -- old_recipe.basename = recipe.basename
        -- old_recipe.overridebuild = recipe.overridebuild
        -- old_recipe.cookbook_atlas = recipe.cookbook_atlas
        -- old_recipe.atlasname = recipe.atlasname

        if env.cookerrecipes[cooker] == nil then
            env.cookerrecipes[cooker] = {}
        end
        if recipe.name then
            table.insert(env.cookerrecipes[cooker], recipe.name)
        end
    end
end

------这个方法是重新添加一个食谱，但有些问题解决不了
-- local AddCookerRecipe
-- AddCookerRecipe = function(cooker, recipe)
--     if (not globalcookerrecipes[cooker] or not globalcookerrecipes[cooker][recipe.name]) then
--         _AddCookerRecipe(cooker, recipe)
--     else
--         local name = recipe.name
--         recipe.overridesymbolname = recipe.overridesymbolname or name
--         recipe.imagename = recipe.imagename or name
--         recipe.basename = recipe.basename or name
--         recipe.name = name .. "_tro" or "tro food"
--         AddCookerRecipe(cooker, recipe)
--         if RegisterFoodAtlas then ----兼容智能锅----但为什么取不到呢，以及无可避免的物品栏贴图覆盖
--             print("register in smart crockpot")
--             RegisterFoodAtlas(name, recipe.imagename, recipe.cookbook_atlas)
--         end
--     end
-- end



for tabIdx, foodTab in pairs(foodsGrandDef) do
    for _, foodDef in pairs(foodTab) do
        if foodDef.isMasterfood == nil then
            AddCookerRecipe("cookpot", foodDef)
            AddCookerRecipe("archive_cookpot", foodDef)
        end
        AddCookerRecipe("portablecookpot", foodDef)
        if foodDef.card_def then
            AddRecipeCard("cookpot", foodDef)
        end
        if duplicated_recipes[foodDef.name] then
            print("duplicated_recipes", foodDef.name)
            foodTab[_] = nil
        end
    end
    GenerateSpicedFoods(foodTab) -----这个函数在env里没有
end

local spicedfoods = require("spicedfoods")
for _, foodDef in pairs(spicedfoods) do
    if foodDef.mod then
        AddCookerRecipe("portablespicer", foodDef)
    end
end

AddIngredientValues({ "butterfly_tropical_wings", }, { decoration = 2 }, true, false)
AddIngredientValues({ "crab", "limpets", "mussel", }, { fish = 0.5 }, true, false)
AddIngredientValues({ "coconut_cooked", "coconut_halved", }, { fruit = 1, fat = 1 }, true, false)
AddIngredientValues({ "coffeebeans", }, { fruit = .5 }, true, false)
AddIngredientValues({ "coffeebeans_cooked", }, { fruit = 1 }, true, false)
AddIngredientValues(
    { "aloe", "asparagus", "foliage", "lotus_flower", "quagmire_spotspice_sprig", "radish", "seacucumber",
        "sweet_potato", "turnip", }, { veggie = 1 }, true, false)
AddIngredientValues({ "seaweed", }, { veggie = 1 }, true, true)
AddIngredientValues(
    { "coi", "dogfish_dead", "fish2", "fish3", "fish4", "fish5", "fish6", "fish7", "oceanfish_small_61_inv",
        "oceanfish_small_71_inv", "oceanfish_small_81_inv", "roe_cooked", "roe", "salmon", "shark_fin", },
    { meat = 0.5, fish = 1 }, true, false)
AddIngredientValues({ "swordfish_dead", }, { fish = 1.5 }, true, false)
AddIngredientValues({ "quagmire_crabmeat", }, { fish = 0.5, crab = 1 }, true, false)
AddIngredientValues({ "lobster_land", }, { meat = 1.0, fish = 1.0 }, false, false)
AddIngredientValues({ "fish_dogfish", }, { fish = 1 }, true, false)
AddIngredientValues({ "doydoyegg", }, { egg = 1 }, true, false)
AddIngredientValues({ "dorsalfin", }, { inedible = 1 }, true, false)
AddIngredientValues({ "jellyfish", "jellyfish_dead", "jellyjerky", }, { fish = 1, jellyfish = 1, monster = 1 }, true,
    false)
AddIngredientValues({ "snowitem", }, { meat = 0.5, frozen = 1 }, true, false)
AddIngredientValues({ "quagmire_sap", }, { sweetener = 1 }, true, false)
AddIngredientValues({ "seataro", }, { veggie = 1, frozen = 1 }, true, false)
AddIngredientValues({ "blueberries", }, { fruit = 0.5, frozen = 0.25 }, true, false)
AddIngredientValues({ "blueberries_cooked", }, { fruit = 0.75 }, true, false)
AddIngredientValues({ "quagmire_mushrooms", }, { mushroom = 1, veggie = 0.5 }, true, false)
AddIngredientValues({ "jellybug", "slugbug", }, { bug = 1 }, true, false)
AddIngredientValues({ "cutnettle", }, { antihistamine = 1 }, true, false)
AddIngredientValues({ "weevole_carapace", }, { inedible = 1 }, true, false)
AddIngredientValues({ "piko_orange", }, { filter = 1 }, true, false)
AddIngredientValues({ "snake_bone", }, { bone = 1 }, true, false)
AddIngredientValues({ "fennel", "yelow_cap", "yelow_cooked", }, { veggie = 0.5 }, true, false)
AddIngredientValues({ "quagmire_smallmeat", }, { meat = 0.5, smallmeat = 1 }, true, false) -- "smallmeat" for quagmire, I think

-- Craft Pot Support
-- Need 64x img
-- local state, ingtag = pcall(require, "ingredienttags")
-- if state then
--     AddFoodTag("antihistamine", { name = "Antihistamine", atlas = "images/inventory_hamlet.xml" })
--     AddFoodTag("bone", { name = "", atlas = "" })
--     AddFoodTag("crab", { name = "", atlas = "" })
--     AddFoodTag("filter", { name = "", atlas = "" })
--     AddFoodTag("jellyfish", { name = "", atlas = "" })
--     AddFoodTag("smallmeat", { name = "", atlas = "" })
-- end
-- STRINGS.NAMES.ANTIHISTAMINE = "Antihistamine"
