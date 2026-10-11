local skinprefabs = {}

local function AddSkinAsset(skindata)
    local assetname = skindata.assetname or skindata.build or skindata.skinname
    local assetfile = "anim/" .. assetname .. ".zip"
    skindata.assets = skindata.assets or {}

    for _, asset in ipairs(skindata.assets) do
        if asset.type == "ANIM" and asset.file == assetfile then
            return
        end
    end

    table.insert(skindata.assets, Asset("ANIM", assetfile))
end

local function AddSkinPrefabs(skinlist, is_nature_skin)
    for _, prefabdata in pairs(skinlist) do
        for skinname, skindata in pairs(prefabdata) do
            if is_nature_skin then
                PREFAB_SKINS_SHOULD_NOT_CHANGE[skinname] = true
                PREFAB_SKINS_SHOULD_NOT_SELECT[skinname] = true
            end

            AddSkinAsset(skindata)
            table.insert(skinprefabs,
                TROPICAL_SKIN_API.MakeItemSkin(skindata.prefabname, skindata.skinname, skindata, true))
        end
    end
end

AddSkinPrefabs(require("datadefs/skin_item_defs").skinlist, false)
AddSkinPrefabs(require("datadefs/skin_nature_defs").skinlist, true)

return unpack(skinprefabs)
