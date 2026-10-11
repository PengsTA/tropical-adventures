local AddModRPCHandler = AddModRPCHandler
local AddShardModRPCHandler = AddShardModRPCHandler
local AddClientModRPCHandler = AddClientModRPCHandler

AddClientModRPCHandler("Tropical adventures", "tile_changed", function(data)
    local tilechangewatcher = ThePlayer and ThePlayer.components.tilechangewatcher
    if tilechangewatcher then
        if TheWorld.ismastersim then
            -- TODO: Use the data if we have more granular updates in the future
            tilechangewatcher:NotifyUpdate()
        else
            -- Delay this for a frame on client to wait for the tile to update
            ThePlayer:DoStaticTaskInTime(0, function()
                -- TODO: Use the data if we have more granular updates in the future
                tilechangewatcher:NotifyUpdate()
            end)
        end
    end
end)

AddShardModRPCHandler("TropicalAdventures", "SyncAporkalypseBeginDate", function(shardid, date)
    local aporkalypse = TheWorld.components.aporkalypse
    if aporkalypse ~= nil then
        aporkalypse.begin_date = date
    end
end)
