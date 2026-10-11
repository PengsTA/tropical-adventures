local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:DoTaskInTime(0, function(marker)
        local manager = TheWorld.components.tigersharker
        if manager:GetBoss() == nil then
            manager.home = { x = marker:GetPosition().x, z = marker:GetPosition().z }
            if manager.respawn_time == nil then
                manager:ScheduleRespawn(30 * (TUNING.TOTAL_DAY_TIME or 480))
            end
        end
        marker:Remove()
    end)
    return inst
end

return Prefab("tigershark_spawner", fn, nil, { "tigershark" })
