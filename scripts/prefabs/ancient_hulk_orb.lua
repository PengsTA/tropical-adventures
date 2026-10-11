local assets =
{
     Asset("ANIM", "anim/metal_hulk_projectile.zip"), 
}

local ANCIENT_HULK_DAMAGE = 100
local ANCIENT_HULK_SPEED = 60

local DAMAGE_CANT_TAGS = { "DECOR", "INLIMBO", "laser" }
local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }

local function setfires(x, y, z, rad)
     for _,v in ipairs(TheSim:FindEntities(x, y, z, rad, nil, DAMAGE_CANT_TAGS)) do 
          if v.components.burnable then
               local vx, vy, vz = v.Transform:GetWorldPosition()
               if not TheWorld.Map:IsOceanAtPoint(vx, vy, vz, false) then
                    v.components.burnable:Ignite()
               end
          end
          -- TODO: cook raw food?
     end
end

local function DoDamage(inst, ent, rad)
     local x, y, z = inst.Transform:GetWorldPosition()
     local ents = ent and {ent} or TheSim:FindEntities(x, 0, z, rad, nil, DAMAGE_CANT_TAGS, DAMAGE_ONEOF_TAGS)
     local rad = rad or 0
     local targets = {}
     local attacker = inst.components.projectile and inst.components.projectile.attacker or 
                      inst.components.complexprojectile and inst.components.complexprojectile.attacker

     for _,v in ipairs(ents) do
          if not targets[v] and v:IsValid() and not v:IsInLimbo() and not v:HasTag("laser_immune") and 
               not (v.components.health and v.components.health:IsDead()) and attacker then 

               local vx, vy, vz = v.Transform:GetWorldPosition()
               local range = rad + v:GetPhysicsRadius(0)
               if ent or v:GetDistanceSqToPoint(Vector3(x,y,z)) < range * range then
                    local isworkable = false
                    if v.components.workable then
                         local work_action = v.components.workable:GetWorkAction()
                         isworkable = ( not work_action and v:HasTag("NPC_workable")) or
                                      ( v.components.workable:CanBeWorked() and
                                      ( work_action == ACTIONS.CHOP or
                                        work_action == ACTIONS.HAMMER or
                                        work_action == ACTIONS.MINE or
                                      ( work_action == ACTIONS.DIG and
                                        not v.components.spawner and
                                        not v.components.childspawner )))
                    end
                    
                    if isworkable then
                         targets[v] = true
                         v:DoTaskInTime(0, function() v.components.workable:Destroy(attacker) end)
                    elseif v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
                         targets[v] = true
                         local num = v.components.pickable.numtoharvest or 1
                         local product = v.components.pickable.product
                         v:DoTaskInTime(0, function() 
                              v.components.pickable:Pick()
                              if product and num > 0 then
                                   for i = 1, num do
                                        local loot = SpawnPrefab(product)
                                        loot.Transform:SetPosition(vx, 0, vz)
                                        targets[loot] = true
                                        Launch(loot, attacker, 0.2)
                                   end
                              end
                         end)
                    elseif v.components.health then
                         targets[v] = true
                         if v.components.combat and attacker.components.combat and attacker.components.combat:CanTarget(v) then
                              local dmg = inst.components.combat.defaultdamage
                              v.components.combat:GetAttacked(attacker, dmg)
                         end
                         if v:IsValid() and not v.components.health:IsDead() then
                              if v.components.freezable then
                                   if v.components.freezable:IsFrozen() then
                                        v.components.freezable:Unfreeze()
                                   elseif v.components.freezable.coldness > 0 then
                                        v.components.freezable:AddColdness(-2)
                                   end
                              end
                              if v.components.temperature then
                                   local maxtemp = v.components.temperature:GetMax()
                                   local curtemp = v.components.temperature:GetCurrent()
                                   if maxtemp > curtemp then
                                        v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                                   end
                              end
                         end
                    end

                    if v:IsValid() then
                         SpawnPrefab("laserhit"):SetTarget(v)
                    end
               end
          end
     end
end

local EXPLODE_CANT_TAGS = {"INLIMBO", "outofreach", "DECOR"}

local function launch_away(inst, position)
     if inst.Physics == nil then
          return
     end
     local x, y, z = inst.Transform:GetWorldPosition()
     inst.Physics:Teleport(x, y + 0.1, z)
     local px, py, pz = position:Get()
     local angle = (180 - inst:GetAngleToPoint(px, py, pz)) * DEGREES
     inst.Physics:SetVel(8 * math.cos(angle), 12, 8 * math.sin(angle))
end

local function WaterExplode(position, rad)
     local x, y, z = position:Get()
     local ent = TheSim:FindEntities(x, y, z, rad, nil, EXPLODE_CANT_TAGS)
     for _,v in ipairs(ent) do
          if v:IsOnOcean(false) and v.components.oceanfishable then
               local projectile = v.components.oceanfishable:MakeProjectile()
               local ae_cp = projectile.components.complexprojectile
               if ae_cp then
                    ae_cp:SetHorizontalSpeed(16)
                    ae_cp:SetGravity(-30)
                    ae_cp:SetLaunchOffset(Vector3(0, 0.5, 0))
                    ae_cp:SetTargetOffset(Vector3(0, 0.5, 0))

                    local pos = v:GetPosition()
                    local launch_position = pos + (pos - position):Normalize() * 8
                    ae_cp:Launch(launch_position, projectile, ae_cp.owningweapon)
               else
                    launch_away(projectile, position)
               end
          end
     end
end

local function OnHit(inst) 
     ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.4, 0.03, 1.5, inst, TUNING.SHAKE_DIST)
     inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")
     inst.AnimState:PlayAnimation("impact")

     local endtime = inst.AnimState:GetCurrentAnimationLength()
     inst:DoTaskInTime(endtime, inst.Remove)

     local x, y, z = inst.Transform:GetWorldPosition()
     local radius = 3.5
     inst:DoTaskInTime(0.2, function() DoDamage(inst, nil, radius) end)
     inst:DoTaskInTime(0.3, function() setfires(x, y, z, radius) end)

     if TheWorld.Map:IsOceanAtPoint(x, y, z, false) then
          local fx = SpawnPrefab("crab_king_waterspout")
          fx.Transform:SetPosition(x, y, z)
          -- Wave
          local pos = Vector3(x, y, z)
          local rad = 0
          local num = 10
          local speed = 6
          local idle = 1.5
          inst:DoTaskInTime(0.1, function() 
               SpawnAttackWaves(pos, nil, rad, num, 360, speed, "rogue_wave", idle, nil)
               WaterExplode(pos, radius)
          end)
     else
          inst:DoTaskInTime(0, function() 
               local ring = SpawnPrefab("laser_ring")
               ring.Transform:SetPosition(x, y, z) 
          end)
     end
end

local function orbfn()
     local inst = CreateEntity()
     inst.entity:AddTransform()
     inst.entity:AddAnimState()
     inst.entity:AddSoundEmitter()
     inst.entity:AddLight()
     inst.entity:AddNetwork()

     MakeProjectilePhysics(inst, 75, 0.5)
     
     inst.Light:SetIntensity(.6)
     inst.Light:SetRadius(3)
     inst.Light:SetFalloff(1)
     inst.Light:SetColour(1, 0.3, 0.3)
     inst.Light:Enable(true)

     inst.AnimState:SetBank("metal_hulk_projectile")
     inst.AnimState:SetBuild("metal_hulk_projectile")
     inst.AnimState:PlayAnimation("spin_loop", true)

     inst:AddTag("projectile")
     inst:AddTag("laser")

     inst.entity:SetPristine()

     if not TheWorld.ismastersim then
          return inst
     end

     inst.persists = false

     inst:AddComponent("complexprojectile")
     inst.components.complexprojectile:SetOnHit(OnHit)
     inst.components.complexprojectile:SetHorizontalSpeed(ANCIENT_HULK_SPEED)
     inst.components.complexprojectile:SetGravity(-1)
     inst.components.complexprojectile.usehigharc = false

     inst:AddComponent("combat")
     inst.components.combat:SetDefaultDamage(ANCIENT_HULK_DAMAGE)

     return inst
end

local function OnCollidesmall(inst, ent)
     DoDamage(inst, ent)

     if TUNING.SMALL_LASER_BURN then
          local x, y, z = ent.Transform:GetWorldPosition()
          ent:DoTaskInTime(0.2, function() setfires(x, y, z, 1) end)
     end

     local explosion = SpawnPrefab("laser_explosion")
     explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())  
     explosion.Transform:SetScale(0.4,0.4,0.4)

     inst:Remove()
end

local function orbsmallfn()
     local inst = CreateEntity()
     inst.entity:AddTransform()
     inst.entity:AddAnimState()
     inst.entity:AddSoundEmitter()
     inst.entity:AddLight()
     inst.entity:AddNetwork()

     MakeCharacterPhysics(inst, 1, 0.5)
     inst.Physics:SetCollisionCallback(OnCollidesmall)
     inst.Physics:ClearCollisionMask()
     inst.Physics:CollidesWith(COLLISION.OBSTACLES)
     inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
     inst.Physics:CollidesWith(COLLISION.CHARACTERS)
     inst.Physics:CollidesWith(COLLISION.GIANTS)

     inst.Light:SetIntensity(.6)
     inst.Light:SetRadius(3)
     inst.Light:SetFalloff(1)
     inst.Light:SetColour(1, 0.3, 0.3)
     inst.Light:Enable(true)

     inst.Transform:SetScale(0.5,0.5,0.5)

     inst.AnimState:SetBank("metal_hulk_projectile")
     inst.AnimState:SetBuild("metal_hulk_projectile")
     inst.AnimState:PlayAnimation("spin_loop", true)

     inst:AddTag("projectile")
     inst:AddTag("laser")

     inst.entity:SetPristine()

     if not TheWorld.ismastersim then
          return inst
     end

     inst.persists = false
     inst.collide = OnCollidesmall

     inst:AddComponent("projectile")
     inst.components.projectile:SetSpeed(ANCIENT_HULK_SPEED)
     inst.components.projectile:SetHoming(false)
     inst.components.projectile.hitdist = 0.5

     inst:AddComponent("combat")
     inst.components.combat:SetDefaultDamage(ANCIENT_HULK_DAMAGE/2)
     inst.components.combat.playerdamagepercent = 0.5

     inst:DoTaskInTime(2, inst.Remove)

     return inst
end

return Prefab("ancient_hulk_orb", orbfn, assets),
       Prefab("ancient_hulk_orb_small", orbsmallfn, assets)
