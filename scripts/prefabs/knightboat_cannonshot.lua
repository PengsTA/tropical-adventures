local assets =
{
	Asset("ANIM", "anim/coconut_cannon.zip"),
	Asset("ANIM", "anim/coconade_obsidian.zip"),
	Asset("ANIM", "anim/coconade.zip"),
	Asset("ANIM", "anim/swap_coconade.zip"),
}

local prefabs =
{
	"impact",
	"explode_small",
	"bombsplash",
}

local KNIGHTBOAT_RADIUS = 1.5
local KNIGHTBOAT_DAMAGE = 50
local CANNONBOAT_RADIUS = 4
local CANNONBOAT_DAMAGE = 50
local OBSIDIAN_CANNONBOAT_RADIUS = 9
local OBSIDIAN_CANNONBOAT_DAMAGE = 350
local OBSIDIAN_CANNONBOAT_BUILDINGDAMAGE = 15




local function onthrown(inst, thrower, pt, time_to_target)
	local pt = inst:GetPosition()
	inst.Physics:SetFriction(.2)
	inst.Transform:SetFourFaced()
	inst:FacePoint(pt:Get())
	inst.AnimState:PlayAnimation("throw", true)

	local smoke = SpawnPrefab("collapse_small")
	local x, y, z = inst.Transform:GetWorldPosition()
	y = y + 1

	inst.UpdateTask = inst:DoPeriodicTask(FRAMES, function()
		local pos = inst:GetPosition()
		if pos.y <= 0.3 then
			local ents = TheSim:FindEntities(pos.x, 0, pos.z, KNIGHTBOAT_RADIUS, nil, { "FX", "DECOR", "INLIMBO" })

			inst.components.explosive:OnBurnt()
			local ground = TheWorld.Map:GetTile(TheWorld.Map:GetTileCoordsAtPoint(pos.x, pos.y, pos.z))

			local x, y, z = inst.Transform:GetWorldPosition()
			if TheWorld.Map:IsOceanAtPoint(x, y, z) then
				local splash = SpawnPrefab("bombsplash")
				SpawnWavesSW(inst, 4, 360, 6, nil, nil, 2, true, true)
				splash.Transform:SetPosition(pos.x, pos.y, pos.z)
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_large")
			else
				inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
				local explode = SpawnPrefab("explode_small")
				explode.Transform:SetPosition(pos.x, pos.y, pos.z)
			end

			inst:Remove()
		end
	end)
end





local function Explode(inst)
	local prefab = "mushroombomb"
	local fx = SpawnPrefab(prefab)
	fx.Transform:SetPosition(x, y, z)
	fx.AnimState:PlayAnimation("explode")
	fx.Transform:SetScale(2.5, 2.5, 2.5)
	fx:DoTaskInTime(fx.AnimState:GetCurrentAnimationLength(), fx.Remove)
	fx.persists = false

	fx._explode:push()
	FadeOut(fx)

	if not TheNet:IsDedicated() then
		CreateGroundFX(fx)
	end

	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_explode")
	inst.SoundEmitter:KillSound("hiss")
	inst.components.explosive:OnBurnt()
end



local function onremove(inst)
	inst.SoundEmitter:KillSound("hiss")
	if inst.UpdateTask then
		inst.UpdateTask:Cancel()
	end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()


	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("coconut_cannon")
	inst.AnimState:SetBuild("coconut_cannon")
	inst.AnimState:PlayAnimation("throw", true)

	inst:AddTag("thrown")
	inst:AddTag("projectile")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("explosive")
	inst.components.explosive.explosivedamage = KNIGHTBOAT_DAMAGE
	inst.components.explosive.explosiverange = KNIGHTBOAT_RADIUS
	inst.components.explosive.skip_camera_flash = true

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(25)
	inst.components.complexprojectile:SetGravity(-25)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 3, 0))
	inst.components.complexprojectile:SetOnLaunch(onthrown)
	--    inst.components.complexprojectile:SetOnHit(onhitground)



	inst.persists = false

	inst.OnRemoveEntity = onremove

	return inst
end

local function onthrowncannon(inst, attacker, target)
	inst._fx = SpawnPrefab("torchfire")
	inst._fx.entity:SetParent(inst.entity)
	inst._fx.entity:AddFollower()
	inst._fx.Follower:FollowSymbol(inst.GUID, "coconade01", 40, -105, 0)
	inst.AnimState:PlayAnimation("throw", true)
	inst:AddTag("NOCLICK")
	inst.persists = false
	inst.SoundEmitter:KillSound("hiss")
	inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")


	local smoke = SpawnPrefab("collapse_small")
	local x, y, z = inst.Transform:GetWorldPosition()
	smoke.Transform:SetPosition(x, y, z)

	inst.Physics:SetMass(1)
	inst.Physics:SetCapsule(0.2, 0.2)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)

	inst.Transform:SetFourFaced()
	inst.AnimState:PlayAnimation("throw", true)

	local smoke = SpawnPrefab("collapse_small")
	local x, y, z = inst.Transform:GetWorldPosition()
	y = y + 1

	inst.UpdateTask = inst:DoPeriodicTask(FRAMES, function()
		local pos = inst:GetPosition()
		if pos.y <= 0.3 then
			local ents = TheSim:FindEntities(pos.x, 0, pos.z, KNIGHTBOAT_RADIUS, nil, { "FX", "DECOR", "INLIMBO" })
			inst.components.explosive:OnBurnt()
			local x, y, z = inst.Transform:GetWorldPosition()
			if TheWorld.Map:IsOceanAtPoint(x, y, z) then
				local splash = SpawnPrefab("bombsplash")
				SpawnWavesSW(inst, 4, 360, 6, nil, nil, 2, true, true)
				splash.Transform:SetPosition(pos.x, pos.y, pos.z)
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_large")
			else
				inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
				local explode = SpawnPrefab("explode_small")
				explode.Transform:SetPosition(pos.x, pos.y, pos.z)
			end

			inst:Remove()
		end
	end)
end


local function fncannon(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()


	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("coconade")
	inst.AnimState:SetBuild("coconade")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("thrown")
	inst:AddTag("projectile")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("explosive")
	inst.components.explosive.explosivedamage = CANNONBOAT_DAMAGE
	inst.components.explosive.explosiverange = CANNONBOAT_RADIUS
	inst.components.explosive.skip_camera_flash = true


	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(18)
	inst.components.complexprojectile:SetGravity(-25)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 3, 0))
	inst.components.complexprojectile:SetOnLaunch(onthrowncannon)

	inst.persists = false

	inst.OnRemoveEntity = onremove

	return inst
end

local function onthrowncannonobsidian(inst, thrower, pt, time_to_target)
	inst._fx = SpawnPrefab("torchfire")
	inst._fx.entity:SetParent(inst.entity)
	inst._fx.entity:AddFollower()
	inst._fx.Follower:FollowSymbol(inst.GUID, "coconade01", 40, -105, 0)
	inst.AnimState:PlayAnimation("throw", true)
	inst:AddTag("NOCLICK")
	inst.persists = false

	inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")
	inst.Physics:SetMass(1)
	inst.Physics:SetCapsule(0.2, 0.2)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function OnHitObsidian(inst, attacker, target)
	local pos = inst:GetPosition()
	inst.SoundEmitter:KillSound("hiss")
	inst.components.explosive:OnBurnt()

	if TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z) then
		local splash = SpawnPrefab("bombsplash")
		SpawnWavesSW(inst, 4, 360, 6, nil, nil, 2, true, true)
		splash.Transform:SetPosition(pos.x, pos.y, pos.z)
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_large")
	else
		inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
		local explode = SpawnPrefab("explode_small")
		explode.Transform:SetPosition(pos.x, pos.y, pos.z)
	end

	inst:Remove()
end

local function fnobsidian(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()


	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("coconade_obsidian")
	inst.AnimState:SetBuild("coconade_obsidian")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("thrown")
	inst:AddTag("projectile")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("explosive")
	inst.components.explosive.explosivedamage = OBSIDIAN_CANNONBOAT_DAMAGE
	inst.components.explosive.explosiverange = OBSIDIAN_CANNONBOAT_RADIUS
	inst.components.explosive.buildingdamage = OBSIDIAN_CANNONBOAT_BUILDINGDAMAGE
	inst.components.explosive.skip_camera_flash = true

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(18)
	inst.components.complexprojectile:SetGravity(-25)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 3, 0))
	inst.components.complexprojectile:SetOnLaunch(onthrowncannonobsidian)
	inst.components.complexprojectile:SetOnHit(OnHitObsidian)

	inst.persists = false

	inst.OnRemoveEntity = onremove

	return inst
end

return Prefab("knightboat_cannonshot", fn, assets, prefabs), Prefab("cannonshot", fncannon, assets, prefabs),
	Prefab("cannonshotobsidian", fnobsidian, assets, prefabs)
