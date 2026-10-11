local TrawlHelper = require("tools/trawl_helper")

local function MakeFreeSwimmingTrawlable(inst, fn)
    TrawlHelper.ConfigureSwimmingTrawlable(inst, fn)
end

local function MakeKelpCompatTrawlable(inst)
    if not TheWorld.ismastersim then
        return
    end

    local trawlable = TrawlHelper.ConfigureKelpCompatTrawlable(inst)
    trawlable:SetIgnoreVisibility(true)
end

local function MakeMusselCompatTrawlable(inst)
    if not TheWorld.ismastersim then
        return
    end

    TrawlHelper.ConfigureMusselCompatTrawlable(inst)
end

local function MakeSunkenPrefabTrawlable(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("trawltarget")
    TrawlHelper.ConfigureSunkenPrefabTrawlable(inst)
end

local function MakeOceanFishTrawlable(inst)
    if not TheWorld.ismastersim then
        return
    end

    MakeFreeSwimmingTrawlable(inst, function(fish)
        local item = TrawlHelper.MakeInventoryFish(fish)
        if item == nil then
            return nil
        end

        item.Transform:SetPosition(fish.Transform:GetWorldPosition())
        item.Transform:SetRotation(fish.Transform:GetRotation())
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:MakeMoistureAtLeast(TUNING.MAX_WETNESS)
        end
        TrawlHelper.CopyWeighable(fish, item)
        fish:Remove()
        return item
    end)
end

local function MakeWobsterTrawlable(landprefab)
    return function(inst)
        inst:AddTag("lobster")
        if not TheWorld.ismastersim then
            return
        end

        MakeFreeSwimmingTrawlable(inst, function(wobster)
        local item = SpawnPrefab(landprefab)
        if item ~= nil then
            item.Transform:SetPosition(wobster.Transform:GetWorldPosition())
            item.Transform:SetRotation(wobster.Transform:GetRotation())
            TrawlHelper.CopyWeighable(wobster, item)
        end
        wobster:Remove()
        return item
        end)
    end
end

local function MakeUnderwaterFishTrawlable(invprefab)
    return function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:AddTag("oceanfish")
        MakeFreeSwimmingTrawlable(inst, function(fish)
            local item = Prefabs[invprefab] ~= nil and SpawnPrefab(invprefab) or nil
            if item ~= nil then
                item.Transform:SetPosition(fish.Transform:GetWorldPosition())
                item.Transform:SetRotation(fish.Transform:GetRotation())
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:MakeMoistureAtLeast(TUNING.MAX_WETNESS)
                end
                TrawlHelper.CopyWeighable(fish, item)
            end
            fish:Remove()
            return item
        end)
    end
end

local function GetShoalChild(shoal)
    local spawner = shoal.components.childspawner
    if spawner == nil then
        return nil
    end

    for child in pairs(spawner.childrenoutside) do
        if child ~= nil and child:IsValid() and child:HasTag("oceanfish") then
            return child
        end
    end

    return nil
end

local function MakeShoalInventoryFish(shoal, fish)
    local spawner = shoal.components.childspawner
    local fishprefab = fish ~= nil and fish:IsValid() and (fish.fish_def ~= nil and fish.fish_def.prefab or fish.prefab)
        or spawner ~= nil and spawner.childname
        or nil
    local item = TrawlHelper.SpawnFirstPrefab(fishprefab ~= nil and fishprefab .. "_inv" or nil)
    if item == nil then
        return nil
    end

    item.Transform:SetPosition(shoal.Transform:GetWorldPosition())
    if item.components.inventoryitem ~= nil then
        item.components.inventoryitem:MakeMoistureAtLeast(TUNING.MAX_WETNESS)
    end
    TrawlHelper.CopyWeighable(fish, item)

    if fish ~= nil and fish:IsValid() then
        fish:Remove()
    elseif spawner ~= nil and spawner.childreninside > 0 then
        spawner.childreninside = spawner.childreninside - 1
        if spawner.childreninside == 0 and spawner.onvacate ~= nil then
            spawner.onvacate(shoal)
        end
    end

    return item
end

local function MakeShoalTrawlable(inst)
    if not TheWorld.ismastersim then
        return
    end

    MakeFreeSwimmingTrawlable(inst, function(shoal)
        local fish = GetShoalChild(shoal)
        if fish == nil and shoal.components.childspawner ~= nil and shoal.components.childspawner.childreninside <= 0 then
            return nil
        end

        local item = MakeShoalInventoryFish(shoal, fish)
        if fish ~= nil then
            TheWorld:PushEvent("ms_shoalfishhooked", shoal)
        end
        return item
    end)
end

local function GetSchoolHerdFish(herd)
    local herdcomponent = herd.components.herd
    if herdcomponent == nil then
        return nil
    end

    for fish in pairs(herdcomponent.members) do
        if fish ~= nil and fish:IsValid() and fish:HasTag("oceanfish") then
            return fish
        end
    end

    return nil
end

local function MakeSchoolHerdTrawlable(inst)
    if not TheWorld.ismastersim then
        return
    end

    MakeFreeSwimmingTrawlable(inst, function(herd)
        local fish = GetSchoolHerdFish(herd)
        if fish == nil then
            return nil
        end
        return MakeShoalInventoryFish(herd, fish)
    end)
end

for i = 1, 9 do
    AddPrefabPostInit("oceanfish_small_" .. i, MakeOceanFishTrawlable)
    AddPrefabPostInit("oceanfish_medium_" .. i, MakeOceanFishTrawlable)
    AddPrefabPostInit("schoolherd_oceanfish_small_" .. i, MakeSchoolHerdTrawlable)
    AddPrefabPostInit("schoolherd_oceanfish_medium_" .. i, MakeSchoolHerdTrawlable)
end

for _, index in ipairs({ 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 61, 71, 81, 91 }) do
    AddPrefabPostInit("oceanfish_small_" .. index, MakeOceanFishTrawlable)
    AddPrefabPostInit("schoolherd_oceanfish_small_" .. index, MakeSchoolHerdTrawlable)
end

for i = 1, 9 do
    AddPrefabPostInit("oceanfish_small_underwater_" .. i, MakeUnderwaterFishTrawlable("oceanfish_small_" .. i .. "_inv"))
    AddPrefabPostInit("oceanfish_medium_underwater_" .. i, MakeUnderwaterFishTrawlable("oceanfish_medium_" .. i .. "_inv"))
end

AddPrefabPostInit("wobster_sheller", MakeWobsterTrawlable("wobster_sheller_land"))
AddPrefabPostInit("wobster_moonglass", MakeWobsterTrawlable("wobster_moonglass_land"))
AddPrefabPostInit("oceanfish_shoalspawner", MakeShoalTrawlable)
AddPrefabPostInit("sunkenprefab", MakeSunkenPrefabTrawlable)

for prefab in pairs(TrawlHelper.kelp_compat_prefabs) do
    AddPrefabPostInit(prefab, MakeKelpCompatTrawlable)
end

for prefab in pairs(TrawlHelper.mussel_compat_prefabs) do
    AddPrefabPostInit(prefab, MakeMusselCompatTrawlable)
end

AddPrefabPostInitAny(function(inst)
    local prefab = inst.prefab
    if prefab == nil or not TheWorld.ismastersim then
        return
    end

    if string.match(prefab, "^oceanfish_[^_]+_%d+$") then
        MakeOceanFishTrawlable(inst)
    elseif string.match(prefab, "^schoolherd_oceanfish_[^_]+_%d+$") then
        MakeSchoolHerdTrawlable(inst)
    elseif string.match(prefab, "^oceanfish_[^_]+_underwater_%d+$") then
        local invprefab = string.gsub(prefab, "_underwater_", "_") .. "_inv"
        MakeUnderwaterFishTrawlable(invprefab)(inst)
    elseif prefab == "wobster_sheller" then
        MakeWobsterTrawlable("wobster_sheller_land")(inst)
    elseif prefab == "wobster_moonglass" then
        MakeWobsterTrawlable("wobster_moonglass_land")(inst)
    elseif prefab == "oceanfish_shoalspawner" then
        MakeShoalTrawlable(inst)
    elseif TrawlHelper.IsSunkenPrefabTarget(inst) then
        MakeSunkenPrefabTrawlable(inst)
    elseif TrawlHelper.IsMusselCompatTarget(inst) then
        MakeMusselCompatTrawlable(inst)
    elseif TrawlHelper.IsKelpCompatTarget(inst) then
        MakeKelpCompatTrawlable(inst)
    end
end)
