local RegionDefs = require("tools/regiondefs")

-- DST still owns the calendar. This module is the only place where that
-- calendar is translated into a regional climate season.
local ClimateProfiles = {}

ClimateProfiles.SHIPWRECKED = {
    autumn = "mild",
    winter = "hurricane",
    spring = "monsoon",
    summer = "dry",
}

ClimateProfiles.HAMLET = {
    autumn = "temperate",
    winter = "humid",
    spring = "rainy",
    summer = "lush",
}

ClimateProfiles.PROFILE_NAMES = {
    "dst",
    "mild",
    "hurricane",
    "monsoon",
    "dry",
    "temperate",
    "humid",
    "rainy",
    "lush",
}

ClimateProfiles.PROFILE_IDS = {}
for id, name in ipairs(ClimateProfiles.PROFILE_NAMES) do
    ClimateProfiles.PROFILE_IDS[name] = id
end

ClimateProfiles.PHASE_NAMES = { "early", "middle", "late" }
ClimateProfiles.PHASE_IDS = {}
for id, name in ipairs(ClimateProfiles.PHASE_NAMES) do
    ClimateProfiles.PHASE_IDS[name] = id
end

function ClimateProfiles.GetProgress(state)
    state = state or (TheWorld ~= nil and TheWorld.state) or {}
    local season = state.season
    local length = season ~= nil and state[season .. "length"] or nil
    local elapsed = state.elapseddaysinseason
    local remaining = state.remainingdaysinseason
    -- DST starts friendly seasons halfway through its weather curve. Use
    -- the actual calendar span for tropical schedules, preserving endless mode.
    if length ~= nil and length > 0 and elapsed ~= nil and remaining ~= nil
        and remaining <= length and elapsed + remaining > 0 then
        return math.max(0, math.min(1, elapsed / (elapsed + remaining)))
    end

    local progress = state.seasonprogress
    if progress ~= nil then
        return math.max(0, math.min(1, progress))
    end

    if length ~= nil and length > 0 and remaining ~= nil then
        return math.max(0, math.min(1, 1 - remaining / length))
    end
    return 0
end

function ClimateProfiles.GetPhase(progress)
    progress = progress == nil and ClimateProfiles.GetProgress() or progress
    return progress < 1 / 3 and "early"
        or progress > 2 / 3 and "late"
        or "middle"
end

function ClimateProfiles.GetShipwreckedProfile(state)
    state = state or (TheWorld ~= nil and TheWorld.state) or {}
    return ClimateProfiles.SHIPWRECKED[state.season] or "mild"
end

function ClimateProfiles.GetHamletProfile(state)
    state = state or (TheWorld ~= nil and TheWorld.state) or {}
    return ClimateProfiles.HAMLET[state.season] or "temperate"
end

function ClimateProfiles.GetProfile(primary, state)
    primary = RegionDefs.GetPrimaryName(primary)
    if primary == "shipwrecked" then
        return ClimateProfiles.GetShipwreckedProfile(state)
    elseif primary == "hamlet" then
        return ClimateProfiles.GetHamletProfile(state)
    end
    return "dst"
end

function ClimateProfiles.GetProfileName(id)
    -- Shipwrecked's original enum names are wet/green, but the game's
    -- player-facing seasons are Hurricane/Monsoon. Accept the old ids only
    -- as a migration convenience; never expose them as canonical profiles.
    if id == "wet" then
        id = "hurricane"
    elseif id == "green" then
        id = "monsoon"
    end
    return type(id) == "string" and ClimateProfiles.PROFILE_IDS[id] ~= nil and id
        or type(id) == "number" and ClimateProfiles.PROFILE_NAMES[id]
        or "dst"
end

function ClimateProfiles.GetPhaseName(id)
    return type(id) == "string" and ClimateProfiles.PHASE_IDS[id] ~= nil and id
        or type(id) == "number" and ClimateProfiles.PHASE_NAMES[id]
        or "early"
end

function ClimateProfiles.IsShipwreckedMild(state)
    return ClimateProfiles.GetShipwreckedProfile(state) == "mild"
end

function ClimateProfiles.IsShipwreckedHurricane(state)
    return ClimateProfiles.GetShipwreckedProfile(state) == "hurricane"
end

function ClimateProfiles.IsShipwreckedMonsoon(state)
    return ClimateProfiles.GetShipwreckedProfile(state) == "monsoon"
end

function ClimateProfiles.IsShipwreckedDry(state)
    return ClimateProfiles.GetShipwreckedProfile(state) == "dry"
end

-- Kept for existing saved-mod integrations. New code must use the named
-- Hurricane and Monsoon helpers above.
ClimateProfiles.IsShipwreckedWet = ClimateProfiles.IsShipwreckedHurricane
ClimateProfiles.IsShipwreckedGreen = ClimateProfiles.IsShipwreckedMonsoon

function ClimateProfiles.IsHamletTemperate(state)
    return ClimateProfiles.GetHamletProfile(state) == "temperate"
end

function ClimateProfiles.IsHamletHumid(state)
    return ClimateProfiles.GetHamletProfile(state) == "humid"
end

function ClimateProfiles.IsHamletRainy(state)
    -- Hamlet keeps its own player-facing season label, but its rainy-season
    -- mechanics are intentionally driven by Shipwrecked's one global monsoon
    -- timeline. Do not create a second spring/rain clock here.
    return ClimateProfiles.IsShipwreckedMonsoon(state)
end

function ClimateProfiles.IsHamletLush(state)
    return ClimateProfiles.GetHamletProfile(state) == "lush"
end

return ClimateProfiles
