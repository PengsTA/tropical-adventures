require "prefabutil"

local ROOM_LAYOUTS = require "datadefs/interior"
local InteriorLayoutBuilder = require "tools/interior_layout_builder"
local ShopRoomBuilder = require "tools/shop_room_builder"

local assets =
{
	Asset("ANIM", "anim/pig_shop_doormats.zip"),
}

local SHOP_DEFS = ROOM_LAYOUTS.shops.defs

local function RoomOnActivateByOther(inst, source, doer)
	if doer ~= nil and doer.Physics ~= nil then
		doer.Physics:CollidesWith(COLLISION.WORLD)
	end
end

local function RoomOnActivate(inst, doer)
	if doer:HasTag("player") then
		if doer.components.talker ~= nil then
			doer.components.talker:ShutUp()
		end
	else
		inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
	end
end

local function RoomOnAccept(inst, giver, item)
	inst.components.inventory:DropItem(item)
	inst.components.teleporter:Activate(item)
end

local function PlayRoomTravelSound(inst, doer)
	inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
end

local function ExitOnDoneTeleporting(inst, obj)
end

local function ExitOnActivate(inst, doer)
	if doer:HasTag("player") then
		ProfileStatsSet("wormhole_used", true)

		local other = inst.components.teleporter.targetTeleporter
		if other ~= nil then
			DeleteCloseEntsWithTag("WORM_DANGER", other, 15)
		end

		if doer.components.talker ~= nil then
			doer.components.talker:ShutUp()
		end
	elseif inst.SoundEmitter ~= nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
	end
end

local function ExitOnActivateByOther(inst, source, doer)
end

local function ExitOnAccept(inst, giver, item)
	inst.components.inventory:DropItem(item)
	inst.components.teleporter:Activate(item)
end

local function PlayExitTravelSound(inst, doer)
	inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
end

local function ExitOnHaunt(inst, haunter)
	inst.components.teleporter:Activate(haunter)
end

local function BuildShopLayout(inst, context, def)
	inst.exit = context.exit
	inst.Transform:SetPosition(context.room.x, 0, context.room.z)

	local layout = ROOM_LAYOUTS.shops.layouts[def.layout]
	assert(layout ~= nil, "missing shop room layout: " .. tostring(def.layout))
	InteriorLayoutBuilder.SpawnFixtures(context.room, layout, { root = inst })

	-- Legacy save flag used by the old room builders.
	if inst.caverna == nil then
		inst.caverna = 1
	end
end

local function MakeRoomBuilder(def)
	return function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
		inst.entity:AddMiniMapEntity()

		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(1)
		inst.AnimState:SetFinalOffset(2)
		inst.Transform:SetEightFaced()
		inst.MiniMapEntity:SetIcon("minimap_volcano_entrance.tex")

		inst:AddTag("vulcano_part")
		inst:AddTag("antlion_sinkhole_blocker")
		inst:SetDeployExtraSpacing(2.5)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		inst:AddComponent("teleporter")
		inst.components.teleporter.onActivate = RoomOnActivate
		inst.components.teleporter.onActivateByOther = RoomOnActivateByOther
		inst.components.teleporter.offset = 0
		inst.components.teleporter.travelcameratime = 0.6
		inst.components.teleporter.travelarrivetime = 0.5

		inst:AddComponent("inventory")

		inst:AddComponent("trader")
		inst.components.trader.acceptnontradable = true
		inst.components.trader.onaccept = RoomOnAccept
		inst.components.trader.deleteitemonaccept = false

		local context = ShopRoomBuilder.Begin(inst, {
			exit_prefab = def.exit_prefab,
			kind = def.kind,
			spawn_perimeter = def.spawn_perimeter,
		})
		BuildShopLayout(inst, context, def)
		ShopRoomBuilder.Finish(inst, context)

		inst.components.teleporter.targetTeleporter = inst.exit
		inst.exit.components.teleporter.targetTeleporter = inst
		inst:ListenForEvent("starttravelsound", PlayRoomTravelSound)

		return inst
	end
end

local function MakeExitDoor(def)
	return function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		local minimap = inst.entity:AddMiniMapEntity()
		minimap:SetIcon("vamp_bat_cave.tex")

		inst.AnimState:SetBank("pig_shop_doormats")
		inst.AnimState:SetBuild("pig_shop_doormats")
		inst.AnimState:PlayAnimation(def.door_anim)
		inst.Transform:SetRotation(90)
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)

		inst:AddTag("trader")
		inst:AddTag("alltrader")
		inst:AddTag("guard_entrance")
		inst:AddTag("hamletteleport")
		inst:AddTag("antlion_sinkhole_blocker")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("trader")
		inst.components.trader.acceptnontradable = true
		inst.components.trader.onaccept = ExitOnAccept
		inst.components.trader.deleteitemonaccept = false

		inst:AddComponent("inspectable")
		inst.components.inspectable:RecordViews()

		inst:AddComponent("teleporter")
		inst.components.teleporter.onActivate = ExitOnActivate
		inst.components.teleporter.onActivateByOther = ExitOnActivateByOther
		inst.components.teleporter.offset = 0
		inst.components.teleporter.hamlet = true
		inst.components.teleporter.travelcameratime = 0.2
		inst.components.teleporter.travelarrivetime = 0.1
		inst:ListenForEvent("starttravelsound", PlayExitTravelSound)
		inst:ListenForEvent("doneteleporting", ExitOnDoneTeleporting)

		inst:AddComponent("inventory")
		inst:AddComponent("hauntable")
		inst.components.hauntable:SetOnHauntFn(ExitOnHaunt)

		return inst
	end
end

local prefabs = {}

for _, def in ipairs(SHOP_DEFS) do
	table.insert(prefabs, Prefab(def.room_builder, MakeRoomBuilder(def)))
	table.insert(prefabs, Prefab(def.exit_prefab, MakeExitDoor(def), assets))
end

return unpack(prefabs)
