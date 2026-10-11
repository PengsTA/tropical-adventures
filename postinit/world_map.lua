--@Author: Peng
local Utils = require("tools/utils")
local RoomExtensions = require "tools/interior_room_extensions"
local RegionDefs = require("tools/regiondefs")
local WALL_SECTION_BUILD_DISTANCE = 0.35

-----------map related--------------------------
require("components/map")


----种植判定改动
local function FindVisualTileAtPoint_TestArea(map, pt_x, pt_z, r)
    local best = { tile_type = WORLD_TILES.INVALID, render_layer = -1 }
    for _z = -1, 1 do
        for _x = -1, 1 do
            local x, z = pt_x + _x * r, pt_z + _z * r

            local tile_type = map:GetTileAtPoint(x, 0, z) -----这里判断地皮总有点不太合适，判断初始地皮会好一些
            local tile_info = GetTileInfo(tile_type)
            local render_layer = tile_info ~= nil and tile_info._render_layer or 0
            if render_layer > best.render_layer then
                best.tile_type = tile_type
                best.render_layer = render_layer
                best.x = x
                best.z = z
            end
        end
    end

    return best.tile_type ~= WORLD_TILES.INVALID and best or nil
end

Map.FindVisualTileAtPoint = function(self, x, y, z)
    local best = FindVisualTileAtPoint_TestArea(self, x, z, 0.95)
    return (best ~= nil) and best.tile_type or 1 ---1应该是虚空吧
end

function Map:CanPlantAtPoint(x, y, z)
    local tile = self:FindVisualTileAtPoint(x, y, z)
    if not TileGroupManager:IsLandTile(tile) then
        return false
    end
    return not GROUND_HARD[tile]
end

-------区域判定改动
local function FindVisualNodeAtPoint_TestArea(map, pt_x, pt_z, r)
    local best = { tile_type = WORLD_TILES.INVALID, render_layer = -1 }
    for _z = -1, 1 do
        for _x = -1, 1 do
            local x, z = pt_x + _x * r, pt_z + _z * r

            local tile_type = map:GetTileAtPoint(x, 0, z) -----这里判断地皮总有点不太合适，判断初始地皮会好一些
            if IsValidNodeTile(tile_type) then
                local tile_info = GetTileInfo(tile_type)
                local render_layer = tile_info ~= nil and tile_info._render_layer or 0
                if render_layer > best.render_layer then
                    best.tile_type = tile_type
                    best.render_layer = render_layer
                    best.x = x
                    best.z = z
                end
            end
        end
    end

    return best.tile_type ~= WORLD_TILES.INVALID and best or nil
end

Map.FindVisualNodeAtPoint = function(self, x, y, z, has_tag)
    local node_index

    local nodeid = self:GetNodeIdAtPoint(x, 0, z)
    local in_node = nodeid and nodeid ~= 0

    local tile_type = self:GetTileAtPoint(x, 0, z)
    local is_valid_tile = IsValidNodeTile(tile_type)
    if in_node and is_valid_tile then
        node_index = nodeid
    else
        local best = FindVisualNodeAtPoint_TestArea(self, x, z, 4)
            or FindVisualNodeAtPoint_TestArea(self, x, z, 16)
            or FindVisualNodeAtPoint_TestArea(self, x, z, 64)
            or FindVisualNodeAtPoint_TestArea(self, x, z, 256)

        node_index = (best ~= nil) and self:GetNodeIdAtPoint(best.x, 0, best.z) or 0
    end


    if has_tag == nil then
        return TheWorld.topology.nodes[node_index], node_index
    else
        local node = TheWorld.topology.nodes[node_index]
        return ((node ~= nil and table.contains(node.tags, has_tag)) and node or nil), node_index
    end
end

local function GetTopologyTagQuery(map, x, y, z)
    local node = map:FindVisualNodeAtPoint(x, y, z)
    local tags = node ~= nil and node.tags or nil
    return function(tag)
        return tags ~= nil and table.contains(tags, tag)
    end
end

function Map:HasTopologyTagAtPoint(x, y, z, tag)
    return GetTopologyTagQuery(self, x, y, z)(tag)
end

function Map:GetPrimaryRegionAtPoint(x, y, z)
    return RegionDefs.GetPrimaryName(RegionDefs.ResolvePrimaryRegion(GetTopologyTagQuery(self, x, y, z)))
end

function Map:GetSubregionAtPoint(x, y, z, primary)
    local has_tag = GetTopologyTagQuery(self, x, y, z)
    primary = primary or RegionDefs.ResolvePrimaryRegion(has_tag)
    return RegionDefs.GetSubregionName(RegionDefs.ResolveSubregion(primary, has_tag))
end

function Map:GetRegionProfileAtPoint(x, y, z)
    local has_tag = GetTopologyTagQuery(self, x, y, z)
    local primary = RegionDefs.ResolvePrimaryRegion(has_tag)
    return {
        primary = RegionDefs.GetPrimaryName(primary),
        subregion = RegionDefs.GetSubregionName(RegionDefs.ResolveSubregion(primary, has_tag)),
        isinterior = self:IsInteriorAtPoint(x, y, z),
        isdeeprainforest = has_tag("deeprainforest"),
    }
end

function Map:IsPrimaryRegionAtPoint(x, y, z, primary)
    return self:GetPrimaryRegionAtPoint(x, y, z) == RegionDefs.GetPrimaryName(primary)
end

function Map:IsSubregionAtPoint(x, y, z, subregion)
    return self:GetSubregionAtPoint(x, y, z) == RegionDefs.GetSubregionName(subregion)
end

function Map:IsTropicalRegionAtPoint(x, y, z)
    return RegionDefs.IsTropicalPrimary(self:GetPrimaryRegionAtPoint(x, y, z))
end

function Map:IsDSTRegionAtPoint(x, y, z)
    return not self:IsOutsideWorldAtPoint(x, y, z)
        and self:IsPrimaryRegionAtPoint(x, y, z, RegionDefs.PRIMARY.dst)
end

-- Legacy map APIs retained for compatibility. New code uses the explicit
-- topology, primary-region, and subregion queries above.
Map.IsCityAreaAtPoint = function(self, x, y, z)
    return self:IsSubregionAtPoint(x, y, z, RegionDefs.SUBREGION.ham_city)
end

Map.IsCivilizedAreaAtPoint = function(self, x, y, z)
    return self:HasTopologyTagAtPoint(x, y, z, "civilized")
end

Map.IsTropicalAreaAtPoint = Map.IsTropicalRegionAtPoint

Map.IsShipwreckedAreaAtPoint = function(self, x, y, z)
    return self:IsPrimaryRegionAtPoint(x, y, z, RegionDefs.PRIMARY.shipwrecked)
end

Map.IsHamletAreaAtPoint = function(self, x, y, z)
    return self:IsPrimaryRegionAtPoint(x, y, z, RegionDefs.PRIMARY.hamlet)
end

Map.IsRainforestAreaAtPoint = function(self, x, y, z)
    return self:IsSubregionAtPoint(x, y, z, RegionDefs.SUBREGION.ham_rainforest)
end

Map.IsVolcanoAreaAtPoint = function(self, x, y, z)
    return self:IsSubregionAtPoint(x, y, z, RegionDefs.SUBREGION.sw_volcano)
end

local width, height
local _SetTile = Map.SetTile
function Map:SetTile(tile_x, tile_y, tile, ...)
    if not width then
        width, height = TheWorld.Map:GetWorldSize()
    end
    local newtile
    if tile == WORLD_TILES.DIRT then
        local x = (tile_x - width / 2) * TILE_SCALE
        local z = (tile_y - height / 2) * TILE_SCALE
        newtile = (self:IsPrimaryRegionAtPoint(x, 0, z, RegionDefs.PRIMARY.shipwrecked) and WORLD_TILES.BEACH) or nil
    end
    _SetTile(self, tile_x, tile_y, newtile or tile, ...)
end

local BASE_TILES = {
    -- [WORLD_TILES.VOLCANO_ROCK] = true,
    [WORLD_TILES.BEACH] = true,
}

local _CanPlaceTurfAtPoint = Map.CanPlaceTurfAtPoint
function Map:CanPlaceTurfAtPoint(x, y, z, ...)
    return _CanPlaceTurfAtPoint(self, x, y, z, ...) or BASE_TILES[self:GetTileAtPoint(x, y, z)]
end

-------------------地图判定（新）------------------------------------

-- local worldwidth, worldheight = TheWorld.Map:GetWorldSize()
local check_size = 1350
local INTERIOR_ORIGIN_PADDING = 128
local CURRENT_ROOM_SEARCH_PADDING = 24

local function IsPotentialInteriorCoordinate(x, z)
    if TheWorld == nil or TheWorld.Map == nil then
        return false
    end
    local width, height = TheWorld.Map:GetSize()
    if width == nil or height == nil then
        return false
    end

    local tile_scale = TILE_SCALE or 4
    local origin_x = width * tile_scale * 0.5 + INTERIOR_ORIGIN_PADDING
    local origin_z = height * tile_scale * 0.5 + INTERIOR_ORIGIN_PADDING
    return x >= origin_x - CURRENT_ROOM_SEARCH_PADDING
        and z >= origin_z - CURRENT_ROOM_SEARCH_PADDING
end

local function checkxz(x, z)
    return math.abs(z) >= check_size
        or math.abs(x) >= check_size
        or IsPotentialInteriorCoordinate(x, z)
end

-------------------来自于猪人部落-------------
local HamHome = {} --室内的中心坐标，由于地皮一定在中心
-- The largest current room shell is 20 x 28. Twenty-four units reaches its
-- farthest corner plus the invisible wall thickness without probing neighbours.
local ROOM_SEARCH_RADIUS = CURRENT_ROOM_SEARCH_PADDING
local lastHamHome = {} --缓冲，短时间内在一个房间附近求值的可能性较大
local WALL_HALF_THICKNESS = 0.49
local WALL_END_INSET = 1

local function GetDynamicRoomBounds(v)
    if v._ta_width == nil or v._ta_depth == nil then
        return nil
    end

    local width = v._ta_width:value()
    local depth = v._ta_depth:value()
    if width == nil or depth == nil or width <= 0 or depth <= 0 then
        return nil
    end

    return width * 0.5, depth * 0.5
end
-- 室内可放置建筑，物品不会掉入“水”中

local function CheckNearRoomCenter(x, z, v, checkwall)
    local half_width, half_depth = GetDynamicRoomBounds(v)
    if half_width == nil then
        return false
    end

    local xx, _, zz = v.Transform:GetWorldPosition()
    local dx = x - xx
    local dz = z - zz
    if not checkwall then
        return math.abs(dx) <= half_width and math.abs(dz) <= half_depth
    end

    -- The front edge is intentionally open. It is the room entrance, not a
    -- wall, so map wall queries only report the rear and two side edges.
    if math.abs(dx + half_width) <= WALL_HALF_THICKNESS
        and math.abs(dz) <= half_depth - WALL_END_INSET then
        return "back"
    elseif math.abs(dz - half_depth) <= WALL_HALF_THICKNESS
        and math.abs(dx) <= half_width - WALL_END_INSET then
        return "right"
    elseif math.abs(dz + half_depth) <= WALL_HALF_THICKNESS
        and math.abs(dx) <= half_width - WALL_END_INSET then
        return "left"
    end

    return false
end

local function IsHamRoomAtPoint(x, y, z, checkwall)
    -- if type(x) ~= "number" then
    --     x, y, z = x.x or x, x.y or y, x.z or z
    -- end

    if checkxz(x, z) then --判断的基础，也许光判断z就行了
        -- 缓存
        if lastHamHome.home then
            if lastHamHome.home:IsValid() then
                local isroom = CheckNearRoomCenter(x, z, lastHamHome.home, checkwall)
                if isroom
                --[[VecUtil_DistSq(lastHamHome.pos[1], lastHamHome.pos[2], x, z) < DIS_SQ]] then
                    return isroom
                end
            else
                lastHamHome.home = nil
                lastHamHome.pos = nil
            end
        end

        -- 缓存表
        for ent, pos in pairs(HamHome) do
            if ent:IsValid() then
                -- print(x, z, pos[1], pos[2], VecUtil_DistSq(pos[1], pos[2], x, z))
                local isroom = CheckNearRoomCenter(x, z, ent, checkwall)
                if isroom
                --[[VecUtil_DistSq(pos[1], pos[2], x, z) < DIS_SQ]] then
                    lastHamHome.home = ent
                    lastHamHome.pos = pos
                    return isroom
                end
            else
                HamHome[ent] = nil
            end
        end

        -- 查找
        local ents = TheSim:FindEntities(x, 0, z, ROOM_SEARCH_RADIUS, { "interior_center" }) --查找地板
        if #ents > 0 then
            for _, ent in ipairs(ents) do
                if ent:IsValid() then
                    local ex, _, ez = ent.Transform:GetWorldPosition()
                    HamHome[ent] = { ex, ez }
                    local isroom = CheckNearRoomCenter(x, z, ent, checkwall)
                    if isroom then
                        lastHamHome.home = ent
                        lastHamHome.pos = { ex, ez }
                        return isroom
                    end
                end
            end
        end
    end
    return false
end

-----------新的Map函数---------------
Map.IsInteriorAtPoint = function(self, x, y, z)
    return IsHamRoomAtPoint(x, y, z, false)
end

Map.IsHamRoomAtPoint = Map.IsInteriorAtPoint

Map.IsInteriorWallAtPoint = function(self, x, y, z)
    return IsHamRoomAtPoint(x, y, z, true) --true则检查墙点
end

Map.IsHamRoomWallAtPoint = Map.IsInteriorWallAtPoint

Map.IsOutsideWorldAtPoint = function(self, x, y, z)
    if checkxz(x, z) then --判断的基础，也许光判断z就行了
        return true
    end
    return false
end


Map.IsNotForestAreaAtPoint = function(self, x, y, z)
    return not self:IsDSTRegionAtPoint(x, y, z)
end

Map.IsForestAreaAtPoint = Map.IsDSTRegionAtPoint




----------房间-----------------
local function CheckHamRoomBefore(self, x, y, z)
    local isroom = IsHamRoomAtPoint(x, y, z, false)

    if isroom == true then
        return { true }, true
    end
end


local function GetHamHomeBefore(self, x, y, z, extra_radius) ----yz乱用的后果
    local isroom = IsHamRoomAtPoint(x, y, z or y, false)
    if isroom == true then
        return { lastHamHome.home }, true
    end
end


---------- 根据components/deployable.lua判断需要覆盖的方法
Utils.FnDecorator(Map, "IsAboveGroundAtPoint", CheckHamRoomBefore)
Utils.FnDecorator(Map, "IsPassableAtPoint", CheckHamRoomBefore)
Utils.FnDecorator(Map, "IsVisualGroundAtPoint", CheckHamRoomBefore)
Utils.FnDecorator(Map, "CanPlantAtPoint", CheckHamRoomBefore) --允许房间里种植，不知道算不算超模


-------------地皮中心---------------------
local _GetTileCenterPoint = Map.GetTileCenterPoint
function Map:GetTileCenterPoint(x, y, z, ...)
    if z and checkxz(x, z) then
        return math.floor(x / 4) * 4 + 2, 0, math.floor(z / 4) * 4 + 2
    else
        return _GetTileCenterPoint(self, x, y, z, ...)
    end
end

---------放置检查---------------------限制制作的配方-----------------------
local banrecipe = { "playerhouse_city", "pighouse_city", "city_lamp", "pig_guard_tower", "pig_guard_tower_palace",
    "pugaliskfountain_made",
    "hua_player_house_recipe",
    "homesign", "townportal", "telebase", "hua_player_house1_recipe",
    "hua_player_house_pvz_recipe", "hua_player_house_tardis_recipe", "infantree_carpet", "myth_house_bamboo"

}

local old_CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint
Map.CanDeployRecipeAtPoint = function(self, pt, recipe, rot, ...)
    if recipe.build_mode == "insidedoor" then
        local pt_x, pt_y, pt_z = pt:Get()
        -- Expansion doors can use all four logical wall centers, including the
        -- open front side.
        return RoomExtensions.GetWallBuildInfoAtPoint(pt_x, pt_y, pt_z, { center_only = true, rendered_walls_only = false }) ~= nil
    elseif recipe.build_mode == "wallsection" then
        local pt_x, pt_y, pt_z = pt:Get()
        return RoomExtensions.GetWallBuildInfoAtPoint(pt_x, pt_y, pt_z, {
            center_only = false,
            wall_distance = WALL_SECTION_BUILD_DISTANCE,
        }) ~= nil
    elseif recipe.build_mode == "interior" then
        local pt_x, pt_y, pt_z = pt:Get()
        return IsHamRoomAtPoint(pt_x, pt_y, pt_z, false)
    elseif tableutil.has_component(banrecipe, recipe.name) or string.find(recipe.name, "pig_shop") then
        local pt_x, pt_y, pt_z = pt:Get()
        local isroom = IsHamRoomAtPoint(pt_x, pt_y, pt_z, false)
        if isroom then
            return false
        else
            return old_CanDeployRecipeAtPoint(self, pt, recipe, rot, ...)
        end
    else
        return old_CanDeployRecipeAtPoint(self, pt, recipe, rot, ...)
    end
end
