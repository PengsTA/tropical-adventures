local a,t={},{}local function e(i,n,o)local i={id=#t,texture="levels/textures/shader_water_nomip/"..n..".tex",shader="shaders/tile_particle_"..i..".ksh",blue_shader="shaders/tile_particle_"..i.."_blue.ksh",tile=WORLD_TILES[o[1]],}t[#t+1]=i
for t,e in ipairs(o)do
local e=WORLD_TILES[e]if e~=nil then a[e]=i end
end
end
e("lilypond","water_lilypond",{"LILYPOND"})e("mangrove","water_mangrove",{"MANGROVE","OCEAN_WATERLOG"})e("coral","water_coral",{"OCEAN_BRINEPOOL","OCEAN_BRINEPOOL_SHORE"})e("hazardous","water_graveyard",{"OCEAN_HAZARDOUS"})e("shallow","water_shallow",{"OCEAN_COASTAL","OCEAN_COASTAL_SHORE"})e("medium","water_medium",{"OCEAN_SWELL"})e("deep","water_deep",{"OCEAN_ROUGH"})local function o(e)local t=a[e]if t~=nil then return t.tile end
return IsOceanTile(e)and WORLD_TILES.OCEAN_COASTAL or nil
end
return{tiles=a,emitters=t,GetRenderTileType=o}