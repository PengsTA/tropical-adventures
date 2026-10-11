--[[
birds.lua

Different birds are just reskins of crow without any special powers at the moment.
To make a new bird add it at the bottom of the file as a 'makebird(name)' call

This assumes the bird already has a build, inventory icon, sounds and a feather_name prefab exists

]] --
require "brains/birdbrain"
require "stategraphs/SGbird"
local ClimateProfiles = require("tools/climateprofiles")

local toucan_hamlet_sounds = {
    takeoff = "dontstarve_DLC002/creatures/toucan/takeoff",
    chirp = "dontstarve_DLC002/creatures/toucan/chirp",
    flyin = "dontstarve/birds/flyin",
}

local pigeon_sounds = {
    takeoff = "dontstarve_DLC003/creatures/pigeon/takeoff",
    chirp = "dontstarve_DLC003/creatures/pigeon/chirp",
    flyin = "dontstarve/birds/flyin",
}

local parrot_blue_sounds = {
    takeoff = "dontstarve_DLC002/creatures/parrot/takeoff",
    chirp = "dontstarve_DLC002/creatures/parrot/chirp",
    flyin = "dontstarve/birds/flyin",
}

local kingfisher_sounds = {
    takeoff = "dontstarve_DLC003/creatures/king_fisher/take_off",
    chirp = "dontstarve_DLC003/creatures/king_fisher/chirp",
    flyin = "dontstarve/birds/flyin",
}

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and not inst.sg:HasStateTag("flight")
end

local BIRD_TAGS = {"bird"}
local function OnAttacked(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, BIRD_TAGS)
    local num_friends = 0
    local maxnum = 5
    for _, v in pairs(ents) do
        if v ~= inst then
            v:PushEvent("gohome")
            num_friends = num_friends + 1
        end

        if num_friends > maxnum then
            return
        end
    end
end

local function OnTrapped(inst, data)
    if data and data.trapper and data.trapper.settrapsymbols then
        data.trapper.settrapsymbols(inst.trappedbuild)
    end
end

local function OnPutInInventory(inst)
    -- Otherwise sleeper won't work if we're in a busy state
    inst.sg:GoToState("idle")
end

local function OnDropped(inst)
    inst.sg:GoToState("stunned")
end

local function canbeattacked(inst, attacked)
	return not inst.sg:HasStateTag("flight")
end

local function seedspawntest(inst)
	local ground = TheWorld
	local isWinter = ClimateProfiles.IsHamletHumid(TheWorld.state)
	if ground and ground.components.birdspawner then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ground = TheWorld
		local tile = ground.Map:GetTileAtPoint(x, y, z)
	end
	return not (isWinter)
end

local function makebird(name, sounds, feather_name)
	local featherpostfix = feather_name or name

    local assets =
    {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/" .. name .. "_build.zip"),
        Asset("SOUND", "sound/birds.fsb"),
    }

	local prefabs =
	{
		"seeds",
		"smallmeat",
		"cookedsmallmeat",
		"feather_" .. featherpostfix,
		"feather_crow",
	}

	local function fn()
		local Parrotblue = (name == "parrot_blue")
        local Kingfisher = (name == "kingfisher")
        local inst = CreateEntity()

        --Core components
        inst.entity:AddTransform()
        inst.entity:AddPhysics()
        inst.entity:AddAnimState()
        inst.entity:AddDynamicShadow()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        --Initialize physics
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        inst.Physics:SetMass(1)
        inst.Physics:SetSphere(1)

        inst:AddTag("bird")
        inst:AddTag(name)
        inst:AddTag("smallcreature")
        inst:AddTag("likewateroffducksback")
        inst:AddTag("stunnedbybomb")
        inst:AddTag("noember")

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")

        inst.Transform:SetTwoFaced()

        inst.AnimState:SetBank("crow")
        inst.AnimState:SetBuild(name.."_build")
        inst.AnimState:PlayAnimation("idle")

        inst.DynamicShadow:SetSize(1, .75)
        inst.DynamicShadow:Enable(false)

        MakeFeedableSmallLivestockPristine(inst)

        if Kingfisher then
            MakeInventoryFloatable(inst, nil, .07)
        end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

        inst:AddComponent("inspectable")

        inst.sounds = sounds
        inst.trappedbuild = name.."_build"

		inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
		inst.components.locomotor:EnableGroundSpeedMultiplier(false)
		inst.components.locomotor:SetTriggersCreep(false)

		inst:AddComponent("lootdropper")
        inst.components.lootdropper:AddRandomLoot("feather_" .. feather_name, 1)
		inst.components.lootdropper:AddRandomLoot("smallmeat", 1)
		inst.components.lootdropper.numrandomloot = 1

		inst:AddComponent("occupier")

		inst:AddComponent("eater")
        if Kingfisher then
			inst.components.eater:SetDiet({ FOODTYPE.SEEDS }, { FOODTYPE.MEAT })
		else
			inst.components.eater:SetDiet({ FOODTYPE.SEEDS }, { FOODTYPE.SEEDS })
		end

		inst:AddComponent("sleeper")
		inst.components.sleeper.watchlight = true
		inst.components.sleeper:SetSleepTest(ShouldSleep)

		inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true
        inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem.canbepickedupalive = true
        if not Kingfisher then
            inst.components.inventoryitem:SetSinks(true)
        end

		inst:AddComponent("cookable")
		inst.components.cookable.product = "cookedsmallmeat"

		inst:AddComponent("health")
		inst.components.health:SetMaxHealth(TUNING.BIRD_HEALTH)
		inst.components.health.murdersound = "dontstarve/wilson/hit_animal"

        inst.flyawaydistance = TUNING.BIRD_SEE_THREAT_DISTANCE

		inst:AddComponent("combat")
		inst.components.combat.hiteffectsymbol = "crow_body"
		inst.components.combat.canbeattackedfn = canbeattacked

		local brain = require "brains/birdbrain"
		inst:SetBrain(brain)
		inst:SetStateGraph("SGbird")

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
		inst.components.hauntable.panicable = true

		MakeSmallBurnableCharacter(inst, "crow_body")
		MakeTinyFreezableCharacter(inst, "crow_body")

		inst:AddComponent("periodicspawner")
		if Parrotblue then
			inst.components.periodicspawner:SetPrefab("oinc") --("dubloon")
		elseif Kingfisher and math.random() < 0.1 then
			inst.components.periodicspawner:SetPrefab("coi")
			inst.components.periodicspawner.onlanding = true
		else
			inst.components.periodicspawner:SetPrefab("seeds")
		end
		inst.components.periodicspawner:SetDensityInRange(20, 2)
		inst.components.periodicspawner:SetMinimumSpacing(8)
		--inst.components.periodicspawner:SetSpawnTestFn( seedspawntest )

        inst:ListenForEvent("ontrapped", OnTrapped)
        inst:ListenForEvent("attacked", OnAttacked)

        local birdspawner = TheWorld.components.birdspawner
        if birdspawner ~= nil then
            inst:ListenForEvent("onremove", birdspawner.StopTrackingFn)
            inst:ListenForEvent("enterlimbo", birdspawner.StopTrackingFn)
            -- inst:ListenForEvent("exitlimbo", birdspawner.StartTrackingFn)
            birdspawner:StartTracking(inst)
        end

		MakeFeedableSmallLivestock(inst, TUNING.BIRD_PERISH_TIME, OnPutInInventory, OnDropped)

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return
	makebird("toucan_hamlet", toucan_hamlet_sounds, "robin"),
	makebird("pigeon", pigeon_sounds, "robin_winter"),
	makebird("parrot_blue", parrot_blue_sounds, "robin_winter"),
	makebird("kingfisher", kingfisher_sounds, "robin_winter")
