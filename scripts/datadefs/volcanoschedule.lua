-- Shipwrecked dry-season volcano schedule. Delays are relative to the
-- preceding eruption so the same data also works after an altar offering.
local function Warnings(a, b, c)
    return {
        { segments = a, severity = "small" },
        { segments = b, severity = "medium" },
        { segments = c, severity = "large" },
    }
end

local function Eruption(delay, firerain, rate, ash, smoke, warnings)
    return {
        delay_segments = delay,
        firerain_delay_segments = 0,
        firerain_segments = firerain,
        firerain_per_sec = rate,
        ash_delay_segments = 1,
        ash_segments = ash,
        smoke_delay_segments = 1,
        smoke_segments = smoke,
        warnings = warnings,
    }
end

return {
    Eruption(51, 1, .5, 5, 4, Warnings(16, 8, 4)),
    Eruption(38, 1, .5, 5, 4, Warnings(16, 8, 4)),
    Eruption(26, 2, .5, 6, 5, Warnings(16, 8, 4)),
    Eruption(21, 2, .5, 7, 6, Warnings(16, 8, 4)),
    Eruption(24, 3, .5, 8, 7, Warnings(16, 8, 4)),
    Eruption(20, 3, .5, 8, 7, Warnings(16, 8, 4)),
    Eruption(24, 3, .5, 9, 8, Warnings(16, 8, 4)),
    Eruption(20, 3, .5, 9, 8, Warnings(12, 6, 2)),
    Eruption(18, 3, .5, 9, 8, Warnings(4, 2, 1)),
    Eruption(14, 3, .5, 9, 8, Warnings(4, 2, 1)),
    Eruption(11, 3, .5, 9, 8, Warnings(4, 2, 1)),
    Eruption(9, 3, .5, 9, 8, Warnings(4, 2, 1)),
    Eruption(8, 3, .5, 9, 8, Warnings(4, 2, 1)),
    Eruption(8, 3, .5, 9, 8, Warnings(4, 2, 1)),
    Eruption(8, 3, 1, 9, 8, Warnings(4, 2, 1)),
    Eruption(8, 3, 1, 9, 8, Warnings(4, 2, 1)),
    Eruption(8, 3, 1, 9, 8, Warnings(4, 2, 1)),
}
