GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })


local require = require
local modimport = modimport


require "tools/tableutil"               ----一些表相关的工具函数，都在表tableutil里
require "tools/tileutil"                ----一些关于tile的工具函数
require "tools/spawnutil"               ----地形生成相关工具

modimport "scripts/tools/modutil"       ----api修改及新的mod工具
modimport "scripts/tools/upvaluehelper" ----用来hook的一些函数 来自冰冰羊
modimport "main/tuning"                 -- tuning + constants
modimport "main/ta_customize"           ----世界设置项
modimport "main/ta_config"              ----mod 设置相关内容
modimport "main/tiledefs"               ----缺少行走的声音



----生成世界需要用到的内容
if rawget(_G, "WorldSim") then
    ----------新内容
    modimport "scripts/map/tro_lockandkey"      ----地形锁钥
    modimport "scripts/map/init_static_layouts" --新的 static layouts
    modimport "scripts/map/city_layouts"        --新的城镇 layouts
    modimport "scripts/map/ruin_maze_layouts"   --新的地下遗迹layouts
    modimport "scripts/map/rooms/ham"
    modimport "scripts/map/rooms/sw"
    modimport "scripts/map/rooms/ocean"
    modimport "scripts/map/tasks/ham"
    modimport "scripts/map/tasks/sw"
    modimport "scripts/map/newstartlocation"

    -------------修改之前内容
    modimport "postinit/map/rooms"
    modimport "postinit/map/tasks"
    modimport "postinit/map/levels" -----------[[几乎所有地形修改都在这里]]
    modimport "postinit/map/graph"
    modimport "postinit/map/storygen"
    modimport "postinit/map/forest_map_new" -----在这里添加哈姆雷特城镇
    modimport "postinit/map/ocean_gen_new"  ----防止新的水面地皮被覆盖 ---但是暴力覆盖似乎太严重
    modimport "postinit/map/node"           ------------防止清空水上内容
end
