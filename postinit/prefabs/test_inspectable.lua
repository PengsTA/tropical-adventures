AddPrefabPostInitAny(function(inst)
    if not TheWorld or not TheWorld.ismastersim then return end
    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
    end
end)
