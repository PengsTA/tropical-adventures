require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/sea_yard.zip"),
	Asset("MINIMAP_IMAGE", "sea_yard"),
	Asset("ANIM", "anim/sea_yard_meter.zip"),
}

local prefabs =
{
	"collapse_small",
	"sea_yard_arms_fx"
}

local loot =
{
	"limestone",
	"limestone",
	"limestone",
	"tar",
	"tar",
	"tar",
	"log",
	"log",
}

local SEA_YARD_MAX_FUEL_TIME = 30 * 16
local SEA_YARD_REPAIR_RANGE = 5
local SEA_YARD_REPAIR_PER_SECOND = .7

local function onturnon(inst)
	if not inst:HasTag("burnt") then
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seagull/chirp_seagull")
		inst:DoTaskInTime(18 / 30,
			function() inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seagull/chirp_seagull") end)
		inst.AnimState:PlayAnimation("enter")
		inst.AnimState:PushAnimation("idle", true)
	end
end

local function onturnoff(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PushAnimation("idle", true)
		--inst.SoundEmitter:KillSound("idlesound")
	end
end

local function NeedsRepair(target)
	return target ~= nil
		and target:IsValid()
		and target.components.boathealth ~= nil
		and not target.components.boathealth:IsFull()
end

local function FindRepairTarget(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local closest, closest_dist_sq = nil, math.huge
	for _, boat in ipairs(TheSim:FindEntities(x, y, z, SEA_YARD_REPAIR_RANGE, { "boatsw" }, { "INLIMBO" })) do
		if NeedsRepair(boat) then
			local dist_sq = inst:GetDistanceSqToInst(boat)
			if dist_sq < closest_dist_sq then
				closest = boat
				closest_dist_sq = dist_sq
			end
		end
	end
	return closest
end

local function StopRepairing(inst)
	local was_repairing = inst.repair_target ~= nil or inst.armsfx ~= nil or inst.components.fueled.consuming
	inst.repair_target = nil
	inst.components.fueled:StopConsuming()
	if inst.armsfx ~= nil then
		if inst.armsfx:IsValid() then
			inst.armsfx.stopfx(inst.armsfx)
		end
		inst.armsfx = nil
	end
	if was_repairing then
		onturnoff(inst)
	end
end

local function StartRepairing(inst, boat)
	inst.repair_target = boat
	inst.components.fueled:StartConsuming()
	onturnon(inst)

	if inst.armsfx == nil then
		local arms = SpawnPrefab("sea_yard_arms_fx")
		if arms ~= nil then
			arms.entity:SetParent(boat.entity)
			arms.Transform:SetPosition(0, 0, 0)
			arms.AnimState:SetFinalOffset(5)
			inst.armsfx = arms
		end
	end
end

local function UpdateRepairing(inst)
	if inst.components.fueled:IsEmpty() then
		StopRepairing(inst)
		return
	end

	local target = inst.repair_target
	if not NeedsRepair(target) or inst:GetDistanceSqToInst(target) > SEA_YARD_REPAIR_RANGE * SEA_YARD_REPAIR_RANGE then
		local next_target = FindRepairTarget(inst)
		if next_target == nil then
			StopRepairing(inst)
			return
		end
		if next_target ~= target then
			StopRepairing(inst)
			StartRepairing(inst, next_target)
		end
		target = next_target
	end

	target.components.boathealth:DoDelta(SEA_YARD_REPAIR_PER_SECOND, "repair", inst)
end

local function onhammered(inst, worker)
	StopRepairing(inst)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")

		inst.AnimState:PushAnimation("idle", true)

		inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seagull/chirp_seagull")
	end
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or inst:HasTag("fire") then
		data.burnt = true
	end
end

local function onload(inst, data)
	if data and data.burnt then
		inst.components.burnable.onburnt(inst)
	end
end



local function OnFuelSectionChange(old, new, inst)
	local fuelAnim = 0
	if inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.01 then
		fuelAnim = "0"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.1 then
		fuelAnim = "1"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.2 then
		fuelAnim = "2"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.3 then
		fuelAnim = "3"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.4 then
		fuelAnim = "4"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.5 then
		fuelAnim = "5"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.6 then
		fuelAnim = "6"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.7 then
		fuelAnim = "7"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.8 then
		fuelAnim = "8"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.9 then
		fuelAnim = "9"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 1 then
		fuelAnim = "10"
	end
	if inst then inst.AnimState:OverrideSymbol("swap_meter", "sea_yard_meter", fuelAnim) end
end

local function OnFuelEmpty(inst)
	StopRepairing(inst)
end

local function ontakefuelfn(inst)
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
	local fuelAnim = 0
	if inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.01 then
		fuelAnim = "0"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.1 then
		fuelAnim = "1"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.2 then
		fuelAnim = "2"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.3 then
		fuelAnim = "3"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.4 then
		fuelAnim = "4"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.5 then
		fuelAnim = "5"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.6 then
		fuelAnim = "6"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.7 then
		fuelAnim = "7"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.8 then
		fuelAnim = "8"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 0.9 then
		fuelAnim = "9"
	elseif inst and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= 1 then
		fuelAnim = "10"
	end
	if inst then inst.AnimState:OverrideSymbol("swap_meter", "sea_yard_meter", fuelAnim) end
end

local function onplaced(inst)
	inst:RemoveEventCallback("animover", onplaced)
end

local function getstatus(inst, viewer)
	if inst.components.fueled and inst.components.fueled.currentfuel <= 0 then
		return "OFF"
	elseif inst.components.fueled and (inst.components.fueled.currentfuel / inst.components.fueled.maxfuel) <= .25 then
		return "LOWFUEL"
	else
		return "ON"
	end
end


local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local minimap = inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()
	minimap:SetPriority(5)
	minimap:SetIcon("sea_yard.tex")

	inst:SetPhysicsRadiusOverride(1.5)
	MakeWaterObstaclePhysics(inst, 0.4, 2, 1.25)

	anim:SetBank("sea_yard")
	anim:SetBuild("sea_yard")
	anim:PlayAnimation("idle", true)

	inst:AddTag("structure")
	inst:AddTag("nowaves")
	inst:AddTag("seayard")
	inst:AddTag("ignorewalkableplatforms")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end


	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("fueled")
	inst.components.fueled:SetDepletedFn(OnFuelEmpty)
	inst.components.fueled.accepting = true
	inst.components.fueled:SetSections(10)
	inst.components.fueled.ontakefuelfn = ontakefuelfn
	inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
	inst.components.fueled:InitializeFuelLevel(SEA_YARD_MAX_FUEL_TIME)
	inst.components.fueled.bonusmult = 5
	-- inst.components.fueled.fueltype = "TAR"

	--	inst:AddComponent("machine")
	--	inst.components.machine.turnonfn = StartRepairing
	--	inst.components.machine.turnofffn = StopRepairing
	--	inst.components.machine.caninteractfn = CanInteract
	--	inst.components.machine.cooldowntime = 0.5

	inst.AnimState:OverrideSymbol("swap_meter", "sea_yard_meter", 10)


	inst:ListenForEvent("onbuilt", function()
		anim:PlayAnimation("place")
		anim:PushAnimation("idle", true)
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/shipyard/craft")

		inst:ListenForEvent("animover", onplaced)
	end)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(loot)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
	MakeSnowCovered(inst, .01)

	inst.OnSave = onsave
	inst.OnLoad = onload
	inst.OnRemoveEntity = StopRepairing
	inst:DoTaskInTime(0, ontakefuelfn)
	inst:DoPeriodicTask(1, UpdateRepairing)

	return inst
end

--Using old prefab names
return Prefab("shipwrecked/sea_yard", fn, assets, prefabs),
	MakePlacer("shipwrecked/sea_yard_placer", "sea_yard", "sea_yard", "placer")
