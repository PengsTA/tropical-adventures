local InteriorLayoutBuilder = {}

local function ResolveValue(value, room, context, definition)
    if type(value) == "function" then
        return value(room, context, definition)
    end
    return value
end

function InteriorLayoutBuilder.ResolveRoomPosition(room, definition, context)
    local half_width = room.width / 2
    local half_depth = room.depth / 2
    local inset = ResolveValue(definition.inset, room, context, definition) or 0
    local offset = ResolveValue(definition.offset, room, context, definition) or 0

    if definition.edge == "back" then
        return -half_width + inset, offset
    elseif definition.edge == "front" then
        return half_width - inset, offset
    elseif definition.edge == "left" then
        return offset, -half_depth + inset
    elseif definition.edge == "right" then
        return offset, half_depth - inset
    elseif definition.corner == "back_left" then
        return -half_width + inset, -half_depth + inset
    elseif definition.corner == "back_right" then
        return -half_width + inset, half_depth - inset
    elseif definition.corner == "front_left" then
        return half_width - inset, -half_depth + inset
    elseif definition.corner == "front_right" then
        return half_width - inset, half_depth - inset
    end

    return ResolveValue(definition.x, room, context, definition) or 0,
        ResolveValue(definition.z, room, context, definition) or 0
end

function InteriorLayoutBuilder.SpawnPerimeter(room, definition)
    if definition == nil then
        return
    end

    local prefab = definition.prefab or "wall_invisible"
    local left = definition.left or -(room.width / 2)
    local right = definition.right or (room.width / 2)
    local front = definition.front or -(room.depth / 2)
    local back = definition.back or (room.depth / 2)

    for x = left, right do
        for z = front, back do
            if x == left or x == right or z == front or z == back then
                local part = SpawnPrefab(prefab)
                if part ~= nil then
                    part.Transform:SetPosition(room.x + x, 0, room.z + z)
                end
            end
        end
    end
end

function InteriorLayoutBuilder.SpawnFixture(room, definition, context)
    local prefab = definition.prefab or definition.name
    if prefab == nil then
        return nil
    end

    context = context or {}
    local inst = SpawnPrefab(prefab)
    if inst == nil then
        return nil
    end

    local x, z = InteriorLayoutBuilder.ResolveRoomPosition(room, definition, context)
    local y = ResolveValue(definition.y, room, context, definition) or 0
    inst.Transform:SetPosition(room.x + x, y, room.z + z)

    local rotation = ResolveValue(definition.rot or definition.rotation, room, context, definition)
    if rotation ~= nil then
        inst.Transform:SetRotation(rotation)
    end

    if definition.scale ~= nil then
        local scale = ResolveValue(definition.scale, room, context, definition)
        if type(scale) == "table" then
            inst.Transform:SetScale(scale[1] or 1, scale[2] or scale[1] or 1, scale[3] or scale[1] or 1)
        else
            inst.Transform:SetScale(scale, scale, scale)
        end
    end

    if definition.state ~= nil and inst.sg ~= nil then
        inst.sg:GoToState(definition.state)
    end

    if definition.start_anim ~= nil then
        inst.startAnim = ResolveValue(definition.start_anim, room, context, definition)
    end

    local anim = ResolveValue(definition.anim or definition.play_anim, room, context, definition)
    if anim ~= nil and inst.AnimState ~= nil then
        inst.AnimState:PlayAnimation(anim, definition.loop == true)
    end

    if definition.shoptype ~= nil then
        inst.shoptype = ResolveValue(definition.shoptype, room, context, definition)
    end

    if definition.saleitem ~= nil then
        inst.saleitem = ResolveValue(definition.saleitem, room, context, definition)
    end

    if definition.health and inst.components.health ~= nil then
        inst.components.health:SetPercent(1)
    end

    if context.playercrafted or definition.playercrafted then
        inst:AddTag("playercrafted")
        if inst.EnableInteriorDemolition ~= nil then
            inst:EnableInteriorDemolition()
        end
    end

    if definition.addtags ~= nil then
        for _, tag in ipairs(definition.addtags) do
            inst:AddTag(tag)
        end
    end

    if definition.child and context.root ~= nil then
        context.root:AddChild(inst)
    end

    if definition.init ~= nil then
        definition.init(inst, room, context, definition)
    end

    if definition.key ~= nil then
        context.by_key = context.by_key or {}
        context.by_key[definition.key] = inst
    end

    return inst
end

function InteriorLayoutBuilder.SpawnFixtures(room, layout, context)
    context = context or {}
    context.by_key = context.by_key or {}
    context.spawned = context.spawned or {}

    if layout == nil then
        return context
    end

    InteriorLayoutBuilder.SpawnPerimeter(room, layout.perimeter)

    for _, definition in ipairs(layout.fixtures or layout.addprops or {}) do
        if not context.extension or definition.extension then
            local inst = InteriorLayoutBuilder.SpawnFixture(room, definition, context)
            if inst ~= nil then
                table.insert(context.spawned, inst)
            end
        end
    end

    return context
end

return InteriorLayoutBuilder
