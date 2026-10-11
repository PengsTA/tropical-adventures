local assets =
{
	Asset("ANIM", "anim/dragoon_egg.zip"),
	Asset("ANIM", "anim/meteorshadow.zip"),
}

local VOLCANO_FIRERAIN_WARNING = 2
local VOLCANO_FIRERAIN_DAMAGE = 300
local VOLCANO_FIRERAIN_LAVA_CHANCE = 0.5

local prefabs =
{
	"lavapool",
	"groundpound_fx",
	"groundpoundring_fx",
	"firerainshadow",
	"meteor_impact"
}




local function DoStep(inst)
	local x, y, z = inst.Transform:GetLocalPosition()
	local ground = TheWorld.Map:GetTile(TheWorld.Map:GetTileCoordsAtPoint(x, y, z))

	local WALKABLE_PLATFORM_TAGS = { "walkableplatform" }
	local plataforma = false
	local pos_x, pos_y, pos_z = inst.Transform:GetWorldPosition()
	local entities = TheSim:FindEntities(x, 0, z, TUNING.MAX_WALKABLE_PLATFORM_RADIUS, WALKABLE_PLATFORM_TAGS)
	for i, v in ipairs(entities) do
		local walkable_platform = v.components.walkableplatform
		if walkable_platform and walkable_platform.radius == nil then walkable_platform.radius = 4 end
		if walkable_platform ~= nil then
			local platform_x, platform_y, platform_z = v.Transform:GetWorldPosition()
			local distance_sq = VecUtil_LengthSq(x - platform_x, z - platform_z)
			if distance_sq <= walkable_platform.radius * walkable_platform.radius then plataforma = true end
		end
	end

	if math.random() < VOLCANO_FIRERAIN_LAVA_CHANCE and not plataforma then
		local lavapool = SpawnPrefab("lavapool")
		lavapool.Transform:SetPosition(x, y, z)
		if TileGroupManager:IsOceanTile(ground) --[[(ground == GROUND.OCEAN_COASTAL or
				ground == GROUND.OCEAN_COASTAL_SHORE or
				ground == GROUND.OCEAN_SWELL or
				ground == GROUND.OCEAN_ROUGH or
				ground == GROUND.OCEAN_BRINEPOOL or
				ground == GROUND.OCEAN_BRINEPOOL_SHORE or
				ground == GROUND.OCEAN_WATERLOG or
				ground == GROUND.OCEAN_HAZARDOUS)]] then
			lavapool:Remove()
			local lavapool = SpawnPrefab("bombsplash")
			lavapool.Transform:SetPosition(x, y, z)
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_large")
			SpawnWavesSW(inst, 8, 360, 6)
		end
	else
		if TileGroupManager:IsOceanTile(ground) --[[(ground == GROUND.OCEAN_COASTAL or
				ground == GROUND.OCEAN_COASTAL_SHORE or
				ground == GROUND.OCEAN_SWELL or
				ground == GROUND.OCEAN_ROUGH or
				ground == GROUND.OCEAN_BRINEPOOL or
				ground == GROUND.OCEAN_BRINEPOOL_SHORE or
				ground == GROUND.OCEAN_WATERLOG or
				ground == GROUND.OCEAN_HAZARDOUS)]] and not plataforma then
			local lavapool = SpawnPrefab("bombsplash")
			lavapool.Transform:SetPosition(x, y, z)
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/splash_large")
			SpawnWavesSW(inst, 8, 360, 6)
		else
			if not plataforma then
				local impact = SpawnPrefab("meteor_impact")
				impact.components.timer:StartTimer("remove", TUNING.TOTAL_DAY_TIME * 2)
				impact.Transform:SetPosition(x, y, z)
			end
		end
	end

	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano/volcano_rock_smash")
	inst.components.groundpounder.numRings = 2
	inst.components.groundpounder.burner = true
	inst.components.groundpounder:GroundPound()
	ShakeAllCameras(CAMERASHAKE.FULL, .35, .02, 1.25, inst, 40)
end

local function StartStep(inst)
	local shadow = SpawnPrefab("firerainshadow")
	shadow.Transform:SetPosition(inst:GetPosition():Get())
	shadow.Transform:SetRotation(math.random(0, 360)) --(GetRotation(inst))
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")
	inst:Hide()
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (5 * FRAMES), function(inst) inst:DoStep() end)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (14 * FRAMES), function(inst)
		inst:Show()
		inst.AnimState:PlayAnimation("idle")
		inst:ListenForEvent("animover", function(inst) inst:Remove() end)
	end)
end

local function firerainfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	trans:SetFourFaced()

	anim:SetBank("meteor")
	anim:SetBuild("draegg")
	anim:PlayAnimation("idle")

	inst:AddTag("FX")
	inst.persists = false
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("groundpounder")
	inst.components.groundpounder.numRings = 2
	inst.components.groundpounder.ringDelay = 0.1
	inst.components.groundpounder.initialRadius = 1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.pointDensity = .25
	inst.components.groundpounder.damageRings = 1
	inst.components.groundpounder.destructionRings = 1
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.burner = true
	inst.components.groundpounder.ring_fx_scale = 0.75

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(VOLCANO_FIRERAIN_DAMAGE)

	inst.DoStep = DoStep
	inst.StartStep = StartStep

	inst:Hide()

	return inst
end

local easing = require("easing")
local function LerpIn(inst)
	local s = easing.inExpo(inst:GetTimeAlive(), 1, 1 - inst.StartingScale, inst.TimeToImpact)

	inst.Transform:SetScale(s, s, s)
	if s >= inst.StartingScale then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function OnRemove(inst)
	if inst.sizeTask then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function Impact(inst)
	inst:Remove()
end

local function shadowfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()

	anim:SetBank("meteor_shadow")
	anim:SetBuild("meteorshadow1")
	anim:PlayAnimation("idle")
	anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	anim:SetLayer(LAYER_BACKGROUND)
	anim:SetSortOrder(3)
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst.persists = false
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	local s = 2
	inst.StartingScale = s
	inst.Transform:SetScale(s, s, s)
	inst.TimeToImpact = VOLCANO_FIRERAIN_WARNING

	--	inst:AddComponent("colourtweener")
	--	inst.AnimState:SetMultColour(0,0,0,0)
	--	inst.components.colourtweener:StartTween({0,0,0,1}, inst.TimeToImpact, Impact)

	inst.OnRemoveEntity = OnRemove

	inst.sizeTask = inst:DoPeriodicTask(FRAMES, LerpIn)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING + 2 * FRAMES, inst.Remove)

	return inst
end

return Prefab("common/shipwrecked/firerain", firerainfn, assets, prefabs),
	Prefab("common/shipwrecked/firerainshadow", shadowfn, assets, prefabs)
