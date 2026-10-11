require "prefabutil"

local InteriorLayoutBuilder = require "tools/interior_layout_builder"
local InteriorRoomBuilder = require "tools/interior_room_builder"
local RoomExtensions = require "tools/interior_room_extensions"
local ROOM_LAYOUTS = require "datadefs/interior"

local assets =
{
	Asset("ANIM", "anim/pisohamlet.zip"),
	Asset("ANIM", "anim/wallhamletpig.zip"),
	Asset("ANIM", "anim/palace.zip"),
	Asset("ANIM", "anim/pig_shop_doormats.zip"),
	Asset("ANIM", "anim/palace_door.zip"),
	Asset("ANIM", "anim/interior_wall_decals_palace.zip"),
}

local prefabs = {}
local PALACE_LAYOUT = ROOM_LAYOUTS.palace
local ROOM_SIZES = ROOM_LAYOUTS.sizes
local PALACE_ROOM_ORDER = {
    PALACE_LAYOUT.rooms.main,
    PALACE_LAYOUT.rooms.gallery,
    PALACE_LAYOUT.rooms.upper,
}

local ROOM_DIRECTIONS = {
	back = 1,
	front = 2,
	left = 3,
	right = 4,
}

local ROOM_DIRECTION_NAMES = {
	[1] = "back",
	[2] = "front",
	[3] = "left",
	[4] = "right",
}

local function OnSave(inst, data)
	-- Keep the old save key so existing worlds can still recognize the room.
	data.entrada = inst.entrada
	data.interior_built = inst.interior_built
end

local function OnLoad(inst, data)
	if data ~= nil and (data.interior_built or data.entrada) then
		inst.interior_built = true
		inst.entrada = data.entrada or 1
	end
end

local function BuilderOnActivateByOther(inst, source, doer)
	if doer ~= nil and doer.Physics ~= nil then
		doer.Physics:CollidesWith(COLLISION.WORLD)
	end
end

local function BuilderOnActivate(inst, doer)
	if doer:HasTag("player") then
		if doer.components.talker ~= nil then
			doer.components.talker:ShutUp()
		end
	else
		inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
	end
end

local function BuilderOnAccept(inst, giver, item)
	inst.components.inventory:DropItem(item)
	inst.components.teleporter:Activate(item)
end

local function LinkTeleporters(from, to, bidirectional)
	if from ~= nil and from.components.teleporter ~= nil then
		from.components.teleporter.targetTeleporter = to
	end
	if bidirectional ~= false and to ~= nil and to.components.teleporter ~= nil then
		to.components.teleporter.targetTeleporter = from
	end
end

local function BuildPalaceRoom(builder, room, room_def, doors)
	local size = ROOM_SIZES[room_def.kind]
	local shell = InteriorRoomBuilder.BuildShell(room, size)
	local layout = PALACE_LAYOUT.layouts[room_def.layout]
	assert(layout ~= nil, "missing palace room layout: " .. tostring(room_def.layout))

	builder.Transform:SetPosition(room.x, 0, room.z)
	local context = InteriorLayoutBuilder.SpawnFixtures(room, layout, { root = builder })
	for key, door in pairs(context.by_key) do
		doors[key] = door
	end

	InteriorRoomBuilder.FitContents(shell, { builder })

	return shell
end

local function LinkPalaceRooms(builder, rooms, doors)
	builder:DoTaskInTime(1, function(inst)
		local exterior = SpawnPrefab(PALACE_LAYOUT.exterior_prefab)
		if exterior ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
			exterior.Transform:SetPosition(x, y, z)
			LinkTeleporters(exterior, doors.exit)
			LinkTeleporters(doors.upper_to_exit, exterior, false)
		end

		for _, connection in ipairs(PALACE_LAYOUT.connections) do
			if connection.to ~= "exterior" then
				local source_door = doors[connection.from]
				local target_door = doors[connection.to]
				local source_room = rooms[connection.from_room]
				local target_room = rooms[connection.to_room]
				local direction = RoomExtensions.GetWallDirection(source_door, false)
				if source_room == nil
					or target_room == nil
					or not RoomExtensions.LinkRoomDoors(
						source_door,
						source_room.id,
						direction,
						target_door,
						target_room.id
					) then
					-- Preserve the original teleport route if a layout definition is
					-- incomplete, even though it will not be added to the room map.
					LinkTeleporters(source_door, target_door)
				end
			end
		end

		inst:Remove()
	end)
end

local function BuildPalaceInterior(inst)
	local manager = TheWorld.components.interior_manager
	if manager == nil then
		return
	end

	local rooms = {}
	local doors = {}
	local palace_id = nil
	for _, room_def in ipairs(PALACE_ROOM_ORDER) do
		local room = manager:Allocate(nil, room_def.kind)
		palace_id = palace_id or room.id
		room.house_id = palace_id
		room.room_template = room_def.kind
		room.camera_profile_kind = room_def.kind
		room.map_x = room_def.map_x or 0
		room.map_z = room_def.map_z or 0
		rooms[room_def.key] = room
		BuildPalaceRoom(inst, room, room_def, doors)
	end

	inst.exit = doors.exit
	LinkPalaceRooms(inst, rooms, doors)
end

local function entrance()
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
	inst.components.teleporter.onActivate = BuilderOnActivate
	inst.components.teleporter.onActivateByOther = BuilderOnActivateByOther
	inst.components.teleporter.offset = 0
	inst.components.teleporter.travelcameratime = 0.2
	inst.components.teleporter.travelarrivetime = 0.1

	inst:AddComponent("inventory")

	inst:AddComponent("trader")
	inst.components.trader.acceptnontradable = true
	inst.components.trader.onaccept = BuilderOnAccept
	inst.components.trader.deleteitemonaccept = false

	if not inst.interior_built and inst.entrada == nil then
		BuildPalaceInterior(inst)
		inst.interior_built = true
		inst.entrada = 1
	end

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

local function SpawnPiso1(inst)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("pisohamlet")
	inst.AnimState:SetBuild("pisohamlet")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(5)
	inst.AnimState:SetScale(3.8, 3.8, 3.8)
	inst.AnimState:PlayAnimation("floor_marble_royal")
	inst:AddTag("NOCLICK")
	inst:AddTag("alt_tile")
	inst:AddTag("vulcano_part")
	inst:AddTag("pisointeriorpalace")
	inst:AddTag("terremoto")
	inst:AddTag("interior_center")

	return inst
end

local function SpawnPiso2(inst)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("pisohamlet")
	inst.AnimState:SetBuild("pisohamlet")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(5)
	inst.AnimState:SetScale(5.5, 5.5, 5.5)
	inst.AnimState:PlayAnimation("floor_marble_royal_small")
	inst:AddTag("NOCLICK")
	inst:AddTag("alt_tile")
	inst:AddTag("vulcano_part")
	inst:AddTag("pisogalleryinteriorpalace")
	inst:AddTag("caveinterior")
	inst:AddTag("terremoto")
	inst:AddTag("interior_center")

	return inst
end

local function SpawnPiso3(inst)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("pisohamlet")
	inst.AnimState:SetBuild("pisohamlet")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(5)
	inst.AnimState:SetScale(4.5, 4.5, 4.5)
	inst.AnimState:PlayAnimation("floor_marble_royal_small")
	inst:AddTag("NOCLICK")
	inst:AddTag("alt_tile")
	inst:AddTag("vulcano_part")
	inst:AddTag("shopinterior")
	inst:AddTag("interior_center")

	return inst
end

local function wall_common1(build)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("wallhamletpig")
	inst.AnimState:SetBuild("wallhamletpig")
	inst.AnimState:PlayAnimation("wall_royal_high", true)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(7)
	inst.AnimState:SetScale(4.3, 4.8, 4.8)

	return inst
end

local function wall_common2(build)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("wallhamletpig")
	inst.AnimState:SetBuild("wallhamletpig")
	inst.AnimState:PlayAnimation("wall_royal_high", true)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetScale(2.5, 3, 3)
	return inst
end

local function wall_common3(build)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("wallhamletpig")
	inst.AnimState:SetBuild("wallhamletpig")
	inst.AnimState:PlayAnimation("wall_royal_high", true)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetScale(3.1, 3.2, 3.2)
	return inst
end

local function DoorOnDoneTeleporting(inst, obj)
end

local function DoorOnActivate(inst, doer)
	if doer:HasTag("player") then
		ProfileStatsSet("wormhole_used", true)

		local other = inst.components.teleporter.targetTeleporter
		if other ~= nil then
			DeleteCloseEntsWithTag("WORM_DANGER", other, 15)
		end

		if doer.components.talker ~= nil then
			doer.components.talker:ShutUp()
		end
	end
end

local function DoorOnActivateByOther(inst, source, doer)
end

local function DoorOnAccept(inst, giver, item)
	inst.components.inventory:DropItem(item)
	inst.components.teleporter:Activate(item)
end

local function StartTravelSound(inst, doer)
end

local function OnHaunt(inst, haunter)
	inst.components.teleporter:Activate(haunter)
end

local function AddDoorComponents(inst, definition)
	if definition.save then
		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
	end

	inst:AddComponent("trader")
	inst.components.trader.acceptnontradable = true
	inst.components.trader.onaccept = DoorOnAccept
	inst.components.trader.deleteitemonaccept = false

	inst:AddComponent("inspectable")
	inst.components.inspectable:RecordViews()

	inst:AddComponent("teleporter")
	inst.components.teleporter.onActivate = DoorOnActivate
	inst.components.teleporter.onActivateByOther = DoorOnActivateByOther
	inst.components.teleporter.offset = 0
	if definition.hamlet then
		inst.components.teleporter.hamlet = true
	end
	inst.components.teleporter.travelcameratime = 0.2
	inst.components.teleporter.travelarrivetime = 0.1
	inst:ListenForEvent("starttravelsound", StartTravelSound)
	inst:ListenForEvent("doneteleporting", definition.on_done or DoorOnDoneTeleporting)

	inst:AddComponent("inventory")
	if definition.hauntable then
		inst:AddComponent("hauntable")
		inst.components.hauntable:SetOnHauntFn(OnHaunt)
	end
end

local function GetRoomDirection(inst)
	return inst.room_direction or ROOM_DIRECTION_NAMES[inst._ta_room_direction:value()]
end

local function SetRoomDirection(inst, direction)
	direction = RoomExtensions.NormalizeDirection(direction)
	local direction_id = ROOM_DIRECTIONS[direction]
	if direction_id == nil then
		return false
	end

	inst.room_direction = direction
	inst._ta_room_direction:set(direction_id)
	for label, _ in pairs(ROOM_DIRECTIONS) do
		inst:RemoveTag("interior_" .. label .. "_door")
	end
	inst:AddTag("interior_" .. direction .. "_door")
	return true
end

local function ConfigureRoomLink(inst)
	function inst:Link(target, target_room_id)
		self.components.teleporter.targetTeleporter = target
		self.target_door = target
		self.target_room_id = target_room_id
		self._ta_target_door:set(target)
	end

	inst.SetRoomDirection = SetRoomDirection

	local old_on_save = inst.OnSave
	inst.OnSave = function(door, data)
		if old_on_save ~= nil then
			old_on_save(door, data)
		end
		data.ta_target_door = door.target_door ~= nil and door.target_door.GUID or nil
		data.ta_target_room_id = door.target_room_id
		data.ta_room_direction = door.room_direction
	end

	local old_load_post_pass = inst.LoadPostPass
	inst.LoadPostPass = function(door, ents, data)
		if old_load_post_pass ~= nil then
			old_load_post_pass(door, ents, data)
		end
		if data ~= nil and data.ta_target_door ~= nil and ents[data.ta_target_door] ~= nil then
			local target = ents[data.ta_target_door].entity
			if target ~= nil then
				door:Link(target, data.ta_target_room_id)
			end
		end
		if data ~= nil and data.ta_room_direction ~= nil then
			door:SetRoomDirection(data.ta_room_direction)
		end
	end
end

local function RestoreRoomLink(inst)
	local target = inst.components.teleporter.targetTeleporter
	if target == nil or not target:IsValid() then
		return
	end

	local source_room = RoomExtensions.GetRoomForEntity(inst)
	local target_room = RoomExtensions.GetRoomForEntity(target)
	if source_room == nil
		or target_room == nil
		or source_room == target_room
		or source_room._ta_room_id == nil
		or target_room._ta_room_id == nil then
		return
	end

	local direction = RoomExtensions.GetWallDirection(inst, false)
	RoomExtensions.LinkRoomDoors(
		inst,
		source_room._ta_room_id:value(),
		direction,
		target,
		target_room._ta_room_id:value()
	)
end

local function MakePalaceDoor(definition)
	return function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		local minimap = inst.entity:AddMiniMapEntity()
		if definition.minimap_icon ~= nil then
			minimap:SetIcon(definition.minimap_icon)
		end

		inst.AnimState:SetBank(definition.bank)
		inst.AnimState:SetBuild(definition.build)
		inst.AnimState:PlayAnimation(definition.anim)
		if definition.layer ~= nil then
			inst.AnimState:SetLayer(definition.layer)
		end
		if definition.twofaced then
			inst.Transform:SetTwoFaced()
		end
		if definition.rotation ~= nil then
			inst.Transform:SetRotation(definition.rotation)
		end

		for _, tag in ipairs(definition.tags) do
			inst:AddTag(tag)
		end
		inst:AddTag("interior_door")

		-- Match the map-facing interface of player-house extension doors while
		-- retaining the palace's own visuals and gameplay behavior.
		inst._ta_target_door = net_entity(inst.GUID, "ta_palace_door.target")
		inst._ta_room_direction = net_tinybyte(inst.GUID, "ta_palace_door.direction")
		inst.GetRoomDirection = GetRoomDirection

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		AddDoorComponents(inst, definition)
		ConfigureRoomLink(inst)
		-- Older palace saves retain teleporter targets but predate the map-link
		-- fields. Rebuild those fields after component references are restored.
		inst:DoTaskInTime(1, RestoreRoomLink)
		return inst
	end
end

local function shadowfnsouth()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("palace_door")
	inst.AnimState:SetBuild("palace_door")
	inst.AnimState:PlayAnimation("south_floor")
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK")
	inst:AddTag("SELECT_ME")

	return inst
end

local DOOR_TAGS = {
	"trader",
	"alltrader",
	"hamletteleport",
	"antlion_sinkhole_blocker",
}

local function WithTags(tags, ...)
	local result = {}
	for _, tag in ipairs(tags) do
		table.insert(result, tag)
	end
	for _, tag in ipairs({ ... }) do
		table.insert(result, tag)
	end
	return result
end

return Prefab("pig_palace_entrance", entrance),
	Prefab("pig_palace_floor", SpawnPiso1, assets),
	Prefab("pig_palace_gallery_floor", SpawnPiso2, assets),
	Prefab("pig_palace_shop_floor", SpawnPiso3, assets),
	Prefab("wallpalace", wall_common1, assets),
	Prefab("wallshop", wall_common2, assets),
	Prefab("wallgallery", wall_common3, assets),

	Prefab("palace_door_saida", MakePalaceDoor({
		bank = "palace_door",
		build = "palace_door",
		anim = "south",
		minimap_icon = "vamp_bat_cave.tex",
		tags = WithTags(DOOR_TAGS, "guard_entrance"),
		hamlet = true,
		hauntable = true,
	}), assets),
	Prefab("palace_door_west", MakePalaceDoor({
		bank = "wall_decals_palace",
		build = "interior_wall_decals_palace",
		anim = "door_sidewall",
		rotation = 270,
		layer = LAYER_WORLD_BACKGROUND,
		tags = WithTags(DOOR_TAGS, "lockable_door", "door_east"),
		save = true,
	}), assets),
	Prefab("gallery_door_west", MakePalaceDoor({
		bank = "wall_decals_palace",
		build = "interior_wall_decals_palace",
		anim = "door_sidewall",
		rotation = 270,
		tags = WithTags(DOOR_TAGS, "lockable_door", "door_west"),
		save = true,
	}), assets),
	Prefab("gallery_door_east", MakePalaceDoor({
		bank = "wall_decals_palace",
		build = "interior_wall_decals_palace",
		anim = "door_sidewall",
		rotation = 180,
		twofaced = true,
		tags = WithTags(DOOR_TAGS, "lockable_door", "door_east"),
		save = true,
	}), assets),
	Prefab("giftshop_door_south", MakePalaceDoor({
		bank = "pig_shop_doormats",
		build = "pig_shop_doormats",
		anim = "idle_giftshop",
		rotation = -90,
		layer = LAYER_WORLD_BACKGROUND,
		tags = WithTags(DOOR_TAGS, "guard_entrance"),
		save = true,
	}), assets),
	Prefab("giftshop_door_east", MakePalaceDoor({
		bank = "wall_decals_palace",
		build = "interior_wall_decals_palace",
		anim = "door_sidewall",
		rotation = 180,
		twofaced = true,
		tags = WithTags(DOOR_TAGS, "lockable_door", "door_east"),
		save = true,
	}), assets),

	Prefab("prop_door_shadowpalace", shadowfnsouth, assets, prefabs)
