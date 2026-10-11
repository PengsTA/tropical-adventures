local assets =
{
	Asset("ANIM", "anim/swap_quackeringram.zip"),
}

local prefabs =
{
	"quackering_wave"
}

local BoatEquip = require("tools/boat_equipment_helper")

local QUACKERINGRAM_USE_COUNT = 25
local QUACKERINGRAM_DAMAGE = 100
local QUACKERINGRAM_START_BOOST = 8
local QUACKERINGRAM_HIT_BOOST = 25

local function onfinished(inst)
	if inst.windFX then
		inst.windFX:Remove()
	end

	inst:Remove()
end

local function spawnWake(pilot)
	if pilot then
		local wake = SpawnPrefab("quackering_wake")
		wake.entity:AddFollower()
		if pilot.wakeLeft == true then
			wake.idleanimation = "idle"
			pilot.wakeLeft = false
		else
			wake.idleanimation = "idle_2"
			pilot.wakeLeft = true
		end
		if wake.Follower then
			wake.Follower:FollowSymbol(pilot.GUID, "torso", 0, 0, 0)
		end

		wake.Transform:SetRotation(pilot.Transform:GetRotation())

		pilot.wakeTask = pilot:DoTaskInTime(5 * FRAMES, function() spawnWake(pilot) end)
	end
end

local function BoostPilot(inst, pilot, amount)
	if pilot ~= nil and pilot.Physics ~= nil then
		pilot.Physics:SetMotorVel(pilot.Physics:GetMotorSpeed() + amount, 0, 0)
		if pilot.components.locomotor ~= nil then
			pilot.components.locomotor:SetExternalSpeedMultiplier(pilot, "QUACKERINGRAM", 1 + amount / 10)
			if pilot.quackeringram_boosttask ~= nil then
				pilot.quackeringram_boosttask:Cancel()
			end
			pilot.quackeringram_boosttask = pilot:DoTaskInTime(0.35, function()
				if pilot:IsValid() and pilot.components.locomotor ~= nil then
					pilot.components.locomotor:RemoveExternalSpeedMultiplier(pilot, "QUACKERINGRAM")
				end
				pilot.quackeringram_boosttask = nil
			end)
		end
		pilot:PushEvent("boatramboost", { boost = amount })
	end
end

local function onPotentialRamHit(inst, target)
	local function performRamFX(inst, target)
		local quackeringRamFX = "boat_hit_fx_quackeringram"
		for i = 1, 5, 1 do
			local impactFX = SpawnPrefab(quackeringRamFX)

			local dx = math.random(-3, 3)
			local dz = math.random(-3, 3)

			local x, y, z = target.Transform:GetWorldPosition()

			impactFX.Transform:SetPosition(x + dx, y, z + dz)
		end
	end

	local hitTarget = false
	local inpocket = target.components.inventoryitem and target.components.inventoryitem:IsHeld()
	local isfriend = (target:HasTag("player")) or target:HasTag("companion") or target:HasTag("boatsw") or
		target:HasTag("ventania") or target:HasTag("lobster") or target:HasTag("ondamedia") or target:HasTag("FX")

	if not inpocket and not isfriend then
		if target.components.combat then
			hitTarget = true
			local pilot = inst.components.rammer:FindPilot()
			if pilot then
				if pilot.components.inventory then
					pilot.components.inventory.insulated = true
				end

				target.components.combat:GetAttacked(pilot, QUACKERINGRAM_DAMAGE, inst)

				if pilot.components.inventory then
					pilot.components.inventory.insulated = false
				end
			end
		elseif target.components.workable and not target:HasTag("busy") then
			hitTarget = true
			target.components.workable:Destroy(inst)
		end
	end

	if hitTarget then
		performRamFX(inst, target)

		BoostPilot(inst, inst.components.rammer:FindPilot(), QUACKERINGRAM_HIT_BOOST)

		inst.components.rammer:StartCooldown()
		inst.components.finiteuses:Use()
	end
end

local function updateWindFX(inst)
	local pilot = inst.components.rammer:FindPilot()
	if pilot == nil then
		return
	end

	local sortOrder = -1

	local facing = pilot.AnimState:GetCurrentFacing()
	inst.windFX:ChangeDirection(facing)

	if facing == 1 then
		sortOrder = 3
	end

	inst.windFX.AnimState:SetSortOrder(sortOrder)

	local p = Vector3(pilot.Transform:GetWorldPosition())
	inst.windFX.Transform:SetPosition(p.x, p.y, p.z)
end

local function DetachFromBoat(inst)
	local boat = BoatEquip.GetItemBoat(inst)
	if boat ~= nil then
		boat.AnimState:ClearOverrideSymbol(inst.symboltooverride, inst.build, inst.symbol)
	end
	BoatEquip.ClearItemBoatState(inst)
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.Transform:SetFourFaced()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	inst.AnimState:SetBuild("swap_quackeringram")
	inst.AnimState:SetBank("quackeringram")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryPhysics(inst)
	inst.build = "swap_quackeringram"
	inst.symbol = "swap_quackeringram"
	inst.symboltooverride = "swap_lantern"
	inst:AddTag("quackeringram")
	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst:AddComponent("equippable")
	inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_LAMP
	inst.components.equippable.restrictedtag = "ta_boat_equipment"

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(QUACKERINGRAM_USE_COUNT)
	inst.components.finiteuses:SetUses(QUACKERINGRAM_USE_COUNT)
	inst.components.finiteuses:SetOnFinished(onfinished)

	inst.windFX = SpawnPrefab("quackering_wave")
	inst.windFX:HideEffect()
	inst.SoundEmitter:KillSound("ram_LP")

	inst:AddComponent("rammer")
	inst.components.rammer.minSpeed = 2.5
	inst.components.rammer.onRamTarget = onPotentialRamHit
	inst.components.rammer.onUpdate = function(dt)
		if inst.components.rammer:IsActive() then
			updateWindFX(inst)
		end
	end

	inst.components.rammer.onActivate = function()
		local pilot = inst.components.rammer:FindPilot()
		if pilot == nil then
			return
		end

		local facing = pilot.AnimState:GetCurrentFacing()
		inst.windFX:ShowEffect(facing)
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/quackering_ram/impact")
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/quackering_ram/ram_LP", "ram_LP")
		BoostPilot(inst, pilot, QUACKERINGRAM_START_BOOST)
	end
	inst:ListenForEvent("onpickup", DetachFromBoat)
	inst.components.rammer.onDeactivate = function()
		inst.windFX:HideEffect()
		inst.SoundEmitter:KillSound("ram_LP")
	end

	return inst
end

return Prefab("common/inventory/quackeringram", fn, assets, prefabs)
