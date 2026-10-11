local InteriorDefs = require "datadefs/interior"

local PROFILE_IDS = {
    player_house = 1,
    player_house_hall = 1,
    player_house_extension = 1,
    palace_main = 2,
    palace_gallery = 2,
    palace_upper = 2,
    roc_cave = 4,
    vampirebat_cave = 4,
}
local PROFILE_NAMES = { "player_house", "palace", "shop", "cave" }

local function GetProfileId(kind)
    return PROFILE_IDS[kind] or (string.sub(kind or "", 1, 5) == "shop_" and 3 or 0)
end

local function GetRoomKind(room)
    return room.room_template or room.kind or room.camera_profile_kind or "default"
end

local function CreateProfiles(defaults)
    local profiles = {}
    for kind in pairs(InteriorDefs.sizes) do
        local source = defaults[kind] or defaults[PROFILE_NAMES[GetProfileId(kind)]] or defaults.default
        local profile = {}
        for key, value in pairs(source) do
            profile[key] = value
        end
        profiles[kind] = profile
    end
    for kind, profile in pairs(defaults) do
        if profiles[kind] == nil then
            profiles[kind] = profile
        end
    end
    return profiles
end

return {
    GetProfileId = GetProfileId,
    GetRoomKind = GetRoomKind,
    CreateProfiles = CreateProfiles,
    ProfileNames = PROFILE_NAMES,
}
