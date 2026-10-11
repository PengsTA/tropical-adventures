local function AddSeaworthyCourt(task, layout)
    task.set_pieces = task.set_pieces or {}
    local present = false
    for _, piece in ipairs(task.set_pieces) do
        if piece.name == layout then present = true; break end
    end
    if not present then
        -- Detached regions may have no background nodes; use any valid task node.
        table.insert(task.set_pieces, { name = layout })
    end
    task.required_prefabs = task.required_prefabs or {}
    if not tableutil.has_component(task.required_prefabs, "seaworthy_broken") then
        table.insert(task.required_prefabs, "seaworthy_broken")
    end
end

for _, name in ipairs({ "Speak to the king", "Speak to the king classic" }) do
    AddTaskPreInit(name, function(task) AddSeaworthyCourt(task, "PigKingSeaworthy") end)
end
AddTaskPreInit("BoreKing", function(task) AddSeaworthyCourt(task, "WildboreKingSeaworthy") end)

AddTaskPreInit("GreenForest", function(task)
    task.keys_given = { KEYS.CAVE, KEYS.TIER3, KEYS.GREEN, KEYS.ENTRANCE_INNER, KEYS.HAM_CAVE }
end)

AddTaskPreInit("RedForest", function(task)
    task.keys_given = { KEYS.CAVE, KEYS.TIER3, KEYS.RED, KEYS.ENTRANCE_INNER, KEYS.VOLCANO_ENTRANCE }
end)


AddTaskPreInit("CaveExitTask5", function(task)
    task.locks = { LOCKS.ENTRANCE_INNER }
end)

AddTaskPreInit("CaveExitTask6", function(task)
    task.locks = { LOCKS.ENTRANCE_INNER }
end)

AddTaskPreInit("CaveExitTask7", function(task)
    task.locks = { LOCKS.ENTRANCE_INNER }
end)

AddTaskPreInit("CaveExitTask8", function(task)
    task.locks = { LOCKS.ENTRANCE_INNER }
end)

AddTaskPreInit("CaveExitTask9", function(task)
    task.locks = { LOCKS.ENTRANCE_INNER }
end)

AddTaskPreInit("CaveExitTask10", function(task)
    task.locks = { LOCKS.ENTRANCE_INNER }
end)
