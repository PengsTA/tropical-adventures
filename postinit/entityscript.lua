require("entityscript")


GLOBAL.setfenv(1, GLOBAL)
local RegionDefs = require("tools/regiondefs")
local ClimateProfiles = require("tools/climateprofiles")

-- local entity_to_inst = {}
-- local _CreateEntity = CreateEntity
-- CreateEntity = function()
--     print("CreateEntity111")
--     local inst = _CreateEntity()
--     entity_to_inst[inst.entity] = inst
--     return inst
-- end

-- function GetEntityinst(entity)
--     return entity_to_inst[entity] or nil
-- end

function EntityScript:IsInPrimaryRegion(primary)
    return TheWorld.Map:IsPrimaryRegionAtPoint(self:GetPosition():Get(), primary)
end

function EntityScript:IsInSubregion(subregion)
    return TheWorld.Map:IsSubregionAtPoint(self:GetPosition():Get(), subregion)
end

function EntityScript:IsInTropicalRegion()
    return TheWorld.Map:IsTropicalRegionAtPoint(self:GetPosition():Get())
end

function EntityScript:IsInInterior()
    return TheWorld.Map:IsInteriorAtPoint(self:GetPosition():Get())
end

function EntityScript:IsInWorld()
    local x, y, z = self.Transform:GetWorldPosition()
    return math.abs(x) <= 1350 and math.abs(z) <= 1350
    -- local width, height = TheWorld.Map:GetWorldSize()
    -- local x, y, z = self.Transform:GetWorldPosition()
    -- local tile_x, tile_y = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)

    -- return tile_x <= width and tile_y <= height

    -- local nx = (tile_x - width / 2) * TILE_SCALE
    -- local nz = (tile_y - height / 2) * TILE_SCALE
    -- local worldwidth, worldheight = TheWorld.Map:GetWorldSize()
    -- local x, y, z = self.Transform:GetWorldPosition()
    -- return math.abs(x) <= worldwidth and math.abs(z) <= worldheight
    -- return true
end

--实体是否在虚空的房间里面
function EntityScript:IsInHamRoom()
    return self:IsInInterior()
end

function EntityScript:IsOutsideWorld()
    return TheWorld.Map:IsOutsideWorldAtPoint(self:GetPosition():Get())
end

function EntityScript:IsNotInForestArea()
    return not TheWorld.Map:IsDSTRegionAtPoint(self:GetPosition():Get())
end

function EntityScript:IsInForestArea()
    return TheWorld.Map:IsDSTRegionAtPoint(self:GetPosition():Get())
end

function EntityScript:IsOnLandTile()
    return TheWorld.Map:IsLandTileAtPoint(self.Transform:GetWorldPosition())
end

function EntityScript:GetIsFlooded()
    if not self:IsValid() or self.Transform == nil or TheWorld == nil then
        return false
    end

    local floodmanager = TheWorld.components ~= nil and TheWorld.components.floodmanager or nil
    if floodmanager == nil then
        return false
    end

    local x, _, z = self.Transform:GetWorldPosition()
    return floodmanager:IsFloodedAtPoint(x, z)
end

function EntityScript:AwareGetClimateProfile()
    local climate = self.components.regionalclimate
    if climate ~= nil then
        return climate:GetSeasonProfile()
    end

    local classified = self.player_classified
    if classified ~= nil and classified._regionalclimate_profile ~= nil then
        return ClimateProfiles.GetProfileName(classified._regionalclimate_profile:value())
    end
    return "dst"
end

function EntityScript:AwareGetClimatePhase()
    local climate = self.components.regionalclimate
    if climate ~= nil then
        return climate:GetSeasonPhase()
    end

    local classified = self.player_classified
    if classified ~= nil and classified._regionalclimate_phase ~= nil then
        return ClimateProfiles.GetPhaseName(classified._regionalclimate_phase:value())
    end
    return "early"
end

local function GetAwarePrimaryRegion(inst)
    return RegionDefs.GetPrimaryIdFromTags(function(tag)
        return inst:HasTag(tag)
    end)
end

local function GetAwareSubregion(inst)
    return RegionDefs.GetSubregionIdFromTags(function(tag)
        return inst:HasTag(tag)
    end)
end

function EntityScript:AwareHasTopologyTag(tag)
    local aware = self.components.areaaware
    return aware ~= nil and aware:CurrentlyInTag(tag) and true or false
end

function EntityScript:AwareInPrimaryRegion(primary)
    -- local current = GetAwarePrimaryRegion(self)
    -- return current ~= nil and current == RegionDefs.GetPrimaryId(primary)
    return self:HasTag("region_primary_" .. RegionDefs.PRIMARY_NAMES[primary])
end

function EntityScript:AwareInSubregion(subregion)
    -- local current = GetAwareSubregion(self)
    -- return current ~= nil and current == RegionDefs.GetSubregionId(subregion)
    return self:HasTag("region_sub_" .. RegionDefs.SUBREGION_NAMES[subregion])
end

function EntityScript:AwareInInterior()
    return self:HasTag(RegionDefs.INTERIOR_TAG)
end

function EntityScript:AwareInDSTRegion()
    return self:AwareInPrimaryRegion(RegionDefs.PRIMARY.dst)
end

function EntityScript:AwareInShipwreckedRegion()
    return self:AwareInPrimaryRegion(RegionDefs.PRIMARY.shipwrecked)
end

function EntityScript:AwareInHamletRegion()
    return self:AwareInPrimaryRegion(RegionDefs.PRIMARY.hamlet)
end

function EntityScript:AwareInTropicalRegion()
    return self:AwareInShipwreckedRegion() or self:AwareInHamletRegion()
end

function EntityScript:AwareInDSTMainlandRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.dst_mainland)
end

function EntityScript:AwareInDSTMoonIslandRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.dst_moonisland)
end

function EntityScript:AwareInShipwreckedVanillaRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.sw_vanilla)
end

function EntityScript:AwareInShipwreckedVolcanoRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.sw_volcano)
end

function EntityScript:AwareInHamletCityRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.ham_city)
end

function EntityScript:AwareInHamletRainforestRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.ham_rainforest)
end

function EntityScript:AwareInHamletWildsRegion()
    return self:AwareInSubregion(RegionDefs.SUBREGION.ham_wilds)
end

-- Legacy aliases. New gameplay code should use the explicit region names.
EntityScript.IsInTropicalArea = EntityScript.IsInTropicalRegion
EntityScript.IsInShipwreckedArea = function(self)
    return self:IsInPrimaryRegion(RegionDefs.PRIMARY.shipwrecked)
end
EntityScript.IsInHamletArea = function(self)
    return self:IsInPrimaryRegion(RegionDefs.PRIMARY.hamlet)
end
EntityScript.IsInVolcanoArea = function(self)
    return self:IsInSubregion(RegionDefs.SUBREGION.sw_volcano)
end
EntityScript.AwareInCityArea = EntityScript.AwareInHamletCityRegion
EntityScript.AwareInCivilizedArea = EntityScript
.AwareInCityArea                                                 --function(self)  return self:AwareHasTopologyTag("civilized")  end
EntityScript.AwareInTropicalArea = EntityScript.AwareInTropicalRegion
EntityScript.AwareInShipwreckedArea = EntityScript.AwareInShipwreckedRegion
EntityScript.AwareInHamletArea = EntityScript.AwareInHamletRegion
EntityScript.AwareInVolcanoArea = EntityScript.AwareInShipwreckedVolcanoRegion

-----暂时用不到修改pushevent，而且这个函数用到的太多，
-- --推入事件
-- local _PushEvent = EntityScript.PushEvent
-- function EntityScript:PushEvent(event, data)
--     if not self.eventmuted or not self.eventmuted[event] then                    --没有静默
--         _PushEvent(self, event, data)
--         if self.eventlistening_shared and self.eventlistening_shared[event] then --是否分享
--             local parent = self.entity:GetParent()
--             if parent and parent:IsValid() then
--                 parent:PushEvent(event, data)
--             end
--         end
--     end
-- end

-- --事件监听静默
-- function EntityScript:SetEventMute(event, muted)
--     if self.eventmuted == nil then
--         self.eventmuted = {}
--     end
--     -- print(event)
--     self.eventmuted[event] = muted and true or nil
-- end

-- --事件监听共享--会同时分享给上一级
-- function EntityScript:SetEventShare(event, shared)
--     if self.eventlistening_shared == nil then
--         self.eventlistening_shared = {}
--     end
--     self.eventlistening_shared[event] = shared and true or nil
-- end

function EntityScript:StopWatchingOneOfWorldStates(var)
    if not self.worldstatewatching then return end
    if self.muted_worldstate == nil then self.muted_worldstate = {} end
    self.muted_worldstate[var] = self.worldstatewatching[var] or {}

    -- for i, fn in ipairs(self.worldstatewatching[var]) do
    --     fn(self, initval or false)
    -- end

    TheWorld.components.worldstate:RemoveWatcher(var, self)
    self.worldstatewatching[var] = nil
end

function EntityScript:ReWatchingOneOfWorldStates(var)
    if not self.muted_worldstate then return end
    if self.worldstatewatching == nil then
        self.worldstatewatching = {}
    end
    self.worldstatewatching[var] = self.muted_worldstate[var] or {}
    for i, fn in ipairs(self.worldstatewatching[var]) do
        TheWorld.components.worldstate:AddWatcher(var, self.inst, fn, self)
    end

    self.muted_worldstate[var] = nil
end

function EntityScript:GetEventCallbacks(event, source, source_file, test_fn)
    source = source or self

    if not self.event_listening[event] or not self.event_listening[event][source] then
        return
    end

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and (info.source == source_file) and (not test_fn or test_fn(fn)) then
                return fn
            end
        elseif (not test_fn or test_fn(fn)) then
            return fn
        end
    end
end

--------------------------------------------------------------------------------------------
----------------------------------[[ 相关物品hook ]]-----------------------------------------
--------------------------------------------------------------------------------------------
local old_CanEntitySeePoint = CanEntitySeePoint
CanEntitySeePoint = function(inst, ...)
    return old_CanEntitySeePoint(inst, ...) or inst:IsInHamRoom()
end

local old_CanEntitySeeInDark = CanEntitySeeInDark
CanEntitySeeInDark = function(inst)
    return old_CanEntitySeeInDark(inst) or inst:IsInHamRoom()
end



local _SetOceanBlendParams = AnimState.SetOceanBlendParams
function AnimState:SetOceanBlendParams(...)
    if TUNING.ocean_style == "tropical" or TUNING.ocean_style == "blue" then return end
    return _SetOceanBlendParams(self, ...)
end

local _SetLayer = AnimState.SetLayer
function AnimState:SetLayer(layer, ...)
    if TUNING.ocean_style == "tropical" and layer <= LAYER_BELOW_GROUND then
        layer = LAYER_GROUND -- TODO: if sorting issues occur use ground and increase the sort
        self:SetSortOrder(5)
    end
    return _SetLayer(self, layer, ...)
end

-- local creep_entity = {}
-- local _AddGroundCreepEntity = Entity.AddGroundCreepEntity
-- Entity.AddGroundCreepEntity = function(self, ...)
--     local creep = _AddGroundCreepEntity(self, ...)
--     creep_entity[creep] = self
-- end

local _OnCreep = GroundCreep.OnCreep
function GroundCreep:OnCreep(x, y, z, ...)
    return _OnCreep(self, x, y, z, ...) and not TheWorld.Map:IsOutsideWorldAtPoint(x, y, z)
end

-- local GroundCreepEntity = GroundCreepEntity
-- local _SetRadius = GroundCreepEntity.SetRadius
-- function GroundCreepEntity.SetRadius(self, rad)
--     local inst = GetEntityinst(self)
--     if inst and inst:IsOutsideWorld() then
--         return
--     end
--     _SetRadius(self, rad)
-- end
