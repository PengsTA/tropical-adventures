local assets =
{
	Asset("ANIM", "anim/frog.zip"),
	Asset("ANIM", "anim/frog_water.zip"),
	Asset("ANIM", "anim/frog_treefrog_build.zip"),
	Asset("SOUND", "sound/frog.fsb"),
}

local prefabs =
{
	"froglegs",
	"splash",
	"venomgland",
	"froglegs_poison",
}

local brain = require "brains/frog2brain"

local sounds = {
	base = {
		grunt = "dontstarve_DLC003/creatures/enemy/frog_poison/grunt",
		walk = "dontstarve/frog/walk",
		spit = "dontstarve_DLC003/creatures/enemy/frog_poison/attack_spit",
		voice = "dontstarve_DLC003/creatures/enemy/frog_poison/attack_spit",
		splat = "dontstarve/frog/splat",
		die = "dontstarve_DLC003/creatures/enemy/frog_poison/death",
		wake = "dontstarve/frog/wake",
	},
}

local function OnWaterChange(inst, onwater)
	if onwater then
		inst.onwater = true
		inst.sg:GoToState("submerge")
		inst.DynamicShadow:Enable(false)
		inst.components.locomotor.walkspeed = 3
	else
		inst.onwater = false
		inst.sg:GoToState("emerge")
		inst.DynamicShadow:Enable(true)
		inst.components.locomotor.walkspeed = 4
	end
end

local function retargetfn(inst)
	if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() then
		local notags = { "FX", "NOCLICK", "INLIMBO" }
		return FindEntity(inst, TUNING.FROG_TARGET_DIST, function(guy)
			if guy.components.combat and guy.components.health and not guy.components.health:IsDead() and not guy:HasTag("hippopotamoose") and not guy:HasTag("glowfly") then
				return guy.components.inventory ~= nil or guy:HasTag("insect")
			end
		end, nil, notags)
	end
end

local function ShouldSleep(inst)
	return false -- frogs either go to their home, or just sit on the ground.
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, 30,
		function(dude) return dude:HasTag("frog") and not dude.components.health:IsDead() end, 5)
end

local function OnGoingHome(inst)
	local fx = SpawnPrefab("splash")
	local pos = inst:GetPosition()
	fx.Transform:SetPosition(pos.x, pos.y, pos.z)

	--local splash = PlayFX(Vector3(inst.Transform:GetWorldPosition() ), "splash", "splash", "splash")
	inst.SoundEmitter:PlaySound("dontstarve/frog/splash")
end

local function OnEntityWake(inst)
	inst.components.tiletracker:Start()
end

local function OnEntitySleep(inst)
	inst.components.tiletracker:Stop()
end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	local physics = inst.entity:AddPhysics()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	shadow:SetSize(1.5, .75)
	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("frog")
	inst.AnimState:SetBuild("frog_treefrog_build")
	inst.AnimState:PlayAnimation("idle")

	MakeCharacterPhysics(inst, 1, .3)
	inst.Physics:ClearCollidesWith(COLLISION.BOAT_LIMITS)

	inst:AddTag("animal")
	inst:AddTag("prey")
	inst:AddTag("smallcreature")
	inst:AddTag("frog")
	inst:AddTag("canbetrapped")
	inst:AddTag("duskok")
	inst:AddTag("eatsbait")
	inst:AddTag("scarytoprey")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = 4
	inst.components.locomotor.runspeed = 8
	inst.components.locomotor.pathcaps = { allowocean = true }

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetSleepTest(ShouldSleep)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.FROG_HEALTH)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddChanceLoot("froglegs_poison", 1)
	--inst.components.lootdropper:AddChanceLoot("venomgland", 0.5)

	inst:AddComponent("eater")
	inst:AddComponent("tiletracker")
	inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.FROG_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.FROG_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)

	inst.components.combat.onhitotherfn = function(inst, other, damage) inst.components.thief:StealItem(other) end

	inst:AddComponent("thief")
	--inst:AddComponent("poisonous")
	MakeTinyFreezableCharacter(inst, "frogsack")
	MakeSmallBurnableCharacter(inst, "frogsack")

	inst.sounds = sounds.base

	inst:AddComponent("knownlocations")
	inst:AddComponent("inspectable")


	inst:SetBrain(brain)
	inst:SetStateGraph("SGfrog2")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("goinghome", OnGoingHome)

	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

	return inst
end

return Prefab("frog_poison", fn, assets, prefabs)
