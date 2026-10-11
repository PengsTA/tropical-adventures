local TrawlHelper = require("tools/trawl_helper")
local TrawlLoot = require("datadefs/trawl_loot_defs")
local BoatEquip = require("tools/boat_equipment_helper")

local net_assets =
{
    Asset("ANIM", "anim/swap_trawlnet.zip"),
    Asset("ANIM", "anim/swap_trawlnet_half.zip"),
    Asset("ANIM", "anim/swap_trawlnet_full.zip"),
}


local net_prefabs =
{
    "trawlnetdropped"
}

local dropped_assets =
{
    Asset("ANIM", "anim/swap_trawlnet.zip"),
    Asset("ANIM", "anim/ui_chest_3x2.zip"),
}

local TRAWLNET_MAX_ITEMS = TrawlLoot.max_items
local TRAWLNET_ITEM_DISTANCE = TrawlLoot.item_distance or 120
local TRAWL_FULL_SPEED_PENALTY = 0.75
local TRAWL_SINK_TIME = 30 * 3
local TRAWL_PICKUP_RADIUS = 2
local TRAWL_CHECK_PERIOD = FRAMES * 5
local TRAWL_SUCCESS_COOLDOWN = 1.5
local TRAWL_SCAN_EXCLUDE_TAGS = { "FX", "INLIMBO", "ignoretrawlnettarget", "player" }

local function CleanInvalidContainerSlots(container_entity)
    if container_entity == nil or not container_entity:IsValid() then
        return
    end

    local container = container_entity.components and container_entity.components.container or nil
    if container == nil then
        return
    end

    for slot, item in pairs(container.slots) do
        if item == nil or not item:IsValid() then
            container.slots[slot] = nil
        end
    end
end

local function getLootList(inst)
    local loottable = TrawlLoot.loot.normal
    if TheWorld.state.issummer then
        loottable = TrawlLoot.loot.hurricane
    elseif TheWorld.state.iswinter then
        loottable = TrawlLoot.loot.dry
    end


    local map = TheWorld.Map
    local x, y, z = inst.Transform:GetWorldPosition()
    local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))

    if ground == GROUND.OCEAN_SWELL then
        return loottable.medium
    elseif ground == GROUND.OCEAN_ROUGH then
        return loottable.deep
    else
        return loottable.shallow
    end
end

local function HasTrawlLoot(inst, prefab)
    local found = false
    if inst.components.inventory ~= nil then
        inst.components.inventory:ForEachItem(function(item)
            if item.prefab == prefab then
                found = true
            end
        end)
    end
    return found
end

local function NormalizeLootEntry(entry)
    return type(entry) == "table" and entry[1] or entry, type(entry) == "table" and entry[2] or 1
end

local function SelectTrawlLoot(inst, list, depth)
    local total = 0
    local choices = {}

    for _, entry in pairs(list) do
        local prefab, weight = NormalizeLootEntry(entry)
        if prefab ~= nil and weight ~= nil and weight > 0 then
            if not TrawlLoot.unique[prefab] or not HasTrawlLoot(inst, prefab) then
                total = total + weight
                choices[#choices + 1] = { prefab = prefab, ceiling = total }
            end
        end
    end

    if total <= 0 then
        return depth == "deep" and "boneshard" or "seaweed"
    end

    local roll = math.random() * total
    for _, choice in ipairs(choices) do
        if roll <= choice.ceiling then
            return choice.prefab
        end
    end

    return choices[#choices].prefab
end

local function GetTrawlBucket(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local map = TheWorld.Map
    local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))
    if ground == GROUND.OCEAN_ROUGH then
        return "deep"
    elseif ground == GROUND.OCEAN_SWELL then
        return "medium"
    end
    return "shallow"
end

local function RefreshTrawlVisual(inst)
    local boat = BoatEquip.GetItemBoat(inst)
    if boat ~= nil and boat.components.boatequipment ~= nil then
        boat.components.boatequipment:UpdateVisuals()
    end
end

local StopTrawling

local function IsBehindSailor(sailor, target)
    local sx, _, sz = sailor.Transform:GetWorldPosition()
    local tx, _, tz = target.Transform:GetWorldPosition()
    local dx = tx - sx
    local dz = tz - sz
    local distance_sq = dx * dx + dz * dz
    if distance_sq < 1 then
        return false
    end

    local heading = -sailor.Transform:GetRotation() * DEGREES
    return (dx * math.cos(heading) + dz * math.sin(heading)) <= 0
end

local function GetTrawlPoint(sailor)
    local x, y, z = sailor.Transform:GetWorldPosition()
    local angle = sailor.Transform:GetRotation() * DEGREES
    return x - 3 * math.cos(angle), y, z + 3 * math.sin(angle)
end

local function CanTrawlItem(item)
    local inventoryitem = item.components.inventoryitem
    return inventoryitem ~= nil
        and not inventoryitem:IsHeld()
        and inventoryitem.cangoincontainer
        and not (item:HasTag("FX") or item:HasTag("NOCLICK") or item:HasTag("trap") or item:HasTag("player"))
end

local function IsValidTrawlTargetEntity(target)
    if target == nil or not target:IsValid() then
        return false
    end

    if target.components ~= nil and target.components.pickable ~= nil
        and not TrawlHelper.IsMusselCompatTarget(target)
        and not TrawlHelper.IsKelpCompatTarget(target) then
        return false
    end

    return true
end

local function GetTrawlCandidateType(target)
    if not IsValidTrawlTargetEntity(target) then
        return nil
    end

    if CanTrawlItem(target) then
        return "floating"
    end

    if TrawlHelper.IsMusselCompatTarget(target) then
        return not TrawlHelper.IsMatureMusselFarm(target) and "mussel_compat" or nil
    end

    if TrawlHelper.IsKelpCompatTarget(target) then
        return "kelp_compat"
    end

    if TrawlHelper.IsRuntimeFishTarget(target) then
        return target:HasTag("oceanfishable_creature") and "fishable_creatures" or "oceanfish"
    end

    if target:HasTag("trawltarget") or target.components ~= nil and target.components.trawlable ~= nil then
        return "trawltargets"
    end

    return nil
end

local function GetDistanceSq(source_x, source_z, target)
    if target == nil or not target:IsValid() then
        return math.huge
    end
    local tx, _, tz = target.Transform:GetWorldPosition()
    local dx = tx - source_x
    local dz = tz - source_z
    return dx * dx + dz * dz
end

local function EnsureTrawlableTargetForCategory(inst, target, category)
    if not IsValidTrawlTargetEntity(target) then
        return nil
    end
    if target.components == nil then
        return nil
    end

    if category == "mussel_compat" then
        return TrawlHelper.ConfigureMusselCompatTrawlable(target)
    end

    if category == "trawltargets" then
        return target.components.trawlable
    end

    if category == "kelp_compat" then
        return TrawlHelper.EnsureRuntimeKelpCompatTrawlable(inst, target)
    end

    if category == "fishable_creatures" or category == "oceanfish" then
        return TrawlHelper.EnsureRuntimeFishTrawlable(inst, target)
    end

    return nil
end

local function CollectTrawlCandidates(inst, x, y, z)
    local candidates = {}
    local seen = {}

    for _, target in ipairs(TheSim:FindEntities(x, y, z, TRAWL_PICKUP_RADIUS, nil, TRAWL_SCAN_EXCLUDE_TAGS)) do
        if target ~= nil and seen[target] == nil then
            seen[target] = true
            local category = GetTrawlCandidateType(target)
            if category ~= nil then
                local candidate = {
                    target = target,
                    category = category,
                    distance_sq = GetDistanceSq(x, z, target),
                }
                if category ~= "floating" then
                    candidate.trawlable = EnsureTrawlableTargetForCategory(inst, target, category)
                end

                candidates[#candidates + 1] = candidate
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.distance_sq < b.distance_sq
    end)

    return candidates
end

local function UpdateTrawlBuild(inst)
    local inventory = inst.components.inventory
    local fullness = inventory:NumItems() / inventory.maxslots
    inst.build = fullness <= 0.33 and "swap_trawlnet"
        or fullness <= 0.66 and "swap_trawlnet_half"
        or "swap_trawlnet_full"
    inst.sail_speed_mult = -TRAWL_FULL_SPEED_PENALTY * fullness
    RefreshTrawlVisual(inst)
end

local function SpawnDroppedTrawlnet(inst, x, y, z, angle)
    if inst == nil or not inst:IsValid() then
        return false
    end

    if inst._is_trawling_dropped then
        return false
    end
    inst._is_trawling_dropped = true

    local chest = SpawnPrefab("trawlnetdropped")
    if chest == nil then
        inst._is_trawling_dropped = nil
        return false
    end

    chest:DoDetach()
    chest.Transform:SetPosition(x, y, z)
    if angle ~= nil then
        local offset = Vector3(-3 * math.cos(angle * DEGREES), 0, 3 * math.sin(angle * DEGREES))
        chest.Transform:SetPosition(x + offset.x, y, z + offset.z)
        chest:FacePoint(x, y, z)
    end

    local inventory = inst.components.inventory
    if inventory == nil then
        chest:Remove()
        inst._is_trawling_dropped = nil
        return false
    end

    for item_slot = 1, inventory.maxslots do
        local item = inventory:RemoveItemBySlot(item_slot)
        if item ~= nil and item:IsValid() and item.components.inventoryitem ~= nil then
            chest.components.container:GiveItem(item, item_slot)
        end
    end

    StopTrawling(inst)
    if inst:IsValid() then
        local inventoryitem = inst.components.inventoryitem
        if inventoryitem ~= nil and inventoryitem.owner ~= nil then
            inventoryitem:RemoveFromOwner(true)
        end
        inst:Remove()
    end

    inst._is_trawling_dropped = nil

    return true
end

local function DropFullTrawlnet(inst, sailor)
    if inst == nil or not inst:IsValid() then
        return false
    end

    local drop_sailor = sailor
    if drop_sailor == nil or not drop_sailor:IsValid() then
        drop_sailor = BoatEquip.GetItemSailor(inst)
    end

    if drop_sailor == nil or not drop_sailor:IsValid() then
        local boat = BoatEquip.GetItemBoat(inst)
        if boat ~= nil and boat:IsValid() then
            local boat_sailor = boat.components.sailable ~= nil and boat.components.sailable:GetSailor() or nil
            if boat_sailor ~= nil and boat_sailor:IsValid() then
                drop_sailor = boat_sailor
            end
        end
    end

    if drop_sailor == nil or not drop_sailor:IsValid() then
        drop_sailor = inst
    end

    local x, y, z = drop_sailor.Transform:GetWorldPosition()
    local angle = drop_sailor.Transform:GetRotation()
    local spawned = SpawnDroppedTrawlnet(inst, x, y, z, angle)
    if not spawned then
        return false
    end

    return true
end

local function PutItemInNet(inst, item, sailor)
    local inventory = inst.components.inventory
    if inventory == nil or item == nil or not item:IsValid() or item.components.inventoryitem == nil then
        return false
    end

    local inventoryitem = item.components.inventoryitem
    inventoryitem:SetLanded(false, false)

    if inventoryitem.owner ~= nil and inventoryitem.owner ~= inst then
        inventoryitem:RemoveFromOwner(true)
    end

    for slot = 1, inventory.maxslots do
        if inventory.itemslots[slot] == nil then
            local destroyed = inventoryitem:OnPickup(inst, sailor ~= nil and sailor:GetPosition() or nil)
            if destroyed then
                return false
            end

            inventory.itemslots[slot] = item
            inventoryitem:OnPutInInventory(inst)
            inst:PushEvent("itemget", { item = item, slot = slot })
            if item.components.equippable ~= nil then
                item.components.equippable:ToPocket()
            end
            return inventoryitem:IsHeldBy(inst)
        end
    end

    return false
end

local function StoreTrawlItem(inst, sailor, item)
    if item == nil or not item:IsValid() or inst.components.inventory:IsFull() then
        return false
    end

    local captured = item

    if not PutItemInNet(inst, captured, sailor) then
        return false
    end

    if captured.components.weighable ~= nil and sailor ~= nil and sailor:IsValid() then
        captured.components.weighable:SetPlayerAsOwner(sailor)
    end
    if sailor ~= nil and sailor.components ~= nil and sailor.components.sailor ~= nil then
        sailor.components.sailor:NotifyTrawlItem()
    elseif sailor ~= nil then
        sailor:PushEvent("trawl_item", { item = item })
    end
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/collect")
    inst.trawl_next_pickup_time = GetTime() + TRAWL_SUCCESS_COOLDOWN
    UpdateTrawlBuild(inst)
    if inst.components.inventory:IsFull() then
        if sailor ~= nil then
            sailor:PushEvent("trawl_full")
        end
        DropFullTrawlnet(inst, sailor)
    end
    return true
end

local function TrawlTarget(inst, sailor, target, trawlable, category)
    if not IsValidTrawlTargetEntity(target) then
        return false
    end

    if trawlable == nil then
        return false
    end

    local loot = trawlable:Trawl(sailor)
    if loot == nil then
        if category == "fishable_creatures" or category == "oceanfish" then
            trawlable = TrawlHelper.EnsureRuntimeFishTrawlable(inst, target)
            loot = trawlable ~= nil and trawlable:Trawl(sailor) or nil
        end
    end
    if loot == nil then
        return false
    end
    if loot.components ~= nil then
        local stored = StoreTrawlItem(inst, sailor, loot)
        return stored
    end
    local stored = false
    for _, item in ipairs(loot) do
        if item ~= nil and item:IsValid() and StoreTrawlItem(inst, sailor, item) then
            if inst == nil or not inst:IsValid() or inst.components.inventory:IsFull() then
                return true
            end
            stored = true
        end
    end
    if stored then
        return true
    end
    return false
end

local function TryTrawlCandidates(inst, sailor, candidates)
    for _, candidate in ipairs(candidates) do
        local target = candidate.target or candidate
        if IsValidTrawlTargetEntity(target) then
            if candidate.category == "floating" then
                local isbehind = IsBehindSailor(sailor, target)
                if isbehind and StoreTrawlItem(inst, sailor, target) then
                    return true
                end
            else
                local trawlable = candidate.trawlable
                if trawlable == nil then
                    trawlable = EnsureTrawlableTargetForCategory(inst, target, candidate.category)
                    candidate.trawlable = trawlable
                end
                local isbehind = IsBehindSailor(sailor, target)
                local isvisible = target.entity:IsVisible()
                local cantrawl = trawlable ~= nil and trawlable:CanBeTrawledBy(sailor, isbehind, isvisible)
                if trawlable ~= nil
                    and cantrawl
                    and TrawlTarget(inst, sailor, target, trawlable, candidate.category)
                then
                    return true
                end
            end
        end
    end
    return false
end

local function TryTrawlAtPoint(inst, sailor, x, y, z)
    local candidates = CollectTrawlCandidates(inst, x, y, z)
    return TryTrawlCandidates(inst, sailor, candidates)
end

local function GenerateTrawlLoot(inst, sailor)
    local bucket = GetTrawlBucket(sailor)
    local table_for_depth = getLootList(sailor)
    return SpawnPrefab(SelectTrawlLoot(inst, table_for_depth, bucket))
end

local function CanRunTrawlTask(inst)
    local boat = BoatEquip.GetItemBoat(inst)
    local sailor = boat ~= nil
        and boat.components.sailable ~= nil
        and boat.components.sailable:GetSailor()
        or nil
    return sailor ~= nil and sailor.components.locomotor ~= nil
end

StopTrawling = function(inst)
    inst.trawl_last_pos = nil
    if inst.trawl_task ~= nil then
        inst.trawl_task:Cancel()
        inst.trawl_task = nil
    end
end

local function UpdateTrawling(inst)
    local boat = BoatEquip.GetItemBoat(inst)
    local sailor = boat ~= nil and boat.components.sailable ~= nil and boat.components.sailable:GetSailor() or nil
    if boat == nil or sailor == nil or sailor.components.locomotor == nil then
        StopTrawling(inst)
        return
    end

    local x, _, z = sailor.Transform:GetWorldPosition()
    if inst.trawl_last_pos ~= nil then
        local dx = x - inst.trawl_last_pos.x
        local dz = z - inst.trawl_last_pos.z
        inst.trawl_distance = inst.trawl_distance + math.sqrt(dx * dx + dz * dz)
    end
    inst.trawl_last_pos = { x = x, z = z }

    if inst.trawl_next_pickup_time ~= nil and GetTime() < inst.trawl_next_pickup_time then
        return
    end

    local tx, ty, tz = GetTrawlPoint(sailor)
    if TryTrawlAtPoint(inst, sailor, tx, ty, tz) then
        return
    end

    if inst.trawl_distance >= TRAWLNET_ITEM_DISTANCE then
        inst.trawl_distance = inst.trawl_distance - TRAWLNET_ITEM_DISTANCE
        if not StoreTrawlItem(inst, sailor, GenerateTrawlLoot(inst, sailor)) then
            StopTrawling(inst)
            return
        end
    end
end

local function StartTrawling(inst)
    if inst.trawl_task == nil and CanRunTrawlTask(inst) then
        inst.trawl_distance = inst.trawl_distance or 0
        inst.trawl_task = inst:DoPeriodicTask(TRAWL_CHECK_PERIOD, UpdateTrawling)
        inst:DoTaskInTime(0, UpdateTrawling)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/attach")
    end
end

local function RefreshTrawlState(inst)
    if inst ~= nil and inst.components.inventory ~= nil then
        UpdateTrawlBuild(inst)
        if BoatEquip.GetItemBoat(inst) ~= nil and inst.trawl_task == nil then
            StartTrawling(inst)
        end
    end
end

local function net(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("trawlnet")
    inst.AnimState:SetBuild("swap_trawlnet")
    inst.AnimState:PlayAnimation("idle")
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.build = "swap_trawlnet"
    inst.symbol = "swap_trawlnet"
    inst.symboltooverride = "swap_trawlnet" --swap_lantern_off
    inst.sail_speed_mult = 0

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddTag("trawlnet")
    inst:AddTag("aquatic")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = TRAWLNET_MAX_ITEMS
    inst.components.inventory.show_invspace = true

    inst:AddComponent("inventoryitem")
    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_SAIL
    inst.components.equippable.restrictedtag = "ta_boat_equipment"

    inst:ListenForEvent("boatequipped", StartTrawling)
    inst:ListenForEvent("boat_embarked", StartTrawling)
    inst:ListenForEvent("oceanwrapped", function(inst) inst.trawl_last_pos = nil end)
    inst:ListenForEvent("boatunequipped", function(inst, data)
        StopTrawling(inst)
        if inst._drop_task ~= nil or inst.components.inventory == nil or inst.components.inventory:NumItems() == 0 then
            return
        end

        local boat = data ~= nil and data.boat or BoatEquip.GetItemBoat(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local angle = inst.Transform:GetRotation()
        if boat ~= nil and boat:IsValid() then
            x, y, z = boat.Transform:GetWorldPosition()
            local sailor = boat.components.sailable ~= nil and boat.components.sailable:GetSailor() or nil
            if sailor ~= nil then
                angle = sailor.Transform:GetRotation()
            else
                angle = boat.Transform:GetRotation()
            end
        end

        inst._drop_task = inst:DoTaskInTime(0, function()
            inst._drop_task = nil
            if inst:IsValid() and inst.components.inventory ~= nil and inst.components.inventory:NumItems() > 0 then
                SpawnDroppedTrawlnet(inst, x, y, z, angle)
            end
        end)
    end)
    inst:ListenForEvent("boat_disembarked", StopTrawling)
    inst:ListenForEvent("onremove", StopTrawling)
    inst.rowsound = "dontstarve_DLC002/common/trawl_net/move_LP"
    inst:DoPeriodicTask(1, RefreshTrawlState)
    return inst
end


local function sink(inst, instant)
    if not instant then
        inst.AnimState:PlayAnimation("sink_pst")
        inst:ListenForEvent("animover", function()
            CleanInvalidContainerSlots(inst)
            inst.components.container:DropEverything()
            inst:Remove()
        end)
    else
        -- this is to catch the nets that for some reason dont have the right timer save data.
        CleanInvalidContainerSlots(inst)
        inst.components.container:DropEverything()
        inst:Remove()
    end
end

local function getsinkstate(inst)
    if inst.components.timer:TimerExists("sink") then
        return "sink"
    elseif inst.components.timer:TimerExists("startsink") then
        return "full"
    end
    return "sink"
end

local function startsink(inst)
    inst.AnimState:PlayAnimation("full_to_sink")
    inst.components.timer:StartTimer("sink", TRAWL_SINK_TIME * 1 / 3)
    inst.AnimState:PushAnimation("idle_" .. getsinkstate(inst), true)
end


local function dodetach(inst)
    inst.components.timer:StartTimer("startsink", TRAWL_SINK_TIME * 2 / 3)
    inst.AnimState:PlayAnimation("detach")
    inst.AnimState:PushAnimation("idle_" .. getsinkstate(inst), true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/detach")
end

local function onopen(inst)
    inst.AnimState:PlayAnimation("interact_" .. getsinkstate(inst)) --TODO: uncomment this when this anim exists
    inst.AnimState:PushAnimation("idle_" .. getsinkstate(inst), true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/open")
end

local function onclose(inst)
    inst.AnimState:PlayAnimation("interact_" .. getsinkstate(inst)) --TODO: uncomment this when this anim exists
    inst.AnimState:PushAnimation("idle_" .. getsinkstate(inst), true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/close")
end

local function ontimerdone(inst, data)
    if data.name == "startsink" then
        startsink(inst)
    end

    if data.name == "sink" then
        sink(inst)
    end
    -- These are sticking around some times.. maybe the timer name is being lost somehow? This will catch that?
    if data.name ~= "sink" and data.name ~= "startsink" then
        sink(inst)
    end
end


local function getstatusfn(inst, viewer)
    local sinkstate = getsinkstate(inst)
    local timeleft = (inst.components.timer and inst.components.timer:GetTimeLeft("sink")) or TRAWL_SINK_TIME
    if sinkstate == "sink" then
        return "SOON"
    elseif sinkstate == "full" and timeleft <= (TRAWL_SINK_TIME * 0.66) * 0.5 then
        return "SOONISH"
    else
        return "GENERIC"
    end
end

local function onloadtimer(inst)
    if not inst.components.timer:TimerExists("sink") and not inst.components.timer:TimerExists("startsink") then
        sink(inst, true)
    end
end

local function onload(inst, data)
    inst.AnimState:PlayAnimation("idle_" .. getsinkstate(inst), true)
end

local function dropped_net()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetTwoFaced()

    inst:AddTag("structure")
    inst:AddTag("chest")
    inst:AddTag("aquatic")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("trawlnet")
    inst.AnimState:SetBuild("swap_trawlnet")
    inst.AnimState:PlayAnimation("idle_full", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    MakeInventoryPhysics(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatusfn

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("trawlnetdropped")
    inst.replica.container:WidgetSetup("trawlnetdropped")

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst.onloadtimer = onloadtimer

    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    inst.DoDetach = dodetach

    -- this task is here because sometimes the savedata on the timer is empty.. so no timers are reloaded.
    -- when that happens, the nets sit around forever.
    inst:DoTaskInTime(0, function() onloadtimer(inst) end)

    inst.OnLoad = onload

    return inst
end

return Prefab("common/inventory/trawlnet", net, net_assets, net_prefabs),
    Prefab("common/inventory/trawlnetdropped", dropped_net, dropped_assets)
