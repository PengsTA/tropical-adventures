--require("map/treasurehunt")

local assets =
{
	Asset("ANIM", "anim/stash_map.zip"),
	Asset("INV_IMAGE", "stash_map"),
	Asset("ANIM", "anim/x_marks_spot_bandit.zip"),

}

local treasure_loot =
{
	[1] = "tfwp_healing_staff",
	[2] = "purplegem",
	[3] = "orangegem",
	[4] = "yellowgem",
	[5] = "greengem",
	[6] = "redgem",
	[7] = "bluegem",
	[8] = "supertelescope",
	[9] = "spear_poison",
	[10] = "boat_lantern",
	[11] = "papyrus",
	[12] = "tunacan",
	[13] = "goldnugget",
	[14] = "gears",
	[15] = "rope",
	[16] = "minerhat",
	[17] = "oinc100",
	[18] = "obsidianaxe",
	[19] = "telescope",
	[20] = "captainhat",
	[21] = "peg_leg",
	[22] = "volcanostaff",
	[23] = "footballhat",
	[24] = "spear",
	[25] = "goldenaxe",
	[26] = "goldenshovel",
	[27] = "goldenpickaxe",
	[28] = "seatrap",
	[29] = "compass",
	[30] = "boneshard",
	[31] = "transistor",
	[32] = "gunpowder",
	[33] = "heatrock",
	[34] = "antivenom",
	[35] = "healingsalve",
	[36] = "blowdart_sleep",
	[37] = "nightsword",
	[38] = "amulet",
	[39] = "clothsail",
	[40] = "boatrepairkit",
	[41] = "coconade",
	[42] = "boatcannon",
	[43] = "snakeskinhat",
	[44] = "armor_snakeskin",
	[45] = "spear_launcher",
	[46] = "piratehat",
	[47] = "boomerang",
	[48] = "snakeskin",
	[49] = "strawhat",
	[50] = "blubbersuit",
	[51] = "nightmarefuel",
	[52] = "obsidianmachete",
	[53] = "trap_teeth",
	[54] = "spear_obsidian",
	[55] = "armorobsidian",
	[56] = "goldenmachete",
	[57] = "obsidiancoconade",
	[58] = "fabric",
	[59] = "harpoon",
	[60] = "umbrella",
	[61] = "birdtrap",
	[62] = "featherhat",
	[63] = "beehat",
	[64] = "bandage",
	[65] = "armorwood",
	[66] = "armormarble",
	[67] = "blowdart_pipe",
	[68] = "armorgrass",
	[69] = "armorseashell",
	[70] = "cane",
	[71] = "icestaff",
	[72] = "firestaff",
	[73] = "blowdart_fire",
	[74] = "yellowamulet",
	[75] = "armorruins",
	[76] = "ruins_bat",
	[77] = "ruinshat",
	[78] = "cutgrass",
	[79] = "charcoal",
	[80] = "axe",
	[81] = "hammer",
	[82] = "shovel",
	[83] = "bugnet",
	[84] = "fishingrod",
	[85] = "spidergland",
	[86] = "silk",
	[87] = "flint",
	[88] = "coral",
}


local hamlet_treasure_loot =
{
	[1] = "goldnugget",
	[2] = "armor_metalplate",
	[3] = "halberd",
	[4] = "metalplatehat",
	[5] = "tunacan",
	[6] = "trinket_17",
	[7] = "alloy",
	[8] = "oinc10",
}


local function onunwrapped(inst, pos, doer)
	if doer == nil or not doer:IsValid() or doer.components.inventory == nil then
		return
	end
	local x, y = require("tools/land_search").Find(TheWorld.Map, 1, doer:GetPosition())
	if x == nil then
		return
	end

	SpawnPrefab("bandittreasure").Transform:SetPosition(x, 0, y)

	doer:DoTaskInTime(0, function()
		if doer.player_classified ~= nil then
			doer.player_classified.MapExplorer:RevealArea(x, 0, y)
		end
		doer.components.inventory:GiveItem(SpawnPrefab("papyrus"))
	end)

	if doer.player_classified ~= nil and doer.player_classified.revealtreasure then
		local val = (x + 16384) * 65536 + (y + 16384)
		doer.player_classified.revealtreasure:set_local(val)
		doer.player_classified.revealtreasure:set(val)
	end

	inst:Remove()
end

local function messagebottlefn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)

	anim:SetBank("stash_map")
	anim:SetBuild("stash_map")
	anim:PlayAnimation("idle")

	inst:AddTag("aquatic")
	inst:AddTag("banditmap")
	inst:AddTag("nosteal")
	inst:AddTag("unwrappable")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")



	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)

	inst.no_wet_prefix = true

	inst:AddComponent("unwrappable")
	inst.components.unwrappable:SetOnUnwrappedFn(onunwrapped)

	return inst
end

local function onfinishcallback(inst, worker)
	-- figure out which side to drop the loot
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local hispos = Vector3(worker.Transform:GetWorldPosition())

	local he_right = ((hispos - pt):Dot(TheCamera:GetRightVec()) > 0)

	if he_right then
		inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec() * (math.random() + 1)))
		inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec() * (math.random() + 1)))
	else
		inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec() * (math.random() + 1)))
		inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec() * (math.random() + 1)))
	end

	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/loot_reveal")


	local chest = SpawnPrefab("treasurechest")
	local map = TheWorld.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	chest.Transform:SetPosition(x, y, z)




	for i = 1, 20 do
		if math.random() > 0.5 then
			local single = SpawnPrefab("oinc")
			chest.components.container:GiveItem(single)
		end
	end

	for i = 1, 4 do
		if math.random() > 0.5 then
			local single = SpawnPrefab(treasure_loot[math.random(1, #treasure_loot)])
			chest.components.container:GiveItem(single)
		end
	end

	for i = 1, 4 do
		if math.random() > 0.5 then
			local single = SpawnPrefab(hamlet_treasure_loot[math.random(1, #hamlet_treasure_loot)])
			chest.components.container:GiveItem(single)
		end
	end


	local creature_type = math.random(1, 2)

	for i = 1, 4 do
		if math.random() > 0.5 then
			if creature_type == 1 then
				local single = SpawnPrefab("scorpion")
				chest.components.container:GiveItem(single)
			else
				local single = SpawnPrefab("snake_amphibious")
				chest.components.container:GiveItem(single)
			end
		else

		end
	end

	inst:Remove()
end

local function onsave(inst, data)

end

local function onload(inst, data)

end

local function RevealFog(inst)
	inst.entity:Show()
	inst.MiniMapEntity:SetEnabled(true)
	local x, y, z = inst.Transform:GetLocalPosition()
	local minimap = TheWorld.minimap.MiniMap
	local map = TheWorld.Map
	local cx, cy, cz = map:GetTileCenterPoint(x, 0, z)
	minimap:ShowArea(cx, cy, cz, 30)
	map:VisitTile(map:GetTileCoordsAtPoint(cx, cy, cz))
end


local function FocusMinimap(inst)
	local px, py, pz = ThePlayer.Transform:GetWorldPosition()
	local x, y, z = inst.Transform:GetLocalPosition()
	local minimap = TheWorld.minimap.MiniMap
	--ThePlayer.HUD.controls:ToggleMap()
	--minimap:Focus(x - px, z - pz, -minimap:GetZoom()) --Zoom in all the way
end


local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local minimap = inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst.entity:AddSoundEmitter()

	inst:AddTag("buriedtreasure")

	minimap:SetIcon("xspot.tex")
	--	minimap:SetEnabled(false)

	anim:SetBank("x_marks_spot_bandit")
	anim:SetBuild("x_marks_spot_bandit")
	anim:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(3)
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({ "peagawkfeather" })

	inst.components.workable:SetOnFinishCallback(onfinishcallback)

	--	inst:DoTaskInTime(1, RevealFog)
	--	inst:DoTaskInTime(0.5, FocusMinimap)

	inst.OnSave = onsave
	inst.OnLoad = onload

	return inst
end

return Prefab("bandittreasure", fn, assets, prefabs),
	Prefab("banditmap", messagebottlefn, assets)
