local locale = LanguageTranslator.defaultlang

local function en_zh(en, zh)
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

local LEVELCATEGORY = LEVELCATEGORY
local customize_dat = require("datadefs/ta_customization")(modinfo.ta_world_options)
local worldgen_customization = customize_dat.worldgen_options
local climate_customization = customize_dat.climate_options

-- Adding customization items immediately rebuilds existing world menus.
if not rawget(_G, "WorldSim") and not TheNet:IsDedicated() then
    modimport "main/ta_config_frontend"
end

local ta_customize_table = {
    ta_worldgen = {
        order = 1.1,
        text = en_zh(" Tropical Adventures | Ship of Theseus", "热带冒险 | 忒修斯之船"),
        category = LEVELCATEGORY.WORLDGEN,
        items = worldgen_customization
    },

    ta_climate = {
        order = -1,
        text = en_zh(" Tropical Adventures climates", "热带冒险气候"),
        category = LEVELCATEGORY.SETTINGS,
        items = climate_customization,
    }

}



local function add_group_and_item(category, name, text, desc, atlas, order, items)
    if text then
        AddCustomizeGroup(category, name, text or "ooo", desc, atlas, order)
    end
    if items then
        for _, v in ipairs(items) do
            STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(v.name)] = v.label
            AddCustomizeItem(category, name, v.name, v)
        end
    end
end

for name, data in pairs(ta_customize_table) do
    add_group_and_item(data.category, name, data.text, data.desc, data.atlas, data.order, data.items)
end



------world setting overrides ----这个 东西是加载世界时执行的东西，对生成世界无效
-- local WSO = require("worldsettings_overrides")
-- WSO.Pre.coastline = function(difficulty)
--     TUNING.coastline = difficulty
--     print("set coastline11111111")
-- end
