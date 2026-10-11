local w="shaders/ta_interior_surface.ksh"local q="shaders/ta_interior_floor.ksh"local e=require"datadefs/interior"local k=require"tools/interior_room_extensions"local x=require"tools/interior_render"local m=require"tools/room_camera_profiles"local r=e.surface_styles
local h=e.surface_materials
local o=4
local i=1.25
local t=o*0.29296875*i
local b=math.pi/180
local T=36
local E=o
local _=1.05
local n=1e10
local g="ta_interior_surface_colour"local l="ta_interior_surface_floor_scale"local z="ta_interior_surface_wall_scale_"local d={}local v=m.GetProfileId
local u={Asset("ANIM","anim/pig_shop_doormats.zip"),Asset("SHADER",w),Asset("SHADER",q),}local c={}local p={}local y={}local s={}local function a(e)if not s[e]then
s[e]=true
table.insert(u,Asset("IMAGE",e))end
end
local function j()EnvelopeManager:AddVector2Envelope(l,{{0,{t,t}},{1,{t,t}},})end
local function f(a)local e=math.floor(a*1000+0.5)local e=z..e
if d[e]then
return e
end
d[e]=true
local t=t*a
EnvelopeManager:AddVector2Envelope(e,{{0,{t,t}},{1,{t,t}},})return e
end
local function s()local e=rawget(_G,"TUNING")return e~=nil and e.HAMROOM~=nil and e.HAMROOM.roomcamera or{}end
local function z(t,e)e=e or s()return(e.pitch or T)*b
end
local function d(t,e)e=e or s()return(e.heading or 0)*b
end
local function b(t,e)local a=z(t,e)local t=d(t,e)local e=-math.tan(a)return e*math.cos(t),1,e*math.sin(t)end
local function T(e)local t=s()local o,a,t=b(e,t)local e=e.wall_height_multiplier or _
return{wall_height=E*e,wall_height_multiplier=e,vertical_x=o,vertical_y=a,vertical_z=t,}end
for t,e in pairs(r)do
c[e.id]=e
a(e.floor)a(e.wall)end
for t,e in pairs(h.floors)do
p[e.id]=e
a(e.texture)end
for t,e in pairs(h.walls)do
y[e.id]=e
a(e.texture)end
local function d()EnvelopeManager:AddColourEnvelope(g,{{0,{1,1,1,1}},{1,{1,1,1,1}},})j()d=nil
end
local function z(e)e:ClearAllParticles(0)e:AddParticleUV(0,n,0,-0.02,0,0,0,0,0,0)end
local function j(e,h,s,t)e:ClearAllParticles(1)e:ClearAllParticles(2)local i=t.wall_height*0.5
local o=t.vertical_x*i
local a=t.vertical_y*i
local t=t.vertical_z*i
e:AddParticleUV(1,n,o,a,-s/2+t,0,0,0,0,0)e:AddParticleUV(1,n,o,a,s/2+t,0,0,0,0,0)e:AddParticleUV(2,n,-h/2+o,a,t,0,0,0,0,0)end
local function a(e)if e.VFXEffect==nil then return end
local a=e._ta_width:value()local n=e._ta_depth:value()local s=c[e._ta_style:value()]or r.player_wood
local h=p[e._ta_floor:value()]or s
local t=y[e._ta_wall:value()]or s
local r=h.texture or h.floor
if a<=0 or n<=0 then
return
end
local h,u,d=e.Transform:GetWorldPosition()x.EnsureBounds(h,d)local e=e.VFXEffect
e:SetRenderResources(0,resolvefilepath(r),resolvefilepath(q))e:SetRenderResources(1,resolvefilepath(t.texture or t.wall),resolvefilepath(w))e:SetRenderResources(2,resolvefilepath(t.texture or t.wall),resolvefilepath(w))local t=T(s)local s=t.wall_height_multiplier
e:SetScaleEnvelope(0,l)e:SetScaleEnvelope(1,f(s))e:SetScaleEnvelope(2,f(s))e:SetUVFrameSize(0,a/(o*i),n/(o*i))e:SetUVFrameSize(1,a/(o*s*i),1)e:SetUVFrameSize(2,n/(o*s*i),1)e:SetSpawnVectors(1,1,0,0,t.vertical_x,t.vertical_y,t.vertical_z)e:SetSpawnVectors(2,0,0,1,t.vertical_x,t.vertical_y,t.vertical_z)z(e)j(e,a,n,t)end
local function i(e)if d~=nil then
d()end
local e=e.entity:AddVFXEffect()e:InitEmitters(3)for t=0,2 do
e:SetMaxNumParticles(t,t==1 and 2 or 1)e:SetMaxLifetime(t,n)e:SetColourEnvelope(t,g)e:SetScaleEnvelope(t,t==0 and l or f(1))e:SetUVFrameSize(t,1,1)e:SetKillOnEntityDeath(t,true)e:EnableDepthTest(t,true)e:SetBlendMode(t,BLENDMODE.Premultiplied)end
e:SetLayer(0,LAYER_GROUND)e:SetSortOrder(0,-2)e:SetLayer(1,LAYER_GROUND)e:SetSortOrder(1,0)e:SetLayer(2,LAYER_GROUND)e:SetSortOrder(2,0)e:SetSpawnVectors(0,1,0,0,0,0,1)local o,a,t=b(nil,s())e:SetSpawnVectors(1,1,0,0,o,a,t)e:SetSpawnVectors(2,0,0,1,o,a,t)end
local function l()local e=CreateEntity()e.entity:AddTransform()e.entity:AddNetwork()e:AddTag("FX")e:AddTag("NOCLICK")e:AddTag("NOBLOCK")e:AddTag("alt_tile")e:AddTag("ta_interior_surface")if not TheNet:IsDedicated()then
i(e)end
e._ta_width=net_byte(e.GUID,"ta_house_surface.width","ta_house_surface_dirty")e._ta_depth=net_byte(e.GUID,"ta_house_surface.depth","ta_house_surface_dirty")e._ta_style=net_smallbyte(e.GUID,"ta_house_surface.style","ta_house_surface_dirty")e._ta_floor=net_smallbyte(e.GUID,"ta_house_surface.floor","ta_house_surface_dirty")e._ta_wall=net_smallbyte(e.GUID,"ta_house_surface.wall","ta_house_surface_dirty")if not TheNet:IsDedicated()then
e:ListenForEvent("ta_house_surface_dirty",a)e.OnEntityWake=a
end
e.entity:SetPristine()if not TheWorld.ismastersim then
e:DoTaskInTime(0.5,a)return e
end
function e:Configure(o,t,e)local e=type(e)=="number"and c[e]or r[e]e=e or r.player_wood
self._ta_width:set(o)self._ta_depth:set(t)self._ta_style:set(e.id)self._ta_floor:set(0)self._ta_wall:set(0)a(self)end
function e:SetFloorMaterial(e)local e=h.floors[e]if e==nil then
return false
end
self._ta_floor:set(e.id)a(self)return true
end
function e:SetWallMaterial(t)local t=h.walls[t]if t==nil then
return false
end
self._ta_wall:set(t.id)a(self)return true
end
e.OnSave=function(a,t)t.width=a._ta_width:value()t.depth=a._ta_depth:value()t.style=a._ta_style:value()t.floor_material=a._ta_floor:value()t.wall_material=a._ta_wall:value()end
e.OnLoad=function(t,e)if e~=nil then
t:Configure(e.width or 0,e.depth or 0,e.style)t._ta_floor:set(e.floor_material or 0)t._ta_wall:set(e.wall_material or 0)a(t)end
end
return e
end
local function i(e)if e._ta_extension_demolition_enabled then
return
end
e._ta_extension_demolition_enabled=true
e._ta_extension_room:set(true)e:RemoveTag("NOCLICK")e:AddTag("trader")e:AddTag("alltrader")e:AddComponent("inspectable")e:AddComponent("trader")e.components.trader.acceptnontradable=true
e.components.trader.deleteitemonaccept=false
e.components.trader:SetAbleToAcceptTest(function(t,e)return e~=nil
and e.prefab=="demolition_permit"and k.CanDemolishExtensionRoom(t)end)e.components.trader.onaccept=function(a,t,e)if k.DemolishExtensionRoom(a,t)then
e:Remove()elseif t~=nil and e.components.inventoryitem~=nil then
e.Transform:SetPosition(t.Transform:GetWorldPosition())e.components.inventoryitem:OnDropped(true)end
end
end
local function n(e)if e._ta_extension_room:value()then
e:RemoveTag("NOCLICK")e:AddTag("trader")e:AddTag("alltrader")end
end
local function h(t)if t._ta_explored:value()or AllPlayers==nil then
return
end
local o=t._ta_width:value()local a=t._ta_depth:value()if o==nil or a==nil or o<=0 or a<=0 then
return
end
local i,e,s=t.Transform:GetWorldPosition()for n,e in ipairs(AllPlayers)do
if e~=nil and e:IsValid()and e.Transform~=nil and e:HasTag("player")then
local n,h,e=e.Transform:GetWorldPosition()if math.abs(n-i)<=o*0.5 and math.abs(e-s)<=a*0.5 then
t:SetExplored()return
end
end
end
end
local function o(t)return function()local e=CreateEntity()e.entity:AddTransform()e.entity:AddPhysics()e.entity:AddNetwork()e.Physics:SetMass(0)e.Physics:SetCollisionGroup(COLLISION.ITEMS)e.Physics:ClearCollisionMask()e.Physics:SetSphere(0.75)e:AddTag("interior_center")e:AddTag("alt_tile")e:AddTag("canbuild")e:AddTag("pisohousehamlet")e:AddTag("NOBLOCK")e:AddTag("NOCLICK")if t then
e:AddTag("playerhouse_room_center")e:AddTag("casadojogador")end
e._ta_room_id=net_ushortint(e.GUID,"ta_house_center.id")e._ta_owner_id=net_ushortint(e.GUID,"ta_house_center.owner")e._ta_width=net_byte(e.GUID,"ta_house_center.width")e._ta_depth=net_byte(e.GUID,"ta_house_center.depth")e._ta_map_x=net_byte(e.GUID,"ta_house_center.map_x")e._ta_map_z=net_byte(e.GUID,"ta_house_center.map_z")e._ta_exterior_x=net_float(e.GUID,"ta_house_center.exterior_x")e._ta_exterior_z=net_float(e.GUID,"ta_house_center.exterior_z")e._ta_explored=net_bool(e.GUID,"ta_house_center.explored")e._ta_extension_room=net_bool(e.GUID,"ta_house_center.extension_room","ta_house_center_extension_room_dirty")e._ta_camera_profile=net_tinybyte(e.GUID,"ta_house_center.camera_profile")e._ta_camera_kind=net_string(e.GUID,"ta_house_center.camera_kind")e:ListenForEvent("ta_house_center_extension_room_dirty",n)e.entity:SetPristine()if not TheWorld.ismastersim then
return e
end
e:DoPeriodicTask(0.25,h)function e:Configure(e)self._ta_room_id:set(e.id)self._ta_owner_id:set(e.house_id or e.id or 0)self._ta_width:set(e.width)self._ta_depth:set(e.depth)self._ta_map_x:set((e.map_x or 0)+32)self._ta_map_z:set((e.map_z or 0)+32)self._ta_exterior_x:set(e.exterior_x or 0)self._ta_exterior_z:set(e.exterior_z or 0)self._ta_camera_profile:set(v(e.camera_profile_kind or e.room_template or e.kind))self._ta_camera_kind:set(m.GetRoomKind(e))if e.kind=="player_house_extension"then
i(self)end
end
function e:SetExplored()self._ta_explored:set(true)self:AddTag("room_explored")end
e.OnSave=function(t,a)a.room_id=t._ta_room_id:value()a.owner_id=t._ta_owner_id:value()a.width=t._ta_width:value()a.depth=t._ta_depth:value()a.map_x=t._ta_map_x:value()a.map_z=t._ta_map_z:value()a.exterior_x=t._ta_exterior_x:value()a.exterior_z=t._ta_exterior_z:value()a.camera_profile=t._ta_camera_profile:value()a.camera_kind=t._ta_camera_kind:value()a.explored=t._ta_explored:value()end
e.OnLoad=function(e,t)if t~=nil then
e._ta_room_id:set(t.room_id or 0)e._ta_owner_id:set(t.owner_id or 0)e._ta_width:set(t.width or 0)e._ta_depth:set(t.depth or 0)e._ta_map_x:set(t.map_x or 32)e._ta_map_z:set(t.map_z or 32)e._ta_exterior_x:set(t.exterior_x or 0)e._ta_exterior_z:set(t.exterior_z or 0)e._ta_camera_profile:set(t.camera_profile or 0)e._ta_camera_kind:set(t.camera_kind or"")if t.explored then
e:SetExplored()end
local t=TheWorld.components.interior_manager
if t~=nil then
t:RegisterRoomCenter(e._ta_room_id:value(),e)local t=t:GetRoom(e._ta_room_id:value())if t~=nil then
e._ta_camera_profile:set(v(t.camera_profile_kind or t.room_template or t.kind))e._ta_camera_kind:set(m.GetRoomKind(t))if t.kind=="player_house_extension"then
i(e)end
end
end
end
end
return e
end
end
local i={back=1,front=2,left=3,right=4,}local a={[1]="back",[2]="front",[3]="left",[4]="right",}local function n(e)return e
end
local function s(t,e)if e~=nil and e:HasTag("player")and e.SoundEmitter~=nil then
e.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")end
end
local function d(t,e)if e~=nil and e:HasTag("player")and t.SoundEmitter~=nil then
t.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")end
end
local function r(t,a,e)t.components.inventory:DropItem(e)t.components.teleporter:Activate(e)end
local function h()local e=CreateEntity()e.entity:AddTransform()e.entity:AddAnimState()e.entity:AddSoundEmitter()e.entity:AddNetwork()e.AnimState:SetBank("pig_shop_doormats")e.AnimState:SetBuild("pig_shop_doormats")e.AnimState:PlayAnimation("idle_old")e.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)e.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)e:AddTag("hamletteleport")e:AddTag("interior_door")e:AddTag("NOBLOCK")e._ta_target_door=net_entity(e.GUID,"ta_house_door.target")e._ta_room_direction=net_tinybyte(e.GUID,"ta_house_door.direction")function e:GetRoomDirection()return a[self._ta_room_direction:value()]end
e.entity:SetPristine()if not TheWorld.ismastersim then
return e
end
e:AddComponent("teleporter")e.components.teleporter.onActivate=s
e.components.teleporter.offset=0
e.components.teleporter.hamlet=true
e.components.teleporter.travelcameratime=0.25
e.components.teleporter.travelarrivetime=0
e:ListenForEvent("doneteleporting",d)e:AddComponent("inventory")e:AddComponent("trader")e.components.trader.acceptnontradable=true
e.components.trader.onaccept=r
e.components.trader.deleteitemonaccept=false
e:AddComponent("inspectable")function e:Link(e,t)self.components.teleporter.targetTeleporter=e
self.target_door=e
self.target_room_id=t
self._ta_target_door:set(e)end
function e:SetRoomDirection(t)t=n(t)local a=i[t]if a==nil then
return false
end
self.room_direction=t
self._ta_room_direction:set(a)for e,t in pairs(i)do
self:RemoveTag("interior_"..e.."_door")end
self:AddTag("interior_"..t.."_door")return true
end
e.OnSave=function(t,a)a.target_door=t.target_door~=nil and t.target_door.GUID or nil
a.target_room_id=t.target_room_id
a.room_direction=t.room_direction
end
e.LoadPostPass=function(a,t,e)if e~=nil and e.target_door~=nil and t[e.target_door]~=nil then
local t=t[e.target_door].entity
if t~=nil then
a:Link(t,e.target_room_id)end
end
if e~=nil and e.room_direction~=nil then
a:SetRoomDirection(e.room_direction)end
end
return e
end
return Prefab("playerhouse_room_surface",l,u),Prefab("playerhouse_room_center",o(true)),Prefab("interior_room_center",o(false)),Prefab("playerhouse_room_door",h,u)