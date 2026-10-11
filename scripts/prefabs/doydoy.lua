local EaterFilters = require("tools/eater_filters")
local assets_baby =
{

	Asset("ANIM", "anim/doydoy.zip"),
	Asset("ANIM", "anim/doydoy_baby.zip"),
	Asset("ANIM", "anim/doydoy_baby_build.zip"),
	Asset("ANIM", "anim/doydoy_teen_build.zip"),
	Asset("INV_IMAGE", "doydoy_baby"),
	Asset("INV_IMAGE", "doydoy_teen"),
}

local seabeach_amount = {
	doydoy = 0,
}

local function InitAnimationFromPosition(inst)
	if inst.components.inventoryitem and inst.components.inventoryitem.owner then
		return
	end


	local map = TheWorld.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))
	if TileGroupManager:IsOceanTile(ground) --[[ground == GROUND.OCEAN_COASTAL or
		ground == GROUND.OCEAN_COASTAL_SHORE or
		ground == GROUND.OCEAN_SWELL or
		ground == GROUND.OCEAN_ROUGH or
		ground == GROUND.OCEAN_BRINEPOOL or
		ground == GROUND.OCEAN_BRINEPOOL_SHORE or
		ground == GROUND.OCEAN_WATERLOG or
		ground == GROUND.OCEAN_HAZARDOUS]] then
		inst.onwater = true
		inst.components.inventoryitem.canbepickedup = true

		inst.sg:GoToState("idle_water")
	end
end

local function ondropped(inst)
	local map = TheWorld.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))
	if TileGroupManager:IsOceanTile(ground) --[[ground == GROUND.OCEAN_COASTAL or
		ground == GROUND.OCEAN_COASTAL_SHORE or
		ground == GROUND.OCEAN_SWELL or
		ground == GROUND.OCEAN_ROUGH or
		ground == GROUND.OCEAN_BRINEPOOL or
		ground == GROUND.OCEAN_BRINEPOOL_SHORE or
		ground == GROUND.OCEAN_WATERLOG or
		ground == GROUND.OCEAN_HAZARDOUS]] then
		if inst:HasTag("baby") then
			local bolha = SpawnPrefab("frogsplash")
			bolha.Transform:SetPosition(x, y, z)
			inst:Remove()
		else
			inst:RemoveComponent("sleeper")
			inst.components.inventoryitem.canbepickedup = true
			inst.sg:GoToState("idle_water")
			return
		end
	end

	inst:AddTag("mating")
	if not inst.components.sleeper then
		inst:AddComponent("sleeper")
	end
	inst.components.sleeper:GoToSleep()
end


local assets =
{
	Asset("ANIM", "anim/doydoy.zip"),
	Asset("ANIM", "anim/doydoy_adult_build.zip"),
}

local prefabs_baby =
{
	"doydoyfeather",
	"drumstick",
}

local prefabs =
{
	"doydoyfeather",
	"drumstick",
	"doydoy_mate_fx",
}

local seg_time = 30 --each segment of the clock is 30 seconds
local total_day_time = seg_time * 16

local DOYDOY_HEALTH = 100
local DOYDOY_WALK_SPEED = 2

local DOYDOY_BABY_HEALTH = 25
local DOYDOY_BABY_WALK_SPEED = 5
local DOYDOY_BABY_GROW_TIME = total_day_time * 2 --time to grow up

local DOYDOY_TEEN_HEALTH = 75
local DOYDOY_TEEN_WALK_SPEED = 1.5
local DOYDOY_TEEN_SCALE = 0.8
local DOYDOY_TEEN_GROW_TIME = total_day_time * 1 --time to grow up


local babyloot = { "smallmeat", "doydoyfeather" }
local teenloot = { "drumstick", "doydoyfeather", "doydoyfeather" }
local adultloot = { 'meat', 'drumstick', 'drumstick', 'doydoyfeather', 'doydoyfeather' }

local babyfoodprefs = { "SEEDS" }
local teenfoodprefs = { "SEEDS", "VEGGIE" }
local adultfoodprefs = { "MEAT", "VEGGIE", "SEEDS", "ELEMENTAL", "WOOD" }

local babysounds =
{
	eat_pre = "dontstarve_DLC002/creatures/baby_doy_doy/eat_pre",
	swallow = "dontstarve_DLC002/creatures/baby_doy_doy/swallow",
	hatch = "dontstarve_DLC002/creatures/baby_doy_doy/hatch",
	death = "dontstarve_DLC002/creatures/baby_doy_doy/death",
	jump = "dontstarve_DLC002/creatures/baby_doy_doy/jump",
	peck = "dontstarve_DLC002/creatures/teen_doy_doy/peck",
}

local teensounds =
{
	idle = "dontstarve_DLC002/creatures/teen_doy_doy/idle",
	eat_pre = "dontstarve_DLC002/creatures/teen_doy_doy/eat_pre",
	swallow = "dontstarve_DLC002/creatures/teen_doy_doy/swallow",
	hatch = "dontstarve_DLC002/creatures/teen_doy_doy/hatch",
	death = "dontstarve_DLC002/creatures/teen_doy_doy/death",
	jump = "dontstarve_DLC002/creatures/baby_doy_doy/jump",
	peck = "dontstarve_DLC002/creatures/teen_doy_doy/peck",
}

local function SetBaby(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddTag("baby")
	inst:RemoveTag("teen")

	inst.AnimState:SetBank("doydoy_baby")
	inst.AnimState:SetBuild("doydoy_baby_build")
	inst.AnimState:PlayAnimation("idle", true)

	inst.sounds = babysounds
	inst.components.combat:SetHurtSound("dontstarve/creatures/together/grass_gekko/hit")

	inst.Transform:SetScale(1, 1, 1)

	inst.components.health:SetMaxHealth(DOYDOY_BABY_HEALTH)
	inst.components.locomotor.walkspeed = DOYDOY_BABY_WALK_SPEED
	inst.components.locomotor.runspeed = DOYDOY_BABY_WALK_SPEED
	inst.components.lootdropper:SetLoot(babyloot)
	inst.components.eater.foodprefs = babyfoodprefs

	inst.components.inventoryitem:ChangeImageName("doydoy_baby")

	inst.components.named:SetName(STRINGS.NAMES["DOYDOYBABY"])
end

local function SetTeen(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddTag("teen")
	inst:RemoveTag("baby")

	inst.AnimState:SetBank("doydoy")
	inst.AnimState:SetBuild("doydoy_teen_build")
	inst.AnimState:PlayAnimation("idle", true)

	inst.sounds = teensounds
	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/baby_doy_doy/hit")

	local scale = DOYDOY_TEEN_SCALE
	inst.Transform:SetScale(scale, scale, scale)

	inst.components.health:SetMaxHealth(DOYDOY_TEEN_HEALTH)
	inst.components.locomotor.walkspeed = DOYDOY_TEEN_WALK_SPEED
	inst.components.locomotor.runspeed = DOYDOY_TEEN_WALK_SPEED
	inst.components.lootdropper:SetLoot(teenloot)
	inst.components.eater.foodprefs = teenfoodprefs

	inst.components.inventoryitem:ChangeImageName("doydoy_teen")

	inst.components.named:SetName(STRINGS.NAMES["DOYDOYTEEN"])
end

local function SetFullyGrown(inst)
	inst.needtogrowup = true
end

local function GetBabyGrowTime()
	return DOYDOY_BABY_GROW_TIME
end

local function GetTeenGrowTime()
	return DOYDOY_TEEN_GROW_TIME
end

local growth_stages =
{
	{ name = "baby",  time = GetBabyGrowTime, fn = SetBaby },
	{ name = "teen",  time = GetTeenGrowTime, fn = SetTeen },
	{ name = "grown", time = GetTeenGrowTime, fn = SetFullyGrown },
}

local function OnEntitySleep(inst)
	if inst.shouldGoAway then
		inst:Remove()
	end
end

local function OnEntityWake(inst)
	inst:ClearBufferedAction()

	if inst.needtogrowup then
		local grown = SpawnPrefab("doydoy")
		grown.Transform:SetPosition(inst.Transform:GetWorldPosition())
		grown.Transform:SetRotation(inst.Transform:GetRotation())

		inst:Remove()
	end
end

local function CanEatFn(inst, food)
	return food.prefab ~= "doydoyegg" and food.prefab ~= "doydoyegg_cooked" and food.prefab ~= "doydoyegg_cracked"
end

local function OnInventory(inst)
	inst:RemoveTag("mating")
	inst:ClearBufferedAction()
end

local function OnMate(inst, partner)

end


local function OnDead(inst)
	if seabeach_amount.doydoy < 3 then
		local x, z = require("tools/land_search").Find(TheWorld.Map, 2, inst:GetPosition())
		if x ~= nil then
			local spawner = SpawnPrefab("doydoy_spawner")
			spawner.Transform:SetPosition(x, 0, z)
		end
	end
end

local function commonfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	shadow:SetSize(1.5, 0.8)

	inst.Transform:SetFourFaced()

	MakeCharacterPhysics(inst, 50, .5)

	inst.AnimState:SetBank("doydoy")
	inst.AnimState:SetBuild("doydoy_adult_build")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("doydoy")
	inst:AddTag("companion")
	inst:AddTag("animal")

	inst:AddTag("nosteal") --不被猴子偷

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("talker")
	inst:AddComponent("inventoryitem")



	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.canbepickedup = false
	inst.components.inventoryitem.longpickup = true
	inst.components.inventoryitem:SetOnDroppedFn(ondropped)

	inst:AddComponent("health")
	inst:AddComponent("sizetweener")
	inst:AddComponent("sleeper")

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")

	inst:AddComponent("inventory")
	inst:AddComponent("entitytracker")

	inst:AddComponent("eater")
	EaterFilters.Restrict(inst.components.eater, CanEatFn)

	inst:ListenForEvent("entitysleep", OnEntitySleep)
	inst:ListenForEvent("entitywake", OnEntityWake)

	MakeSmallBurnableCharacter(inst, "swap_fire")
	MakeSmallFreezableCharacter(inst, "mossling_body")


	inst:AddComponent("locomotor")


	inst:AddComponent("combat")

	inst:ListenForEvent("death", OnDead)
	inst:ListenForEvent("gotosleep", function(inst) inst.components.inventoryitem.canbepickedup = true end)
	inst:ListenForEvent("onwakeup", function(inst)
		inst.components.inventoryitem.canbepickedup = false
		if inst.day_to_spawn then
			inst.day_to_spawn = inst.day_to_spawn - 1
		end
	end)

	--	MakeFeedablePet(inst, total_day_time, OnInventory, OnDropped)

	--数量统计
	seabeach_amount.doydoy = seabeach_amount.doydoy + 1

	inst:ListenForEvent("onremove", function(inst, data)
		if seabeach_amount.doydoy > 0 then
			seabeach_amount.doydoy = seabeach_amount.doydoy - 1
		end
	end)

	return inst
end

local function babyfn(Sim)
	local inst = commonfn(Sim)

	if not TheWorld.ismastersim then
		return inst
	end

	inst.AnimState:SetBank("doydoy_baby")
	inst.AnimState:SetBuild("doydoy_baby_build")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("baby")
	inst:AddTag("doydoy")

	inst.sounds = babysounds

	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/doy_doy/hit")
	inst:AddComponent("named")

	inst.components.health:SetMaxHealth(DOYDOY_BABY_HEALTH)
	inst.components.locomotor.walkspeed = DOYDOY_BABY_WALK_SPEED
	inst.components.locomotor.runspeed = DOYDOY_BABY_WALK_SPEED
	inst.components.lootdropper:SetLoot(babyloot)

	-- boat hopping setup
	inst.components.locomotor:SetAllowPlatformHopping(true)
	inst:AddComponent("embarker")

	inst.components.inventoryitem:ChangeImageName("doydoy_baby")

	inst.components.eater.foodprefs = babyfoodprefs

	inst:SetStateGraph("SGdoydoybaby")
	local brain = require("brains/doydoybrain")
	inst:SetBrain(brain)

	inst:AddComponent("growable")
	inst.components.growable.stages = growth_stages
	-- inst.components.growable.growonly = true
	inst.components.growable:SetStage(1)
	inst.components.growable.growoffscreen = true
	inst.components.growable:StartGrowing()

	inst:DoTaskInTime(0, InitAnimationFromPosition)

	return inst
end

local function onpreload(inst, data)
	if data then
		if data.day_to_spawn then
			inst.day_to_spawn = data.day_to_spawn
		end
		if data.hastag_mating ~= nil then
			if data.hastag_mating then inst:AddTag("mating") else inst:RemoveTag("mating") end
		end
		if data.hastag_daddy ~= nil or data.hastag_mommy ~= nil then
			inst:RemoveTag("daddy")
			inst:RemoveTag("mommy")
			if data.hastag_mommy then
				inst:AddTag("mommy")
			elseif data.hastag_daddy then
				inst:AddTag("daddy")
			end
		end
	end
end

local function onsave(inst, data)
	data.day_to_spawn = inst.day_to_spawn
	data.hastag_mating = inst:HasTag("mating")
	data.hastag_daddy = inst:HasTag("daddy")
	data.hastag_mommy = inst:HasTag("mommy")
end

local function adultfn(Sim)
	local inst = commonfn(Sim)

	inst.OnSave = onsave
	inst.OnPreLoad = onpreload

	MakeInventoryFloatable(inst, "large", 0.8, { 0.8, 0.8, 0.8 })

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddTag("mating")
	inst:AddTag("doydoy")
	inst.day_to_spawn = 0

	inst.AnimState:SetBank("doydoy")
	inst.AnimState:SetBuild("doydoy_adult_build")
	inst.AnimState:PlayAnimation("idle", true)

	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/doy_doy/hit")

	inst.components.health:SetMaxHealth(DOYDOY_HEALTH)
	inst.components.locomotor.walkspeed = DOYDOY_WALK_SPEED
	inst.components.lootdropper:SetLoot(adultloot)

	-- boat hopping setup
	inst.components.locomotor:SetAllowPlatformHopping(true)
	inst:AddComponent("embarker")

	inst.components.eater.foodprefs = adultfoodprefs

	inst:SetStateGraph("SGdoydoy")
	local brain = require("brains/doydoybrain")
	inst:SetBrain(brain)

	inst:AddComponent("named")
	if math.fmod(seabeach_amount.doydoy, 2) == 0 then
		inst:AddTag("daddy")
		inst.components.named:SetName("Doydoy(M)")
	else
		inst:AddTag("mommy")
		inst.components.named:SetName("DoyDoy(F)")
	end

	inst:DoTaskInTime(0, InitAnimationFromPosition)

	return inst
end

return Prefab("common/monsters/doydoybaby", babyfn, assets_baby, prefabs_baby),
	Prefab("common/monsters/doydoy", adultfn, assets, prefabs)
