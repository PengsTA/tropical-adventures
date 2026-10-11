local o=require("tools/water_render_config")local h=require("tools/water_render_masks")local a=o.emitters
local t=(PLAYER_CAMERA_SEE_DISTANCE/TILE_SCALE)+5
local s={{0,0},{1,0},{0,1},{-1,0},{0,-1},{1,1},{-1,1},{-1,-1},{1,-1},}local e=Class(function(e,t)e.inst=t
e.falloffs={}e.tiletest=SpawnTileFxEntity(a)e.inst.components.tilechangewatcher:ListenToUpdate(function()e:UpdateTiles()end)end)function e:ClearTiles()for t,e in ipairs(a)do
self.tiletest:ClearTile(e.id)end
self.tiles={}end
function e:SpawnTiles()for t,e in ipairs(a)do
local t=e.id
for a,e in ipairs(self.tiles[t]or{})do
self.tiletest:SpawnTile(e.position,e.overhang_type,e.neighbor_type,t)end
self.tiletest.VFXEffect:FastForward(t,GetTime())end
end
function e:OnRemoveEntity()self:ClearTiles()self.tiletest:Remove()end
e.OnRemoveFromEntity=e.OnRemoveEntity
function e:UpdateTiles()self:ClearTiles()if self.inst:IsOutsideWorld()then return end
local e=self.inst.components.tilechangewatcher
local n=e.last_tile_center
for i=-t,t do
for t=-t,t do
local t=n+Vector3(i*TILE_SCALE,0,t*TILE_SCALE)local n,i={},{}for s,a in ipairs(s)do
local e=e:CachedTileAtPoint(t.x+a[1]*TILE_SCALE,0,t.z+a[2]*TILE_SCALE)local e=o.GetRenderTileType(e)local e=o.tiles[e]if e~=nil then
n[s]=e.id
i[e.id]=true
end
end
for a,e in ipairs(a)do
local e=e.id
if i[e]then
local a,o=h.Build(n,e)self.tiles[e]=self.tiles[e]or{}self.tiles[e][#self.tiles[e]+1]={position=t,overhang_type=a,neighbor_type=o,}end
end
end
end
self:SpawnTiles()end
return e