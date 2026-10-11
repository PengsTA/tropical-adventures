local function RecoverPlayerFixture(inst)
    inst:DoTaskInTime(0, function()
        local manager = TheWorld.components.interior_manager
        local x, _, z = inst.Transform:GetWorldPosition()
        local room = manager ~= nil and manager:GetRoomAtPoint(x, z) or nil
        if room ~= nil and string.sub(room.kind or "", 1, 12) == "player_house"
            and inst.EnableInteriorDemolition ~= nil then
            inst:AddTag("playercrafted")
            inst:EnableInteriorDemolition()
        end
    end)
end

return { RecoverPlayerFixture = RecoverPlayerFixture }
