local TrawlHelper = {}

local KELP_COMPAT_PREFABS = {
    seaweed_planted = "seaweed_stalk",
    bullkelp_plant = "bullkelp_root",
}

local MUSSEL_COMPAT_PREFABS = {
    mussel_farm = true,
}

TrawlHelper.kelp_compat_prefabs = KELP_COMPAT_PREFABS
TrawlHelper.mussel_compat_prefabs = MUSSEL_COMPAT_PREFABS

function TrawlHelper.CopyWeighable(source, target)
    if source ~= nil and target ~= nil
        and source.components.weighable ~= nil
        and target.components.weighable ~= nil
    then
        target.components.weighable:CopyWeighable(source.components.weighable)
    end
end

function TrawlHelper.SpawnFirstPrefab(...)
    for i = 1, select("#", ...) do
        local prefab = select(i, ...)
        if prefab ~= nil then
            local item = SpawnPrefab(prefab)
            if item ~= nil then
                return item
            end
        end
    end
end

local function PreparePrefabLoot(source, prefab, count)
    local loot = {}
    if prefab == nil then
        return loot
    end

    count = math.max(1, tonumber(count) or 1)

    local function additem(item, stack_size)
        if item == nil then
            return
        end
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:InheritWorldWetnessAtTarget(source)
        end

        if item.components.stackable ~= nil and item.components.stackable:IsStack() and stack_size ~= nil then
            item.components.stackable:SetStackSize(stack_size)
        end

        item.Transform:SetPosition(source.Transform:GetWorldPosition())
        loot[#loot + 1] = item
    end

    local first = SpawnPrefab(prefab)
    if first == nil then
        return loot
    end

    local first_stack = first.components.stackable
    if first_stack == nil or not first_stack:IsStack() then
        additem(first)
        for _ = 2, count do
            additem(SpawnPrefab(prefab))
        end
        return loot
    end

    local stackmax = first_stack.maxsize or 1
    local first_count = math.min(count, stackmax)
    additem(first, first_count)

    local remaining = count - first_count
    while remaining > 0 do
        local extra = math.min(remaining, stackmax)
        remaining = remaining - extra

        local next_item = SpawnPrefab(prefab)
        if next_item == nil then
            break
        end

        additem(next_item, extra)
    end

    return loot
end

function TrawlHelper.GetFishPrefab(fish)
    return fish ~= nil and fish:IsValid() and (fish.fish_def ~= nil and fish.fish_def.prefab or fish.prefab) or nil
end

function TrawlHelper.MakeInventoryFish(fish)
    local fishprefab = TrawlHelper.GetFishPrefab(fish)
    return TrawlHelper.SpawnFirstPrefab(
        fishprefab ~= nil and fishprefab .. "_inv" or nil,
        fish ~= nil and fish.prefab ~= nil and fish.prefab .. "_inv" or nil,
        fish ~= nil and fish.prefab ~= nil and fish.prefab .. "_land" or nil,
        fishprefab ~= nil and fishprefab .. "_land" or nil
    )
end

function TrawlHelper.MakeInventoryFishFromOceanFish(fish)
    if fish == nil or not fish:IsValid() then
        return nil
    end

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
    if fish.components.weighable ~= nil then
        fish.components.weighable:SetPlayerAsOwner(nil)
    end

    fish:Remove()
    return item
end

function TrawlHelper.IsRuntimeFishTarget(target)
    return target ~= nil
        and target:IsValid()
        and (
            target:HasTag("oceanfish")
            or target:HasTag("oceanfishable_creature")
            or target.components.oceanfishable ~= nil
        )
end

function TrawlHelper.IsMatureMusselFarm(target)
    if not TrawlHelper.IsMusselCompatTarget(target) then
        return false
    end

    local pickable = target.components.pickable
    if pickable == nil or not pickable:CanBePicked() then
        return false
    end

    local can_interact = pickable.caninteractwith == nil or pickable.caninteractwith
    local is_stuck = pickable.IsStuck ~= nil and pickable:IsStuck() or false
    return can_interact and not is_stuck
end

function TrawlHelper.IsKelpCompatTarget(target)
    if target == nil or not target:IsValid() then
        return false
    end
    return KELP_COMPAT_PREFABS[target.prefab] ~= nil
end

function TrawlHelper.IsMusselCompatTarget(target)
    return target ~= nil
        and target:IsValid()
        and MUSSEL_COMPAT_PREFABS[target.prefab] == true
end

local function GetKelpCompatRootPrefab(target)
    if target == nil or not target:IsValid() then
        return nil
    end

    local by_prefab = KELP_COMPAT_PREFABS[target.prefab]
    return by_prefab
end

function TrawlHelper.IsSunkenPrefabTarget(target)
    return target ~= nil
        and target:IsValid()
        and target.components ~= nil
        and target.components.sunkenprefabinfo ~= nil
end

function TrawlHelper.MakeMusselCompatLoot(inst)
    if TrawlHelper.IsMatureMusselFarm(inst) then
        return nil
    end

    local pickable = inst.components ~= nil and inst.components.pickable or nil
    local loot = PreparePrefabLoot(inst, pickable ~= nil and pickable.product or "mussel", 1)
    if #loot == 0 then
        return nil
    end

    inst:Remove()
    return loot
end

function TrawlHelper.ConfigureMusselCompatTrawlable(inst, fn)
    if inst.components.trawlable == nil then
        inst:AddComponent("trawlable")
    end
    inst.components.trawlable:SetIgnoreVisibility(true)
    inst.components.trawlable:SetTrawlFn(fn or TrawlHelper.MakeMusselCompatLoot)
    return inst.components.trawlable
end

function TrawlHelper.MakeKelpCompatLoot(inst, sailor)
    local rootprefab = GetKelpCompatRootPrefab(inst)
    if rootprefab == nil then
        return nil
    end

    local loot = PreparePrefabLoot(inst, rootprefab, 1)
    local pickable = inst.components ~= nil and inst.components.pickable or nil
    if pickable ~= nil
        and pickable:CanBePicked()
        and (pickable.caninteractwith == nil or pickable.caninteractwith)
    then
        local product = pickable.product
        if product ~= nil then
            local product_loot = PreparePrefabLoot(inst, product, pickable.numtoharvest or 1)
            for _, item in ipairs(product_loot) do
                table.insert(loot, item)
            end
        end
    end

    inst:Remove()
    return loot
end

function TrawlHelper.ConfigureKelpCompatTrawlable(inst, fn)
    if inst.components.trawlable == nil then
        inst:AddComponent("trawlable")
    end
    inst.components.trawlable:SetTrawlFn(fn or TrawlHelper.MakeKelpCompatLoot)
    return inst.components.trawlable
end

function TrawlHelper.MakeSunkenPrefabLoot(inst)
    local sunkeninfo = inst.components.sunkenprefabinfo
    if sunkeninfo == nil then
        return nil
    end

    local record = sunkeninfo:GetSunkenPrefab()
    local item = record ~= nil and SpawnSaveRecord ~= nil and SpawnSaveRecord(record) or nil
    if item == nil then
        return nil
    end

    if item.LongUpdate ~= nil and sunkeninfo.GetTimeSubmerged ~= nil then
        item:LongUpdate(sunkeninfo:GetTimeSubmerged())
    end
    item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
    return item
end

function TrawlHelper.ConfigureSunkenPrefabTrawlable(inst, fn)
    if inst.components.trawlable == nil then
        inst:AddComponent("trawlable")
    end
    inst.components.trawlable:SetIgnoreVisibility(true)
    inst.components.trawlable:SetTrawlFn(fn or TrawlHelper.MakeSunkenPrefabLoot)
    return inst.components.trawlable
end

function TrawlHelper.EnsureRuntimeKelpCompatTrawlable(_, target)
    if not TrawlHelper.IsKelpCompatTarget(target) then
        return target ~= nil and target.components ~= nil and target.components.trawlable or nil
    end

    local trawlable = TrawlHelper.ConfigureKelpCompatTrawlable(target)
    trawlable:SetIgnoreVisibility(true)
    return trawlable
end

function TrawlHelper.ConfigureSwimmingTrawlable(inst, fn)
    if inst.components.trawlable == nil then
        inst:AddComponent("trawlable")
    end
    inst.components.trawlable:SetIgnoreVisibility(true)
    inst.components.trawlable:SetTrawlFn(fn or TrawlHelper.MakeInventoryFishFromOceanFish)
    return inst.components.trawlable
end

function TrawlHelper.EnsureRuntimeFishTrawlable(_, target)
    if not TrawlHelper.IsRuntimeFishTarget(target) then
        return target ~= nil and target.components ~= nil and target.components.trawlable or nil
    end

    local trawlable = TrawlHelper.ConfigureSwimmingTrawlable(target)
    return trawlable
end

return TrawlHelper
