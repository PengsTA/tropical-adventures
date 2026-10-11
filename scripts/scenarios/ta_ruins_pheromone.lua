local ChestFunctions = require("scenarios/chestfunctions")

local function OnCreate(inst)
    ChestFunctions.AddChestItems(inst, {
        { item = "pheromonestone", count = 1 },
        { item = "goldnugget", count = 3 },
        { item = "oinc", count = 5 },
    })
end

return { OnCreate = OnCreate }
