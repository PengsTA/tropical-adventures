local function fn()
    local inst = Prefabs.treasurechest.fn()
    inst:SetPrefabNameOverride("treasurechest")
    return inst
end

return Prefab("ta_ruins_pheromone_chest", fn, nil,
    { "treasurechest", "pheromonestone", "goldnugget", "oinc" })
