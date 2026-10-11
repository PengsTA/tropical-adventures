GLOBAL.setfenv(1, GLOBAL)

require("map/network")
local BermudaWorldgen = require("tools/bermuda_worldgen")

TUNING.MAPWRAPPER_WARN_RANGE = TUNING.MAPWRAPPER_WARN_RANGE or 14
TUNING.MAPEDGE_PADDING = TUNING.MAPEDGE_PADDING or (TUNING.MAPWRAPPER_WARN_RANGE + 10)
TUNING.BERMUDA_AMOUNT = TUNING.BERMUDA_AMOUNT or BermudaWorldgen.DEFAULT_COUNT

local OriginalPostPopulate = Graph.GlobalPostPopulate
Graph.GlobalPostPopulate = function(self, entities, width, height, ...)
    local result = OriginalPostPopulate(self, entities, width, height, ...)
    if not TUNING.test_map then
        local pairs = BermudaWorldgen.Generate(WorldSim, self, entities, width, height, {
            count = TUNING.BERMUDA_AMOUNT,
            padding = TUNING.MAPEDGE_PADDING,
        })
        print(string.format("[Tropical Adventures] Bermuda Triangle pairs placed: %d", pairs))
    end
    return result
end
