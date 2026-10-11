local TechTree = require("techtree")
local Utils = require("tools/utils")

local Builder = require("components/builder")
require("tools/prototyper_policy").ApplyBuilder(Builder)

Utils.FnDecorator(Builder, "MakeRecipeAtPoint", function(self, recipe)
    if not self:KnowsRecipe(recipe) and recipe.level.HOME and recipe.level.HOME <= 2 then
        self:AddRecipe(recipe.name)
        if recipe.nounlock then
            self.inst:DoTaskInTime(1, function()
                self:RemoveRecipe(recipe.name)
            end)
        end
    end
end)

-- function builder:MakeRecipeAtPoint(recipe, pt, rot, skin)
--     if recipe.placer ~= nil and self:KnowsRecipe(recipe.name) and ---为什么这个环节会出问题呢
--     self:IsBuildBuffered(recipe.name) and TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot) then
--         self:MakeRecipe(recipe, pt, rot, skin)
--     end
-- end

-- 装备智慧帽时解锁所有配方
Utils.FnDecorator(Builder, "KnowsRecipe", function(self, recipe)
    if type(recipe) == "string" then
        recipe = GetValidRecipe(recipe)
    end

    if recipe and not recipe.nounlock and not (recipe.level.ANCIENT and recipe.level.ANCIENT >= 10) and self.inst.components.inventory:EquipHasTag("brainjelly") then
        return { true }, true
    end
end)

local function get_oinc_cost(recipe)
    for _, v in ipairs(recipe.ingredients) do
        if v.type == "oinc" then
            return v.amount
        end
    end
end

Utils.FnDecorator(Builder, "HasIngredients", function(self, recipe)
    if type(recipe) == "string" then
        recipe = GetValidRecipe(recipe)
    end

    if not (recipe and get_oinc_cost(recipe)) then
        return
    end

    if self.freebuildmode then
        return { true }, true
    end
    for i, v in ipairs(recipe.ingredients) do
        local amount = math.max(1, RoundBiasedUp(v.amount * self.ingredientmod))
        if v.type == "oinc" then
            if self.inst.components.inventory:HasMoney() < amount then
                return { false }, true
            end
        else
            if not self.inst.components.inventory:Has(v.type, amount, true) then
                return { false }, true
            end
        end
    end
    for i, v in ipairs(recipe.character_ingredients) do
        if not self:HasCharacterIngredient(v) then
            return { false }, true
        end
    end
    for i, v in ipairs(recipe.tech_ingredients) do
        if not self:HasTechIngredient(v) then
            return { false }, true
        end
    end
    return { true }, true
end)

Utils.FnDecorator(Builder, "RemoveIngredients", function(self, ingredients, recname, ...)
    if not self.freebuildmode then
        local recipe = AllRecipes[recname]
        if recipe then
            local cost = get_oinc_cost(recipe)
            if cost then
                self.inst.components.inventory:PayMoney(math.max(1, RoundBiasedUp(cost * self.ingredientmod)))
                ingredients["oinc"] = nil
            end
        end
    end
    return nil, nil, { self, ingredients, recname, ... }
end)

----------------
--- @replica ---
----------------
local Builder_replica = require("components/builder_replica")
local InteriorBuildHeight = require "tools/interior_build_height"

local MakeRecipeAtPoint = Builder_replica.MakeRecipeAtPoint
function Builder_replica:MakeRecipeAtPoint(recipe, ...)
    InteriorBuildHeight.SyncForBuild(self.inst, recipe)
    return MakeRecipeAtPoint(self, recipe, ...)
end

Utils.FnDecorator(Builder_replica, "KnowsRecipe", function(self, recipe)
    if type(recipe) == "string" then
        recipe = GetValidRecipe(recipe)
    end

    if recipe and not recipe.nounlock and not (recipe.level.ANCIENT and recipe.level.ANCIENT >= 10) and self.inst.replica.inventory:EquipHasTag("brainjelly") then
        return { true }, true
    end
end)

local HasIngredients = Builder_replica.HasIngredients
function Builder_replica:HasIngredients(recipe, ...)
    local check_all_oincs = self.inst.replica.inventory.check_all_oincs
    self.inst.replica.inventory.check_all_oincs = true
    local ret = { HasIngredients(self, recipe, ...) }
    self.inst.replica.inventory.check_all_oincs = check_all_oincs
    return unpack(ret)
end
