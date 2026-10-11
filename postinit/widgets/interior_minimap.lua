if TheNet:IsDedicated() then
    return
end

-- Interior room-map overlay for the current room centers and extension-door
-- graph. The existing world map remains untouched outside interiors.

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
require "characterutil"
local RoomExtensions = require "tools/interior_room_extensions"
local InteriorDefs = require "datadefs/interior"

local MAP_TEXTURE_ROOT = "levels/textures/tro_map_interior/"
local DEFAULT_FLOOR_ATLAS = "levels/textures/noise_woodfloor_minimap.xml"
local DEFAULT_FLOOR_TEXTURE = "noise_woodfloor_nomip.tex"
local ROOM_FRAME_ATLAS = MAP_TEXTURE_ROOT .. "room_frame.xml"
local DOORMAT_ICON_ATLAS = "images/inventoryimages/inventory_hamlet.xml"
-- Single-player's player-house door uses this marker.  Shop doormats have no
-- dedicated map icon there, so use the generic entrance rather than a cave exit.
local DOORMAT_ICON_TEXTURE = "player_frontdoor.tex"
local MAP_TOGGLE_ATLAS = MAP_TEXTURE_ROOT .. "map_toggle.xml"
local MAP_TOGGLE_TEXTURE = "map_toggle.tex"
local MAP_ATLASES = {
    "frame",
    "passage",
    "passage_blocked",
    "passage_unknown",
    "room_frame",
    "map_toggle",
}

Assets = Assets or {}
for _, name in ipairs(MAP_ATLASES) do
    table.insert(Assets, Asset("ATLAS", MAP_TEXTURE_ROOT .. name .. ".xml"))
end

local WORLD_TO_MAP_SCALE = 15
local ROOM_GAP = 38
local ROOM_ICON_SIZE = 24
local ROOM_DOORMAT_ICON_SIZE = 18
local ROOM_PLAYER_SIZE = 28
local ROOM_ICON_RADIUS_PADDING = 2
local INTERIOR_ZOOM_DEFAULT = 1.25
local INTERIOR_ZOOM_MIN = 0.5
local INTERIOR_ZOOM_MAX = 3
local INTERIOR_ZOOM_STEP = 0.12
local PASSAGE_SCALE = 0.78
local ROOM_FRAME_OUTSET = 3
local ROOM_FRAME_EDGE_WIDTH = 7
-- Keep the map texture density in step with player_house_room's floor quad.
local FLOOR_TEXTURE_REPEAT_SIZE = 5
local INTERIOR_DRAG_SCALE = 1
local DEBUG_INTERIOR_MINIMAP = false
local MAP_FRAME_BLEND_MODE = 2 -- BLENDMODE.Additive

local function MakeFloorVisual(atlas, texture)
    return { atlas = atlas, texture = texture, tint = { 1, 1, 1, 1 } }
end

local function InteriorFloorVisual(name)
    return MakeFloorVisual("levels/textures/interiors/" .. name .. "_minimap.xml", name .. "_nomip.tex")
end

-- Every selectable room floor uses its own source texture. Do not reduce
-- different materials to a similar-looking map texture.
local FLOOR_TEXTURE_VISUALS = {
    ["levels/textures/noise_woodfloor_nomip.tex"] = MakeFloorVisual(DEFAULT_FLOOR_ATLAS, DEFAULT_FLOOR_TEXTURE),
    ["levels/textures/interiors/floor_cityhall_nomip.tex"] = InteriorFloorVisual("floor_cityhall"),
    ["levels/textures/interiors/shop_floor_checker_nomip.tex"] = InteriorFloorVisual("shop_floor_checker"),
    ["levels/textures/interiors/shop_floor_herringbone_nomip.tex"] = InteriorFloorVisual("shop_floor_herringbone"),
    ["levels/textures/interiors/shop_floor_hexagon_nomip.tex"] = InteriorFloorVisual("shop_floor_hexagon"),
    ["levels/textures/interiors/shop_floor_octagon_nomip.tex"] = InteriorFloorVisual("shop_floor_octagon"),
    ["levels/textures/interiors/shop_floor_sheetmetal_nomip.tex"] = InteriorFloorVisual("shop_floor_sheetmetal"),
    ["levels/textures/interiors/shop_floor_woodmetal_nomip.tex"] = InteriorFloorVisual("shop_floor_woodmetal"),
    ["levels/textures/interiors/shop_floor_hoof_curvy_nomip.tex"] = InteriorFloorVisual("shop_floor_hoof_curvy"),
    ["levels/textures/interiors/shop_floor_woodpaneling2_nomip.tex"] = InteriorFloorVisual("shop_floor_woodpaneling2"),
    ["levels/textures/interiors/shop_floor_checkered_nomip.tex"] = InteriorFloorVisual("shop_floor_checkered"),
    ["levels/textures/interiors/shop_floor_marble_nomip.tex"] = InteriorFloorVisual("shop_floor_marble"),
    ["levels/textures/interiors/floor_transitional_nomip.tex"] = InteriorFloorVisual("floor_transitional"),
    ["levels/textures/interiors/floor_woodpanels_nomip.tex"] = InteriorFloorVisual("floor_woodpanels"),
    ["levels/textures/interiors/floor_gardenstone_nomip.tex"] = InteriorFloorVisual("floor_gardenstone"),
    ["levels/textures/interiors/floor_geometrictiles_nomip.tex"] = InteriorFloorVisual("floor_geometrictiles"),
    ["levels/textures/interiors/floor_shag_carpet_nomip.tex"] = InteriorFloorVisual("floor_shag_carpet"),
    ["levels/textures/interiors/floor_marble_royal_nomip.tex"] = InteriorFloorVisual("floor_marble_royal"),
    ["levels/textures/interiors/antcave_floor_nomip.tex"] = InteriorFloorVisual("antcave_floor"),
    ["levels/textures/interiors/batcave_floor_nomip.tex"] = InteriorFloorVisual("batcave_floor"),
    ["levels/textures/interiors/ground_ruins_slab_nomip.tex"] = InteriorFloorVisual("ground_ruins_slab"),
    ["levels/textures/interiors/ground_ruins_slab_blue_nomip.tex"] = InteriorFloorVisual("ground_ruins_slab_blue"),
}

local DEFAULT_FLOOR_VISUAL = FLOOR_TEXTURE_VISUALS["levels/textures/noise_woodfloor_nomip.tex"]

for _, visual in pairs(FLOOR_TEXTURE_VISUALS) do
    table.insert(Assets, Asset("ATLAS", visual.atlas))
end

local function GetFloorVisualForTexture(texture)
    return FLOOR_TEXTURE_VISUALS[texture] or DEFAULT_FLOOR_VISUAL
end

local FLOOR_MATERIAL_VISUALS = {}
for _, material in pairs(InteriorDefs.surface_materials.floors or {}) do
    FLOOR_MATERIAL_VISUALS[material.id] = GetFloorVisualForTexture(material.texture)
end

local FLOOR_STYLE_VISUALS = {}
for _, style in pairs(InteriorDefs.surface_styles or {}) do
    FLOOR_STYLE_VISUALS[style.id] = GetFloorVisualForTexture(style.floor)
end

local DOORMAT_PREFABS = {
    playerhouse_room_door = true,
    playerhouse_city_door_saida = true,
    palace_door_saida = true,
}
for _, shop in ipairs(InteriorDefs.shops.defs or {}) do
    DOORMAT_PREFABS[shop.exit_prefab] = true
end

local function DebugInteriorMinimap(...)
    if DEBUG_INTERIOR_MINIMAP then
        print("[TA_INTERIOR_MINIMAP]", ...)
    end
end

local function IsInteriorDoormat(ent)
    return ent ~= nil and (DOORMAT_PREFABS[ent.prefab]
        or ent:HasTag("guard_entrance")
        or ent:HasTag("interior_map_doormat"))
end

local function IsInteriorMapEntity(ent)
    return ent ~= nil
        and ent:IsValid()
        and ent.Transform ~= nil
        and (ent.MiniMapEntity ~= nil or IsInteriorDoormat(ent) or ent:HasTag("interior_map_icon"))
        and not ent:HasTag("player")
        and not ent:HasTag("INLIMBO")
        and not ent:HasTag("NOCLICK")
        and not ent:HasTag("interior_center")
        and ent.prefab ~= nil
        and ent.prefab ~= "playerhouse_room_surface"
        and ent.prefab ~= "deco_roomglow"
        and ent.prefab ~= "wall_invisible"
end

local function GetCurrentRoom()
    if ThePlayer == nil or ThePlayer.Transform == nil then
        return nil
    end
    local x, y, z = ThePlayer.Transform:GetWorldPosition()
    return RoomExtensions.GetRoomAtPoint(x, y, z)
end

local function IsExplored(room)
    return room ~= nil and room._ta_explored ~= nil and room._ta_explored:value()
end

local function ClearRoomImages(self)
    if self._ta_interior_map_root ~= nil then
        self._ta_interior_map_root:Kill()
        self._ta_interior_map_root = nil
    end
    if self._ta_interior_map_frame ~= nil then
        self._ta_interior_map_frame:Hide()
    end
    self._ta_interior_room_images = {}
end

local function CreateInteriorMapFrame(self)
    if self.bg == nil or self.bg.atlas == nil or self.bg.texture == nil then
        return nil
    end

    local frame = self:AddChild(Image(self.bg.atlas, self.bg.texture))
    frame:SetVRegPoint(ANCHOR_MIDDLE)
    frame:SetHRegPoint(ANCHOR_MIDDLE)
    frame:SetVAnchor(ANCHOR_MIDDLE)
    frame:SetHAnchor(ANCHOR_MIDDLE)
    frame:SetScaleMode(SCALEMODE_FILLSCREEN)
    frame:SetBlendMode(MAP_FRAME_BLEND_MODE)
    frame._ta_map_frame_atlas = self.bg.atlas
    frame._ta_map_frame_texture = self.bg.texture
    frame:Hide()
    return frame
end

local function EnsureInteriorMapFrame(self)
    local frame = self._ta_interior_map_frame
    local bg = self.bg
    if bg == nil or bg.atlas == nil or bg.texture == nil then
        if frame ~= nil then
            frame:Kill()
            self._ta_interior_map_frame = nil
        end
        return nil
    end

    if frame == nil
        or frame._ta_map_frame_atlas ~= bg.atlas
        or frame._ta_map_frame_texture ~= bg.texture then
        if frame ~= nil then
            frame:Kill()
        end
        self._ta_interior_map_frame = CreateInteriorMapFrame(self)
    end
    return self._ta_interior_map_frame
end

local function Clamp(value, min_value, max_value)
    return math.max(min_value, math.min(max_value, value))
end

local function GetCursorCenterPosition()
    local cursor_x, cursor_y = TheSim:GetPosition()
    local screen_width, screen_height = TheSim:GetScreenSize()
    return cursor_x - screen_width * 0.5, cursor_y - screen_height * 0.5
end

local function IsPrimaryMouseDown()
    return TheInput:IsControlPressed(CONTROL_PRIMARY)
        or (TheInput.IsMouseDown ~= nil and TheInput:IsMouseDown(MOUSEBUTTON_LEFT))
end

local function AddImage(root, atlas, texture, offset_x, offset_y, scale_x, scale_y)
    local image = root:AddChild(Image(atlas, texture))
    image:SetHAnchor(ANCHOR_MIDDLE)
    image:SetVAnchor(ANCHOR_MIDDLE)
    image._ta_base_x = root.room_offset_x + offset_x
    image._ta_base_y = root.room_offset_y + offset_y
    image._ta_base_scale_x = scale_x or 1
    image._ta_base_scale_y = scale_y or scale_x or 1
    image:SetPosition(image._ta_base_x, image._ta_base_y)
    if scale_x ~= nil or scale_y ~= nil then
        image:SetScale(image._ta_base_scale_x, image._ta_base_scale_y, 1)
    end
    if root._ta_map_root ~= nil then
        table.insert(root._ta_map_root._ta_transform_widgets, image)
    end
    return image
end

local function GetAtlasForIcon(texture)
    if texture == nil or GetMinimapAtlas == nil then
        return nil
    end

    return GetMinimapAtlas(texture)
end

local function AddIconCandidate(candidates, seen, texture)
    if texture == nil or texture == "" or seen[texture] then
        return
    end
    seen[texture] = true
    table.insert(candidates, texture)
end

local function AddPrefabIconCandidates(candidates, seen, prefab)
    if prefab == nil then
        return
    end

    AddIconCandidate(candidates, seen, prefab .. ".tex")
    AddIconCandidate(candidates, seen, prefab .. ".png")

    local base = string.gsub(prefab, "_backwall$", "")
    base = string.gsub(base, "_sidewall$", "")
    base = string.gsub(base, "_side$", "")
    base = string.gsub(base, "_front$", "")
    if base ~= prefab then
        AddIconCandidate(candidates, seen, base .. ".tex")
        AddIconCandidate(candidates, seen, base .. ".png")
    end
end

local function GetEntityMapIcon(ent)
    if IsInteriorDoormat(ent) then
        return DOORMAT_ICON_ATLAS, DOORMAT_ICON_TEXTURE
    end

    local candidates = {}
    local seen = {}
    local prefab = ent.prefab

    AddPrefabIconCandidates(candidates, seen, prefab)

    for _, texture in ipairs(candidates) do
        local atlas = GetAtlasForIcon(texture)
        if atlas ~= nil then
            return atlas, texture
        end
    end
    return nil, nil
end

local function AddPassage(root, rotation, offset_x, offset_y)
    local passage = AddImage(root, MAP_TEXTURE_ROOT .. "passage.xml", "passage.tex", offset_x, offset_y, PASSAGE_SCALE, PASSAGE_SCALE)
    if rotation ~= nil then
        passage:SetRotation(rotation)
    end
    return passage
end

local function GetDimensions(room)
    return room._ta_width:value(), room._ta_depth:value()
end

local function GetRoomMapSize(room)
    local width, depth = GetDimensions(room)
    return depth * WORLD_TO_MAP_SCALE, width * WORLD_TO_MAP_SCALE
end

local function GetRoomSurface(room)
    local x, _, z = room.Transform:GetWorldPosition()
    for _, surface in ipairs(TheSim:FindEntities(x, 0, z, 2, { "ta_interior_surface" })) do
        if surface:IsValid() and surface._ta_floor ~= nil and surface._ta_style ~= nil then
            return surface
        end
    end
    return nil
end

local function GetRoomFloorVisual(room)
    local surface = GetRoomSurface(room)
    if surface ~= nil then
        local material_id = surface._ta_floor:value()
        if material_id ~= nil and material_id > 0 and FLOOR_MATERIAL_VISUALS[material_id] ~= nil then
            return FLOOR_MATERIAL_VISUALS[material_id], surface
        end

        local style_id = surface._ta_style:value()
        if style_id ~= nil and FLOOR_STYLE_VISUALS[style_id] ~= nil then
            return FLOOR_STYLE_VISUALS[style_id], surface
        end
    end
    return DEFAULT_FLOOR_VISUAL, surface
end

local function AddRoomFrame(root, map_width, map_height)
    local outer_width = map_width + ROOM_FRAME_OUTSET * 2
    local outer_height = map_height + ROOM_FRAME_OUTSET * 2
    local edge_width = ROOM_FRAME_EDGE_WIDTH
    local half_width = outer_width * 0.5
    local half_height = outer_height * 0.5

    local function AddFramePiece(texture, x, y, width, height)
        local piece = AddImage(root, ROOM_FRAME_ATLAS, texture, x, y)
        piece:SetSize(width, height)
    end

    AddFramePiece("room_frame_left.tex", -half_width + edge_width * 0.5, 0, edge_width, outer_height)
    AddFramePiece("room_frame_right.tex", half_width - edge_width * 0.5, 0, edge_width, outer_height)
    AddFramePiece("room_frame_top.tex", 0, half_height - edge_width * 0.5, outer_width, edge_width)
    AddFramePiece("room_frame_bottom.tex", 0, -half_height + edge_width * 0.5, outer_width, edge_width)
end

local function AddRoomFloor(root, room)
    local map_width, map_height = GetRoomMapSize(room)
    local visual, surface = GetRoomFloorVisual(room)
    local floor = AddImage(root, visual.atlas or DEFAULT_FLOOR_ATLAS, visual.texture or DEFAULT_FLOOR_TEXTURE, 0, 0)
    floor:SetSize(map_width, map_height)
    floor:SetTint(unpack(visual.tint or DEFAULT_FLOOR_VISUAL.tint))
    if surface ~= nil and surface._ta_width ~= nil and surface._ta_depth ~= nil then
        floor:SetUVMode(WRAP_MODE.WRAP)
        floor:SetUVScale(
            surface._ta_depth:value() / FLOOR_TEXTURE_REPEAT_SIZE,
            surface._ta_width:value() / FLOOR_TEXTURE_REPEAT_SIZE
        )
    end

    AddRoomFrame(root, map_width, map_height)
end

local function WorldToRoomMapPosition(room, x, z)
    local room_x, _, room_z = room.Transform:GetWorldPosition()
    return (z - room_z) * WORLD_TO_MAP_SCALE, (room_x - x) * WORLD_TO_MAP_SCALE
end

local function AddEntityIcon(root, ent, map_x, map_y)
    local atlas, texture = GetEntityMapIcon(ent)
    if atlas ~= nil then
        local icon = AddImage(root, atlas, texture, map_x, map_y)
        local icon_size = IsInteriorDoormat(ent) and ROOM_DOORMAT_ICON_SIZE or ROOM_ICON_SIZE
        icon:SetSize(icon_size, icon_size)
        return icon
    end

    return nil
end

local function AddRoomEntityIcons(root, room)
    local width, depth = GetDimensions(room)
    local room_x, _, room_z = room.Transform:GetWorldPosition()
    local radius = math.sqrt(width * width + depth * depth) * 0.5 + ROOM_ICON_RADIUS_PADDING
    for _, ent in ipairs(TheSim:FindEntities(room_x, 0, room_z, radius)) do
        if IsInteriorMapEntity(ent) and RoomExtensions.GetRoomForEntity(ent) == room then
            local x, _, z = ent.Transform:GetWorldPosition()
            local map_x, map_y = WorldToRoomMapPosition(room, x, z)
            AddEntityIcon(root, ent, map_x, map_y)
        end
    end
end

local function AddPlayerMarker(root, room)
    if ThePlayer == nil then
        return nil
    end

    local player_x, _, player_z = ThePlayer.Transform:GetWorldPosition()
    if not RoomExtensions.IsPointInRoom(room, player_x, player_z) then
        return nil
    end
    local map_x, map_y = WorldToRoomMapPosition(room, player_x, player_z)
    local atlas, texture = GetCharacterAvatarTextureLocation(ThePlayer.prefab or "unknown")
    local marker = AddImage(root, atlas, texture, map_x, map_y)
    marker:SetSize(ROOM_PLAYER_SIZE, ROOM_PLAYER_SIZE)
    return marker
end

local function AppendRoomTexture(self, start_room)
    local grid, start_x, start_z = RoomExtensions.GetCurrentRoomsGrid(start_room)
    if start_x == nil or start_z == nil then
        return
    end

    local start_width, start_depth = GetDimensions(start_room)
    if start_width <= 0 or start_depth <= 0 then
        return
    end
    local cell_width = start_depth * WORLD_TO_MAP_SCALE + ROOM_GAP
    local cell_height = start_width * WORLD_TO_MAP_SCALE + ROOM_GAP
    local passages = {}
    local player_marker = nil
    local map_root = self:AddChild(Widget("interior_map_root"))
    local background_layer = map_root:AddChild(Widget("interior_map_background"))
    local passage_layer = map_root:AddChild(Widget("interior_map_passages"))
    local icon_layer = map_root:AddChild(Widget("interior_map_icons"))

    map_root._ta_transform_widgets = {}
    background_layer._ta_map_root = map_root
    passage_layer._ta_map_root = map_root
    icon_layer._ta_map_root = map_root
    self._ta_interior_map_root = map_root

    -- Keep the room map at the same level as the normal map texture, then use
    -- the additive frame copy to draw the map border over it.
    map_root:MoveToBack()
    if self.bg ~= nil then
        self.bg:MoveToBack()
    end
    local map_frame = EnsureInteriorMapFrame(self)
    if map_frame ~= nil then
        map_frame:Show()
        map_frame:MoveToFront()
    end

    for grid_x, row in ipairs(grid) do
        for grid_z, cell in ipairs(row) do
            local room = cell and cell.room or nil
            if room ~= nil and (room == start_room or IsExplored(room)) then
                local room_offset_x = (grid_z - start_z) * cell_width
                local room_offset_y = (start_x - grid_x) * cell_height
                background_layer.room_offset_x = room_offset_x
                background_layer.room_offset_y = room_offset_y
                passage_layer.room_offset_x = room_offset_x
                passage_layer.room_offset_y = room_offset_y
                icon_layer.room_offset_x = room_offset_x
                icon_layer.room_offset_y = room_offset_y
                self._ta_interior_room_images[room] = true

                AddRoomFloor(background_layer, room)
                AddRoomEntityIcons(icon_layer, room)
                if room == start_room then
                    player_marker = AddPlayerMarker(icon_layer, room)
                end

                -- Draw each shared passage once, on the back/right edge.
                local room_map_width, room_map_height = GetRoomMapSize(room)
                local passage_x = room_map_width * 0.5 + ROOM_GAP * 0.5
                local passage_y = room_map_height * 0.5 + ROOM_GAP * 0.5
                if cell.back then
                    table.insert(passages, AddPassage(passage_layer, 90, 0, passage_y))
                end
                if cell.right then
                    table.insert(passages, AddPassage(passage_layer, 0, passage_x, 0))
                end
                if cell.front and (grid[grid_x + 1] == nil or grid[grid_x + 1][grid_z] == false) then
                    table.insert(passages, AddPassage(passage_layer, 90, 0, -passage_y))
                end
                if cell.left and (grid[grid_x] == nil or grid[grid_x][grid_z - 1] == false) then
                    table.insert(passages, AddPassage(passage_layer, 0, -passage_x, 0))
                end
            end
        end
    end

    for _, passage in ipairs(passages) do
        passage:MoveToFront()
    end
    if player_marker ~= nil then
        player_marker:MoveToFront()
    end
end

local function RefreshInteriorMap(self)
    if self._ta_map_mode == "world" then
        return false
    end

    local room = GetCurrentRoom()
    if room == nil then
        return false
    end
    if self._ta_interior_debug_room ~= room then
        self._ta_interior_debug_room = room
        DebugInteriorMinimap("refresh", room.prefab or "room", room.GUID or "noguid")
    end
    if self.img ~= nil then
        self.img:Hide()
    end
    ClearRoomImages(self)
    AppendRoomTexture(self, room)
    return true
end

local function UpdateInteriorMapTransform(self)
    if self._ta_interior_map_root ~= nil then
        self._ta_interior_view_x = self._ta_interior_view_x or 0
        self._ta_interior_view_y = self._ta_interior_view_y or 0
        self._ta_interior_view_zoom = self._ta_interior_view_zoom or INTERIOR_ZOOM_DEFAULT
        self._ta_interior_map_root:SetPosition(0, 0, 0)
        self._ta_interior_map_root:SetScale(1, 1, 1)
        for _, widget in ipairs(self._ta_interior_map_root._ta_transform_widgets or {}) do
            if widget ~= nil then
                widget:SetPosition(
                    self._ta_interior_view_x + widget._ta_base_x * self._ta_interior_view_zoom,
                    self._ta_interior_view_y + widget._ta_base_y * self._ta_interior_view_zoom,
                    0
                )
                widget:SetScale(
                    (widget._ta_base_scale_x or 1) * self._ta_interior_view_zoom,
                    (widget._ta_base_scale_y or widget._ta_base_scale_x or 1) * self._ta_interior_view_zoom,
                    1
                )
            end
        end
    end
end

local function IsInteriorMapVisible(self)
    return self ~= nil and self._ta_interior_map_root ~= nil
end

local function OffsetInteriorMap(self, dx, dy)
    if IsInteriorMapVisible(self) then
        self._ta_interior_view_x = (self._ta_interior_view_x or 0) + dx * INTERIOR_DRAG_SCALE
        self._ta_interior_view_y = (self._ta_interior_view_y or 0) + dy * INTERIOR_DRAG_SCALE
        local now = GetTime()
        if self._ta_interior_debug_offset_time == nil or now - self._ta_interior_debug_offset_time > 0.35 then
            self._ta_interior_debug_offset_time = now
            DebugInteriorMinimap("offset", dx, dy, "view", self._ta_interior_view_x, self._ta_interior_view_y)
        end
        UpdateInteriorMapTransform(self)
        return true
    end
    return false
end

local function ZoomInteriorMap(self, delta, cursor_x, cursor_y)
    if IsInteriorMapVisible(self) then
        local old_zoom = self._ta_interior_view_zoom or INTERIOR_ZOOM_DEFAULT
        local new_zoom = Clamp(old_zoom + delta, INTERIOR_ZOOM_MIN, INTERIOR_ZOOM_MAX)
        if new_zoom ~= old_zoom then
            local center_x, center_y
            if cursor_x ~= nil and cursor_y ~= nil then
                local screen_width, screen_height = TheSim:GetScreenSize()
                center_x = cursor_x - screen_width * 0.5
                center_y = cursor_y - screen_height * 0.5
            else
                center_x, center_y = GetCursorCenterPosition()
            end
            local ratio = new_zoom / old_zoom
            local old_x = self._ta_interior_view_x or 0
            local old_y = self._ta_interior_view_y or 0
            self._ta_interior_view_x = center_x - (center_x - old_x) * ratio
            self._ta_interior_view_y = center_y - (center_y - old_y) * ratio
            self._ta_interior_view_zoom = new_zoom
            DebugInteriorMinimap("zoom", old_zoom, "->", new_zoom, "cursor", cursor_x or "nil", cursor_y or "nil")
            UpdateInteriorMapTransform(self)
        end
        return true
    end
    return false
end

AddClassPostConstruct("widgets/mapwidget", function(self)
    DebugInteriorMinimap("mapwidget patch", self.name or "noname")
    self._ta_interior_room_images = {}
    self._ta_interior_map_root = nil
    self._ta_interior_view_x = 0
    self._ta_interior_view_y = 0
    self._ta_interior_view_zoom = INTERIOR_ZOOM_DEFAULT
    self._ta_map_mode = "interior"
    self._ta_interior_map_frame = EnsureInteriorMapFrame(self)

    local old_update_texture = self.UpdateTexture
    function self:UpdateTexture(...)
        if RefreshInteriorMap(self) then
            self._ta_interior_view_x = self._ta_interior_view_x or 0
            self._ta_interior_view_y = self._ta_interior_view_y or 0
            self._ta_interior_view_zoom = self._ta_interior_view_zoom or INTERIOR_ZOOM_DEFAULT
            UpdateInteriorMapTransform(self)
            return
        end
        ClearRoomImages(self)
        self._ta_interior_view_x = 0
        self._ta_interior_view_y = 0
        self._ta_interior_view_zoom = INTERIOR_ZOOM_DEFAULT
        if self.img ~= nil then
            self.img:Show()
        end
        return old_update_texture(self, ...)
    end

    local old_on_update = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local result = old_on_update(self, dt, ...)
        if IsInteriorMapVisible(self) then
            UpdateInteriorMapTransform(self)
        end
        return result
    end

    function self:_ta_UpdateInteriorMapTransform()
        UpdateInteriorMapTransform(self)
    end

    function self:_ta_OffsetInteriorMap(dx, dy)
        return OffsetInteriorMap(self, dx, dy)
    end

    function self:_ta_ZoomInteriorMap(delta, cursor_x, cursor_y)
        return ZoomInteriorMap(self, delta, cursor_x, cursor_y)
    end

    function self:_ta_IsInteriorMapVisible()
        return IsInteriorMapVisible(self)
    end

    function self:_ta_SetMapMode(mode)
        self._ta_map_mode = mode == "world" and "world" or "interior"
        self:UpdateTexture()
    end

    function self:_ta_GetMapMode()
        return self._ta_map_mode or "interior"
    end

    local old_on_hide = self.OnHide
    function self:OnHide(...)
        ClearRoomImages(self)
        self._ta_interior_view_x = 0
        self._ta_interior_view_y = 0
        self._ta_interior_view_zoom = INTERIOR_ZOOM_DEFAULT
        self._ta_map_mode = "interior"
        if self.img ~= nil then
            self.img:Show()
        end
        return old_on_hide(self, ...)
    end
end)

AddClassPostConstruct("screens/mapscreen", function(self)
    DebugInteriorMinimap("mapscreen patch", self.name or "noname")
    local function IsInteriorMapVisibleOnScreen(screen)
        return screen.minimap ~= nil
            and screen.minimap._ta_IsInteriorMapVisible ~= nil
            and screen.minimap:_ta_IsInteriorMapVisible()
    end

    local function UpdateInteriorMap(screen)
        if screen.minimap ~= nil and screen.minimap._ta_UpdateInteriorMapTransform ~= nil then
            screen.minimap:_ta_UpdateInteriorMapTransform()
        end
    end

    local function OffsetInteriorMapOnScreen(screen, dx, dy)
        if screen.minimap ~= nil and screen.minimap._ta_OffsetInteriorMap ~= nil then
            return screen.minimap:_ta_OffsetInteriorMap(dx, dy)
        end
        return false
    end

    local function ZoomInteriorMapOnScreen(screen, delta, x, y)
        if screen.minimap ~= nil and screen.minimap._ta_ZoomInteriorMap ~= nil then
            return screen.minimap:_ta_ZoomInteriorMap(delta, x, y)
        end
        return false
    end

    local function FocusWorldMapOnRoomEntry(screen, room)
        if screen == nil or screen.minimap == nil or room == nil
            or room._ta_exterior_x == nil or room._ta_exterior_z == nil
            or ThePlayer == nil or ThePlayer.Transform == nil then
            return
        end

        local exterior_x = room._ta_exterior_x:value()
        local exterior_z = room._ta_exterior_z:value()
        local player_x, _, player_z = ThePlayer.Transform:GetWorldPosition()
        local heading = TheCamera ~= nil and TheCamera:GetHeadingTarget() * DEGREES or 0
        local dx = exterior_x - player_x
        local dz = exterior_z - player_z

        screen:SetZoom(1)
        screen.minimap.minimap:ResetOffset()

        -- Convert the world-space difference to the map's heading-relative axes.
        local offset_x = dx * math.sin(heading) - dz * math.cos(heading)
        local offset_y = dx * math.cos(heading) + dz * math.sin(heading)
        screen.minimap:Offset(offset_x, offset_y)
    end

    local function ToggleMapMode(screen)
        local room = GetCurrentRoom()
        if room == nil or screen.minimap == nil or screen.minimap._ta_GetMapMode == nil then
            return
        end

        if screen.minimap:_ta_GetMapMode() == "world" then
            screen.minimap:_ta_SetMapMode("interior")
            screen.minimap.minimap:ResetOffset()
        else
            screen.minimap:_ta_SetMapMode("world")
            FocusWorldMapOnRoomEntry(screen, room)
        end
    end

    local function UpdateMapToggleButton(screen)
        if screen._ta_interior_toggle_button == nil then
            return
        end

        if GetCurrentRoom() ~= nil then
            screen._ta_interior_toggle_button:Show()
        else
            screen._ta_interior_toggle_button:Hide()
        end
    end

    self._ta_interior_toggle_button = self.bottomright_root:AddChild(
        ImageButton(MAP_TOGGLE_ATLAS, MAP_TOGGLE_TEXTURE, MAP_TOGGLE_TEXTURE, MAP_TOGGLE_TEXTURE, MAP_TOGGLE_TEXTURE)
    )
    self._ta_interior_toggle_button:SetScale(0.84, 0.84, 1)
    self._ta_interior_toggle_button:SetPosition(-60, 150, 0)
    self._ta_interior_toggle_button:SetImageFocusColour(1, 0.92, 0.67, 1)
    self._ta_interior_toggle_button:SetOnClick(function()
        ToggleMapMode(self)
    end)
    self._ta_interior_toggle_button:Hide()

    local old_on_update = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local result = old_on_update(self, dt, ...)
        UpdateMapToggleButton(self)
        if IsInteriorMapVisibleOnScreen(self) then
            if IsPrimaryMouseDown() then
                local pos = TheInput:GetScreenPosition()
                if self._ta_interior_drag_pos ~= nil then
                    local dx = pos.x - self._ta_interior_drag_pos.x
                    local dy = pos.y - self._ta_interior_drag_pos.y
                    if dx ~= 0 or dy ~= 0 then
                        local now = GetTime()
                        if self._ta_interior_debug_drag_time == nil or now - self._ta_interior_debug_drag_time > 0.35 then
                            self._ta_interior_debug_drag_time = now
                            DebugInteriorMinimap("drag poll", dx, dy)
                        end
                        OffsetInteriorMapOnScreen(self, dx, dy)
                    end
                end
                self._ta_interior_drag_pos = pos
            else
                self._ta_interior_drag_pos = nil
            end
            UpdateInteriorMap(self)
        else
            self._ta_interior_drag_pos = nil
        end
        return result
    end

    local old_on_control = self.OnControl
    function self:OnControl(control, down, ...)
        if IsInteriorMapVisibleOnScreen(self) then
            if down and control == CONTROL_MAP_ZOOM_IN and not TheInput:GetControlIsMouseWheel(control) then
                DebugInteriorMinimap("OnControl zoom in", control)
                ZoomInteriorMapOnScreen(self, INTERIOR_ZOOM_STEP)
                return true
            elseif down and control == CONTROL_MAP_ZOOM_OUT and not TheInput:GetControlIsMouseWheel(control) then
                DebugInteriorMinimap("OnControl zoom out", control)
                ZoomInteriorMapOnScreen(self, -INTERIOR_ZOOM_STEP)
                return true
            end
        end
        return old_on_control(self, control, down, ...)
    end

    local old_on_mouse_button = self.OnMouseButton
    function self:OnMouseButton(button, down, x, y, ...)
        if IsInteriorMapVisibleOnScreen(self) then
            if button == MOUSEBUTTON_LEFT then
                DebugInteriorMinimap("OnMouseButton left", down, x, y)
                self._ta_interior_drag_pos = down and Vector3(x, y, 0) or nil
                return true
            elseif button == MOUSEBUTTON_SCROLLUP then
                DebugInteriorMinimap("OnMouseButton scroll up", down, x, y)
                ZoomInteriorMapOnScreen(self, INTERIOR_ZOOM_STEP, x, y)
                return true
            elseif button == MOUSEBUTTON_SCROLLDOWN then
                DebugInteriorMinimap("OnMouseButton scroll down", down, x, y)
                ZoomInteriorMapOnScreen(self, -INTERIOR_ZOOM_STEP, x, y)
                return true
            end
        end
        return old_on_mouse_button ~= nil and old_on_mouse_button(self, button, down, x, y, ...) or false
    end

end)
