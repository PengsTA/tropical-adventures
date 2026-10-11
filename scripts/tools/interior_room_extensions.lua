-- Room expansion and map topology for the shared interior shell builder.

local InteriorRoomBuilder = require "tools/interior_room_builder"
local InteriorLayoutBuilder = require "tools/interior_layout_builder"
local ROOM_LAYOUTS = require "datadefs/interior"

local InteriorRoomExtensions = {}

InteriorRoomExtensions.DIRECTIONS = {
    back = { x = -1, z = 0, opposite = "front" },
    front = { x = 1, z = 0, opposite = "back" },
    left = { x = 0, z = -1, opposite = "right" },
    right = { x = 0, z = 1, opposite = "left" },
}

function InteriorRoomExtensions.NormalizeDirection(direction)
    return InteriorRoomExtensions.DIRECTIONS[direction] ~= nil and direction or nil
end

local DEFAULT_ROOM = ROOM_LAYOUTS.sizes.player_house_extension

local WALL_BUILD_DISTANCE = 1
local WALL_CORNER_INSET = 2
local WALL_OBJECT_RADIUS = 2.5
local DOOR_OBJECT_RADIUS = 3.5
local WALL_OBJECT_TAGS = { "wallsection", "interior_door" }

local function GetRoomDimensions(room)
    if room == nil or room._ta_width == nil or room._ta_depth == nil then
        return nil
    end

    local width = room._ta_width:value()
    local depth = room._ta_depth:value()
    if width == nil or depth == nil or width <= 0 or depth <= 0 then
        return nil
    end

    return width, depth
end

function InteriorRoomExtensions.IsPointInRoom(room, x, z, margin)
    local width, depth = GetRoomDimensions(room)
    if width == nil then
        return false
    end

    local room_x, _, room_z = room.Transform:GetWorldPosition()
    margin = margin or 0
    return math.abs(x - room_x) <= width * 0.5 + margin
        and math.abs(z - room_z) <= depth * 0.5 + margin
end

function InteriorRoomExtensions.GetRoomAtPoint(x, y, z)
    local candidates = TheSim:FindEntities(x, y or 0, z, 24, { "interior_center" })
    for _, room in ipairs(candidates) do
        if room:IsValid() and InteriorRoomExtensions.IsPointInRoom(room, x, z, 1) then
            return room
        end
    end
    return nil
end

function InteriorRoomExtensions.GetRoomForEntity(inst)
    if inst == nil or inst.Transform == nil then
        return nil
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    return InteriorRoomExtensions.GetRoomAtPoint(x, y, z)
end

function InteriorRoomExtensions.GetWallDirectionAtPoint(room, x, z, rendered_walls_only)
    local width, depth = GetRoomDimensions(room)
    if width == nil then
        return nil
    end

    local room_x, _, room_z = room.Transform:GetWorldPosition()
    local candidates = {
        back = math.abs(x - (room_x - width * 0.5)),
        left = math.abs(z - (room_z - depth * 0.5)),
        right = math.abs(z - (room_z + depth * 0.5)),
    }
    if not rendered_walls_only then
        candidates.front = math.abs(x - (room_x + width * 0.5))
    end

    local direction, distance
    for label, value in pairs(candidates) do
        if distance == nil or value < distance then
            direction = label
            distance = value
        end
    end
    return direction, distance
end

function InteriorRoomExtensions.GetWallDirection(inst, rendered_walls_only)
    local room = InteriorRoomExtensions.GetRoomForEntity(inst)
    if room == nil then
        return nil
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    local direction, distance = InteriorRoomExtensions.GetWallDirectionAtPoint(room, x, z, rendered_walls_only)
    return direction, distance, room
end

function InteriorRoomExtensions.GetDoorDirection(door)
    if door == nil then
        return nil
    end
    if door.GetRoomDirection ~= nil then
        return InteriorRoomExtensions.NormalizeDirection(door:GetRoomDirection())
    end
    return InteriorRoomExtensions.NormalizeDirection(door.room_direction)
end

function InteriorRoomExtensions.GetDoorTarget(door)
    if door == nil then
        return nil
    end
    if door.target_door ~= nil and door.target_door.IsValid ~= nil and door.target_door:IsValid() then
        return door.target_door
    end
    if door._ta_target_door ~= nil then
        local target = door._ta_target_door:value()
        if target ~= nil and target.IsValid ~= nil and target:IsValid() then
            return target
        end
    end
    return nil
end

local function GetRoomId(room)
    return room ~= nil and room._ta_room_id ~= nil and room._ta_room_id:value() or nil
end

local function GetRoomData(room)
    local manager = TheWorld.components.interior_manager
    local room_id = GetRoomId(room)
    return manager ~= nil and room_id ~= nil and manager:GetRoom(room_id) or nil
end

function InteriorRoomExtensions.IsExtensionRoom(room)
    local room_data = GetRoomData(room)
    return room_data ~= nil and room_data.kind == "player_house_extension"
end

-- Doors beyond the main room's front grid line are exterior exits, not room
-- links. This preserves the exterior entrance without discarding the door.
function InteriorRoomExtensions.IsBeyondHouseFront(room, direction)
    direction = InteriorRoomExtensions.NormalizeDirection(direction)
    local direction_data = InteriorRoomExtensions.DIRECTIONS[direction]
    local room_data = GetRoomData(room)
    if direction_data == nil or room_data == nil then
        return false
    end

    if room_data.kind ~= "player_house" and room_data.kind ~= "player_house_extension" then
        return false
    end

    local manager = TheWorld.components.interior_manager
    local house_id = room_data.house_id or room_data.id
    local main_room = manager ~= nil and manager:GetRoom(house_id) or nil
    local main_front_map_x = main_room ~= nil and main_room.map_x or 0
    local target_map_x = (room_data.map_x or 0) + direction_data.x

    return target_map_x > main_front_map_x
end

local function GetRoomBounds(room)
    local room_data = GetRoomData(room)
    if room_data ~= nil and room_data.width ~= nil and room_data.depth ~= nil then
        return room_data.x, room_data.z, room_data.width, room_data.depth
    end

    local width, depth = GetRoomDimensions(room)
    if width == nil then
        return nil
    end

    local x, _, z = room.Transform:GetWorldPosition()
    return x, z, width, depth
end

local function HasChildRooms(start_room, protected_room)
    local protected_id = GetRoomId(protected_room)
    for _, nearby_room in pairs(InteriorRoomExtensions.GetNearRooms(start_room)) do
        local nearby_id = GetRoomId(nearby_room)
        if nearby_id ~= nil and nearby_id ~= 0 and nearby_id ~= protected_id then
            return true
        end
    end
    return false
end

local function GetSafeExitPosition(exit_door, protected_room, fallback_inst)
    local x, y, z
    if exit_door ~= nil and exit_door:IsValid() then
        x, y, z = exit_door.Transform:GetWorldPosition()
    elseif fallback_inst ~= nil and fallback_inst:IsValid() then
        x, y, z = fallback_inst.Transform:GetWorldPosition()
    else
        return nil
    end

    if protected_room ~= nil and protected_room:IsValid() then
        local room_x, _, room_z = protected_room.Transform:GetWorldPosition()
        local dx = room_x - x
        local dz = room_z - z
        local distance = math.sqrt(dx * dx + dz * dz)
        if distance > 0 then
            x = x + dx / distance * 2
            z = z + dz / distance * 2
        end
    end

    return x, y or 0, z
end

local function MovePlayersOut(room, exit_x, exit_y, exit_z)
    if exit_x == nil or AllPlayers == nil then
        return
    end

    for _, player in ipairs(AllPlayers) do
        if player ~= nil
            and player:IsValid()
            and player.Transform ~= nil
            and InteriorRoomExtensions.GetRoomForEntity(player) == room
        then
            player.Transform:SetPosition(exit_x, exit_y or 0, exit_z)
        end
    end
end

local function ClearDoorLink(door)
    if door == nil or not door:IsValid() then
        return
    end

    if door.components ~= nil and door.components.teleporter ~= nil then
        door.components.teleporter.targetTeleporter = nil
    end
    door.target_door = nil
    door.target_room_id = nil
    if door._ta_target_door ~= nil then
        door._ta_target_door:set(nil)
    end
    if door.SetRoomDirection ~= nil then
        local direction = InteriorRoomExtensions.GetDoorDirection(door)
        if direction ~= nil then
            door:SetRoomDirection(direction)
        end
    end
end

local function RemoveRoomEntities(room)
    local x, z, width, depth = GetRoomBounds(room)
    if x == nil then
        return
    end

    local half_width = width * 0.5 + 3
    local half_depth = depth * 0.5 + 3
    local radius = math.sqrt(width * width + depth * depth) * 0.5 + 4
    for _, ent in ipairs(TheSim:FindEntities(x, 0, z, radius)) do
        if ent ~= nil
            and ent:IsValid()
            and ent.Transform ~= nil
            and ent.entity:GetParent() == nil
            and not ent:HasTag("player")
        then
            local ent_x, _, ent_z = ent.Transform:GetWorldPosition()
            if math.abs(ent_x - x) <= half_width and math.abs(ent_z - z) <= half_depth then
                ent:Remove()
            end
        end
    end
end

function InteriorRoomExtensions.GetDoorPosition(room_data, direction)
    direction = InteriorRoomExtensions.NormalizeDirection(direction)
    local direction_data = InteriorRoomExtensions.DIRECTIONS[direction]
    if direction_data == nil then
        return nil
    end

    local half_width = room_data.width * 0.5
    local half_depth = room_data.depth * 0.5
    local offset_x = direction_data.x ~= 0 and direction_data.x * half_width or 0
    local offset_z = direction_data.z ~= 0 and direction_data.z * half_depth or 0
    return room_data.x + offset_x, room_data.z + offset_z
end

local function GetWallAxisOffset(room, direction, x, z)
    local room_x, _, room_z = room.Transform:GetWorldPosition()
    if direction == "back" or direction == "front" then
        return z - room_z
    elseif direction == "left" or direction == "right" then
        return x - room_x
    end
end

local function GetWallAxisLimit(room, direction)
    local width, depth = GetRoomDimensions(room)
    if width == nil then
        return nil
    end
    return (direction == "back" or direction == "front") and depth * 0.5 or width * 0.5
end

local function GetWallPoint(room, direction, x, z, center_only)
    local width, depth = GetRoomDimensions(room)
    if width == nil then
        return nil
    end
    local room_x, _, room_z = room.Transform:GetWorldPosition()
    if center_only then
        return InteriorRoomExtensions.GetDoorPosition({ x = room_x, z = room_z, width = width, depth = depth }, direction)
    elseif direction == "back" then
        return room_x - width * 0.5, z
    elseif direction == "front" then
        return room_x + width * 0.5, z
    elseif direction == "left" then
        return x, room_z - depth * 0.5
    elseif direction == "right" then
        return x, room_z + depth * 0.5
    end
end

local function HasNearbyWallObject(x, y, z, radius, ignored)
    for _, tag in ipairs(WALL_OBJECT_TAGS) do
        for _, ent in ipairs(TheSim:FindEntities(x, y or 0, z, radius, { tag })) do
            if ent ~= ignored
                and ent:IsValid()
                and not ent:HasTag("placer")
                and (ent.prefab == nil or not string.find(ent.prefab, "_placer", 1, true))
            then
                return true
            end
        end
    end
    return false
end

function InteriorRoomExtensions.GetWallBuildInfoAtPoint(x, y, z, options, ignored)
    options = options or {}
    local room = InteriorRoomExtensions.GetRoomAtPoint(x, y, z)
    if room == nil then
        return nil
    end

    local direction, distance = InteriorRoomExtensions.GetWallDirectionAtPoint(room, x, z, options.rendered_walls_only ~= false)
    if direction == nil or distance == nil or distance > (options.wall_distance or WALL_BUILD_DISTANCE) then
        return nil
    end

    local axis_offset = GetWallAxisOffset(room, direction, x, z)
    local axis_limit = GetWallAxisLimit(room, direction)
    if axis_offset == nil or axis_limit == nil then
        return nil
    end
    if math.abs(axis_offset) > axis_limit - (options.corner_inset or WALL_CORNER_INSET) then
        return nil
    end
    if options.center_only and math.abs(axis_offset) > (options.center_tolerance or 1.25) then
        return nil
    end

    local wall_x, wall_z = GetWallPoint(room, direction, x, z, options.center_only)
    if wall_x == nil then
        return nil
    end

    if options.check_overlap ~= false then
        local radius = options.block_radius or (options.center_only and DOOR_OBJECT_RADIUS or WALL_OBJECT_RADIUS)
        if HasNearbyWallObject(wall_x, y, wall_z, radius, ignored) then
            return nil
        end
    end

    return {
        room = room,
        direction = direction,
        distance = distance,
        axis_offset = axis_offset,
        axis_limit = axis_limit,
        x = wall_x,
        y = y,
        z = wall_z,
    }
end

function InteriorRoomExtensions.GetWallBuildInfo(inst, options)
    if inst == nil or inst.Transform == nil then
        return nil
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    return InteriorRoomExtensions.GetWallBuildInfoAtPoint(x, y, z, options, inst)
end

local function GetRoomDoors(room)
    local width, depth = GetRoomDimensions(room)
    if width == nil then
        return {}
    end

    local x, y, z = room.Transform:GetWorldPosition()
    local radius = math.sqrt(width * width + depth * depth) * 0.5 + 2
    local doors = {}
    for _, door in ipairs(TheSim:FindEntities(x, y, z, radius, { "interior_door" })) do
        if door:IsValid() and InteriorRoomExtensions.GetRoomForEntity(door) == room then
            table.insert(doors, door)
        end
    end
    return doors
end

local function GetLinkedRoomId(room_id, direction)
    local manager = TheWorld.components.interior_manager
    local links = manager ~= nil and room_id ~= nil and manager.room_links ~= nil and manager.room_links[room_id] or nil
    return links ~= nil and links[direction] or nil
end

local function FindAdjacentRoom(manager, source_room_id, source_room_data, direction)
    local direction_data = InteriorRoomExtensions.DIRECTIONS[direction]
    if manager == nil or source_room_data == nil or direction_data == nil then
        return nil
    end

    local source_map_x = source_room_data.map_x or 0
    local source_map_z = source_room_data.map_z or 0
    local target_map_x = source_map_x + direction_data.x
    local target_map_z = source_map_z + direction_data.z
    local house_id = source_room_data.house_id or source_room_id

    for room_id, room in pairs(manager.rooms or {}) do
        if room_id ~= source_room_id
            and room.house_id == house_id
            and room.map_x == target_map_x
            and room.map_z == target_map_z
        then
            return room
        end
    end
    return nil
end

local function FindRoomDoor(room, direction)
    for _, door in ipairs(GetRoomDoors(room)) do
        if InteriorRoomExtensions.GetDoorDirection(door) == direction then
            return door
        end
    end
    return nil
end

local function GetMainRoomTemplateKind(main_room, source_room_data)
    local template_kind = main_room.room_template or source_room_data.room_template or main_room.kind
    if template_kind == "player_house" or template_kind == nil then
        template_kind = "player_house_hall"
    end
    return template_kind
end

local function GetMainRoomShellDefinition(manager, source_room_data)
    local house_id = source_room_data.house_id or source_room_data.id
    local main_room = manager:GetRoom(house_id) or source_room_data
    local template_kind = GetMainRoomTemplateKind(main_room, source_room_data)

    local template = ROOM_LAYOUTS.sizes[template_kind] or DEFAULT_ROOM
    return main_room, {
        width = main_room.width or template.width,
        depth = main_room.depth or template.depth,
        reference_width = main_room.reference_width or template.reference_width or template.width,
        reference_depth = main_room.reference_depth or template.reference_depth or template.depth,
        surface_style = main_room.surface_style or template.surface_style,
        center_prefab = main_room.center_prefab or template.center_prefab,
        perimeter_prefab = main_room.perimeter_prefab or template.perimeter_prefab,
    }, template_kind
end

local function GetMainRoomLayout(template_kind)
    for _, definition in ipairs(ROOM_LAYOUTS.player_house.rooms or {}) do
        if definition.kind == template_kind then
            return definition
        end
    end

    for _, definition in pairs(ROOM_LAYOUTS.palace.rooms or {}) do
        if definition.kind == template_kind then
            return ROOM_LAYOUTS.palace.layouts[definition.layout]
        end
    end

    for _, definition in ipairs(ROOM_LAYOUTS.shops.defs or {}) do
        if definition.kind == template_kind then
            return ROOM_LAYOUTS.shops.layouts[definition.layout]
        end
    end

    return nil
end

-- Keep room-to-room teleporters and the client-visible map graph in one
-- place. Every linked pair exposes the same direction and target data used by
-- player-house extensions, regardless of the door's visual prefab.
function InteriorRoomExtensions.LinkRoomDoors(source_door, source_room_id, direction, target_door, target_room_id)
    direction = InteriorRoomExtensions.NormalizeDirection(direction)
    if source_door == nil
        or target_door == nil
        or source_room_id == nil
        or target_room_id == nil
        or direction == nil
        or source_door.Link == nil
        or target_door.Link == nil then
        return false
    end

    local manager = TheWorld.components.interior_manager
    local opposite = InteriorRoomExtensions.DIRECTIONS[direction].opposite
    if manager == nil or opposite == nil then
        return false
    end

    source_door:Link(target_door, target_room_id)
    target_door:Link(source_door, source_room_id)
    if source_door.SetRoomDirection ~= nil then
        source_door:SetRoomDirection(direction)
    end
    if target_door.SetRoomDirection ~= nil then
        target_door:SetRoomDirection(opposite)
    end
    manager:ConnectRooms(source_room_id, direction, target_room_id)
    return true
end

function InteriorRoomExtensions.GetNearRooms(room)
    local rooms = {}
    for _, door in ipairs(GetRoomDoors(room)) do
        local direction = InteriorRoomExtensions.GetDoorDirection(door)
        local target_door = InteriorRoomExtensions.GetDoorTarget(door)
        if direction ~= nil and target_door ~= nil and target_door.IsValid ~= nil and target_door:IsValid() then
            local target_room = InteriorRoomExtensions.GetRoomForEntity(target_door)
            if target_room ~= nil then
                rooms[direction] = target_room
            end
        end
    end
    return rooms
end

local function GetExtensionDemolitionContext(room)
    if room == nil or not room:IsValid() or not InteriorRoomExtensions.IsExtensionRoom(room) then
        return nil
    end

    local linked_doors = {}
    for _, door in ipairs(GetRoomDoors(room)) do
        local target_door = InteriorRoomExtensions.GetDoorTarget(door)
        local target_room = target_door ~= nil and InteriorRoomExtensions.GetRoomForEntity(target_door) or nil
        if target_room ~= nil then
            table.insert(linked_doors, {
                room_door = door,
                exit_door = target_door,
                protected_room = target_room,
            })
        end
    end

    return #linked_doors == 1 and linked_doors[1] or nil
end

local function DemolishExtensionRoom(room, context, worker)
    local manager = TheWorld.components.interior_manager
    local room_id = GetRoomId(room)
    if manager == nil or room_id == nil or room_id == 0 then
        return false
    end

    local exit_x, exit_y, exit_z = GetSafeExitPosition(context.exit_door, context.protected_room, worker or room)
    local collapse_x, collapse_y, collapse_z = context.room_door.Transform:GetWorldPosition()
    local collapse = SpawnPrefab("collapse_big")
    if collapse ~= nil then
        collapse.Transform:SetPosition(collapse_x, collapse_y, collapse_z)
    end

    ClearDoorLink(context.exit_door)
    ClearDoorLink(context.room_door)
    MovePlayersOut(room, exit_x, exit_y, exit_z)
    RemoveRoomEntities(room)
    manager:Release(room_id)
    return true
end

function InteriorRoomExtensions.CanDemolishExtensionRoom(room)
    return GetExtensionDemolitionContext(room) ~= nil
end

function InteriorRoomExtensions.DemolishExtensionRoom(room, worker)
    local context = GetExtensionDemolitionContext(room)
    if context == nil then
        return false
    end
    return DemolishExtensionRoom(room, context, worker)
end

function InteriorRoomExtensions.DemolishLinkedExtension(door, worker)
    if door == nil or door.components == nil then
        return false
    end

    local source_room = InteriorRoomExtensions.GetRoomForEntity(door)
    local target_door = InteriorRoomExtensions.GetDoorTarget(door)
    local target_room = target_door ~= nil and InteriorRoomExtensions.GetRoomForEntity(target_door) or nil
    if source_room == nil or target_room == nil then
        return false
    end

    if InteriorRoomExtensions.IsExtensionRoom(target_room) then
        return InteriorRoomExtensions.DemolishExtensionRoom(target_room, worker)
    elseif InteriorRoomExtensions.IsExtensionRoom(source_room) then
        return InteriorRoomExtensions.DemolishExtensionRoom(source_room, worker)
    end
    return false
end

function InteriorRoomExtensions.GetCurrentRoomsGrid(start_room)
    local grid = {}
    if start_room == nil or not start_room:IsValid() then
        return grid
    end

    local positions = { [start_room] = { x = 0, z = 0 } }
    local queue = { start_room }
    local queue_index = 1
    local min_x, max_x, min_z, max_z = 0, 0, 0, 0

    while queue_index <= #queue do
        local room = queue[queue_index]
        queue_index = queue_index + 1
        local position = positions[room]
        for direction, nearby_room in pairs(InteriorRoomExtensions.GetNearRooms(room)) do
            if positions[nearby_room] == nil then
                local direction_data = InteriorRoomExtensions.DIRECTIONS[direction]
                if direction_data ~= nil then
                    local next_position = {
                        x = position.x + direction_data.x,
                        z = position.z + direction_data.z,
                    }
                    positions[nearby_room] = next_position
                    min_x = math.min(min_x, next_position.x)
                    max_x = math.max(max_x, next_position.x)
                    min_z = math.min(min_z, next_position.z)
                    max_z = math.max(max_z, next_position.z)
                    table.insert(queue, nearby_room)
                end
            end
        end
    end

    local start_x, start_z
    for x = min_x, max_x do
        local row = {}
        for z = min_z, max_z do
            table.insert(row, false)
        end
        table.insert(grid, row)
    end

    for room, position in pairs(positions) do
        local grid_x = position.x - min_x + 1
        local grid_z = position.z - min_z + 1
        local cell = { room = room }
        for direction, nearby_room in pairs(InteriorRoomExtensions.GetNearRooms(room)) do
            if nearby_room ~= nil then
                cell[direction] = true
            end
        end
        grid[grid_x][grid_z] = cell
        if room == start_room then
            start_x = grid_x
            start_z = grid_z
        end
    end

    return grid, start_x, start_z
end

local function SpawnExtensionFixtures(room, layout)
    if layout ~= nil then
        InteriorLayoutBuilder.SpawnFixtures(room, layout, { playercrafted = true, extension = true })
    end
end

local function LinkDoorToRoom(door, source_room_id, room, direction, created_room, shell)
    local manager = TheWorld.components.interior_manager
    if manager == nil or room == nil then
        return false
    end

    local opposite = InteriorRoomExtensions.DIRECTIONS[direction].opposite
    local target_room_center = manager.room_centers ~= nil and manager.room_centers[room.id] or nil
    local target_door = target_room_center ~= nil and target_room_center:IsValid() and FindRoomDoor(target_room_center, opposite) or nil
    if target_door ~= nil and InteriorRoomExtensions.GetDoorTarget(target_door) ~= nil then
        return false
    end
    if target_door == nil then
        target_door = SpawnPrefab(door.prefab)
    end
    if target_door == nil or target_door.Link == nil then
        if target_door ~= nil then
            target_door:Remove()
        end
        if created_room then
            manager:Release(room.id)
            if shell ~= nil and shell.center ~= nil then
                shell.center:Remove()
            end
            if shell ~= nil and shell.surface ~= nil then
                shell.surface:Remove()
            end
        end
        return false
    end

    local target_x, target_z = InteriorRoomExtensions.GetDoorPosition(room, opposite)
    target_door.Transform:SetPosition(target_x, 0, target_z)
    return InteriorRoomExtensions.LinkRoomDoors(
        door,
        source_room_id,
        direction,
        target_door,
        room.id
    )
end

local function FindHouseExterior(room_data)
    local house_id = room_data ~= nil and (room_data.house_id or room_data.id) or nil
    local exterior_x = room_data ~= nil and room_data.exterior_x or nil
    local exterior_z = room_data ~= nil and room_data.exterior_z or nil
    if house_id == nil or exterior_x == nil or exterior_z == nil then
        return nil
    end

    for _, exterior in ipairs(TheSim:FindEntities(exterior_x, 0, exterior_z, 6, { "hamletteleport" })) do
        if exterior:IsValid()
            and exterior.interiorID == house_id
            and exterior.components ~= nil
            and exterior.components.teleporter ~= nil then
            return exterior
        end
    end
    return nil
end

local function LinkDoorToExterior(door, room_data)
    local exterior = FindHouseExterior(room_data)
    if exterior == nil or door == nil or door.LinkExterior == nil then
        return false
    end
    return door:LinkExterior(exterior)
end

local function GetDoorBuildContext(door)
    if door == nil or door.components == nil or door.components.teleporter == nil then
        return nil
    end
    if InteriorRoomExtensions.GetDoorTarget(door) ~= nil
        or (door.IsExteriorExit ~= nil and door:IsExteriorExit()) then
        return nil
    end

    local direction, _, source_room = InteriorRoomExtensions.GetWallDirection(door, false)
    if direction == nil or source_room == nil then
        return nil
    end

    local source_room_id = source_room._ta_room_id ~= nil and source_room._ta_room_id:value() or nil
    if source_room_id == nil or source_room_id == 0 then
        return nil
    end

    local manager = TheWorld.components.interior_manager
    if manager == nil then
        return nil
    end

    local source_room_data = manager:GetRoom(source_room_id)
    if source_room_data == nil then
        return nil
    end
    return manager, source_room, source_room_id, source_room_data, direction
end

function InteriorRoomExtensions.LinkExistingAdjacentRoom(door)
    local manager, source_room, source_room_id, source_room_data, direction = GetDoorBuildContext(door)
    if manager == nil then
        return false
    end

    if InteriorRoomExtensions.IsBeyondHouseFront(source_room, direction) then
        return LinkDoorToExterior(door, source_room_data)
    end

    local linked_room_id = GetLinkedRoomId(source_room_id, direction)
    local room = linked_room_id ~= nil and manager:GetRoom(linked_room_id) or nil
    if room == nil then
        room = FindAdjacentRoom(manager, source_room_id, source_room_data, direction)
    end
    if room == nil then
        return false
    end

    return LinkDoorToRoom(door, source_room_id, room, direction, false, nil)
end

function InteriorRoomExtensions.SpawnNearHouseInterior(door)
    local manager, source_room, source_room_id, source_room_data, direction = GetDoorBuildContext(door)
    if manager == nil then
        return false
    end

    if InteriorRoomExtensions.IsBeyondHouseFront(source_room, direction) then
        return LinkDoorToExterior(door, source_room_data)
    end

    local linked_room_id = GetLinkedRoomId(source_room_id, direction)
    local room = linked_room_id ~= nil and manager:GetRoom(linked_room_id) or nil
    if room == nil then
        room = FindAdjacentRoom(manager, source_room_id, source_room_data, direction)
    end
    local created_room = false
    local shell = nil
    if room == nil then
        local main_room, shell_definition, template_kind = GetMainRoomShellDefinition(manager, source_room_data)
        room = manager:Allocate(nil, "player_house_extension")
        room.house_id = main_room.id or (source_room._ta_owner_id ~= nil and source_room._ta_owner_id:value()) or source_room_id
        room.room_template = template_kind
        room.camera_profile_kind = main_room.camera_profile_kind or template_kind
        room.exterior_x = main_room.exterior_x or source_room_data.exterior_x
        room.exterior_z = main_room.exterior_z or source_room_data.exterior_z
        local source_map_x = source_room_data.map_x or 0
        local source_map_z = source_room_data.map_z or 0
        room.map_x = source_map_x + InteriorRoomExtensions.DIRECTIONS[direction].x
        room.map_z = source_map_z + InteriorRoomExtensions.DIRECTIONS[direction].z

        shell = InteriorRoomBuilder.BuildShell(room, shell_definition)
        SpawnExtensionFixtures(room, GetMainRoomLayout(template_kind))
        created_room = true
    end

    return LinkDoorToRoom(door, source_room_id, room, direction, created_room, shell)
end

return InteriorRoomExtensions
