-- Door prefabs for the player-house expansion system.

require "prefabutil"

local RoomExtensions = require "tools/interior_room_extensions"

local assets = {
    Asset("ANIM", "anim/new_player_house_doors.zip"),
}

local DIRECTIONS = {
    back = 1,
    front = 2,
    left = 3,
    right = 4,
}

local DIRECTION_NAMES = {
    [1] = "back",
    [2] = "front",
    [3] = "left",
    [4] = "right",
}

local ANIM_DIRECTIONS = {
    back = "north",
    front = "south",
    left = "west",
    right = "east",
}

local function GetDoorAnimPrefix(inst)
    return inst._ta_door_anim_name or inst.prefab
end

local function IsLinkedDoor(inst)
    if inst.exterior_exit
        or (inst._ta_exterior_exit ~= nil and inst._ta_exterior_exit:value()) then
        return true
    end
    if inst.target_door ~= nil and inst.target_door.IsValid ~= nil and inst.target_door:IsValid() then
        return true
    end
    local target = inst._ta_target_door ~= nil and inst._ta_target_door:value() or nil
    return target ~= nil and target.IsValid ~= nil and target:IsValid()
end

local function ApplyDoorVisual(inst, direction)
    direction = RoomExtensions.NormalizeDirection(direction)
    local direction_id = DIRECTIONS[direction]
    local anim_prefix = GetDoorAnimPrefix(inst)
    if direction_id == nil or anim_prefix == nil then
        return false
    end

    inst.room_direction = direction
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation(anim_prefix .. (IsLinkedDoor(inst) and "_open_" or "_close_") .. ANIM_DIRECTIONS[direction])
    return true
end

local function SetRoomDirection(inst, direction)
    direction = RoomExtensions.NormalizeDirection(direction)
    local direction_id = DIRECTIONS[direction]
    if direction_id == nil or not ApplyDoorVisual(inst, direction) then
        return false
    end

    inst._ta_room_direction:set(direction_id)
    for label, _ in pairs(DIRECTIONS) do
        inst:RemoveTag("interior_" .. label .. "_door")
    end
    inst:AddTag("interior_" .. direction .. "_door")
    return true
end

local function GetRoomDirection(inst)
    return inst.room_direction or DIRECTION_NAMES[inst._ta_room_direction:value()]
end

local function OnRoomDirectionDirty(inst)
    local direction = DIRECTION_NAMES[inst._ta_room_direction:value()]
    if direction ~= nil then
        ApplyDoorVisual(inst, direction)
    end
end

local function OnTargetDoorDirty(inst)
    ApplyDoorVisual(inst, GetRoomDirection(inst))
end

local function IsExteriorExit(inst)
    return inst.exterior_exit
        or (inst._ta_exterior_exit ~= nil and inst._ta_exterior_exit:value())
end

local function OnExteriorExitDirty(inst)
    ApplyDoorVisual(inst, GetRoomDirection(inst))
end

local function GetTargetDoor(inst)
    if inst.target_door ~= nil and inst.target_door.IsValid ~= nil and inst.target_door:IsValid() then
        return inst.target_door
    end
    local target = inst._ta_target_door:value()
    return target ~= nil and target.IsValid ~= nil and target:IsValid() and target or nil
end

local function HasLinkedDestination(inst)
    return GetTargetDoor(inst) ~= nil or IsExteriorExit(inst)
end

local function OnActivate(inst, doer)
    if doer ~= nil and doer:HasTag("player") and doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
    end
end

local function OnDoneTeleporting(inst, doer)
    if doer ~= nil and doer:HasTag("player") and inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
    end
end

local function AcceptTest(inst, item)
    if item ~= nil and item.prefab == "construction_permit" and not HasLinkedDestination(inst) then
        return true
    end
    if item ~= nil and item.prefab == "demolition_permit" then
        return false, "UN_CONSTRUCTION_PERMIT"
    end
    if HasLinkedDestination(inst) then
        return true
    end
    return false, "UN_CONSTRUCTION_PERMIT"
end

local function OnAccept(inst, giver, item)
    if item ~= nil and item.prefab == "construction_permit" and not HasLinkedDestination(inst) then
        if RoomExtensions.SpawnNearHouseInterior(inst) then
            item:Remove()
        elseif giver ~= nil and item.components.inventoryitem ~= nil then
            item.Transform:SetPosition(giver.Transform:GetWorldPosition())
            item.components.inventoryitem:OnDropped(true)
        end
    else
        inst.components.teleporter:Activate(item)
    end
end

local function OnHaunt(inst, haunter)
    inst.components.teleporter:Activate(haunter)
end

local function OnBuilt(inst)
    local info = RoomExtensions.GetWallBuildInfo(inst, {
        center_only = true,
        rendered_walls_only = false,
    })
    if info ~= nil then
        inst.Transform:SetPosition(info.x, info.y, info.z)
        SetRoomDirection(inst, info.direction)
        RoomExtensions.LinkExistingAdjacentRoom(inst)
    end
end

local function ClearDoorLink(inst)
    if inst.components ~= nil and inst.components.teleporter ~= nil then
        inst.components.teleporter.targetTeleporter = nil
    end
    inst.target_door = nil
    inst.target_room_id = nil
    inst.exterior_exit = false
    if inst._ta_target_door ~= nil then
        inst._ta_target_door:set(nil)
    end
    if inst._ta_exterior_exit ~= nil then
        inst._ta_exterior_exit:set(false)
    end
end

local function OnHammered(inst, worker)
    local target_door = GetTargetDoor(inst)
    if target_door ~= nil then
        ClearDoorLink(target_door)
        local target_x, target_y, target_z = target_door.Transform:GetWorldPosition()
        local target_collapse = SpawnPrefab("collapse_small")
        if target_collapse ~= nil then
            target_collapse.Transform:SetPosition(target_x, target_y, target_z)
        end
        target_door:Remove()
    end

    ClearDoorLink(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local collapse = SpawnPrefab(target_door ~= nil and "collapse_small" or "collapse_big")
    if collapse ~= nil then
        collapse.Transform:SetPosition(x, y, z)
    end
    inst:Remove()
end

local function MakeDoor(name)
    local function fn()
        local inst = CreateEntity()
        inst._ta_door_anim_name = name

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("player_house_doors")
        inst.AnimState:SetBuild("player_house_doors")
        inst.AnimState:PlayAnimation(name .. "_close_north")
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst.entity:SetCanSleep(false)
        inst:AddTag("NOBLOCK")
        inst:AddTag("interior_door")
        inst:AddTag("hamletteleport")
        inst:AddTag("ta_room_extension_door")
        inst:AddTag("trader")
        inst:AddTag("alltrader")

        inst._ta_target_door = net_entity(inst.GUID, "ta_extension_door.target", "ta_extension_door_target_dirty")
        inst._ta_exterior_exit = net_bool(inst.GUID, "ta_extension_door.exterior_exit", "ta_extension_door_exterior_exit_dirty")
        inst._ta_room_direction = net_tinybyte(inst.GUID, "ta_extension_door.direction", "ta_extension_door_direction_dirty")
        inst.GetRoomDirection = GetRoomDirection
        inst.IsExteriorExit = IsExteriorExit
        inst:ListenForEvent("ta_extension_door_target_dirty", OnTargetDoorDirty)
        inst:ListenForEvent("ta_extension_door_exterior_exit_dirty", OnExteriorExitDirty)
        inst:ListenForEvent("ta_extension_door_direction_dirty", OnRoomDirectionDirty)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        SetRoomDirection(inst, "back")
        inst.SetRoomDirection = SetRoomDirection

        inst:AddComponent("inspectable")
        inst:AddComponent("teleporter")
        inst.components.teleporter.offset = 0
        inst.components.teleporter.hamlet = true
        inst.components.teleporter.travelcameratime = 0.25
        inst.components.teleporter.travelarrivetime = 0
        inst.components.teleporter.onActivate = OnActivate
        inst:ListenForEvent("doneteleporting", OnDoneTeleporting)

        inst:AddComponent("trader")
        inst.components.trader.acceptnontradable = true
        inst.components.trader.deleteitemonaccept = false
        inst.components.trader:SetAbleToAcceptTest(AcceptTest)
        inst.components.trader.onaccept = OnAccept

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(OnHaunt)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(OnHammered)
        inst:ListenForEvent("onbuilt", OnBuilt)

        function inst:Link(target, target_room_id)
            self.components.teleporter.targetTeleporter = target
            self.target_door = target
            self.target_room_id = target_room_id
            self.exterior_exit = false
            self._ta_target_door:set(target)
            self._ta_exterior_exit:set(false)
            ApplyDoorVisual(self, GetRoomDirection(self))
        end

        function inst:LinkExterior(exterior)
            if exterior == nil or not exterior:IsValid()
                or exterior.components == nil or exterior.components.teleporter == nil then
                return false
            end

            self.components.teleporter.targetTeleporter = exterior
            self.target_door = nil
            self.target_room_id = nil
            self.exterior_exit = true
            self._ta_target_door:set(nil)
            self._ta_exterior_exit:set(true)
            ApplyDoorVisual(self, GetRoomDirection(self))
            return true
        end

        inst.OnSave = function(door, data)
            data.target_door = door.target_door ~= nil and door.target_door.GUID or nil
            data.target_room_id = door.target_room_id
            data.exterior_exit = door.exterior_exit or nil
            data.room_direction = door.room_direction
        end
        inst.LoadPostPass = function(door, ents, data)
            if data ~= nil and data.target_door ~= nil and ents[data.target_door] ~= nil then
                local target = ents[data.target_door].entity
                if target ~= nil then
                    door:Link(target, data.target_room_id)
                end
            end
            if data ~= nil and data.exterior_exit then
                door.exterior_exit = true
                door._ta_exterior_exit:set(true)
            end
            if data ~= nil and data.room_direction ~= nil then
                door:SetRoomDirection(data.room_direction)
            elseif data ~= nil and data.exterior_exit then
                ApplyDoorVisual(door, GetRoomDirection(door))
            end
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

local function UpdatePlacer(inst, name)
    local info = RoomExtensions.GetWallBuildInfo(inst, {
        center_only = true,
        rendered_walls_only = false,
    })
    local valid = info ~= nil
    if valid then
        inst.Transform:SetPosition(info.x, info.y, info.z)
    end

    inst.accept_placement = valid
    local animation = valid and name .. "_close_" .. ANIM_DIRECTIONS[info.direction] or nil
    if animation ~= nil and animation ~= inst.last_animation then
        inst.AnimState:PlayAnimation(animation)
        inst.last_animation = animation
    end
end

local function MakeDoorPlacer(name)
    return MakePlacer(name .. "_placer", "player_house_doors", "player_house_doors", name .. "_close_north", nil,
        nil, nil, nil, nil, nil, function(inst)
            local original_test = inst.components.placer.testfn
            inst.accept_placement = false
            inst.last_animation = nil
            inst.components.placer.onupdatetransform = function(placer)
                UpdatePlacer(placer, name)
            end
            inst.components.placer.override_build_point_fn = inst.GetPosition
            inst.components.placer.override_testfn = function(placer, pt, rot)
                local can_build, mouse_blocked = true, false
                if original_test ~= nil then
                    can_build, mouse_blocked = original_test(pt, rot)
                end
                return can_build and placer.accept_placement, mouse_blocked
            end
        end)
end

local prefabs = {}
for _, name in ipairs({
    "wood_door",
    "stone_door",
    "organic_door",
    "iron_door",
    "pillar_door",
    "curtain_door",
    "round_door",
    "plate_door",
}) do
    table.insert(prefabs, MakeDoor(name))
    table.insert(prefabs, MakeDoorPlacer(name))
end

return unpack(prefabs)
