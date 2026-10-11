local i=2*1e9
local t=0
local s="tropical_floodwater_colour"local n="tropical_floodwater_scale"local h=require("tools/water_render_masks")local d={Asset("IMAGE","levels/textures/shader_water_nomip/water_shallow.tex"),Asset("SHADER","shaders/tile_particle_flood.ksh"),}local function o()EnvelopeManager:AddColourEnvelope(s,{{0,{.87,.87,.87,.5}},{1,{.87,.87,.87,.5}},})EnvelopeManager:AddVector2Envelope(n,{{0,{1.171875*TILE_SCALE,1.171875*TILE_SCALE}},{1,{1.171875*TILE_SCALE,1.171875*TILE_SCALE}},})o=nil
end
local function l(t,e,n,o,s,a)t.Transform:SetPosition(e.x,e.y,e.z)t.VFXEffect:AddParticleUV(s,i,0,0,0,0,0,0,n+(a or 0)*1024,h.PackTileCenter(o,e.x,e.z))end
local function h(t,e)t.VFXEffect:ClearAllParticles(e)end
local function r()local a=CreateEntity()a.entity:AddTransform()a:AddTag("FX")a:AddTag("CLASSIFIED")a.entity:SetCanSleep(false)a.persists=false
if o~=nil then
o()end
local e=a.entity:AddVFXEffect()e:InitEmitters(1)e:SetRenderResources(t,resolvefilepath("levels/textures/shader_water_nomip/water_shallow.tex"),resolvefilepath("shaders/tile_particle_flood.ksh"))e:SetMaxNumParticles(t,10000)e:SetMaxLifetime(t,i)e:SetColourEnvelope(t,s)e:SetScaleEnvelope(t,n)e:SetUVFrameSize(t,.25,.25)e:SetLayer(t,LAYER_BACKGROUND)e:SetSortOrder(t,TUNING.ocean_style=="tropical"and-2 or-3)e:SetBlendMode(t,BLENDMODE.Premultiplied)e:SetKillOnEntityDeath(t,true)e:SetSpawnVectors(t,1,0,0,0,0,1)a.SpawnTile=l
a.ClearTile=h
return a
end
return Prefab("floodwater_fx",r,d)