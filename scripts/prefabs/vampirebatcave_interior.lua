require "prefabutil"

local InteriorRoomBuilder = require "tools/interior_room_builder"
local ROOM_SIZES = require("datadefs/interior").sizes

local assets =
{
	Asset("ANIM", "anim/pisohamlet.zip"),
	Asset("ANIM", "anim/wallhamletant.zip"),
	Asset("ANIM", "anim/bat_cave_door.zip"),
}

local function getlocationoutofcenter(dist, hole, random, invert)
	local pos = (math.random() * ((dist / 2) - (hole / 2))) + hole / 2
	if invert or (random and math.random() < 0.5) then
		pos = pos * -1
	end
	return pos
end

local function entrance()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	--    inst.AnimState:SetBuild("palace")
	--    inst.AnimState:SetBank("palace")
	--    inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("vulcano_part")
	inst:AddTag("antlion_sinkhole_blocker")

	--------------------------------------------------inicio da criacao---------------------------------------

	local room = TheWorld.components.interior_manager:Allocate(nil, "vampirebat_cave")
	local shell = InteriorRoomBuilder.BuildShell(room, ROOM_SIZES.vampirebat_cave)
	local x, y, z = room.x, 0, room.z
	inst.exit = SpawnPrefab("roc_cave_door_entrada")
	inst.exit.Transform:SetPosition(x - 8, 0, z)
	inst.Transform:SetPosition(x, 0, z)
	---------------------------------itens de dentro----------------------------
	local height = 18
	local width = 26

	local part = SpawnPrefab("deco_cave_cornerbeam")
	if part ~= nil then
		part.Transform:SetPosition(x - height / 2, 0, z - width / 2)
		part.Transform:SetRotation(-90)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	local part = SpawnPrefab("deco_cave_cornerbeam")
	if part ~= nil then
		part.Transform:SetPosition(x - height / 2, 0, z + width / 2)
		part.Transform:SetRotation(180)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	local part = SpawnPrefab("deco_cave_pillar_side")
	if part ~= nil then
		part.Transform:SetPosition(x + height / 2, 0, z - width / 2)
		part.Transform:SetRotation(-90)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	local part = SpawnPrefab("deco_cave_pillar_side")
	if part ~= nil then
		part.Transform:SetPosition(x + height / 2, 0, z + width / 2)
		part.Transform:SetRotation(180)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	local part = SpawnPrefab("deco_cave_bat_burrow")
	if part ~= nil then
		part.Transform:SetPosition(x, 0, z)
		part.Transform:SetRotation(-90)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	for i = 1, math.random(1, 3) do
		local part = SpawnPrefab("deco_cave_ceiling_trim")
		if part ~= nil then
			part.Transform:SetPosition(x - height / 2, 0, z + getlocationoutofcenter(width * 0.6, 3, true))
			part.Transform:SetRotation(180)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	local part = SpawnPrefab("deco_cave_floor_trim_front")
	if part ~= nil then
		part.Transform:SetPosition(x + height / 2, 0, z - width / 4)
		part.Transform:SetRotation(-90)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	local part = SpawnPrefab("deco_cave_floor_trim_front")
	if part ~= nil then
		part.Transform:SetPosition(x + height / 2, 0, z)
		part.Transform:SetRotation(-90)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	local part = SpawnPrefab("deco_cave_floor_trim_front")
	if part ~= nil then
		part.Transform:SetPosition(x + height / 2, 0, z + width / 4)
		part.Transform:SetRotation(-90)
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	if math.random() < 0.7 then
		local part = SpawnPrefab("deco_cave_floor_trim_2")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height / 2 * 0.5, 0, z - width / 2)
			part.Transform:SetRotation(-90)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.7 then
		local part = SpawnPrefab("deco_cave_floor_trim_2")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height / 2 * 0.5, 0, z + width / 2)
			part.Transform:SetRotation(180)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.7 then
		local part = SpawnPrefab("deco_cave_ceiling_trim_2")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height / 2 * 0.5, 0, z - width / 2)
			part.Transform:SetRotation(-90)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.7 then
		local part = SpawnPrefab("deco_cave_ceiling_trim_2")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height / 2 * 0.5, 0, z + width / 2)
			part.Transform:SetRotation(180)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("deco_cave_beam_room")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.65) - height / 2 * 0.65, 0,
				z + getlocationoutofcenter(width * 0.65, 7, false, true))
			part.Transform:SetRotation(-90)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("deco_cave_beam_room")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.65) - height / 2 * 0.65, 0,
				z + getlocationoutofcenter(width * 0.65, 7))
			part.Transform:SetRotation(-90)
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	local part = SpawnPrefab("flint")
	if part ~= nil then
		part.Transform:SetPosition(x + getlocationoutofcenter(height * 0.65, 3, true), 0,
			z + getlocationoutofcenter(width * 0.65, 3, true))
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("flint")
		if part ~= nil then
			part.Transform:SetPosition(x + getlocationoutofcenter(height * 0.65, 3, true), 0,
				z + getlocationoutofcenter(width * 0.65, 3, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	local part = SpawnPrefab("stalagmite")
	if part ~= nil then
		part.Transform:SetPosition(x + getlocationoutofcenter(height * 0.65, 4, true), 0,
			z + getlocationoutofcenter(width * 0.65, 4, true))
		if part.components.health ~= nil then
			part.components.health:SetPercent(1)
		end
	end


	if math.random() < 0.5 then
		if math.random() < 0.5 then
			local part = SpawnPrefab("stalagmite")
			if part ~= nil then
				part.Transform:SetPosition(x + getlocationoutofcenter(height * 0.65, 4, true), 0,
					z + getlocationoutofcenter(width * 0.65, 4, true))
				if part.components.health ~= nil then
					part.components.health:SetPercent(1)
				end
			end
		else
			local part = SpawnPrefab("stalagmite_tall")
			if part ~= nil then
				part.Transform:SetPosition(x + getlocationoutofcenter(height * 0.65, 4, true), 0,
					z + getlocationoutofcenter(width * 0.65, 4, true))
				if part.components.health ~= nil then
					part.components.health:SetPercent(1)
				end
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("stalagmite_tall")
		if part ~= nil then
			part.Transform:SetPosition(x + getlocationoutofcenter(height * 0.65, 3, true), 0,
				z + getlocationoutofcenter(width * 0.65, 3, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("deco_cave_stalactite")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height * 0.5 / 2, 0,
				z + getlocationoutofcenter(width, 6, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("deco_cave_stalactite")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height * 0.5 / 2, 0,
				z + getlocationoutofcenter(width, 6, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("deco_cave_stalactite")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height * 0.5 / 2, 0,
				z + getlocationoutofcenter(width, 6, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	if math.random() < 0.5 then
		local part = SpawnPrefab("deco_cave_stalactite")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height * 0.5 / 2, 0,
				z + getlocationoutofcenter(width, 6, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	for i = 1, math.random(2, 5) do
		local part = SpawnPrefab("cave_fern")
		if part ~= nil then
			part.Transform:SetPosition(x + (math.random() * height * 0.5) - height * 0.5 / 2, 0,
				z + getlocationoutofcenter(width * 0.7, 3, true))
			if part.components.health ~= nil then
				part.components.health:SetPercent(1)
			end
		end
	end

	--------------------------------------------cria caverna e conecta com a saida-------------------------------------------------------	
	InteriorRoomBuilder.FitContents(shell, { inst })

	inst:DoTaskInTime(2, function(inst)
		local portaentrada = SpawnPrefab("vampirebatcave")
		local a, b, c = inst.Transform:GetWorldPosition()
		portaentrada.Transform:SetPosition(a, b, c)
		if portaentrada.components.teleporter then
			portaentrada.components.teleporter.targetTeleporter = inst.exit
			inst.exit.components.teleporter.targetTeleporter = portaentrada
		end
		inst:Remove()
	end)



	return inst
end

---------------------------------pisos---------------------------------------------------------------------------
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
	inst.AnimState:PlayAnimation("batcave_floor")
	inst:AddTag("caveinterior")

	inst:AddTag("NOCLICK")
	inst:AddTag("alt_tile")
	inst:AddTag("vulcano_part")
	inst:AddTag("terremoto")
	inst:AddTag("canbuild")
	inst:AddTag("interior_center")

	return inst
end

local function wall_common(build)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("wallhamletant")
	inst.AnimState:SetBuild("wallhamletant")
	inst.AnimState:PlayAnimation("batcave_wall_rock", true)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(7)
	inst.AnimState:SetScale(4.5, 4.5, 4.5)

	return inst
end

return Prefab("vampirebatcave_entrance", entrance),
	Prefab("vampirebatcave_floor", SpawnPiso1, assets),
	Prefab("wallinteriorvampirebatcave", wall_common, assets)
