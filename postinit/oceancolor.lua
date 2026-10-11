local WORLD_TILES = WORLD_TILES

GLOBAL.setfenv(1, GLOBAL)

local is_worldgen = rawget(_G, "WORLDGEN_MAIN") ~= nil

if not is_worldgen then
    TileGroups.TAOceanTiles = TileGroupManager:AddTileGroup()
end

local _color = (TUNING.ocean_style == "tropical")
local _blue = (TUNING.ocean_style == "blue")

local function DisableNativeOceanRendering(tile_id)
    if not is_worldgen then
        TileGroupManager:AddInvalidTile(TileGroups.TransparentOceanTiles, tile_id)
        TileGroupManager:AddValidTile(TileGroups.TAOceanTiles, tile_id)
    end
end


---------------------------------------------------修改这个调整世界背景颜色
if _blue then
    TUNING.OCEAN_SHADER.OCEAN_FLOOR_COLOR      = { 0, 100, 100, 255 }
    TUNING.OCEAN_SHADER.OCEAN_FLOOR_COLOR_DUSK = { 0, 60, 60, 155 }
end


local GroundTiles = require("worldtiledefs")

local function ConfigureShaderOceanFalloffs()
    if not is_worldgen then
        -- Filter before world.lua creates the native falloff render layers.
        for i = #GroundTiles.falloff, 1, -1 do
            local falloff = GroundTiles.falloff[i]
            if _color or (_blue and falloff[1] == FALLOFF_IDS.FALLOFF) then
                table.remove(GroundTiles.falloff, i)
            elseif _blue then
                if falloff[1] == FALLOFF_IDS.DOCK_FALLOFF then
                    local name = "ta_dock_falloff_compact"
                    local definition = falloff[2]
                    definition.name = name
                    definition.texture_name = resolvefilepath("levels/tiles/" .. name .. ".tex")
                    definition.atlas = resolvefilepath("levels/tiles/" .. name .. ".xml")
                    table.insert(GroundTiles.assets, Asset("IMAGE", definition.texture_name))
                    table.insert(GroundTiles.assets, Asset("FILE", definition.atlas))
                end
                if falloff[1] == FALLOFF_IDS.DOCK_FALLOFF
                    or falloff[1] == FALLOFF_IDS.OCEANICE_FALLOFF then
                    falloff[2].neighbor_needs_falloff = TileGroups.TAOceanTiles
                end
            end
        end
    end
end

local tile_tbl = {
    OCEAN_COASTAL_SHORE = "OCEAN_SHALLOW_SHORE",
    OCEAN_COASTAL = "OCEAN_SHALLOW",
    OCEAN_SWELL = "OCEAN_MEDIUM",
    OCEAN_ROUGH = "OCEAN_DEEP",
    OCEAN_WATERLOG = "MANGROVE",
    OCEAN_BRINEPOOL = "OCEAN_CORAL",
    OCEAN_BRINEPOOL_SHORE = "OCEAN_CORAL",
    OCEAN_HAZARDOUS = "OCEAN_SHIPGRAVEYARD",

    OCEAN_CORAL = "OCEAN_CORAL",
    LILYPOND = "LILYPOND",
    MANGROVE = "MANGROVE",
}

local function GetShaderWaterTileDef(tile_id, tbl)
    local override = "OCEAN_SHALLOW"
    for origin, mapped_tile in pairs(tbl) do
        if tile_id == WORLD_TILES[origin] then
            override = mapped_tile
            break
        end
    end
    return tro_tiledefs[override]
end

local function tile_redirect(tbl)
    -----大地图
    if _blue then
        -- Match Porkland's lilypond registration: no ground entry means no tile TEX is rendered.
        for i = #GroundTiles.ground, 1, -1 do
            local tile_id = GroundTiles.ground[i][1]
            if IsOceanTile(tile_id) then
                DisableNativeOceanRendering(tile_id)
                table.remove(GroundTiles.ground, i)
            end
        end
    elseif _color then
        for _, v in ipairs(GroundTiles.ground) do
            if IsOceanTile(v[1]) then
                v[2] = GetShaderWaterTileDef(v[1], tbl).ground_tile_def
                DisableNativeOceanRendering(v[1])
            end
        end
    end

    ----小地图
    for k, v in pairs(GroundTiles.minimap) do
        if IsOceanTile(v[1]) then
            if _color or _blue then
                v[2] = GetShaderWaterTileDef(v[1], tbl).minimap_tile_def
            end
        end
    end
end

if TUNING.ocean_style ~= "default" and (not TheNet:IsDedicated()) then
    ConfigureShaderOceanFalloffs()
    tile_redirect(tile_tbl)
end
