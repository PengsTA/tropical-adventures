local ShopRoomBuilder = {}
local ROOM_LAYOUTS = require "datadefs/interior"
local SHOP_ROOM_SIZES = ROOM_LAYOUTS.sizes
local InteriorRoomBuilder = require "tools/interior_room_builder"
local DOORMAT_INSET = 1

local ROOM_BUILDERS = ROOM_LAYOUTS.shop_builder_by_exterior

local function FitFurnitureToRoom(context)
    InteriorRoomBuilder.FitContents(context, { context.exit, context.builder })
end

function ShopRoomBuilder.ScheduleForExterior(exterior)
    if exterior.interiorID ~= nil then
        return
    end

    local builder_prefab = ROOM_BUILDERS[exterior.prefab]
    local manager = TheWorld.components.interior_manager
    if builder_prefab ~= nil and manager ~= nil then
        manager:BuildForExterior(exterior, builder_prefab)
    end
end

function ShopRoomBuilder.Begin(inst, config)
    local manager = TheWorld.components.interior_manager
    assert(manager ~= nil, "interior_manager is required before creating a room")

    local exterior = manager:ConsumePendingExterior()
    local room = manager:Allocate(exterior, config.kind)
    room.room_template = config.kind
    room.camera_profile_kind = config.kind

    local size = SHOP_ROOM_SIZES[config.kind] or SHOP_ROOM_SIZES.default
    local shell = InteriorRoomBuilder.BuildShell(room, {
        width = config.width or size.width,
        depth = config.depth or size.depth,
        reference_width = config.reference_width or size.reference_width,
        reference_depth = config.reference_depth or size.reference_depth,
        surface_style = config.surface_style or size.surface_style or "shop_default",
        perimeter_prefab = config.perimeter_prefab,
        spawn_perimeter = config.spawn_perimeter,
    })
    local half_width = room.width / 2

    inst.Transform:SetPosition(room.x, 0, room.z)
    inst:RemoveTag("interior_center")

    local exit = SpawnPrefab(config.exit_prefab)
    assert(exit ~= nil, "missing room exit prefab: " .. tostring(config.exit_prefab))
    local exit_x = config.exit_x or (half_width - (config.exit_inset or DOORMAT_INSET))
    exit.Transform:SetPosition(room.x + exit_x, 0, room.z + (config.exit_z or 0))

    shell.exit = exit
    shell.exterior = exterior
    shell.builder = inst
    return shell
end

function ShopRoomBuilder.Finish(inst, context)
    FitFurnitureToRoom(context)
    inst:DoTaskInTime(0, function(room_builder)
        local exterior = context.exterior
        if exterior:IsValid() then
            exterior.components.teleporter.targetTeleporter = context.exit
            context.exit.components.teleporter.targetTeleporter = exterior
        else
            context.exit:Remove()
        end
        room_builder:Remove()
    end)
end

return ShopRoomBuilder
