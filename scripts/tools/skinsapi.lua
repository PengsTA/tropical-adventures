-- 皮肤api,来自小穹
-- 在此感谢风铃大佬
-- 皮肤api,看不懂,能用就行

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end, })

GLOBAL.PREFAB_SKINS_SHOULD_NOT_CHANGE = {}

-- verion = 1.09
-- v1.10 更新 atlas 和 image直接注册到Prefab 方便调用
--       增加 GetSkinBase  获取皮肤对应的基础prefab
--      增加了默认 release_group
-- v1.09 更新  增加GetAllSkin 方法 新增 isitemskins 和 ischaracterskins 属性
-- v1.08 更新  增加物品皮肤对ThankYouPopup的兼容  需要自行注册 ATLAS_BUILD
-- v1.07 更新  增加 MakeSkinNameMap GetSkinMap GetSkinMapByBase 三个方法
-- v1.06 更新 新增对 [API] Modded Skins 的捕获逃逸
-- v1.05 更新 修复兼容性问题
-- v1.04 更新 兼容R20版本
-- v1.03 更新 增加了对 share_bigportrait_name和 FrameSymbol的支持
-- 调用示例
-- 乱动皮肤的后果自负！！！
--[[
    MakeCharacterSkin("sora","sora_dress",{
        name = "连衣长裙",      --皮肤的显示名称
        des = "悠!快出來...\n你在哪儿?",        --选人界面的皮肤描述
        quotes = "悠......",
        rarity = "总之就是非常可爱",
        raritycorlor = {255/255,215/255,0/255,1},
        skins = {normal_skin = "sora_dress",ghost_skin = "ghost_sora_build"},
        skin_tags = {"BASE","sora","CHARACTER"},
        init_fn = function()  print("dress_init") end,
        clear_fn = function() print("dress_clear") end,
    })
    MakeItemSkinDefaultImage("cookpot","images/inventoryimages/sora2sword.xml","sora2sword")    --设置默认皮肤的制作栏贴图
    MakeItemSkin("cookpot","cookpot_portable",{
        name = "便携锅",
        atlas = "images/inventoryimages1.xml",
        image = "portablecookpot_item",
        build = "portable_cook_pot",
        bank = "portable_cook_pot",
        basebuild = "cook_pot",
        basebank = "cook_pot",
    })
    GetSkin("sora_dress")
    如果需要在prefab里调用
    先GLOBAL.SoraAPI = env
    然后在prefab文件里
    SoraAPI.MakeCharacterSkin(...)
    SoraAPI.MakeItemSkin(...)
    SoraAPI.GetSkin(name)
    --如果喜欢用  aaa_build配方来制作 aaa 之类的话
    请打开下面的开关 recipe_help

    ]]
local CreatePrefabSkin -- 重新定义一下自己的 试图绕过Modded API的截取 在文件结尾有重新定义
local recipe_help = true
local thank_help = true
-- 人物皮肤API
local characterskins = {}
--[[格式 skinname = {
                打*的为必填项 反之不必须
                                base_prefab = base,

                                *name = string or skinname   --皮肤的名称
                                des = string or "",         --皮肤界面的描述
                                quotes = string or nil      --选人界面的描述
                                rarity = string or "Loyal", --珍惜度 官方不存在的珍惜度则直接覆盖字符串
                                rarityorder = int or -1 --  --珍惜度的排序 用于按优先级排序 基本没啥用
                                raritycorlor = {R,G,B,A} or { 0.635, 0.769, 0.435, 1 }

                                checkfn = function or nil,  检查是否拥有的 主要是客机自己执行 为空则默认拥有
                                checkclientfn = function or nil, 检查客户端是否拥有的 主要是主机执行
                                init_fn = function or nil,
                                clear_fn = function or nil,
                                share_bigportrait_name = string or nil,  --人物皮肤的背景图 大图
                                FrameSymbol = string or nil ,            --人物base皮肤的背景
                                *skins = {
                                    normal_skin  = string or name,
                                    ghost_skin   = string or name_ghost,
                                } or nil


                                --所有参数会顺传给返回的prefab
                                    skintags = {} or nil, 皮肤的tag 用于过滤
                                    assets = {} or nil,   皮肤用到的资源
                                --其他参数暂时用不到，需要的自己带进来吧，会自动传递官方的
                              }]]

local FrameSymbol = {}
local skincharacters = {}
local default_release_group = -100
local default_display_order = -1000
local function AppendUnique(list, value)
    for _, existing in ipairs(list) do
        if existing == value then
            return
        end
    end
    table.insert(list, value)
end

-- 人物过滤
local SKIN_AFFINITY_INFO = require("skin_affinity_info")
function MakeCharacterSkin(base, skinname, data, defer_registration)
    default_release_group = default_release_group - 1
    default_display_order = default_display_order + 1
    -- 基于哪个人物的  皮肤名称 额外数据
    data.type = nil

    -- 标记一下是拥有皮肤的人物
    if not skincharacters[base] then
        skincharacters[base] = true
    end
    characterskins[skinname] = data
    data.base_prefab = base
    data.ischaracterskins = true
    data.rarity = data.rarity or "Loyal" -- 默认珍惜度
    data.release_group = data.release_group or default_release_group
    data.display_order = data.display_order or default_display_order
    data.build_name_override = data.build_name_override or skinname
    -- 不存在的珍惜度 自动注册字符串
    if not STRINGS.UI.RARITY[data.rarity] then
        STRINGS.UI.RARITY[data.rarity] = data.rarity
        SKIN_RARITY_COLORS[data.rarity] = data.raritycorlor or { 0.635, 0.769, 0.435, 1 }
        RARITY_ORDER[data.rarity] = data.rarityorder or -default_release_group
        if data.FrameSymbol then
            FrameSymbol[data.rarity] = data.FrameSymbol
        end
    end
    -- 注册到字符串
    STRINGS.SKIN_NAMES[skinname] = data.name or skinname
    STRINGS.SKIN_DESCRIPTIONS[skinname] = data.des or ""
    STRINGS.SKIN_QUOTES[skinname] = data.quotes or ""
    -- 注册到皮肤列表
    if not PREFAB_SKINS[base] then
        PREFAB_SKINS[base] = {}
    end
    AppendUnique(PREFAB_SKINS[base], skinname)
    if not SKIN_AFFINITY_INFO[base] then
        SKIN_AFFINITY_INFO[base] = {}
    end
    AppendUnique(SKIN_AFFINITY_INFO[base], skinname)

    -- 创建皮肤预制物
    local prefab_skin = CreatePrefabSkin(skinname, data)
    if data.clear_fn then
        prefab_skin.clear_fn = data.clear_fn
    end
    prefab_skin.type = "base"
    if not defer_registration then
        RegisterPrefabs(prefab_skin) -- 注册并加载皮肤的prefab
        TheSim:LoadPrefabs({ skinname })
    end
    return prefab_skin
end

-- 物品皮肤
local itemskins = {}
--[[格式 skinname = {
                打*的为必填项 反之不必须
                            base = "",
                                *name = string or skinname   --皮肤的名称
                                des = string or "",         --皮肤界面的描述       好像没啥用
                                rarity = string or "Loyal", --珍惜度 官方不存在的珍惜度则直接覆盖字符串
                                rarityorder = int or -1 --      珍惜度的排序 好像没啥用
                                raritycorlor = {R,G,B,A} or { 0.635, 0.769, 0.435, 1 }  --珍惜度的颜色
                                atlas = string or nil,      --贴图xml
                                image = string or nil,        --贴图tex 不带.tex
                                --解决官方默认皮肤图标不搜索mod的问题  如果是 prefab和imagename名字一致的 建议用官方的 RegisterInventoryItemAtlas
                                bank    = string or nil,        --如果需要替换bank就传 不需要就不传
                                build   = string or skinname,   --如果需要替换build就传 不需要就默认和皮肤同名
                                anim    = string or nil,        --如果需要替换anim就传 不需要就不传

                                basebank    = string or nil,        --如果替换了bank就传 不需要就不传
                                basebuild   = string or prefab,        --如果替换了build就传 不需要默认原prefab
                                baseanim    = string or nil,        --如果替换了anim就传 不需要就不传

                                checkfn = function or nil,  检查是否拥有的 主要是客机自己执行 为空则默认拥有
                                checkclientfn = function or nil, 检查客户端是否拥有的 主要是主机执行
                                initfn = function or nil,
                                clearfn = function or nil,

                                --所有参数会顺传给返回的prefab
                                    skintags = {} or nil, 皮肤的tag 用于过滤
                                    assets = {} or nil,   皮肤用到的资源
                                --其他参数暂时用不到，需要的自己带进来吧，会自动传递官方的

                            }

            ]]
local itembaseimage = {}
function MakeItemSkinDefaultImage(base, atlas, image)
    itembaseimage[base] = { atlas, (image or base) .. ".tex", "default.tex" }
end

function MakeItemSkin(base, skinname, data, defer_registration)
    default_release_group = default_release_group - 1
    default_display_order = default_display_order + 1
    data.type = nil
    itemskins[skinname] = data
    data.base_prefab = base
    data.isitemskins = true
    data.rarity = data.rarity or "Loyal" -- 默认珍惜度
    data.build_name_override = data.build_name_override or skinname
    data.release_group = data.release_group or default_release_group
    data.display_order = data.display_order or default_display_order

    -- 不存在的珍惜度 自动注册字符串
    if not STRINGS.UI.RARITY[data.rarity] then
        STRINGS.UI.RARITY[data.rarity] = data.rarity
        SKIN_RARITY_COLORS[data.rarity] = data.raritycorlor or { 0.635, 0.769, 0.435, 1 } --可以自己修改显示颜色
        RARITY_ORDER[data.rarity] = data.rarityorder or -default_release_group
        if data.FrameSymbol then
            FrameSymbol[data.rarity] = data.FrameSymbol
        end
    end
    -- 注册到字符串
    STRINGS.SKIN_NAMES[skinname] = STRINGS.SKIN_NAMES[skinname] or data.name or skinname --方便在单独的string文件中写名字
    STRINGS.SKIN_DESCRIPTIONS[skinname] = STRINGS.SKIN_DESCRIPTIONS[skinname] or data.des or ""
    if data.atlas and data.image then
        RegisterInventoryItemAtlas(data.atlas, data.image .. ".tex") --注册到atlas只需要这一句就够了，甚至不需要
    end
    -- 注册到皮肤列表
    if not PREFAB_SKINS[base] then
        PREFAB_SKINS[base] = {}
    end
    AppendUnique(PREFAB_SKINS[base], skinname)
    if not PREFAB_SKINS_IDS[base] then
        PREFAB_SKINS_IDS[base] = {}
    end
    if PREFAB_SKINS_IDS[base][skinname] == nil then
        local index = 0
        for _, value in pairs(PREFAB_SKINS_IDS[base]) do
            index = math.max(index, value)
        end
        PREFAB_SKINS_IDS[base][skinname] = index + 1
    end
    -- 创建皮肤预制物
    -- data.extra_init_fn = data.init_fn or nil --进行自定义init 和clear
    -- data.extra_clear_fn = data.clear_fn or nil
    data.init_fn = function(inst)
        basic_skininit_fn(inst, skinname)
    end
    data.clear_fn = function(inst)
        basic_skinclear_fn(inst, skinname)
    end
    if data.skinpostfn then
        data.skinpostfn(data) -- 给一个玩家改init_fn的接口
    end
    local prefab_skin = CreatePrefabSkin(skinname, data)
    if data.clear_fn then
        prefab_skin.clear_fn = data.clear_fn
    end
    if data.atlas and data.image then
        prefab_skin.atlas = data.atlas
        prefab_skin.image = data.image
        prefab_skin.imagename = data.image .. ".tex"
    end
    prefab_skin.type = "item"
    if not defer_registration then
        RegisterPrefabs(prefab_skin) -- 注册并加载皮肤的prefab
        TheSim:LoadPrefabs({ skinname })
    end
    return prefab_skin
end

GLOBAL.TROPICAL_SKIN_API = {
    MakeItemSkin = MakeItemSkin,
}

local namemaps = {}
-- 允许 skinname 皮肤 共用base的权限

function GetSkinBase(name)
    return (itemskins[name] and itemskins[name].base_prefab) or
        (characterskins[name] and characterskins[name].base_prefab) or ""
end

function MakeSkinNameMap(base, skinname)
    namemaps[skinname] = base
end

function GetSkinMap(skinname)
    return namemaps[skinname] or skinname
end

function GetSkinMapByBase(base)
    local r = {
        [base] = 1
    }
    for k, v in pairs(namemaps) do
        if v == base then
            r[k] = 1
        end
    end
    return r
end

-- 下面的可以不看

-- 皮肤权限hook--help 为什么 要用metatable

local timelastest = TheSim:GetRealTime()

local mt = getmetatable(TheInventory)
local oldTheInventoryCheckOwnership = TheInventory.CheckOwnership
mt.__index.CheckOwnership = function(i, name, ...)
    -- print(i,name,...)
    -- if true then return true end
    name = namemaps[name] or name
    --help 也就是说原版dst收费的皮肤名字不是字符串？然后根据checkfn判断玩家是否有权限
    if type(name) == "string" and (characterskins[name] or itemskins[name]) then
        if characterskins[name] and characterskins[name].checkfn then
            return characterskins[name].checkfn(i, name, ...)
        elseif itemskins[name] and itemskins[name].checkfn then
            return itemskins[name].checkfn(i, name, ...)
        else
            return true
        end
    else
        return oldTheInventoryCheckOwnership(i, name, ...)
    end
end
local oldTheInventoryCheckOwnershipGetLatest = TheInventory.CheckOwnershipGetLatest
mt.__index.CheckOwnershipGetLatest = function(i, name, ...)
    -- print(i,name,...)
    -- if true then return true, TheSim:GetRealTime() end
    name = namemaps[name] or name
    if type(name) == "string" and (characterskins[name] or itemskins[name]) then
        if characterskins[name] and characterskins[name].checkfn then
            return characterskins[name].checkfn(i, name, ...), TheSim:GetRealTime()
        elseif itemskins[name] and itemskins[name].checkfn then
            return itemskins[name].checkfn(i, name, ...), TheSim:GetRealTime()
        else
            return true, TheSim:GetRealTime()
        end
    else
        return oldTheInventoryCheckOwnershipGetLatest(i, name, ...)
    end
end

local oldTheInventoryCheckClientOwnership = TheInventory.CheckClientOwnership
mt.__index.CheckClientOwnership = function(i, userid, name, ...)
    -- if true then return true end
    name = namemaps[name] or name
    if type(name) == "string" and (characterskins[name] or itemskins[name]) then
        if characterskins[name] and characterskins[name].checkclientfn then
            return characterskins[name].checkclientfn(i, userid, name, ...)
        elseif itemskins[name] and itemskins[name].checkclientfn then
            return itemskins[name].checkclientfn(i, userid, name, ...)
        else
            return true
        end
    else
        return oldTheInventoryCheckClientOwnership(i, userid, name, ...)
    end
end

local oldExceptionArrays = GLOBAL.ExceptionArrays
GLOBAL.ExceptionArrays = function(ta, tb, ...)
    local need
    for i = 1, 100, 1 do
        local data = debug.getinfo(i, "S")
        if data then
            if data.source and data.source:match("^scripts/networking.lua") then
                need = true
            end
        else
            break
        end
    end
    if need then
        local newt = oldExceptionArrays(ta, tb, ...)
        for k, v in pairs(skincharacters) do
            table.insert(newt, k) -- 偷渡
        end
        return newt
    else
        return oldExceptionArrays(ta, tb, ...)
    end
end
local oldIsDefaultCharacterSkin = IsDefaultCharacterSkin
GLOBAL.IsDefaultCharacterSkin = function(item, ...)
    item = item and namemaps[item] or item
    if item and characterskins[item] then
        if characterskins[item].checkfn then
            return characterskins[item].checkfn(nil, item)
        else
            return true
        end
    else
        return oldIsDefaultCharacterSkin(item, ...)
    end
end
local oldGetPortraitNameForItem = GetPortraitNameForItem
GLOBAL.GetPortraitNameForItem = function(item)
    item = item and namemaps[item] or item
    if item and characterskins[item] and characterskins[item].share_bigportrait_name then
        return characterskins[item].share_bigportrait_name
    end
    return oldGetPortraitNameForItem(item)
end
local oldGetFrameSymbolForRarity = GetFrameSymbolForRarity
GLOBAL.GetFrameSymbolForRarity = function(item)
    item = item and namemaps[item] or item
    return FrameSymbol[item] or oldGetFrameSymbolForRarity(item)
end
-- 骗过皮肤面板，让他以为我们是官方人物
local function sorabaseenable(self)
    if self.name == "LoadoutSelect" then -- 加载LoadoutSelect之前
        for k, v in pairs(skincharacters) do
            if not table.contains(DST_CHARACTERLIST, k) then
                table.insert(DST_CHARACTERLIST, k)
            end
        end
    elseif self.name == "LoadoutRoot" then -- 已经判断完have_base_option了  可以删了 哈哈
        for k, v in pairs(skincharacters) do
            if table.contains(DST_CHARACTERLIST, k) then
                RemoveByValue(DST_CHARACTERLIST, k)
            end
        end
    end
end
AddClassPostConstruct("widgets/widget", sorabaseenable)
AddSimPostInit(function()
    if not TheNet:IsOnlineMode() then
        local net = getmetatable(GLOBAL.TheNet)
        net.__index.IsOnlineMode = function(n, ...)
            return true
        end
    end
end)
-- 人物皮肤的init_fn 和 clear_fn
AddComponentPostInit("skinner", function(self)
    local oldfn = self.SetSkinName
    if oldfn then
        function self.SetSkinName(s, skinname, ...)
            local old = s.skin_name
            local new = skinname
            if characterskins[old] and characterskins[old].clear_fn then
                characterskins[old].clear_fn(s.inst, old)
            end
            if characterskins[new] and characterskins[new].init_fn then
                characterskins[new].init_fn(s.inst, new)
            end
            oldfn(s, skinname, ...)
        end
    end
end)

AddClassPostConstruct("widgets/recipepopup", function(self)
    local oldfn = self.GetSkinOptions
    function self.GetSkinOptions(s, ...)
        local ret = oldfn(s, ...)
        if ret then
            if ret[1] and ret[1].image then
                if s.recipe and s.recipe.product and itembaseimage[s.recipe.product] then -- 存在则覆盖
                    ret[1].image = itembaseimage[s.recipe.product]
                end
            end
            for k, v in pairs(s.skins_list) do
                if ret[k + 1] and ret[k + 1].image and v and v.item and itemskins[v.item] and
                    (itemskins[v.item].atlas or itemskins[v.item].image) then
                    local image = itemskins[v.item].image or v.item .. ".tex"
                    if image:sub(-4) ~= ".tex" then
                        image = image .. ".tex"
                    end
                    local atlas = itemskins[v.item].atlas or GetInventoryItemAtlas(image)
                    ret[k + 1].image = { atlas, image, "default.tex" }
                end
            end
        end
        return ret
    end
end)

local skinselector = require("widgets/redux/craftingmenu_skinselector")
function hookskinselector(self)
    local oldfn = self.GetSkinOptions
    function self.GetSkinOptions(s, ...)
        local ret = oldfn(s, ...)
        if ret then
            if ret[1] and ret[1].image then
                if s.recipe and s.recipe.product and itembaseimage[s.recipe.product] then -- 存在则覆盖
                    ret[1].image = itembaseimage[s.recipe.product]
                end
            end
            for k, v in pairs(s.skins_list) do
                if ret[k + 1] and ret[k + 1].image and v and v.item and itemskins[v.item] and
                    (itemskins[v.item].atlas or itemskins[v.item].image) then
                    local image = itemskins[v.item].image or v.item .. ".tex"
                    if image:sub(-4) ~= ".tex" then
                        image = image .. ".tex"
                    end
                    local atlas = itemskins[v.item].atlas or GetInventoryItemAtlas(image)
                    ret[k + 1].image = { atlas, image, "default.tex" }
                end
            end
        end
        return ret
    end
end

hookskinselector(skinselector)

local oldGetSkinInvIconName = GetSkinInvIconName
GLOBAL.GetSkinInvIconName = function(item, ...)
    if itemskins[item] and itemskins[item].image then
        local image = itemskins[item].image
        if image:sub(-4) == ".tex" then
            image = image:sub(1, -5)
        end
        return image
    end
    return oldGetSkinInvIconName(item, ...)
end

-- 这是全局函数 所以可以放后面 在执行前定义好就行
function basic_skininit_fn(inst, skinname)
    if inst.components.placer == nil and not TheWorld.ismastersim then
        return
    end
    local data = itemskins[skinname]
    if not data then return end
    if data.bank then
        inst.AnimState:SetBank(data.bank)
    end

    if data.build then
        inst.AnimState:SetBuild(data.build)
    end

    if data.anim then
        inst.AnimState:PlayAnimation(data.anim)
    end

    if data.override ~= nil then
        for _, dat in pairs(data.override) do
            inst.AnimState:OverrideSymbol(dat[1], dat[2], dat[3])
        end
    end

    if inst.components.inventoryitem and data.image then
        inst.components.inventoryitem:ChangeImageName(data.image)
    end

    if inst.MiniMapEntity and (data.minimapicon or data.image) then ---主要问题在于原版物品用的png作为minimap
        inst.MiniMapEntity:SetIcon(data.minimapicon or data.image .. ".tex")
    end

    if data.extra_init_fn then
        data.extra_init_fn(inst, skinname)
    end
end

function basic_skinclear_fn(inst, skinname) -- 默认认为 build 和prefab同名 不对的话自己改
    local prefab = inst.prefab or ""
    if inst.components.placer == nil and not TheWorld.ismastersim then
        return
    end

    local data = itemskins[skinname]
    if not data then return end
    if data.bank then
        inst.AnimState:SetBank(data.basebank or prefab)
    end
    if data.anim and data.baseanim then
        inst.AnimState:PlayAnimation(data.baseanim)
    end

    if data.build then
        inst.AnimState:SetBuild(data.basebuild or prefab)
    end

    if data.override and data.baseoverride then
        for _, dat in pairs(data.baseoverride) do
            inst.AnimState:OverrideSymbol(dat[1], dat[2], dat[3])
        end
    end

    if inst.components.inventoryitem ~= nil and data.image then
        inst.components.inventoryitem:ChangeImageName(data.baseimage or prefab)
    end

    if inst.MiniMapEntity and (data.minimapicon or data.image) then
        inst.MiniMapEntity:SetIcon(data.base_minimapicon or (data.baseimage or prefab) .. ".tex")
    end

    if itemskins[skinname].extra_clear_fn then
        itemskins[skinname].extra_clear_fn(inst, skinname)
    end
end

local oldSpawnPrefab = SpawnPrefab --help 果然还是hook这个函数了
GLOBAL.SpawnPrefab = function(prefab, skin, skinid, userid, ...)
    if itemskins[skin] then
        skinid = 0
    end
    return oldSpawnPrefab(prefab, skin, skinid, userid, ...)
end
local oldReskinEntity = Sim.ReskinEntity
Sim.ReskinEntity = function(sim, guid, oldskin, newskin, skinid, userid, ...)
    local inst = Ents[guid]
    if oldskin and itemskins[oldskin] then
        itemskins[oldskin].clear_fn(inst) -- 清除旧皮肤的
        inst:SetPrefabNameOverride(nil)
    end

    local r = oldReskinEntity(sim, guid, oldskin, newskin, skinid, userid, ...)
    if newskin and itemskins[newskin] then
        if PREFAB_SKINS_SHOULD_NOT_CHANGE[newskin] then
            inst.skinname = nil
            inst.natureskinname = newskin
            inst.skin_id = nil
            inst:SetPrefabNameOverride(itemskins[newskin].name or inst.prefab)
        else
            inst.skinname = newskin
            inst.skin_id = 0
        end
        itemskins[newskin].init_fn(inst)
    end
    return r
end

function GetSkin(name)
    return characterskins[name] or itemskins[name] or nil
end

function GetAllSkin()
    return characterskins, itemskins
end

if recipe_help then
    AddSimPostInit(function()
        for k, v in pairs(AllRecipes) do
            if v.product ~= v.name and PREFAB_SKINS[v.product] then
                PREFAB_SKINS[v.name] = PREFAB_SKINS[v.product]
                PREFAB_SKINS_IDS[v.name] = PREFAB_SKINS_IDS[v.product]
            end
        end
    end)
end

if thank_help then --这个是什么？
    local ThankYouPopup = require "screens/thankyoupopup"
    local tohook = {
        OpenGift = 1,
        ChangeGift = 1
    }
    for k, v in pairs(tohook) do
        tohook[k] = ThankYouPopup[k]
        ThankYouPopup[k] = function(self, ...)
            local r = tohook[k](self, ...)

            local item = self.current_item and self.items and self.items[self.current_item] and
                self.items[self.current_item].item
            if item then
                local skin = GetSkin(item)
                if skin and skin.swap_icon then
                    self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", skin.swap_icon.build,
                        skin.swap_icon.image)
                elseif skin and skin.image and skin.atlas then
                    self.spawn_portal:GetAnimState():OverrideSkinSymbol("SWAP_ICON", softresolvefilepath(skin.atlas),
                        skin.image .. ".tex")
                end
            end

            return r
        end
    end
end

local oldCreatePrefabSkin = GLOBAL.CreatePrefabSkin
local fninfo = debug.getinfo(oldCreatePrefabSkin)
if fninfo and fninfo.source and not fninfo.source:match("scripts/prefabskin%.lua") then -- 不是官方的就用自己的
    print("UseMySelfCreatePrefabSkin")
    function CreatePrefabSkin(name, info)
        local prefab_skin = Prefab(name, nil, info.assets, info.prefabs)
        prefab_skin.is_skin = true
        -- Hack to deal with mods with bad data. Type is now required, and who knows how many character mods are missing this field.
        if info.type == nil then
            info.type = "base"
        end
        prefab_skin.base_prefab = info.base_prefab
        prefab_skin.type = info.type
        prefab_skin.skin_tags = info.skin_tags
        prefab_skin.init_fn = info.init_fn
        prefab_skin.build_name_override = info.build_name_override
        prefab_skin.bigportrait = info.bigportrait
        prefab_skin.rarity = info.rarity
        prefab_skin.rarity_modifier = info.rarity_modifier
        prefab_skin.skins = info.skins
        prefab_skin.skin_sound = info.skin_sound
        prefab_skin.is_restricted = info.is_restricted
        prefab_skin.granted_items = info.granted_items
        prefab_skin.marketable = info.marketable
        prefab_skin.release_group = info.release_group or default_release_group

        prefab_skin.linked_beard = info.linked_beard
        prefab_skin.share_bigportrait_name = info.share_bigportrait_name
        if info.torso_tuck_builds ~= nil then
            for _, base_skin in pairs(info.torso_tuck_builds) do
                BASE_TORSO_TUCK[base_skin] = "full"
            end
        end
        if info.torso_untuck_builds ~= nil then
            for _, base_skin in pairs(info.torso_untuck_builds) do
                BASE_TORSO_TUCK[base_skin] = "untucked"
            end
        end
        if info.torso_untuck_wide_builds ~= nil then
            for _, base_skin in pairs(info.torso_untuck_wide_builds) do
                BASE_TORSO_TUCK[base_skin] = "untucked_wide"
            end
        end
        if info.has_alternate_for_body ~= nil then
            for _, base_skin in pairs(info.has_alternate_for_body) do
                BASE_ALTERNATE_FOR_BODY[base_skin] = true
            end
        end
        if info.has_alternate_for_skirt ~= nil then
            for _, base_skin in pairs(info.has_alternate_for_skirt) do
                BASE_ALTERNATE_FOR_SKIRT[base_skin] = true
            end
        end
        if info.one_piece_skirt_builds ~= nil then
            for _, base_skin in pairs(info.one_piece_skirt_builds) do
                ONE_PIECE_SKIRT[base_skin] = true
            end
        end
        if info.legs_cuff_size ~= nil then
            for base_skin, size in pairs(info.legs_cuff_size) do
                BASE_LEGS_SIZE[base_skin] = size
            end
        end
        if info.feet_cuff_size ~= nil then
            for base_skin, size in pairs(info.feet_cuff_size) do
                BASE_FEET_SIZE[base_skin] = size
            end
        end
        if info.skin_sound ~= nil then
            SKIN_SOUND_FX[name] = info.skin_sound
        end
        if info.fx_prefab ~= nil then
            SKIN_FX_PREFAB[name] = info.fx_prefab
        end
        if info.type ~= "base" then
            prefab_skin.clear_fn = _G[prefab_skin.base_prefab .. "_clear_fn"]
        end
        return prefab_skin
    end
else
    CreatePrefabSkin = oldCreatePrefabSkin
end
