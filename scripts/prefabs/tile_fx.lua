local s="pl_tilecolourenvelope"local h="pl_tilescaleenvelope"local d=2*1e9
local n=TUNING.ocean_style=="blue"local c=n and LAYER_BELOW_OCEAN or LAYER_BACKGROUND
local r="pl_tilecolourenvelope_tropical"local o=require("tools/water_render_masks")local u={Asset("IMAGE","levels/textures/ham/water_lilypond2.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_lilypond.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_mangrove.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_coral.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_graveyard.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_shallow.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_medium.tex"),Asset("IMAGE","levels/textures/shader_water_nomip/water_deep.tex"),Asset("SHADER","shaders/tile_particle_pond.ksh"),Asset("SHADER","shaders/tile_particle_ocean.ksh"),Asset("SHADER","shaders/tile_particle_lilypond.ksh"),Asset("SHADER","shaders/tile_particle_mangrove.ksh"),Asset("SHADER","shaders/tile_particle_coral.ksh"),Asset("SHADER","shaders/tile_particle_hazardous.ksh"),Asset("SHADER","shaders/tile_particle_shallow.ksh"),Asset("SHADER","shaders/tile_particle_medium.ksh"),Asset("SHADER","shaders/tile_particle_deep.ksh"),Asset("SHADER","shaders/tile_particle_lilypond_blue.ksh"),Asset("SHADER","shaders/tile_particle_mangrove_blue.ksh"),Asset("SHADER","shaders/tile_particle_coral_blue.ksh"),Asset("SHADER","shaders/tile_particle_hazardous_blue.ksh"),Asset("SHADER","shaders/tile_particle_shallow_blue.ksh"),Asset("SHADER","shaders/tile_particle_medium_blue.ksh"),Asset("SHADER","shaders/tile_particle_deep_blue.ksh"),}local function t()EnvelopeManager:AddColourEnvelope(s,{{0,{0.87,0.87,0.87,1}},{1,{0.87,0.87,0.87,1}},})local a,e=1.171875*4,1.171875*4
EnvelopeManager:AddVector2Envelope(h,{{0,{a,e}},{1,{a,e}},})t=nil
end
local function i()EnvelopeManager:AddColourEnvelope(r,{{0,{0.87,0.87,0.87,0.5}},{1,{0.87,0.87,0.87,0.5}},})i=nil
end
local function f(t,e,n,i,a)t.Transform:SetPosition(e.x,e.y,e.z)t.VFXEffect:AddParticleUV(a,d,0,0,0,0,0,0,n,o.PackTileCenter(i,e.x,e.z))end
local function w(t,e)t.VFXEffect:ClearAllParticles(e)end
local function m(e)local o=e:GetPosition()for t=-6,6,1 do
for a=-6,6,1 do
e:SpawnTile(o+Vector3(t*4,0,a*4),1,0)end
end
end
local o={}function SpawnTileFxEntity(e)o=e
local e=SpawnPrefab("tile_fx")o={}return e
end
local function l()local a=CreateEntity()a.entity:AddTransform()a:AddTag("FX")a:AddTag("CLASSIFIED")a.entity:SetCanSleep(false)a.persists=false
if t~=nil then
t()end
if i~=nil then
i()end
local e=a.entity:AddVFXEffect()e:InitEmitters(GetTableSize(o))for t,i in ipairs(o)do
local t=i.id
local a=n and i.blue_shader or i.shader
e:SetRenderResources(t,resolvefilepath(i.texture),resolvefilepath(a))e:SetMaxNumParticles(t,10000)e:SetMaxLifetime(t,d)e:SetColourEnvelope(t,n and s or r)e:SetScaleEnvelope(t,h)e:SetUVFrameSize(t,0.25,0.25)e:SetLayer(t,c)e:SetSortOrder(t,t-#o-2)e:SetBlendMode(t,BLENDMODE.Premultiplied)e:SetKillOnEntityDeath(t,true)e:SetSpawnVectors(t,1,0,0,0,0,1)end
a.SpawnTile=f
a.ClearTile=w
a.TestSpawn=m
return a
end
return Prefab("tile_fx",l,u)