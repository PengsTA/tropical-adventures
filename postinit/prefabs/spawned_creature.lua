local creatures = require("datadefs/creature_spawn_defs").creatures
for _, v in pairs(creatures) do
    local prefabname = v.checkname or v.prefab
    local function AddPopulationTag(inst)
        inst:AddTag("spawned_" .. prefabname)
    end
    AddPrefabPostInit(v.prefab, AddPopulationTag)
    if v.checkname ~= nil and v.checkname ~= v.prefab then
        AddPrefabPostInit(v.checkname, AddPopulationTag)
    end
end
