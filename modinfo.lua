---@diagnostic disable: lowercase-global

-----世界设置里的值不能是false,否则会用默认设置，所以modinfo最好保持同步
---全局的locale只在modinfo中存在，在servercreationmain中需要用translator
local locale = locale or LanguageTranslator.defaultlang

-- local function en_zh(en, zh)
--     return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
-- end

local lang = "en"
local function en_zh(en, zh) -- Other languages don't work
    local chinese_languages =
    {
        zh = "zh",      -- Chinese for Steam
        zhr = "zh",     -- Chinese for WeGame
        ch = "zh",      -- Chinese mod
        chs = "zh",     -- Chinese mod
        chinese = "zh", -- Chinese mod
        sc = "zh",      -- simple Chinese
        zht = "zh",     -- traditional Chinese for Steam
        tc = "zh",      -- traditional Chinese
        cht = "zh",     -- Chinese mod
    }

    if chinese_languages[locale] ~= nil then
        lang = chinese_languages[locale]
    end

    return lang == "zh" and zh or en
end

local function table_insert(t, value, pos)
    if pos == nil then
        pos = #t + 1
    end

    for i = #t, pos, -1 do
        t[i + 1] = t[i]
    end

    t[pos] = value
end

local function my_ipairs(t)
    local i = 0
    local n = #t
    return function()
        i = i + 1
        if i <= n then
            return i, t[i]
        end
    end
end


folder_name = folder_name or "workshop-"

local isdev = not folder_name:find("workshop-")

local function pub_dev(pub, dev)
    return isdev and dev or pub
end

name = pub_dev(en_zh("Tropical Adventures|Ship of Theseus", "热带冒险|忒修斯之船"),
    en_zh("Tropical Adventures|Dev", "热带冒险|开发版"))

author = "Peng et al."
version = "26.09.19"
forumthread = ""
api_version = 10
priority = -100




local desc_ch = "进入游戏后，单击左下角图标查看模组百科。所有你想知道的内容都在这里了。"
local desc_en =
"After entering the game, click the icon in the lower left corner to view the mod wiki. All the things you want to know are here."
description = en_zh(desc_en, desc_ch)

dst_compatible = true
dont_starve_compatible = false
all_clients_require_mod = true
-- client_only_mod = false
reign_of_giants_compatible = false
server_filter_tags = { "Shipwrecked", "Hamlet", "海难", "哈姆雷特", "猪镇", "三合一", "热带冒险" }

icon_atlas = "images/modicon/modicon.xml"
icon = "modicon.tex"

-- mod_dependencies = {
--     { --GEMCORE
--         -- workshop = "workshop-3361402499",

--     },
-- }


local options_enable = {
    { description = en_zh("Enabled", "开启"), data = "enabled" },
    { description = en_zh("Disabled", "关闭"), data = "disabled" },

}

local options_enable2 = {
    { description = en_zh("Disabled", "关闭"), data = "disabled" },
}


local options_pairedkey = {
    { description = en_zh("Disabled", "关闭"), data = false },
    { description = "Q/E", data = "qe" },
    { description = "↓/↑", data = "du" },
    { description = "←/→", data = "lr" },
    { description = "-/+", data = "mp" },
    { description = "pagedown/pageup", data = "pp" },
    { description = "home/end", data = "he" },
}


local function Breaker(title_en, title_zh)
    return { name = en_zh(title_en, title_zh), options = { { description = "", data = false } }, default = false }
end






global_options =
{

    -- {
    --     name = "set_language",
    --     label = en_zh("Language", "选择语言"),
    --     hover = "ch/en/ja/ko/es/fr/ru/it/pl/de/pt/br",

    --     options =
    --     {
    --         { description = en_zh("Auto", "自动"), data = "auto", hover = en_zh("Following your game language", "跟随游戏默认语言") },
    --         { description = "中文", data = "ch" },
    --         { description = "English", data = "en" },
    --         { description = "Japanese", data = "ja" },
    --         { description = "Korean", data = "ko" },
    --         { description = "Spanish", data = "es" },
    --         { description = "French", data = "fr" },
    --         { description = "Russian", data = "ru" },
    --         { description = "Italian", data = "it" },
    --         { description = "Polish", data = "pl" },
    --         { description = "German", data = "de" },
    --         { description = "Portuguese", data = "pt" },
    --         { description = "Portuguese_br", data = "br" },


    --     },
    --     default = "auto",
    -- },


    {
        name = "ocean_style",
        label = en_zh("Ocean Style", "海洋风格"),
        hover = en_zh("Ocean Style", "海洋风格"),
        options =
        {
            {
                description = en_zh("Default", "默认"),
                hover = en_zh("DST ocean", "联机海洋"),
                data = "default"
            },
            {
                description = en_zh("Shipwrecked Style", "海难风格"),
                hover = en_zh("Shipwrecked stylized tropical ocean", "海难风格的热带海洋"),
                data = "tropical"
            },

            -- {
            --     description = en_zh("Mixed Blue ", "碧蓝"),
            --     hover = en_zh("tropical dst oceam", "热带风格的联机海洋"),
            --     data = "blue"
            -- },

        },
        default = "tropical",
    },

    {
        name = "compatible_adjustment",
        label = en_zh("Compatiable Adjustment", "兼容性调整"),
        hover = en_zh("Improve Mod compatibility, but maybe add some lags.",
            "增强Mod兼容性，但也许会增加卡顿"),
        options = {
            { description = en_zh("Disabled", "关闭"), data = false, },
            { description = en_zh("Enabled", "开启"), data = true, },
        },
        default = true,
    },

    {
        name = "dev_portal_reconnector",
        label = en_zh("Reconnect Cave Entrances", "洞穴入口重连"),
        hover = en_zh("If you thought that your world's cave entrances teleported not well, try turn on this option.",
            "如果你觉得洞穴入口传送得不是很对，那就启用这个选项。"),
        options = {
            { description = en_zh("Disabled", "关闭"), data = false, },
            { description = en_zh("Enabled", "开启"), data = true, },
        },
        default = false,
    },
}


developer_options =
{
    {
        name = "test_map",
        label = en_zh("Test Map", "测试地图"),
        hover = en_zh("a small map for testing", "用于测试用的小型地图"),
        options = options_enable,
        default = "disabled",
    },

    {
        name = "test_mode",
        label = en_zh("Test Mode", "测试模式"),
        hover = en_zh("seafork, autoskin, prefabname", "填海叉，开礼物，显示代码名"),
        options = options_enable,
        default = "disabled",
    },

    --[[ isdev and {
        name = "prefabname",
        label = en_zh("Show Prefab Name", "显示物品代码"),
        hover = en_zh("Show Prefab Name on Cursor", "显示物品代码"),
        options = options_enable,
        default = false,
    } or {},

    isdev and {
        name = "seafork",
        label = en_zh("Seafork", "填海叉"),
        hover = en_zh("Sea to Land", "填海造陆"),
        options = options_enable,
        default = false,
    } or {}, ]]
}

client_options =
{


    {
        name = "room_view_key",
        label = en_zh("Room view", "房间视角"),
        hover = en_zh("lower or higher view", "拉低/拉高视角"),
        options = options_pairedkey,
        default = "mp", ----  -/+
    },

    {
        name = "build_height_key",
        label = en_zh("Building height", "建造高度"),
        hover = en_zh("windows or hanging section while building", "窗户、悬挂型建筑高度调整"),
        options = options_pairedkey,
        default = "du", ----  "↓/↑"
    },

    {
        name = "build_rotation_key",
        label = en_zh("Building rotation", "建造角度"),
        hover = en_zh("wall sections, rugs and some decorations", "墙饰/地毯和部分装饰物的建造角度"),
        options = options_pairedkey,
        default = "qe", ----  q/e
    },

    {
        name = "boatlefthud",
        label = en_zh("Boat HUD(Vertical Adjustment)", "海难船只HUD高度补偿"),
        hover = en_zh(
            "Here u can adjust the height of the ShipWreck Boat HUD(It's already self-adapted)",
            "在这里可以调整海难船只HUD的高度补偿(自适应调整)"),
        options =
        {
            { description = "0", data = 0 },
            { description = "↑20", data = 20 },
            { description = "↑40", data = 40 },
            { description = "↑80", data = 80 },
        },
        default = 0,
    },





}

configuration_options = {}

if isdev then
    table_insert(configuration_options, Breaker("Developer Settings", "开发者选项") or nil)
    for i, v in my_ipairs(developer_options) do
        table_insert(configuration_options, v)
    end
end

table_insert(configuration_options, Breaker("Global Options", "全局选项"))
for i, v in my_ipairs(global_options) do
    table_insert(configuration_options, v)
end

table_insert(configuration_options, Breaker("WHEN HOSTING GAME", ""))
table_insert(configuration_options, Breaker("Client Adjustments", "客户端调整"))
table_insert(configuration_options, Breaker("Belows are Client Settings", "以下为客户端设置"))
table_insert(configuration_options, Breaker("DO NOT WORK ", "“创建游戏”时设置无效"))
table_insert(configuration_options, Breaker("WHEN HOSTING GAME", ""))

for i, v in my_ipairs(client_options) do
    table_insert(configuration_options, v)
end

-- table_insert(configuration_options, Breaker("Option Reset ", "选项重置"))
-- table_insert(configuration_options, {
--     name = "already_reset",
--     label = en_zh("Option Reset ", "选项重置"),
--     options = {
--         { description = en_zh("Done", "已完成"), data = true },
--         { description = en_zh("Not yet", "未完成"), data = false },

--     },
--     default = false,
-- })
