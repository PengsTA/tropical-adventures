--[[
birds.lua

Different birds are just reskins of crow without any special powers at the moment.
To make a new bird add it at the bottom of the file as a 'makebird(name)' call

This assumes the bird already has a build, inventory icon, sounds and a feather_name prefab exists

]] --
require "brains/birdbrain"
require "stategraphs/SGbird"
local ClimateProfiles = require("tools/climateprofiles")

local parrot_sounds = {
    takeoff = "dontstarve_DLC002/creatures/parrot/takeoff",
    chirp = "dontstarve_DLC002/creatures/parrot/chirp",
    flyin = "dontstarve/birds/flyin",
}

local parrot_pirate_sounds = {
    takeoff = "dontstarve_DLC002/creatures/parrot/takeoff",
    chirp = "dontstarve_DLC002/creatures/parrot/chirp",
    flyin = "dontstarve/birds/flyin",
}

local toucan_sounds = {
    takeoff = "dontstarve_DLC002/creatures/toucan/takeoff",
    chirp = "dontstarve_DLC002/creatures/toucan/chirp",
    flyin = "dontstarve/birds/flyin",
}

local seagull_sounds = {
    takeoff = "dontstarve_DLC002/creatures/seagull/takeoff_seagull",
    chirp = "dontstarve_DLC002/creatures/seagull/chirp_seagull",
    flyin = "dontstarve/birds/flyin",
    --land = "dontstarve_DLC002/creatures/seagull/landwater",
}

local cormorant_sounds = {
    takeoff = "dontstarve_DLC003/creatures/king_fisher/take_off",
    chirp = "dontstarve_DLC003/creatures/king_fisher/chirp",
    flyin = "dontstarve/birds/flyin",
    land = "dontstarve_DLC002/creatures/cormorant/landwater",
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
	local isWinter = ClimateProfiles.IsShipwreckedHurricane(TheWorld.state)
	if ground and ground.components.birdspawner then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ground = TheWorld
		local tile = ground.Map:GetTileAtPoint(x, y, z)
	end
	return not (isWinter)
end

local function makebird(name, sounds, feather_name, bank, water_bank)
	local featherpostfix = feather_name or name

    local assets =
    {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/" .. name .. "_build.zip"),
        Asset("SOUND", "sound/birds.fsb"),
    }

    if bank ~= nil then
        table.insert(assets, Asset("ANIM", "anim/"..bank..".zip"))
    end

    if water_bank ~= nil then
        table.insert(assets, Asset("ANIM", "anim/"..water_bank..".zip"))
    end

	local prefabs =
	{
		"seeds",
		"smallmeat",
		"cookedsmallmeat",
		"feather_" .. featherpostfix,
		"feather_crow",
	}

	local function fn()
		local namedParrot = (name == "parrot_pirate")
        local Seagull = (name == "seagull")
        local Cormorant = (name == "cormorant")
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
        if water_bank ~= nil then
            -- Birds that float can pass through LIMITS walls, i.e. when hopping.
            inst.Physics:CollidesWith(COLLISION.GROUND)
        else
            inst.Physics:CollidesWith(COLLISION.WORLD)
        end
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

        if Cormorant then
           inst.Transform:SetScale(0.85, 0.85, 0.85)
        end

        inst.AnimState:SetBank(bank or "crow")
        inst.AnimState:SetBuild(name.."_build")
        inst.AnimState:PlayAnimation("idle")

        inst.DynamicShadow:SetSize(1, .75)
        inst.DynamicShadow:Enable(false)

        MakeFeedableSmallLivestockPristine(inst)

        if water_bank ~= nil then
            MakeInventoryFloatable(inst, nil, .07)
        end

		if namedParrot then
			inst:AddComponent("talker")
			inst.components.talker.fontsize = 28
		    inst.components.talker.font = TALKINGFONT
		    inst.components.talker.colour = Vector3(.9, .4, .4, 1)
		    inst:ListenForEvent("donetalking", function() inst.SoundEmitter:KillSound("talk") end)
		    inst:ListenForEvent("ontalk", function()
		    	inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/parrot/chirp", "talk")
			end)
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
        if Cormorant or Seagull then
            inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
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
        if water_bank == nil then
            inst.components.inventoryitem:SetSinks(true)
        end

		inst:AddComponent("cookable")
		inst.components.cookable.product = "cookedsmallmeat"

		inst:AddComponent("health")
		inst.components.health:SetMaxHealth(TUNING.BIRD_HEALTH)
		inst.components.health.murdersound = "dontstarve/wilson/hit_animal"

		if namedParrot then
			inst.components.inspectable.nameoverride = "PARROT"
			inst:AddComponent("named")
			inst.components.named.possiblenames = STRINGS.PARROTNAMES
			inst.components.named:PickNewName()
			inst.components.health.canmurder = false

			inst:AddComponent("talker")
			inst.components.talker.fontsize = 28
		    inst.components.talker.font = TALKINGFONT
		    inst.components.talker.colour = Vector3(.9, .4, .4, 1)
		    inst:ListenForEvent("donetalking", function() inst.SoundEmitter:KillSound("talk") end)
		    inst:ListenForEvent("ontalk", function()
		    	inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/parrot/chirp", "talk")
			end)

			inst:AddComponent("talkingbird")

			inst:AddComponent("sanityaura")
			inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL
		end

        if water_bank ~= nil then
            inst.flyawaydistance = TUNING.WATERBIRD_SEE_THREAT_DISTANCE
        else
            inst.flyawaydistance = TUNING.BIRD_SEE_THREAT_DISTANCE
        end

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
		if namedParrot then
			inst.components.periodicspawner:SetPrefab("dubloon")
		elseif Cormorant and math.random() < 0.1 then
			inst.components.periodicspawner:SetPrefab("roe")
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

        if water_bank ~= nil then
            inst:ListenForEvent("floater_startfloating", function(inst) inst.AnimState:SetBank(water_bank) end)
            inst:ListenForEvent("floater_stopfloating", function(inst) inst.AnimState:SetBank(bank or "crow") end)
        end

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return
	makebird("parrot", parrot_sounds, "robin", nil),
	makebird("parrot_pirate", parrot_pirate_sounds, "robin", nil),
	makebird("toucan", toucan_sounds, "crow", nil),
	makebird("cormorant", cormorant_sounds, "crow", "seagull", "cormorant_water"),
    makebird("seagull", seagull_sounds, "robin_winter", "seagull", "cormorant_water")
