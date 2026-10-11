local InteriorRoomBuilder = {}
local WALL_ANCHOR_DISTANCE = 1.5

function InteriorRoomBuilder.BuildShell(room, definition)
    local manager = TheWorld.components.interior_manager
    assert(manager ~= nil, "interior_manager is required before creating a room shell")
    assert(room ~= nil and definition ~= nil, "a room and shell definition are required")

    room.width = definition.width
    room.depth = definition.depth
    room.reference_width = definition.reference_width or definition.width
    room.reference_depth = definition.reference_depth or definition.depth
    room.surface_style = definition.surface_style
    room.center_prefab = definition.center_prefab or "interior_room_center"
    room.perimeter_prefab = definition.perimeter_prefab or "wall_invisible"
    room.house_id = room.house_id or room.id
    room.map_x = room.map_x or 0
    room.map_z = room.map_z or 0

    local center = SpawnPrefab(room.center_prefab)
    assert(center ~= nil, "missing shared interior room center prefab")
    center.Transform:SetPosition(room.x, 0, room.z)
    center:Configure(room)
    manager:RegisterRoomCenter(room.id, center)

    local surface = SpawnPrefab("playerhouse_room_surface")
    assert(surface ~= nil, "missing shared interior surface prefab")
    surface.Transform:SetPosition(room.x, 0, room.z)
    surface:Configure(room.width, room.depth, definition.surface_style)

    if definition.spawn_perimeter ~= false then
        manager:SpawnPerimeter(room, room.perimeter_prefab, room.width / 2, room.depth / 2)
    end

    return {
        room = room,
        center = center,
        surface = surface,
    }
end

function InteriorRoomBuilder.FitContents(shell, exceptions)
    local room = shell.room
    local reference_width = room.reference_width
    local reference_depth = room.reference_depth
    if reference_width == nil or reference_depth == nil then
        return
    end

    local x_scale = room.width / reference_width
    local z_scale = room.depth / reference_depth
    if x_scale == 1 and z_scale == 1 then
        return
    end

    local ignored = {
        [shell.center] = true,
        [shell.surface] = true,
    }
    if exceptions ~= nil then
        for _, entity in ipairs(exceptions) do
            ignored[entity] = true
        end
    end

    -- Corner props sit outside the old square search radius. Search the full
    -- reference-room diagonal so supports are included before their anchors
    -- are resolved against the new shell.
    local search_radius = math.sqrt((reference_width / 2) ^ 2 + (reference_depth / 2) ^ 2) + 1
    for _, entity in ipairs(TheSim:FindEntities(room.x, 0, room.z, search_radius)) do
        if not ignored[entity]
            and entity.Transform ~= nil
            and (entity.entity == nil or entity.entity:GetParent() == nil) then
            local x, y, z = entity.Transform:GetWorldPosition()
            local offset_x = x - room.x
            local offset_z = z - room.z
            if math.abs(offset_x) <= reference_width / 2 + 0.25
                and math.abs(offset_z) <= reference_depth / 2 + 0.25 then
                local x = room.x + offset_x * x_scale
                local z = room.z + offset_z * z_scale
                local prefab = entity.prefab or ""
                local is_support = string.find(prefab, "cornerbeam", 1, true) ~= nil
                    or string.find(prefab, "pillar", 1, true) ~= nil
                local is_shelf = string.find(prefab, "shelves_", 1, true) ~= nil
                    or string.find(prefab, "bookshelf", 1, true) ~= nil

                local x_inset = reference_width / 2 - math.abs(offset_x)
                local z_inset = reference_depth / 2 - math.abs(offset_z)
                local anchor_x = x_inset <= WALL_ANCHOR_DISTANCE
                local anchor_z = z_inset <= WALL_ANCHOR_DISTANCE

                if is_support then
                    -- Corner beams and pillars preserve their original wall
                    -- inset instead of drifting toward the room centre when
                    -- a room grows to the four-unit grid.
                    if anchor_x then
                        x = room.x + (offset_x < 0 and -1 or 1) * (room.width / 2 - x_inset)
                    end
                    if anchor_z then
                        z = room.z + (offset_z < 0 and -1 or 1) * (room.depth / 2 - z_inset)
                    end
                elseif is_shelf then
                    -- Storage belongs against its nearest wall. Preserve the
                    -- small original gap, while scaling along that wall.
                    if anchor_x and (not anchor_z or x_inset <= z_inset) then
                        x = room.x + (offset_x < 0 and -1 or 1) * (room.width / 2 - x_inset)
                    elseif anchor_z then
                        z = room.z + (offset_z < 0 and -1 or 1) * (room.depth / 2 - z_inset)
                    end
                end

                entity.Transform:SetPosition(x, y, z)
            end
        end
    end
end

return InteriorRoomBuilder
