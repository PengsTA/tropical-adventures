require "brains/snakebrain"
require "stategraphs/SGsnake2"

local SNAKE_SPEED = 3
local SNAKE_TARGET_DIST = 8
local SNAKE_KEEP_TARGET_DIST = 15
local SNAKE_HEALTH = 100
local SNAKE_DAMAGE = 10
local SNAKE_ATTACK_PERIOD = 3

local assets =
{
	Asset("ANIM", "anim/snake_build.zip"),
	Asset("ANIM", "anim/snake_basic.zip"),
	Asset("ANIM", "anim/snake_water.zip"),
	Asset("ANIM", "anim/snake_scaly_build.zip"),
}

local prefabs =
{
	"monstermeat",
	"snakeskin",
	"snakeoil",
}

local sounds = {
	idle = "dontstarve_DLC002/creatures/snake/idle",
	pre_attack = "dontstarve_DLC002/creatures/snake/pre-attack",
	attack = "dontstarve_DLC002/creatures/snake/attack",
	hurt = "dontstarve_DLC002/creatures/snake/hurt",
	taunt = "dontstarve_DLC002/creatures/snake/taunt",
	death = "dontstarve_DLC002/creatures/snake/death",
	sleep = "dontstarve_DLC002/creatures/snake/sleep",
	move = "dontstarve_DLC002/creatures/snake/move",
}

local SHARE_TARGET_DIST = 30

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function retargetfn(inst)
	local dist = SNAKE_TARGET_DIST
	local notags = { "FX", "NOCLICK", "INLIMBO", "wall", "snake", "structure", "ox", "hippopotamoose" }
	return FindEntity(inst, dist, function(guy)
		return inst.components.combat:CanTarget(guy)
	end, nil, notags)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and
		inst:GetDistanceSqToInst(target) <= (SNAKE_KEEP_TARGET_DIST * SNAKE_KEEP_TARGET_DIST) and
		not target:HasTag("aquatic")
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
		function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
		function(dude) return dude:HasTag("snake") and not dude.components.health:IsDead() end, 5)
end

local function DoReturn(inst)
	if inst.components.homeseeker then
		require("tools/home_return").ReturnOffscreen(inst)
	end
end

local function SanityAura(inst, observer)
	if observer.prefab == "webber" then
		return 0
	end
	return -TUNING.SANITYAURA_SMALL
end

local function OnWaterChange(inst, onwater)
	if inst.components.health and inst.components.health:IsDead() then
		return
	end
	if onwater then
		inst.onwater = true
		if inst.sg and not inst.sg:HasStateTag("submerged") then
			inst.sg:GoToState("submerge")
		end
		inst.DynamicShadow:Enable(false)
	else
		if inst.onwater then
			if inst.sg then
				inst.sg:GoToState("emerge")
			end
		end
		inst.onwater = false
		inst.DynamicShadow:Enable(true)
	end
end

local function OnEntityWake(inst)
	if inst.components.tiletracker then
		inst.components.tiletracker:Start()
	end
end

local function OnEntitySleep(inst)
	if inst.components.tiletracker then
		inst.components.tiletracker:Stop()
	end
	if TheWorld.state.isday then
		DoReturn(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("snake")
	inst:AddTag("amphibious_snake")
	inst:AddTag("animal")
	inst:AddTag("canbetrapped")

	MakeCharacterPhysics(inst, 1, .5)

	inst.AnimState:SetBank("snake")
	inst.AnimState:SetBuild("snake_scaly_build")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

	inst.sounds = sounds

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = SNAKE_SPEED

	inst:AddComponent("follower")

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
	inst.components.eater:SetCanEatHorrible()
	inst.components.eater.strongstomach = true

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(SNAKE_HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(SNAKE_DAMAGE)
	inst.components.combat:SetAttackPeriod(SNAKE_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/snake/hurt")
	inst.components.combat:SetRange(2, 3)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddRandomLoot("monstermeat", 1.00)
	inst.components.lootdropper:AddRandomLoot("snakeskin", 0.50)
	inst.components.lootdropper:AddRandomLoot("snakeoil", 0.01)
	inst.components.lootdropper.numrandomloot = math.random(0, 1)

	inst:AddComponent("inspectable")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = SanityAura

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetNocturnal(true)
	inst:ListenForEvent("newcombattarget", OnNewTarget)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

	MakeMediumFreezableCharacter(inst, "hound_body")
	MakeMediumBurnableCharacter(inst, "hound_body")

	inst:AddComponent("tiletracker")
	inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

	inst:SetStateGraph("SGsnake2")
	inst:SetBrain(require("brains/snakebrain"))

	return inst
end

return Prefab("snake_amphibious", fn, assets, prefabs)
