--[[
	毒系统（debuff 化）接线中心

	- lootdropper postinit：支持按名增删掉落回调（中毒生物掉落物折损新鲜度）
	- TroApplyPoison / TroRemovePoison：全局毒接口。全部毒状态承载于 debuff
	  中毒 = poisoned_tro (buff_poisoned_tro)，免疫 = antitoxin_tro (buff_antitoxin_tro)
	- HUD：poisonover 全屏闪烁 + poisonstate netvar（0 无 / 1 中毒 / 2 免疫），
	  客户端徽章经 netvar 读取，不再依赖服务端组件
--]]
AddComponentPostInit("lootdropper", function(self, inst)
	self.loot_postinits = {}

	self.SetLootPostInit = function(_self, name, fn)
		if type(fn) == "function" then
			_self.loot_postinits[name] = fn
		end
	end

	self.RemoveLootPostInit = function(_self, name)
		_self.loot_postinits[name] = nil
	end

	self.old_SpawnLootPrefabVB = self.SpawnLootPrefab
	self.SpawnLootPrefab = function(_self, lootprefab, pt)
		local loot = _self.old_SpawnLootPrefabVB(_self, lootprefab, pt)
		if loot and _self.loot_postinits then
			-- 修复：loot_postinits 是按名索引的字典，ipairs 永远遍历不到，这里改用 pairs
			for _, loot_postinit in pairs(_self.loot_postinits) do
				loot = loot_postinit(_self, loot)
			end
		end
		return loot
	end
end)

local POISON_DEFAULT_DURATION = 60 * 16

local function TargetHasPoisonBlock(target)
	if target.prefab == "wx78" then
		return true
	end
	if not target:HasTag("player") or target.components.inventory == nil then
		return false
	end
	local corpo = target.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
	local cabeca = target.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
	if corpo and corpo.prefab == "armorseashell" then
		return true
	end
	if cabeca and cabeca.prefab == "oxhat" then
		return true
	end
	return false
end

-- 免疫吸收毒素时的绿色一次性气泡（对应旧 SetPoison 免疫分支的特效）
local function SpawnPoisonAbsorbFX(target)
	local fx = GLOBAL.SpawnPrefab("poisonbubble_level1")
	fx.AnimState:SetHSV(130 / 360, 1, .9)
	target:AddChild(fx)
	local burnable = target.components.burnable
	if burnable and #burnable.fxdata > 0 then
		local symbol = burnable.fxdata[1].follow
		if symbol then
			fx.Follower:FollowSymbol(target.GUID, symbol, 0, 0, 0)
		end
	end
end

local function RefreshImmuneDisplay(target)
	if target.components.medal_showbufftime ~= nil then
		target.components.medal_showbufftime:SetBuffInfo()
		if target.replica ~= nil and target.replica.medal_showbufftime ~= nil then
			target.replica.medal_showbufftime:GetBuffInfo()
		end
	end
end

--[[
	施加毒素。返回是否成功中毒（免疫吸收/被抵挡/无效目标返回 false）。
	dmg 缺省 -1，interval 缺省 5，duration 缺省 60*16。
--]]
GLOBAL.TroApplyPoison = function(target, dmg, interval, duration)
	if target == nil or not target:IsValid() or target.components.health == nil then
		return false
	end
	if target:HasTag("poisonimmune") or TargetHasPoisonBlock(target) then
		return false
	end
	duration = duration or POISON_DEFAULT_DURATION

	if target.components.debuffable == nil then
		target:AddComponent("debuffable")
	end
	local debuffable = target.components.debuffable

	local antitoxin = debuffable:GetDebuff("antitoxin_tro")
	if antitoxin ~= nil then
		-- 免疫状态吸收毒素：按本次毒 duration 的一半消耗免疫剩余时间（对应旧 SetPoison 的免疫分支）
		local left = antitoxin.components.timer:GetTimeLeft("buffover") or 0
		local nextleft = left - duration / 2
		if nextleft > 0 then
			antitoxin.components.timer:SetTimeLeft("buffover", nextleft)
			SpawnPoisonAbsorbFX(target)
			RefreshImmuneDisplay(target)
			return false
		end
		-- 免疫耗尽，本次命中直接中毒
		debuffable:RemoveDebuff("antitoxin_tro")
	end

	target:AddDebuff("poisoned_tro", "buff_poisoned_tro",
		{ dmg = dmg or -1, interval = interval or 5, duration = duration }, true)
	return true
end

--[[
	解除毒素。immuneduration 非空时同时授予解毒免疫（与剩余免疫取 max，对应旧 WearOff 语义）；
	否则连同免疫一起清除（对应旧 WearOff() 的 ResetValues 语义）。返回是否成功执行。
--]]
GLOBAL.TroRemovePoison = function(target, immuneduration)
	if target == nil or not target:IsValid() then
		return false
	end
	if target.components.debuffable == nil then
		if immuneduration == nil then
			return false -- 目标从未有过任何毒状态
		end
		target:AddComponent("debuffable")
	end
	local debuffable = target.components.debuffable

	debuffable:RemoveDebuff("poisoned_tro")

	if immuneduration ~= nil then
		local antitoxin = debuffable:GetDebuff("antitoxin_tro")
		if antitoxin ~= nil then
			local left = antitoxin.components.timer:GetTimeLeft("buffover") or 0
			antitoxin.components.timer:SetTimeLeft("buffover", math.max(left, immuneduration))
			RefreshImmuneDisplay(target)
		else
			target:AddDebuff("antitoxin_tro", "buff_antitoxin_tro", { duration = immuneduration }, true)
		end
		return true
	end

	debuffable:RemoveDebuff("antitoxin_tro")
	return true
end

--------------poison-------by EvenMr----------------------------------------------------------------

AddClassPostConstruct("screens/playerhud", function(inst)
	local PoisonOver = require("widgets/poisonover")
	local fn = inst.CreateOverlays
	function inst:CreateOverlays(owner)
		fn(self, owner)
		self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
	end
end)

local function OnPoisonOverDirty(inst)
	if inst._parent and inst._parent.HUD then
		if inst.poisonover:value() then
			inst._parent.HUD.poisonover:Flash()
		end
	end
end

AddPrefabPostInit("player_classified", function(inst)
	inst.poisonover = GLOBAL.net_bool(inst.GUID, "poison.poisonover", "poisonoverdirty")
	inst.poisonstate = GLOBAL.net_smallbyte(inst.GUID, "poison.poisonstate", "poisonstatedirty")
	inst:ListenForEvent("poisonoverdirty", OnPoisonOverDirty)
end)
