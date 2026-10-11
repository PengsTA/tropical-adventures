---------------------------override before main-------------------

-- The vanilla oceanfish prefab file builds its prefab list from
-- prefabs/oceanfishdef at require time. Clear a previous require so the
-- tropical definitions below are included by the vanilla fish prefab file.
package.loaded["prefabs/oceanfish"] = nil
package.loaded["prefabs/schoolherd"] = nil

local oceanfishdefs = require("prefabs/oceanfishdef")
local tro_oceanfishdefs = require("datadefs/tro_oceanfishdef")
local OceanFishAnimation = require("tools/oceanfish_animation")

if not TA_CONFIG.DEPENDENCY.ndnr then
    tableutil.deep_merge(oceanfishdefs, tro_oceanfishdefs, false)
end

OceanFishAnimation.InstallInventoryRemap(AnimState, oceanfishdefs.fish)

local function HasAsset(list, asset)
    for _, item in ipairs(list) do
        if item == asset then
            return true
        end
    end
    return false
end

for _, data in pairs(oceanfishdefs.fish) do
    if data.istropicalfish then
        if data.oceanbuild ~= nil then
            data.extra_anim_assets = data.extra_anim_assets or {}
            if not HasAsset(data.extra_anim_assets, data.oceanbuild) then
                table.insert(data.extra_anim_assets, data.oceanbuild)
            end
        end

        AddPrefabPostInit(data.prefab, function(inst)
            if data.oceanbuild ~= nil then
                inst.AnimState:SetBank("oceanfish_small")
                inst.AnimState:SetBuild(data.oceanbuild)
            end

            if not TheWorld.ismastersim then
                return
            end

            if data.oceanbuild ~= nil then
                inst.oceanbuild = data.oceanbuild
                inst.oceanbank = "oceanfish_small"
                inst.build = data.build or inst.build
                inst.bank = data.bank or inst.bank
                require "stategraphs/SGoceanfishsw"
                inst:SetStateGraph("SGoceanfishsw")
            end
        end)

        if data.inv_scale ~= nil then
            AddPrefabPostInit(data.prefab .. "_inv", function(inst)
                inst.Transform:SetScale(data.inv_scale, data.inv_scale, data.inv_scale)
            end)
        end
    end
end

-- if oceanfishdefs.school[SEASONS.SPRING][WORLD_TILES.LILYPOND].oceanfish_small_11 then
--     print(oceanfishdefs.school[SEASONS.SPRING][WORLD_TILES.LILYPOND].oceanfish_small_11 .. "!!!!!!!!!!!!!")
-- end
