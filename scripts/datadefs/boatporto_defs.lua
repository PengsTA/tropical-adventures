local OnDrop

local function GetItemHealth(item)
    if item == nil then
        return nil
    end

    if item.boat_item_health ~= nil then
        return item.boat_item_health
    end

    local finiteuses = item.components ~= nil and item.components.finiteuses or nil
    return finiteuses ~= nil and (finiteuses.current or (finiteuses.GetUses ~= nil and finiteuses:GetUses())) or nil
end

local function ClampItemHealth(health, maxuses)
    return math.max(1, math.min(math.floor((health or maxuses or 1) + .5), maxuses or math.huge))
end

local function SetBoatHealthFromItem(boat, item)
    if boat ~= nil and boat.components.boathealth ~= nil then
        boat.components.boathealth:SetCurrentHealth(GetItemHealth(item))
    end
end

local function SetItemHealth(item, health, maxuses)
    if item ~= nil and health ~= nil then
        item.boat_item_health = ClampItemHealth(health, maxuses)
        local finiteuses = item.components ~= nil and item.components.finiteuses or nil
        if finiteuses ~= nil then
            local uses = ClampItemHealth(item.boat_item_health, finiteuses.total or finiteuses.maxuses or finiteuses.max or maxuses or nil)
            if finiteuses.SetUses ~= nil then
                finiteuses:SetUses(uses)
            else
                finiteuses.current = uses
            end
        end
    end
end

local function OnSave(inst, data)
    data.boat_item_health = GetItemHealth(inst)
end

local function OnLoad(inst, data)
    if data ~= nil and data.boat_item_health ~= nil then
        if inst.SetBoatItemHealth ~= nil then
            inst.SetBoatItemHealth(inst, data.boat_item_health)
        else
            SetItemHealth(inst, data.boat_item_health, nil)
        end
    end
end

local function MakePortableBoatPostFn(maxuses, prefab)
    return function(inst)
        inst.boat_item_health = maxuses
        inst.SetBoatItemHealth = function(item, health)
            SetItemHealth(item, health, maxuses)
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.components.inventoryitem:SetOnDroppedFn(OnDrop(prefab))
    end
end

OnDrop = function(prefab)
    return function(inst)
        local map = TheWorld.Map
        -- local x, y, z = inst.Transform:GetWorldPosition()
        local pt = inst:GetPosition()
        pt.y = 0
        local ground = map:GetTile(map:GetTileCoordsAtPoint(pt:Get()))

        if TileGroupManager:IsOceanTile(ground) then
            local boat = SpawnAt(prefab, pt)
            SetBoatHealthFromItem(boat, inst)
            return inst:Remove()
        end

        if TileGroupManager:IsLandTile(ground) then
            inst.AnimState:PlayAnimation("idle", true)
        end
    end
end

return {
    corkboatitem = {
        prefab = "corkboat",
        bank = "corkboat",
        build = "corkboat",
        postfn = MakePortableBoatPostFn(80, "corkboat"),
        placer_bank = "rowboat",
        placer_build = "coracle_boat_build",
    },
    porto_armouredboat = {
        prefab = "armouredboat",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "seashell",
        placer_bank = "rowboat",
        placer_build = "rowboat_armored_build",
    },
    porto_cargoboat = {
        prefab = "cargoboat",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "cargo",
        placer_bank = "rowboat",
        placer_build = "rowboat_cargo_build",
    },
    porto_encrustedboat = {
        prefab = "encrustedboat",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "limestone",
        placer_bank = "rowboat",
        placer_build = "rowboat_encrusted_build",
    },
    porto_lograft_old = {
        prefab = "lograft_old",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "IDLE",
        placer_bank = "raft",
        placer_build = "raft_log_build",
    },
    porto_lograft = {
        prefab = "lograft",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "IDLE",
        placer_bank = "raft",
        placer_build = "raft_log_build",
    },
    porto_raft_old = {
        prefab = "raft_old",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "IDLE",
        placer_bank = "raft",
        placer_build = "raft_build",
    },
    porto_raft = {
        prefab = "raft",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "IDLE",
        placer_bank = "raft",
        placer_build = "raft_build",
    },
    porto_rowboat = {
        prefab = "rowboat",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "row",
        placer_bank = "rowboat",
        placer_build = "rowboat_build",
    },
    porto_woodlegsboat = {
        prefab = "woodlegsboat",
        bank = "seafarer_boatsw",
        build = "seafarer_boatsw",
        anim = "pirate",
        onplace = function(inst)
            inst.components.container:GiveItem(SpawnPrefab("woodlegssail"), 1)
            inst.components.container:GiveItem(SpawnPrefab("boatcannon"), 2)
        end,
        placer_bank = "rowboat",
        placer_build = "pirate_boat_build",
        placerpost = function(inst)
            inst.AnimState:OverrideSymbol("swap_sail", "swap_sail_pirate", "swap_sail")
            inst.AnimState:OverrideSymbol("swap_lantern", "swap_cannon", "swap_cannon")
        end,
    },
    surfboard_item = {
        prefab = "surfboard",
        bank = "surfboard",
        build = "surfboard",
        postfn = MakePortableBoatPostFn(100, "surfboard"),
        placer_bank = "raft",
        placer_build = "raft_surfboard_build",
    },
}
