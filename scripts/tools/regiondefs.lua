local RegionDefs = {}

RegionDefs.PRIMARY_NAMES = {
    "dst",
    "shipwrecked",
    "hamlet",
}

RegionDefs.PRIMARY = {}
for id, name in ipairs(RegionDefs.PRIMARY_NAMES) do
    RegionDefs.PRIMARY[name] = id
end

RegionDefs.SUBREGION_NAMES = {
    "dst_mainland",
    "dst_moonisland",
    "sw_vanilla",
    "sw_volcano",
    "ham_city",
    "ham_rainforest",
    "ham_wilds",
}

RegionDefs.SUBREGION = {}
for id, name in ipairs(RegionDefs.SUBREGION_NAMES) do
    RegionDefs.SUBREGION[name] = id
end

RegionDefs.SUBREGION_PRIMARY = {
    [RegionDefs.SUBREGION.dst_mainland] = RegionDefs.PRIMARY.dst,
    [RegionDefs.SUBREGION.dst_moonisland] = RegionDefs.PRIMARY.dst,
    [RegionDefs.SUBREGION.sw_vanilla] = RegionDefs.PRIMARY.shipwrecked,
    [RegionDefs.SUBREGION.sw_volcano] = RegionDefs.PRIMARY.shipwrecked,
    [RegionDefs.SUBREGION.ham_city] = RegionDefs.PRIMARY.hamlet,
    [RegionDefs.SUBREGION.ham_rainforest] = RegionDefs.PRIMARY.hamlet,
    [RegionDefs.SUBREGION.ham_wilds] = RegionDefs.PRIMARY.hamlet,
}

RegionDefs.INTERIOR_TAG = "region_interior"
RegionDefs.INTERIOR_SHOP_TAG = "region_interior_shop"
RegionDefs.DEEP_RAINFOREST_TAG = "region_deeprainforest"

function RegionDefs.GetPrimaryTag(region)
    local id = RegionDefs.GetPrimaryId(region)
    return id ~= nil and "region_primary_" .. RegionDefs.GetPrimaryName(id) or nil
end

function RegionDefs.GetSubregionTag(subregion)
    local id = RegionDefs.GetSubregionId(subregion)
    return id ~= nil and "region_sub_" .. RegionDefs.GetSubregionName(id) or nil
end

function RegionDefs.GetPrimaryIdFromTags(has_tag)
    for id, name in ipairs(RegionDefs.PRIMARY_NAMES) do
        if has_tag("region_primary_" .. name) then
            return id
        end
    end
    return nil
end

function RegionDefs.GetSubregionIdFromTags(has_tag)
    for id, name in ipairs(RegionDefs.SUBREGION_NAMES) do
        if has_tag("region_sub_" .. name) then
            return id
        end
    end
    return nil
end

function RegionDefs.GetRegionProfileFromTags(has_tag)
    local primary = RegionDefs.GetPrimaryIdFromTags(has_tag) or RegionDefs.PRIMARY.dst
    local subregion = RegionDefs.GetSubregionIdFromTags(has_tag) or RegionDefs.SUBREGION.dst_mainland
    return {
        primary = RegionDefs.GetPrimaryName(primary),
        primary_id = primary,
        subregion = RegionDefs.GetSubregionName(subregion),
        subregion_id = subregion,
        isinterior = has_tag(RegionDefs.INTERIOR_TAG),
        isshop = has_tag(RegionDefs.INTERIOR_SHOP_TAG),
        isdeeprainforest = has_tag(RegionDefs.DEEP_RAINFOREST_TAG),
    }
end

function RegionDefs.HasPrimaryRegion(inst, region)
    local tag = RegionDefs.GetPrimaryTag(region)
    return tag ~= nil and inst:HasTag(tag) or false
end

function RegionDefs.HasSubregion(inst, subregion)
    local tag = RegionDefs.GetSubregionTag(subregion)
    return tag ~= nil and inst:HasTag(tag) or false
end

RegionDefs.HAMLET_CITY_TAGS = {
    "City_Foundation",
    "City1",
    "City2",
    "Suburb",
    "Cultivated",
}

function RegionDefs.HasHamletCityTag(has_tag)
    for _, tag in ipairs(RegionDefs.HAMLET_CITY_TAGS) do
        if has_tag(tag) then
            return true
        end
    end
    return false
end

function RegionDefs.GetPrimaryName(id)
    if type(id) == "string" and RegionDefs.PRIMARY[id] ~= nil then
        return id
    end
    return type(id) == "number" and RegionDefs.PRIMARY_NAMES[id] or "dst"
end

function RegionDefs.GetSubregionName(id)
    if type(id) == "string" and RegionDefs.SUBREGION[id] ~= nil then
        return id
    end
    return type(id) == "number" and RegionDefs.SUBREGION_NAMES[id] or "dst_mainland"
end

function RegionDefs.GetPrimaryId(region)
    return type(region) == "string" and RegionDefs.PRIMARY[region] or region
end

function RegionDefs.GetSubregionId(subregion)
    return type(subregion) == "string" and RegionDefs.SUBREGION[subregion] or subregion
end

function RegionDefs.IsTropicalPrimary(primary)
    primary = RegionDefs.GetPrimaryId(primary)
    return primary == RegionDefs.PRIMARY.shipwrecked or primary == RegionDefs.PRIMARY.hamlet
end

function RegionDefs.ResolvePrimaryRegion(has_tag)
    if has_tag("volcano") or has_tag("shipwrecked") then
        return RegionDefs.PRIMARY.shipwrecked
    elseif has_tag("hamlet") or has_tag("rainforest") or RegionDefs.HasHamletCityTag(has_tag) then
        return RegionDefs.PRIMARY.hamlet
    end
    return RegionDefs.PRIMARY.dst
end

function RegionDefs.ResolveSubregion(primary, has_tag)
    primary = RegionDefs.GetPrimaryId(primary)

    if primary == RegionDefs.PRIMARY.shipwrecked then
        return has_tag("volcano") and RegionDefs.SUBREGION.sw_volcano
            or RegionDefs.SUBREGION.sw_vanilla
    elseif primary == RegionDefs.PRIMARY.hamlet then
        if RegionDefs.HasHamletCityTag(has_tag) then
            return RegionDefs.SUBREGION.ham_city
        elseif has_tag("rainforest") then
            return RegionDefs.SUBREGION.ham_rainforest
        end
        return RegionDefs.SUBREGION.ham_wilds
    end

    return (has_tag("lunacyarea") or has_tag("moonhunt")) and RegionDefs.SUBREGION.dst_moonisland
        or RegionDefs.SUBREGION.dst_mainland
end

return RegionDefs
