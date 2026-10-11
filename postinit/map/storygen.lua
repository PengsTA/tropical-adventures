local MapTags = { "frost", "tropical", "hamlet", "shipwrecked", "volcano", "underwater", "deeprainforest", "ta_ruins_maze" }
local GlobalMapTags = { "City1", "City2", "City_Foundation", "Suburb", "Cultivated" }

AddGlobalClassPostConstruct("map/storygen", "Story", function(self)
    for k, v in pairs(MapTags) do
        self.map_tags.Tag[v] = function(tagdata) return "TAG", v end
    end

    for k, v in pairs(GlobalMapTags) do
        self.map_tags.Tag[v] = function(tagdata) return "GLOBALTAG", v end
    end
end)

require("map/storygen")



GLOBAL.setfenv(1, GLOBAL) ----为什么要这么声明变量，不是很理解
TOPOLOGY_SAVE = nil
STORYGEN = nil

local old_buildstory = BuildStory
BuildStory = function(tasks, story_gen_params, level)
    TOPOLOGY_SAVE, STORYGEN = old_buildstory(tasks, story_gen_params, level)
    -- print("BuildStory data has been saved!")
    return TOPOLOGY_SAVE, STORYGEN
end





local troadv = TA_CONFIG.WORLDGEN
-------------以下代码可以直接改变主大陆但是 background room都不会生成
if (troadv.together_not_mainland) and (not troadv.testmap) then
    local land = troadv.multiplayerportal

    function Story:AddRegionsToMainland(on_region_added_fn)
        -- print("!!!!!!!!!!!!!")
        -- print(self.id)
        -- print(self.level.location)

        land = (self.level.location == "forest") and land or "mainland"
        for region_id, region_taskset in pairs(self.region_tasksets) do
            if region_id ~= land then
                local c1, c2 = self:FindMainlandNodesForNewRegion()
                local new_region = self:GenerateNodesForRegion(region_taskset, "RestrictNodesByKey")

                local new_task_nodes = {}
                for k, v in pairs(region_taskset) do
                    new_task_nodes[k] = self.TERRAIN[k]
                end
                self:AddCoveNodes(new_task_nodes)
                self:InsertAdditionalSetPieces(new_task_nodes)

                self:LinkRegions(c1, new_region.entranceNode)
                self:LinkRegions(c2, new_region.finalNode)

                if on_region_added_fn ~= nil then
                    on_region_added_fn()
                end
            end
        end
    end

    function Story:GenerateNodesFromTasks()
        land = (self.level.location == "forest") and land or "mainland"
        local g = self:GenerateNodesForRegion(self.region_tasksets[land], self.gen_params.layout_mode)
        self.startNode = self:_AddPlayerStartNode(g) -- Adds where the player portal will be spawned and used in placement.lua to force the starting point to be at the center of the map
    end
end
