local RegionDefs = require("tools/regiondefs")

local REGION_REFRESH_COOLDOWN = 10
local POSITION_CHECK_FRAME_INTERVAL = 3
local REGION_CHECK_DISTANCE = 8
local REGION_CHECK_DISTANCE_SQ = REGION_CHECK_DISTANCE * REGION_CHECK_DISTANCE
local LARGE_POSITION_CHANGE_DISTANCE = 50
local LARGE_POSITION_CHANGE_DISTANCE_SQ = LARGE_POSITION_CHANGE_DISTANCE * LARGE_POSITION_CHANGE_DISTANCE

local LEGACY_PRIMARY_TAGS = {
    [RegionDefs.PRIMARY.dst] = "region_forest",
    [RegionDefs.PRIMARY.shipwrecked] = "region_shipwrecked",
    [RegionDefs.PRIMARY.hamlet] = "region_hamlet",
}

local function GetTaggedPrimaryId(inst)
    return RegionDefs.GetPrimaryIdFromTags(function(tag)
        return inst:HasTag(tag)
    end)
end

local function GetTaggedSubregionId(inst)
    return RegionDefs.GetSubregionIdFromTags(function(tag)
        return inst:HasTag(tag)
    end)
end

local function UpdateTag(inst, prefix, old_id, new_id, get_name)
    if old_id ~= nil then
        inst:RemoveTag(prefix .. get_name(old_id))
    end
    if new_id ~= nil then
        inst:AddTag(prefix .. get_name(new_id))
    end
end

local function UpdateLegacyPrimaryTag(inst, old_primary, new_primary)
    if old_primary ~= nil then
        inst:RemoveTag(LEGACY_PRIMARY_TAGS[old_primary])
    end
    if new_primary ~= nil then
        inst:AddTag(LEGACY_PRIMARY_TAGS[new_primary])
    end
end

local RegionAware = Class(function(self, inst)
    self.inst = inst
    self._regionpos = nil
    self._nextregionrefresh = nil
    self._queuedrefreshtask = nil
    self._positioncheckframes = 0

    inst:StartUpdatingComponent(self)
    inst:DoTaskInTime(0, function()
        self:RefreshRegion(true)
    end)
end)

function RegionAware:OnRemoveFromEntity()
    self.inst:StopUpdatingComponent(self)
    if self._queuedrefreshtask ~= nil then
        self._queuedrefreshtask:Cancel()
        self._queuedrefreshtask = nil
    end
end

function RegionAware:HasTopologyTag(tag)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    return TheWorld.Map:HasTopologyTagAtPoint(x, y, z, tag)
end

function RegionAware:CanRefreshRegion(force)
    if force or self._regionpos == nil or self._nextregionrefresh == nil
        or GetTime() >= self._nextregionrefresh then
        return true
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local dx = x - self._regionpos.x
    local dy = y - self._regionpos.y
    local dz = z - self._regionpos.z
    return dx * dx + dy * dy + dz * dz > LARGE_POSITION_CHANGE_DISTANCE_SQ
end

function RegionAware:HasMovedForRegionCheck()
    if self._regionpos == nil then
        return true
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local dx = x - self._regionpos.x
    local dy = y - self._regionpos.y
    local dz = z - self._regionpos.z
    return dx * dx + dy * dy + dz * dz > REGION_CHECK_DISTANCE_SQ
end

function RegionAware:RecordRegionRefreshPosition()
    if self._queuedrefreshtask ~= nil then
        self._queuedrefreshtask:Cancel()
        self._queuedrefreshtask = nil
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    self._regionpos = { x = x, y = y, z = z }
    self._nextregionrefresh = GetTime() + REGION_REFRESH_COOLDOWN
end

function RegionAware:RequestRegionRefresh()
    if self:CanRefreshRegion() then
        return self:RefreshRegion()
    end

    if self._queuedrefreshtask == nil then
        local delay = math.max(0, self._nextregionrefresh - GetTime())
        self._queuedrefreshtask = self.inst:DoTaskInTime(delay, function()
            self._queuedrefreshtask = nil
            self:RefreshRegion()
        end)
    end
    return false
end

function RegionAware:OnUpdate()
    self._positioncheckframes = self._positioncheckframes - 1
    if self._positioncheckframes > 0 then
        return
    end
    self._positioncheckframes = POSITION_CHECK_FRAME_INTERVAL

    if self:HasMovedForRegionCheck() then
        self:RequestRegionRefresh()
    end
end

function RegionAware:NotifyClient()
    local classified = self.inst.player_classified
    if classified ~= nil and classified._regionaware_revision ~= nil then
        classified._regionaware_revision:set((classified._regionaware_revision:value() + 1) % 256)
    end
end

function RegionAware:ApplyRegionState(primary, subregion, isinterior, isshop, isdeep)
    isdeep = isdeep == true
    local old_primary = GetTaggedPrimaryId(self.inst)
    local old_subregion = GetTaggedSubregionId(self.inst)
    local old_isinterior = self.inst:HasTag(RegionDefs.INTERIOR_TAG)
    local old_isshop = self.inst:HasTag(RegionDefs.INTERIOR_SHOP_TAG)
    local primary_changed = primary ~= old_primary
    local subregion_changed = subregion ~= old_subregion
    local interior_changed = isinterior ~= old_isinterior
    local shop_changed = isshop ~= old_isshop
    local deep_changed = isdeep ~= self.inst:HasTag(RegionDefs.DEEP_RAINFOREST_TAG)

    if not (primary_changed or subregion_changed or interior_changed or shop_changed or deep_changed) then
        return false
    end

    if primary_changed then
        UpdateTag(self.inst, "region_primary_", old_primary, primary, RegionDefs.GetPrimaryName)
        UpdateLegacyPrimaryTag(self.inst, old_primary, primary)
    end
    if subregion_changed then
        UpdateTag(self.inst, "region_sub_", old_subregion, subregion, RegionDefs.GetSubregionName)
        if old_subregion == RegionDefs.SUBREGION.sw_volcano then
            self.inst:RemoveTag("region_volcano")
        end
        if subregion == RegionDefs.SUBREGION.sw_volcano then
            self.inst:AddTag("region_volcano")
        end
    end
    if interior_changed then
        self.inst:AddOrRemoveTag(RegionDefs.INTERIOR_TAG, isinterior)
    end
    if shop_changed then
        self.inst:AddOrRemoveTag(RegionDefs.INTERIOR_SHOP_TAG, isshop)
    end
    if deep_changed then
        self.inst:AddOrRemoveTag(RegionDefs.DEEP_RAINFOREST_TAG, isdeep)
    end

    self:NotifyClient()

    local current = self:GetRegionProfile()
    if primary_changed then
        self.inst:PushEvent("primaryregionchange", {
            primary = RegionDefs.GetPrimaryName(primary),
            primary_id = primary,
            old_primary = old_primary ~= nil and RegionDefs.GetPrimaryName(old_primary) or nil,
            old_primary_id = old_primary,
        })
    end
    if subregion_changed then
        self.inst:PushEvent("subregionchange", {
            subregion = RegionDefs.GetSubregionName(subregion),
            subregion_id = subregion,
            old_subregion = old_subregion ~= nil and RegionDefs.GetSubregionName(old_subregion) or nil,
            old_subregion_id = old_subregion,
        })
    end
    if interior_changed or shop_changed or deep_changed then
        self.inst:PushEvent("regioncontextchange", current)
    end

    self.inst:PushEvent("regionchange", current)
    return true
end

function RegionAware:ResolveRegion()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local map_profile = TheWorld.Map:GetRegionProfileAtPoint(x, y, z)
    local isinterior = map_profile.isinterior
    local isshop = (isinterior
        and TheWorld.components.interior_manager ~= nil
        and TheWorld.components.interior_manager:IsShopAtPoint(x, z))
        or false
    local current_primary = GetTaggedPrimaryId(self.inst)
    if isinterior and current_primary ~= nil then
        return current_primary, self:GetSubregionId(), true, isshop, false
    end

    local primary = RegionDefs.GetPrimaryId(map_profile.primary)
    local subregion = RegionDefs.GetSubregionId(map_profile.subregion)
    if isinterior and primary == RegionDefs.PRIMARY.dst then
        return RegionDefs.PRIMARY.hamlet, RegionDefs.SUBREGION.ham_wilds, true, isshop, false
    end
    return primary, subregion, isinterior, isshop, not isinterior and map_profile.isdeeprainforest or false
end

function RegionAware:RefreshRegion(force)
    if not self:CanRefreshRegion(force) then
        return false
    end

    local primary, subregion, isinterior, isshop, isdeep = self:ResolveRegion()
    self:RecordRegionRefreshPosition()
    return self:ApplyRegionState(primary, subregion, isinterior, isshop, isdeep)
end

function RegionAware:GetPrimaryRegion()
    return RegionDefs.GetPrimaryName(self:GetPrimaryRegionId())
end

function RegionAware:GetPrimaryRegionId()
    return GetTaggedPrimaryId(self.inst) or RegionDefs.PRIMARY.dst
end

function RegionAware:GetSubregion()
    return RegionDefs.GetSubregionName(self:GetSubregionId())
end

function RegionAware:GetSubregionId()
    return GetTaggedSubregionId(self.inst) or RegionDefs.SUBREGION.dst_mainland
end

function RegionAware:GetRegionProfile()
    return RegionDefs.GetRegionProfileFromTags(function(tag)
        return self.inst:HasTag(tag)
    end)
end

function RegionAware:IsInPrimaryRegion(region)
    return RegionDefs.HasPrimaryRegion(self.inst, region)
end

function RegionAware:IsInSubregion(subregion)
    return RegionDefs.HasSubregion(self.inst, subregion)
end

function RegionAware:IsInInterior()
    return self.inst:HasTag(RegionDefs.INTERIOR_TAG)
end

function RegionAware:IsInShop()
    return self.inst:HasTag(RegionDefs.INTERIOR_SHOP_TAG)
end

-- Legacy aliases. New code should use the explicit primary/subregion methods.
function RegionAware:GetRegion(force)
    if force then
        self:RefreshRegion(true)
    end
    return self:GetPrimaryRegionId()
end

function RegionAware:IsInRegion(region)
    return self:IsInPrimaryRegion(region)
end

function RegionAware:IsInTag(tag)
    return self:IsInPrimaryRegion(tag) or self:IsInSubregion(tag) or self:HasTopologyTag(tag)
end

function RegionAware:GetDebugString()
    local profile = self:GetRegionProfile()
    return string.format("primary:%s, subregion:%s, interior:%s",
        profile.primary,
        profile.subregion,
        tostring(profile.isinterior))
end

return RegionAware
