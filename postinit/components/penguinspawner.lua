AddComponentPostInit("penguinspawner", function(cmp)
    local TryToSpawnFlock
    for per, _ in pairs(cmp.inst.pendingtasks) do
        TryToSpawnFlock = Upvaluehelper.GetUpvalue(per.fn, "TryToSpawnFlock")
        if TryToSpawnFlock then
            break
        end
    end
    local TryToSpawnFlockForPlayer
    if TryToSpawnFlock then
        TryToSpawnFlockForPlayer = Upvaluehelper.GetUpvalue(TryToSpawnFlock, "TryToSpawnFlockForPlayer")
    end
    if not TryToSpawnFlockForPlayer then
        return print("Failed to edit penguinspawner", TryToSpawnFlock, TryToSpawnFlockForPlayer)
    else
        local newTryToSpawnFlockForPlayer = function(playerdata)
            if playerdata.player and playerdata.player:AwareInTropicalRegion() then
                return
            end
            TryToSpawnFlockForPlayer(playerdata)
        end
        Upvaluehelper.SetUpvalue(TryToSpawnFlock, newTryToSpawnFlockForPlayer, "TryToSpawnFlockForPlayer")
    end
end)
