GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

GLOBAL.BOATEQUIPSLOTS = GLOBAL.BOATEQUIPSLOTS or {
    BOAT_SAIL = "sail",
    BOAT_LAMP = "lamp",
}

local require = require
local modimport = modimport

modimport "main/ta_config"

modimport "main/strings"

-- 工具函数，全部在GLOBAL里
require "tools/simutil"
require "tools/standardcomponents"

modimport "main/prefabfiles"
modimport "main/assets"
modimport "main/actions"
modimport "main/componentactions"
modimport "main/postinit" -- postinit相关全都在这里

-- recipes, cooking recipes and other important modules
modimport "main/recipe_tabs"
modimport "main/recipes"
modimport "main/cooking_recipes"
modimport "main/smelting_recipes"
modimport "scripts/tools/skinsapi"
modimport "main/characters"
modimport "main/tropical_fx"
modimport "main/rpc"
modimport "main/ta_seaworthy_setup"
modimport "main/usercommands"

modimport "main/AddIronLordHandlers" -- 活性机甲处理
modimport "main/AddIronLordPostinit" -- 活性机甲构造
modimport "scripts/ArtifactControls" -- 活性机甲控制

modimport "main/event_timer_compat" -- 兼容全局事件计时器模组
