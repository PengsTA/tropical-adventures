--用于管理房间的客户端相关内容
local RoomManager = Class(function(self, inst)
	self.room = inst --房间本体
	self._synttiles = nil
	--仅仅主机端执行的
	if TheWorld.ismastersim then
		self.walls = {} --所有墙
		inst:ListenForEvent("onupgrade", function(inst, data, type)
			self:onupgrade(inst, data, type)
		end)
	end
end)
--------------------------------------------------------------------------
---------------------[[ 地下室内部 ]]--------------------------------------
--------------------------------------------------------------------------
--清除地下室的瓷砖
function RoomManager:RemoveSyntTiles()
	--客户端，主机端同时执行
	if self._synttiles ~= nil then
		local x, y, z = self.room.Transform:GetWorldPosition()
		for _, v in pairs(self._synttiles) do
			BM.Map.RemoveSyntTile(x + v.x, 0, z + v.z)
		end
		self._synttiles = nil
	end
end

local Rectangle = function(grid, step)
	local _x, _z = grid:match("(%d+)x(%d+)")
	local t = {}
	local offset = { x = _x / 2, z = _z / 2 }

	-- print("offsetx为",offset.x,offset.z)
	-- print("信息为",0, _x, step,0, _z, step)
	for x = 0, _x, step do
		for z = 0, _z, step do
			table.insert(t, { x = x - offset.x, z = z - offset.z })
		end
	end
	return t
end
--增加26X26的瓷砖
--用来限制玩家位置的--需要是外墙减6
function RoomManager:AddSyntTiles()
	local str = tostring((self.room.level_bm:value()) * 4 - 2) .. "x" .. tostring((self.room.level_bm:value()) * 4 - 2)
	self._synttiles = BM.Rectangle(str, true, true, 4)
	local x, y, z = self.room.Transform:GetWorldPosition()
	for k, v in pairs(self._synttiles) do
		BM.Map.AddSyntTile(x + v.x, 0, z + v.z)
	end
	--房间拆除时进行删除
	self.room:ListenForEvent("onremove", function()
		self:RemoveSyntTiles()
	end)
end

------------------------------------------------------------------------------------------
---------------------------------[[ 仅仅主机端执行的 ]]--------------------------------------
-------------------------------------------------------------------------------------------
--删除所有墙
function RoomManager:DespawnInteriorWalls()
	if TheWorld.ismastersim and next(self.walls) then
		for k, v in pairs(self.walls) do
			if v:IsValid() then
				v:Remove()
			end
		end
		self.walls = {}
	end
end

--生成墙
function RoomManager:SpawnInteriorWalls()
	if TheWorld.ismastersim then
		self:DespawnInteriorWalls()
		local x, y, z = self.room.Transform:GetWorldPosition()
		--和墙的位置进行匹配
		local str = tostring((self.room.level) * 4 + 2) .. "x" .. tostring((self.room.level) * 4 + 2)
		for _, v in pairs(BM.Rectangle(str, true)) do
			local part = SpawnPrefab(self.room.wall)
			if not part then return end
			table.insert(self.walls, part)
			part.Transform:SetPosition(x + v.x, 0, z + v.z)
		end
	end
end

--更新墙的类型
function RoomManager:SetWallType(type)
	if TheWorld.ismastersim and type then
		self.room.wall = type
		self:SpawnInteriorWalls()
	end
end

function RoomManager.DespawnGarden(inst)
	-- print("删除地下室")
	if not (inst and inst:IsValid()) then return end
	local bx, by, bz = inst.garden.core.Transform:GetWorldPosition()
	local ex, ey, ez = inst.garden.entrance.Transform:GetWorldPosition()
	local range = 20
	for _, entity in pairs(inst.garden) do
		if entity.OnEntitySleep then
			entity:OnEntitySleep()
			range = ((entity.level or 7) * 5) or 20
		end
		BM.Replace(entity, "Remove")
		entity:Remove()
	end
	if not ex then --房子位置不存在，炫彩之门
		for k, v in pairs(Ents) do
			if v:HasTag("multiplayer_portal") then
				ex, ey, ez = v.Transform:GetWorldPosition()
			end
		end
	end
	if not ex then
		ex, ey, ez = 0, 0, 0
	end
	local ents = TheSim:FindEntities(bx, by, bz, range, nil, { "INLIMBO" })
	for i, v in ipairs(ents) do
		if v:HasTag("player") or v:HasTag("irreplaceable") then
			if v.Physics ~= nil then
				v.Physics:Teleport(ex, ey, ez)
			elseif v.Transform ~= nil then
				v.Transform:SetPosition(ex, ey, ez)
			end
		elseif v.components.workable ~= nil then
			v.components.workable:Destroy(v)
		elseif v.components.perishable ~= nil then
			v.components.perishable:LongUpdate(10000)
		elseif v.components.finiteuses ~= nil then
			v.components.finiteuses:Use(10000)
		elseif v.components.fueled ~= nil then
			v.components.fueled:DoUpdate(10000)
		end
		if v and v:IsValid() and not v:HasTag("irreplaceable") then
			v:Remove()
		end
	end
	--删除的物品
	TheWorld:DoTaskInTime(0.5, function(world)
		local ents2 = TheSim:FindEntities(bx, by, bz, range)
		for i, v in ipairs(ents2) do
			if v and v.components.inventoryitem ~= nil then
				if v.Physics ~= nil then
					v.Physics:Teleport(ex, ey, ez)
				elseif v.Transform ~= nil then
					v.Transform:SetPosition(ex, ey, ez)
				end
			else
				v:Remove()
			end
		end
		ents = TheSim:FindEntities(bx, by, bz, 25 * 4, nil, { "INLIMBO" })
		for i, v in ipairs(ents) do
			if v:HasTag("player") or v:HasTag("irreplaceable") then
				if v.Physics ~= nil then
					v.Physics:Teleport(ex, ey, ez)
				elseif v.Transform ~= nil then
					v.Transform:SetPosition(ex, ey, ez)
				end
			end
			if v and v:IsValid() and not v:HasTag("irreplaceable") then
				v:Remove()
			end
		end
	end)
end

--检查是否生成了地下室--并连接中心，入口，出口，并将三个实体都附在上面
function RoomManager:CheckReferences(inst)
	if inst.garden ~= nil then return end
	local garden = { core = inst }
	local x, y, z = inst.Transform:GetWorldPosition()
	--找出口
	local exit = TheSim:FindEntities(x, 0, z, (inst.level) * 4, { "garden_part", "garden_exit" })[1]
	if exit ~= nil then
		--花园出口
		garden.exit = exit
		if exit.components.teleporter ~= nil then
			--花园入口
			garden.entrance = exit.components.teleporter.targetTeleporter
		end
		--设置出口位置
		exit.Transform:SetPosition(x, y, z)
		-- else
		-- 	print("没找到")
	end
	--替换删除函数
	for name, entity in pairs(garden) do
		BM.Replace(entity, "Remove", self.DespawnGarden)
		entity.garden = garden
	end
end

--更新墙和地板的函数
function RoomManager:onupgrade(inst, data, type)
	if string.find(data.source, "wall") then --墙
		local walls = "garden_" .. data.source
		if walls ~= inst.wall then
			inst.wall = walls
			self:SpawnInteriorWalls()
		end
	elseif data.source == "addlevel" then --增加等级
		if inst.level >= 23 then
			inst.components.lootdropper:SpawnLootPrefab("candy_log")
			inst.components.lootdropper:SpawnLootPrefab("candy_log")
			inst.components.lootdropper:SpawnLootPrefab("boards")
			inst.components.lootdropper:SpawnLootPrefab("cutstone")
			inst.components.lootdropper:SpawnLootPrefab("cutstone")
			inst.components.lootdropper:SpawnLootPrefab("cutstone")
			inst.components.lootdropper:SpawnLootPrefab("boards")
			inst.components.lootdropper:SpawnLootPrefab("boards")
			for k, _ in pairs(inst.allplayers) do
				if k and k:IsValid() and k.components and k.components.talker then
					k.components.talker:Say("面积已经达到上限")
					return
				end
			end
		end
		inst.level = inst.level + 2
		inst.level_bm:set(inst.level)
		self:SpawnInteriorWalls()
		self:AddSyntTiles()
	elseif string.find(data.source, "back") then
		inst.back = data.source:match("(.+)_back") or "brich"
		inst.playanim(inst)
	else
		inst.floor = data.source:match("(.+)_turf") or "brich"
		inst.playanim(inst)
	end
end

local prefab_list = {
	berrybush = 10,     --普通浆果
	berrybush2 = 10,    --三叶浆果丛
	carrot_planted = 20, --胡萝卜
	deciduoustree = 40, --桦木树
	evergreen = 30,     --常青树
	evergreen_sparse = 20, --常青树--变异
	-- flower=20,--花
	rock1 = 10,         --普通岩石
	rock_flintless = 10, --全是石头
	blue_mushroom = 10,
	green_mushroom = 10,
	red_mushroom = 10,
}
function RoomManager:Spawn(x, y, z)
	--半径20块地皮
	local item = nil
	for k, v in pairs(prefab_list) do
		for i = 0, v * 2 do
			if TUNING.BACK_BM then
				local newx, newz = math.random(x - 76, x + 76), math.random(z - 76, z + 76)
				item = SpawnPrefab(k)
				if item then
					item.Transform:SetPosition(newx, 0, newz)
				end
			else
				local newx, newz = math.random(x - 44, x + 44), math.random(z - 44, z + 44)
				item = SpawnPrefab(k)
				if item then
					item.Transform:SetPosition(newx, 0, newz)
				end
			end
		end
	end
	for i = 0, 30 do
		local newx, newz = math.random(x - 44, x + 44), math.random(z - 44, z + 44)
		item = SpawnPrefab("flower")
		if item then
			item.Transform:SetPosition(newx, 0, newz)
		end
	end
	item = SpawnPrefab("candy_tree")
	if item then
		item.Transform:SetPosition(x + math.random(-14, 14), 0, z + math.random(-8, 14))
	end

	item = SpawnPrefab("candy_tree")
	if item then
		item.Transform:SetPosition(x - math.random(4, 8), 0, z - math.random(8, 12))
	end
end

return RoomManager
