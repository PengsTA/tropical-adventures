local AddAction = AddAction
local ACTIONS = ACTIONS
local Action = Action
local STRINGS = STRINGS
local BoatEquip = require("tools/boat_equipment_helper")
local BoatRepair = require("tools/boat_repair_helper")

AddAction("LAVASPIT",
    "spit",
    function(act)
        if act.doer and act.target and act.doer.prefab == "dragoon" then
            local spit = SpawnPrefab("dragoonspit")
            local x, y, z = act.doer.Transform:GetWorldPosition()
            local downvec = TheCamera:GetDownVec()
            local offsetangle = math.atan2(downvec.z, downvec.x) * (180 / math.pi)
            while offsetangle > 180 do
                offsetangle = offsetangle - 360
            end
            while offsetangle < -180 do
                offsetangle = offsetangle + 360
            end
            local offsetvec = Vector3(math.cos(offsetangle * DEGREES), -.3, math.sin(offsetangle * DEGREES)) * 1.7
            spit.Transform:SetPosition(x + offsetvec.x, y + offsetvec.y, z + offsetvec.z)
            spit.Transform:SetRotation(act.doer.Transform:GetRotation())
        end
    end
)

-- DEPLOY_AI Action [FIX FOR MOBS THAT PLANT TREES]
AddAction("DEPLOY_AI",
    "Deploy AI",
    function(act)
        if act.invobject and act.invobject.components.deployable then
            local obj =
                (act.doer.components.inventory and act.doer.components.inventory:RemoveItem(act.invobject)) or
                (act.doer.replica.container and act.doer.replica.container:RemoveItem(act.invobject))
            if obj then
                if obj.components.deployable:ForceDeploy(act:GetActionPoint(), act.doer, act.rotation) then
                    return true
                else
                    act.doer.components.inventory:GiveItem(obj)
                end
            end
        end
    end
)



AddAction("FLUP_HIDE",
    "Flup Hide",
    function(act)
        --Dummy action for flup hiding
    end
)

AddAction("FISH1",
    "Fish1",
    function(act)
        local fishingrod =
            (act.invobject and act.invobject.components.fishingrod) or (act.doer and act.doer.components.fishingrod)

        if fishingrod then
            fishingrod:StartFishing(act.target, act.doer)
        end
        return true
    end
)

AddAction("TIGERSHARK_FEED",
    "Tigershark Feed",
    function(act)
        local doer = act.doer
        if doer and doer.components.lootdropper then
            doer.components.lootdropper:SpawnLootPrefab("wetgoop")
        end
    end
)

AddAction("MATE",
    "Mate",
    function(act)
        if act.target == act.doer then
            return false
        end

        if act.doer.components.mateable then
            act.doer.components.mateable:Mate()
            return true
        end
    end
)

AddAction("CRAB_HIDE",
    "Crab Hide",
    function(act)
        --Dummy action for crab.
    end
)

AddAction("HIDECRAB",
    "Hide",
    function(act)
        if act.doer then
            return true
        end
    end)

AddAction("SHOWCRAB",
    "Emerge",
    function(act)
        if act.doer then
            return true
        end
    end)

--[[
AddAction(    "THROW",
    "Throw",
    function(act)
	local thrown = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if act.target and not act.pos then
		act.pos = act.target:GetPosition()
	end
	if thrown and thrown.components.throwable then
		thrown.components.throwable:Throw(act.pos, act.doer)
		return true
	end
    end
)
]]

local THROW = Action({ priority = 0, rmb = true, distance = 20, mount_valid = true })
THROW.str = "Throw"
THROW.id = "THROW"
THROW.fn = function(act)
    local thrown = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if act.target and not act.pos then
        act.pos = act.target:GetPosition()
    end
    if thrown and thrown.components.throwable then
        thrown.components.throwable:Throw(act.pos, act.doer)
        return true
    end
end
AddAction(THROW)

--actions hamlet--
AddAction(
    "PEAGAWK_TRANSFORM",
    "Peagank Transform",
    function(act)
        --Dummy action for flup hiding
    end
)

AddAction(
    "MANUALEXTINGUISH",
    "Manualextinguish",
    function(act)
        if act.doer:HasTag("extinguisher") then
            if act.target.components.burnable and act.target.components.burnable:IsBurning() then
                act.target.components.burnable:Extinguish()
                return true
            end
        elseif act.target.components.sentientball then
            act.target.components.burnable:Extinguish()
            -- damage player?
            return true
        elseif act.invobject:HasTag("frozen") and act.target.components.burnable and act.target.components.burnable:IsBurning() then
            act.target.components.burnable:Extinguish(true, TUNING.SMOTHERER_EXTINGUISH_HEAT_PERCENT, act.invobject)
            return true
        end
    end
)

AddAction(
    "SPECIAL_ACTION",
    "Special Actions",
    function(act)
        if act.doer.special_action then
            act.doer.special_action(act)
            return true
        end
    end
)

AddAction(
    "SPECIAL_ACTION2",
    "Special Actions2",
    function(act)
        if act.doer.special_action2 then
            act.doer.special_action2(act)
            return true
        end
    end
)


AddAction(
    "LAUNCH_THROWABLE",
    "Launch Throwable",
    function(act)
        if act.target and not act.pos then
            act.pos = act.target:GetPosition()
        end
        act.invobject.components.thrower:Throw(act.pos)
        return true
    end
)

AddAction(
    "INFEST",
    "Infest",
    function(act)
        if not act.doer.infesting then
            act.doer.components.infester:Infest(act.target)
        end
    end
)

AddAction(
    "DIGDUNG",
    "Digdung",
    function(act)
        act.target.components.workable:WorkedBy(act.doer, 1)
    end
)

AddAction(
    "MOUNTDUNG",
    "Mountdung",
    function(act)
        act.doer.dung_target:Remove()
        act.doer:AddTag("hasdung")
        act.doer.dung_target = nil
    end
)

AddAction(
    "BARK",
    "Bark",
    function(act)
        return true
    end
)

AddAction(
    "RANSACK",
    "Ransack",
    function(act)
        return true
    end
)

AddAction(
    "CUREPOISON",
    "Curepoison",
    function(act)
        if act.invobject and act.invobject.components.poisonhealer then
            local target = act.target or act.doer
            return act.invobject.components.poisonhealer:Cure(target)
        end
    end
)

AddAction(
    "USEDOOR",
    "Usedoor",
    function(act)
        if act.target:HasTag("secret_room") then
            return false
        end

        if act.target.components.door and not act.target.components.door.disabled then
            act.target.components.door:Activate(act.doer)
            return true
        elseif act.target.components.door and act.target.components.door.disabled then
            return false, "LOCKED"
        end
    end
)

local SHOP = Action({ priority = 9, rmb = true, distance = 1, mount_valid = false })

-- fixed: 客户机鼠标放在 shop_buyer 对象上不显示物品名称和价格
-- note: 针对 SHOP.stroverridefn = function(act) ... end
--       尝试 return nil 会自动使用 ACTION 作为前缀
--       尝试 return 包括空字符串在内的任何字符串都会屏蔽 named 组件的名称显示
--       考虑屏蔽原有的 SHOP.stroverridefn 处理逻辑
SHOP.stroverridefn = function(act)
    return act.target:GetBasicDisplayName() or "SHOP"
end

-- note: 屏蔽原有的 ( ACTION ), 使用 STRINGS.ACTIONS.SHOP
-- TODO: 我需要一个更加优雅的实现, 最好连 STRINGS.ACTIONS.SHOP 都不要显示
-- fixed end




SHOP.id = "SHOP"
SHOP.fn = function(act)
    if act.doer.components.inventory then
        if act.doer:HasTag("player") and act.doer.components.shopper then
            if act.doer.components.shopper:IsWatching(act.target) then
                local sell = true
                local reason = nil

                if act.target:HasTag("shopclosed") or TheWorld.state.isnight then
                    reason = "closed"
                    sell = false
                elseif not act.doer.components.shopper:CanPayFor(act.target) then
                    local prefab_wanted = act.target.costprefab
                    if prefab_wanted == "oinc" then
                        reason = "money"
                    else
                        reason = "goods"
                    end
                    sell = false
                end

                if sell then
                    act.doer.components.shopper:PayFor(act.target)
                    act.target.components.shopdispenser:RemoveItem()
                    act.target:SetImage(nil)

                    if act.target and act.target.shopkeeper_speech then
                        act.target.shopkeeper_speech(act.target,
                            STRINGS.CITY_PIG_SHOPKEEPER_SALE[math.random(1, #STRINGS.CITY_PIG_SHOPKEEPER_SALE)])
                    end

                    return true
                else
                    if reason == "money" then
                        if act.target and act.target.shopkeeper_speech then
                            act.target.shopkeeper_speech(act.target,
                                STRINGS.CITY_PIG_SHOPKEEPER_NOT_ENOUGH
                                [math.random(1, #STRINGS.CITY_PIG_SHOPKEEPER_NOT_ENOUGH)])
                        end
                    elseif reason == "goods" then
                        local itemname = act.target.costprefab or "oinc"
                        if act.target and act.target.shopkeeper_speech then
                            act.target.shopkeeper_speech(act.target,
                                subfmt(STRINGS.CITY_PIG_SHOPKEEPER_DONT_HAVE
                                    [math.random(1, #STRINGS.CITY_PIG_SHOPKEEPER_DONT_HAVE)], {
                                        item = STRINGS.NAMES[itemname and itemname:upper()] or "UNKNOWN",
                                    })
                            )
                        end
                    elseif reason == "closed" then
                        if act.target and act.target.shopkeeper_speech then
                            act.target.shopkeeper_speech(act.target,
                                STRINGS.CITY_PIG_SHOPKEEPER_CLOSING
                                [math.random(1, #STRINGS.CITY_PIG_SHOPKEEPER_CLOSING)])
                        end
                    end
                    return true
                end
            else
                -- act.doer.components.shopper:Take(act.target)
                -- -- THIS IS WHAT HAPPENS IF ISWATCHING IS FALSE
                -- -- print("SHOPPER IS NOT WATCHING")
                -- act.target.components.shopdispenser:RemoveItem()
                -- act.target:SetImage(nil)
                --暂时不让偷东西
                if act.target and act.target.shopkeeper_speech then
                    act.target.shopkeeper_speech(act.target,
                        STRINGS.CITY_PIG_SHOPKEEPER_CLOSING
                        [math.random(1, #STRINGS.CITY_PIG_SHOPKEEPER_CLOSING)])
                end
                return true
            end
        end
    end
end
SHOP.encumbered_valid = true
AddAction(SHOP)

AddAction(
    "FIX",
    "Fix",
    function(act)
        if act.target then
            local target = act.target
            local numworks = 1
            target.components.workable:WorkedBy(act.doer, numworks)
            --	return target:fix(act.doer)		
        end
    end
)

AddAction(
    "STOCK",
    "Stock",
    function(act)
        if act.target then
            act.target.restock(act.target, true)
            act.doer.changestock = nil
            return true
        end
    end
)
-- acoes do jogador--

local function ExtrarummageRange(doer, dest)
    if dest ~= nil then
        local target_x, target_y, target_z = dest:GetPoint()

        local is_on_water = TheWorld.Map:IsOceanTileAtPoint(target_x, 0, target_z) and
            not TheWorld.Map:IsPassableAtPoint(target_x, 0, target_z)
        if is_on_water then
            return 2
        end
    end
    return 0
end

ACTIONS.RUMMAGE.extra_arrive_dist = ExtrarummageRange
---
local BOATMOUNT = Action({ priority = 10, rmb = true, distance = 8, mount_valid = false })
BOATMOUNT.str = (STRINGS.ACTIONS.BOATMOUNT)
BOATMOUNT.id = "BOATMOUNT"
BOATMOUNT.fn = function(act)
    if act.doer and act.target and act.doer:HasTag("player") and act.target:HasTag("boatsw") then
        if act.doer.components.sailor ~= nil and act.target.components.sailable ~= nil then
            if act.doer.components.sailor:IsSailing() then
                act.doer.components.sailor:Disembark(nil, true)
            end
            return act.doer.components.sailor:BoatJump(act.target)
        end
    end
    return false
end
BOATMOUNT.encumbered_valid = true
AddAction(BOATMOUNT)



local BOATDISMOUNT = Action({ priority = 9, rmb = true, distance = 8, mount_valid = false })
BOATDISMOUNT.str = (STRINGS.ACTIONS.BOATDISMOUNT)
BOATDISMOUNT.id = "BOATDISMOUNT"
BOATDISMOUNT.fn = function(act)
    if act.doer ~= nil and act.doer:HasTag("player") then
        if act.doer.components.sailor ~= nil and act.doer.components.sailor:IsSailing() then
            return act.doer.components.sailor:BoatDismount(act:GetActionPoint())
        end
    end
    return false
end
BOATDISMOUNT.encumbered_valid = true
AddAction(BOATDISMOUNT)

local BOATEQUIP = Action({ priority = 10, rmb = true, mount_valid = true })
BOATEQUIP.str = STRINGS.ACTIONS.EQUIP or "Equip"
BOATEQUIP.id = "BOATEQUIP"
BOATEQUIP.fn = function(act)
    if act.doer == nil or act.invobject == nil then
        return false
    end

    local boat = BoatEquip.GetBoatForDoer(act.doer)
    local container = BoatEquip.GetBoatContainer(boat)

    return container ~= nil and container.BoatEquip ~= nil and container:BoatEquip(act.invobject, act.doer) or false
end
AddAction(BOATEQUIP)

local BOATUNEQUIP = Action({ priority = 10, rmb = true, mount_valid = true })
BOATUNEQUIP.str = STRINGS.ACTIONS.UNEQUIP or "Unequip"
BOATUNEQUIP.id = "BOATUNEQUIP"
BOATUNEQUIP.fn = function(act)
    if act.doer == nil or act.invobject == nil then
        return false
    end

    local boat = BoatEquip.GetBoatForDoer(act.doer)
    local container = BoatEquip.GetBoatContainer(boat)
    local eslot = BoatEquip.GetSlotForItem(act.invobject)
    if container == nil or container.BoatUnequip == nil or eslot == nil then
        return false
    end

    if BoatEquip.GetEquippedItem(container, eslot) ~= act.invobject then
        return false
    end

    return container:BoatUnequip(eslot, act.doer) ~= nil
end
AddAction(BOATUNEQUIP)

local SURF = Action({
    priority = 4,
    --is_relative_to_platform=true,
    --disable_platform_hopping=true,
    distance = 20
})
SURF.str = (STRINGS.ACTIONS.SURF)
SURF.id = "SURF"
SURF.fn = function(act)
    local doer_x, doer_y, doer_z = act.doer.Transform:GetWorldPosition()
    local planchadesurf = TheWorld.Map:GetPlatformAtPoint(doer_x, doer_z)
    if planchadesurf and planchadesurf:HasTag("planchadesurf") then
        local pos = act:GetActionPoint()
        if pos == nil then
            pos = act.target:GetPosition()
        end
        planchadesurf.components.oar:Row(act.doer, pos)
        planchadesurf.components.health:DoDelta(-0.5)

        return true
    end
end
SURF.encumbered_valid = true
AddAction(SURF)





local BOATCANNON = Action({ priority = 8, rmb = true, distance = 25, mount_valid = false })
BOATCANNON.str = (STRINGS.ACTIONS.BOATCANNON)
BOATCANNON.id = "BOATCANNON"
BOATCANNON.fn = function(act)
    if act.doer ~= nil and act.doer:HasTag("player") then
        act.doer:AddTag("deleidotiro")
        act.doer:DoTaskInTime(0.5, function(inst) act.doer:RemoveTag("deleidotiro") end)


        local equipamento = BoatEquip.GetBoatForDoer(act.doer)
        local canhao = BoatEquip.GetHead(BoatEquip.GetBoatContainer(equipamento))
        if canhao == nil then
            return false
        end
        --posiciona pra sair no canhao--
        local angle = act.doer:GetRotation()
        local dist = 1.5
        local offset = Vector3(dist * math.cos(angle * DEGREES), 0, -dist * math.sin(angle * DEGREES))
        local x, y, z = act.doer.Transform:GetWorldPosition()
        local x1, y1, z1
        local pos
        if act.target then
            x1, y1, z1 = act.target:GetPosition():Get()
            pos = act.target:GetPosition()
        else
            x1, y1, z1 = act:GetActionPoint():Get()
            pos = act:GetActionPoint()
        end

        local pt = Vector3(x, y, z)
        local bombpos = pt + offset
        local x, y, z = bombpos:Get()

        --

        if canhao and canhao.prefab == "obsidian_boatcannon" then
            if equipamento and canhao then canhao.components.finiteuses:Use(1) end
            local bomba = SpawnPrefab("cannonshotobsidian")
            bomba.Transform:SetPosition(x, y + 1.5, z)
            bomba.components.complexprojectile:Launch(pos)
            act.doer.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/knight_steamboat/cannon")
        else
            if equipamento and canhao and act.doer.prefab ~= "woodlegs" then
                canhao.components.finiteuses:Use(1)
                local bomba = SpawnPrefab("cannonshot")
                bomba.Transform:SetPosition(x, y + 1.5, z)
                bomba.components.complexprojectile:Launch(pos)
                act.doer.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/knight_steamboat/cannon")
            elseif equipamento and equipamento.prefab == "woodlegsboat" and canhao and act.doer.prefab == "woodlegs" then
                local bomba = SpawnPrefab("cannonshot")
                bomba.components.explosive.explosivedamage = 50
                bomba.Transform:SetPosition(x, y + 1.5, z)
                bomba.components.complexprojectile:Launch(pos)
                act.doer.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/knight_steamboat/cannon")
            elseif equipamento and canhao then
                canhao.components.finiteuses:Use(1)
                local bomba = SpawnPrefab("cannonshot")
                bomba.Transform:SetPosition(x, y + 1.5, z)
                bomba.components.complexprojectile:Launch(pos)
                act.doer.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/knight_steamboat/cannon")
            end
        end

        return true
    end
end
AddAction(BOATCANNON)
--[[
local TIRO = Action({ priority = 9, rmb = true, distance = 20, mount_valid = false })
TIRO.str = (STRINGS.ACTIONS.TIRO)
TIRO.id = "TIRO"
TIRO.fn = function(act)
    if act.doer ~= nil and act.doer:HasTag("ironlord") then
        return true
    end
end
--TIRO.encumbered_valid =true
AddAction(TIRO)
]]

local RETRIEVE = Action({ priority = 11, rmb = true, distance = 2, mount_valid = false })
RETRIEVE.str = (STRINGS.ACTIONS.RETRIEVE)
RETRIEVE.id = "RETRIEVE"

local PORTABLE_BOAT_ITEMS = {
    surfboard = "surfboard_item",
    corkboat = "corkboatitem",
}

local function GiveOrDropItem(doer, item, pos)
    if item == nil then
        return
    end

    if doer ~= nil and doer.components.inventory ~= nil and doer.components.inventory:GiveItem(item, nil, pos) then
        return
    end

    item.Transform:SetPosition(pos:Get())
end

local function MovePortableBoatEquipmentToPlayer(boat, doer)
    if boat.components.container == nil then
        return
    end

    for slot = 1, boat.components.container.numslots or 0 do
        local item = boat.components.container:RemoveItemBySlot(slot)
        if item ~= nil then
            if item.prefab == "quackeringram" then
                BoatEquip.SetItemSailor(item, nil)
            end
            GiveOrDropItem(doer, item, boat:GetPosition())
        end
    end
end

local function MakePortableBoatItem(boat)
    local itemprefab = PORTABLE_BOAT_ITEMS[boat.prefab]
    local item = itemprefab ~= nil and SpawnPrefab(itemprefab) or nil
    if item ~= nil and boat.components.boathealth ~= nil and item.SetBoatItemHealth ~= nil then
        item:SetBoatItemHealth(boat.components.boathealth.currenthealth)
    end
    return item
end

RETRIEVE.fn = function(act)
    if act.target.components.breeder and act.target.components.breeder.volume > 0 then
        return act.target.components.breeder:Harvest(act.doer)
    end

    if act.doer ~= nil and act.target ~= nil and act.doer:HasTag("player") and PORTABLE_BOAT_ITEMS[act.target.prefab] ~= nil then
        local item = MakePortableBoatItem(act.target)
        MovePortableBoatEquipmentToPlayer(act.target, act.doer)
        GiveOrDropItem(act.doer, item, act.target:GetPosition())
        act.target:Remove()
        return true
    end
end

AddAction(RETRIEVE)

--[[
local function ExtraDeployDist(doer, dest, bufferedaction)
	if dest ~= nil then
		local target_x, target_y, target_z = dest:GetPoint()

		local is_on_water = TheWorld.Map:IsOceanTileAtPoint(target_x, 0, target_z) and not TheWorld.Map:IsPassableAtPoint(target_x, 0, target_z)
		if is_on_water then
			return ((bufferedaction ~= nil and bufferedaction.invobject ~= nil and bufferedaction.invobject:HasTag("usedeployspacingasoffset") and bufferedaction.invobject.replica.inventoryitem ~= nil and bufferedaction.invobject.replica.inventoryitem:DeploySpacingRadius()) or 0) + 1.0
		end
	end
    return 0
end


ACTIONS.DEPLOY.distance = 6
]]



local BOATREPAIR = Action({ priority = 10, rmb = true, distance = 1, mount_valid = false })
BOATREPAIR.str = (STRINGS.ACTIONS.BOATREPAIR)
BOATREPAIR.id = "BOATREPAIR"

BOATREPAIR.fn = function(act)
    if act.doer and BoatRepair.IsRepairItem(act.invobject) then
        local boat = BoatRepair.GetActionTarget(act.doer, act.target)
        if boat == nil or not boat:IsValid() then
            return false
        end
        if act.target ~= nil and act.target ~= boat and not BoatRepair.IsBoatTarget(act.target) then
            return false
        end

        if boat.components.boathealth ~= nil then
            if boat.components.boathealth:IsFull() then
                return false
            end
            local repair_value = act.invobject.components.repairer ~= nil and act.invobject.components.repairer.healthrepairvalue or 150
            boat.components.boathealth:DoDelta(repair_value, "repair", act.doer)
            BoatRepair.ConsumeItem(act.invobject)
            return true
        end
    end
    return false
end

AddAction(BOATREPAIR)





local OPENTUNA = Action({ priority = 10, rmb = true, distance = 1, mount_valid = false })
OPENTUNA.str = (STRINGS.ACTIONS.OPENTUNA)
OPENTUNA.id = "OPENTUNA"
OPENTUNA.fn = function(act)
    if act.doer ~= nil and act.invobject ~= nil and act.invobject:HasTag("tunacan") then
        local nut = act.invobject
        if act.invobject.replica.inventoryitem then
            if act.invobject.components.stackable and act.invobject.components.stackable.stacksize > 1 then
                nut = act.invobject.components.stackable:Get()
            end
            if act.doer.components.inventory then
                local peixe = SpawnPrefab("fishmeat_cooked")
                act.doer.components.inventory:GiveItem(peixe, 1)
            end
        end
        nut:Remove()
        return true
    end
end
AddAction(OPENTUNA)

local DISLODGE = Action({ priority = 11, rmb = true, distance = 2, mount_valid = false })
DISLODGE.str = (STRINGS.ACTIONS.DISLODGE)
DISLODGE.id = "DISLODGE"
DISLODGE.fn = function(act)
    local equipamento = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if act.target.components.dislodgeable and act.target.components.dislodgeable.canbedislodged and act.target.components.dislodgeable.caninteractwith then
        if act.doer ~= nil and equipamento then
            if equipamento.components.finiteuses then
                equipamento.components.finiteuses:Use(1)
            end

            if equipamento and equipamento:HasTag("ballpein_hammer") then
                if act.target.components.dislodgeable then
                    act.target.components.dislodgeable:Dislodge(act.doer)
                end
                return true
            end
        end
    else
        return false
    end
end
AddAction(DISLODGE)


local SMELT = Action({ priority = 10, mount_valid = true })
SMELT.str = (STRINGS.ACTIONS.SMELT)
SMELT.id = "SMELT"
SMELT.fn = function(act)
    if act.target.components.melter then
        act.target.components.melter:StartCooking()
        return true
    end
end
AddAction(SMELT)

local GIVE2 = Action({ priority = 10, distance = 2, mount_valid = true })
GIVE2.str = (STRINGS.ACTIONS.GIVE)
GIVE2.id = "GIVE2"
GIVE2.fn = function(act)
    if act.invobject.components.inventoryitem then
        act.target.components.shelfer:AcceptGift(act.doer, act.invobject)
        return true
    end
end
AddAction(GIVE2)



local pickupfn = ACTIONS.PICKUP.fn
local extra_arrive_dist = ACTIONS.PICKUP.extra_arrive_dist

ACTIONS.PICKUP.extra_arrive_dist = function(doer, dest, ...)
    return dest and dest.inst and dest.inst:HasTag("shelfcanaccept") and 2 or extra_arrive_dist(doer, dest, ...) -- shelfer没有客机但是有tag, 试试这个
    --return doer:IsInHamRoom() and 2 or extra_arrive_dist(doer, dest, ...) ----检测房间也不是很合理，但是shelfer没有客机
end


ACTIONS.PICKUP.fn = function(act)
    if act.target and act.target.components.inventoryitem and act.target.components.shelfer then
        local item = act.target.components.shelfer:GetGift()
        if item then
            if item.components.perishable then item.components.perishable:StartPerishing() end
            act.target = act.target.components.shelfer:GiveGift()
        end
    end
    return pickupfn(act)
end

local old_HARVEST_fn = ACTIONS.HARVEST.fn
ACTIONS.HARVEST.fn = function(act)
    if act.target.components.melter then return act.target.components.melter:Harvest(act.doer) end
    return old_HARVEST_fn(act)
end


local PAN = Action({ priority = 10, mount_valid = true })
PAN.str = (STRINGS.ACTIONS.PAN)
PAN.id = "PAN"
PAN.fn = function(act)
    if act.target.components.workable and act.target.components.workable.action == ACTIONS.PAN then
        local numworks = 1

        if act.invobject and act.invobject.components.tool then
            numworks = act.invobject.components.tool:GetEffectiveness(ACTIONS.PAN)
        elseif act.doer and act.doer.components.worker then
            numworks = act.doer.components.worker:GetEffectiveness(ACTIONS.PAN)
        end
        act.target.components.workable:WorkedBy(act.doer, numworks)
    end
    return true
end
AddAction(PAN)


local INVESTIGATEGLASS = Action({ priority = 10, mount_valid = true, distance = 2 })
INVESTIGATEGLASS.str = STRINGS.ACTIONS.SPY ---怎么显示中文呢
INVESTIGATEGLASS.id = "INVESTIGATEGLASS"
INVESTIGATEGLASS.fn = function(act)
    if act.target:HasTag("secret_room") then
        act.target.Investigate(act.doer)
        return true
    end

    if act.target and act.target.components.mystery then
        act.target.components.mystery:Investigate(act.doer)

        local equipamento = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if act.doer ~= nil and equipamento then
            equipamento.components.finiteuses:Use(1)
        end

        return true
    end
end
AddAction(INVESTIGATEGLASS)


local function DoToolWork(act, workaction)
    if
        act.target.components.workable ~= nil and act.target.components.workable:CanBeWorked() and
        act.target.components.workable.action == workaction
    then
        if act.target:HasTag("grass_tall") then
            local equipamento = act.doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equipamento and equipamento.prefab == "shears" then
                local x, y, z = act.target.Transform:GetWorldPosition()
                local gramaextra = SpawnPrefab("cutgrass")
                if gramaextra then gramaextra.Transform:SetPosition(x, y, z) end
            end
        end

        if act.target:HasTag("hedgetoshear") then
            local equipamento = act.doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equipamento and equipamento.prefab == "shears" then
                local x, y, z = act.target.Transform:GetWorldPosition()
                local gramaextra = SpawnPrefab("clippings")
                if gramaextra then gramaextra.Transform:SetPosition(x, y, z) end
            end
        end

        if act.target:HasTag("hangingvine") then
            local equipamento = act.doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equipamento and equipamento.prefab == "shears" then
                local x, y, z = act.target.Transform:GetWorldPosition()
                act.target:DoTaskInTime(1, function()
                    local gramaextra = SpawnPrefab("rope")
                    if gramaextra then gramaextra.Transform:SetPosition(x, y, z) end
                end)
            end
        end

        act.target.components.workable:WorkedBy(
            act.doer,
            (act.invobject ~= nil and act.invobject.components.tool ~= nil and
                act.invobject.components.tool:GetEffectiveness(workaction)) or
            (act.doer ~= nil and act.doer.components.worker ~= nil and
                act.doer.components.worker:GetEffectiveness(workaction)) or
            1
        )
    end
    return true
end

local HACK = Action({ priority = 10, mount_valid = true })
HACK.str = (STRINGS.ACTIONS.HACK)
HACK.id = "HACK"
HACK.fn = function(act, ...)
    return DoToolWork(act, ACTIONS.HACK)
end
AddAction(HACK)

local HACK1 = Action({ priority = 10, mount_valid = true })
HACK1.str = (STRINGS.ACTIONS.HACK)
HACK1.id = "HACK1"
HACK1.fn = function(act, ...)
    local equipamento = act.doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipamento and equipamento.components.finiteuses then
        equipamento.components.finiteuses:Use(1)
    end
    local numworks = 1
    if equipamento and equipamento.components.tool then
        numworks = equipamento.components.tool:GetEffectiveness(ACTIONS.HACK)
    elseif act.doer and act.doer.components.worker then
        numworks = act.doer.components.worker:GetEffectiveness(ACTIONS.HACK)
    end
    if equipamento and equipamento.components.obsidiantool then
        equipamento.components.obsidiantool:Use(act.doer, act.target)
    end
    if act.target and act.target.components.hackable then
        act.target.components.hackable:Hack(act.doer, numworks)
        return true
    end
    if act.target and act.target.components.workable and act.target.components.workable.action == ACTIONS.HACK then
        act.target.components.workable:WorkedBy(act.doer, numworks)
        return true
    end
    --    return DoToolWork(act, ACTIONS.HACK)
end
AddAction(HACK1)



local GAS = Action({ priority = 10, distance = 3, mount_valid = true })
GAS.str = (STRINGS.ACTIONS.GAS)
GAS.id = "GAS"
GAS.fn = function(act)
    if act.invobject and act.invobject.components.gasser then
        act.invobject.components.gasser:Gas(act:GetActionPoint() or act.target:GetPosition())
        return true
    end
end
AddAction(GAS)


local ACTIVATESAIL = Action({ priority = 10, mount_valid = true })
ACTIVATESAIL.str = (STRINGS.ACTIONS.LANTERNON)
ACTIVATESAIL.id = "ACTIVATESAIL"
ACTIVATESAIL.fn = function(act)
    if act.doer ~= nil and act.invobject:HasTag("boatlight") then
        if act.invobject.components.equippable ~= nil then
            act.invobject.components.equippable:ToggleOn()
        elseif act.invobject.SetBoatLightEnabled ~= nil then
            act.invobject:SetBoatLightEnabled(true)
        else
            act.invobject:AddTag("ligado")
        end
    end
    return true
end
AddAction(ACTIVATESAIL)

local COMPACTPOOP = Action({ priority = 10, mount_valid = true })
COMPACTPOOP.str = "Compact Poop"
COMPACTPOOP.id = "COMPACTPOOP"
COMPACTPOOP.fn = function(act)
    if act.invobject.components.stackable and act.invobject.components.stackable.stacksize > 1 then
        local nut = act.invobject.components.stackable:Get()
        nut:Remove()
    else
        act.invobject:Remove()
    end
    act.doer.components.inventory:GiveItem(SpawnPrefab("poop2"))
    return true
end
AddAction(COMPACTPOOP)

local DESACTIVATESAIL = Action({ priority = 10, mount_valid = true })
DESACTIVATESAIL.str = (STRINGS.ACTIONS.LANTERNOFF)
DESACTIVATESAIL.id = "DESACTIVATESAIL"
DESACTIVATESAIL.fn = function(act)
    if act.doer ~= nil and act.invobject:HasTag("boatlight") then
        if act.invobject.components.equippable ~= nil then
            act.invobject.components.equippable:ToggleOff()
        elseif act.invobject.SetBoatLightEnabled ~= nil then
            act.invobject:SetBoatLightEnabled(false)
        else
            act.invobject:RemoveTag("ligado")
        end
    end
    return true
end
AddAction(DESACTIVATESAIL)


local JUMPIN = Action({ priority = 10, ghost_valid = true, encumbered_valid = true, invalid_hold_action = true })
JUMPIN.str = (STRINGS.ACTIONS.JUMPIN)
JUMPIN.id = "JUMPIN"
JUMPIN.fn = function(act)
    if act.doer ~= nil and
        act.doer.sg ~= nil and
        act.doer.sg.currentstate.name == "jumpin_pre" then
        if act.target ~= nil and
            act.target.components.teleporter ~= nil and
            act.target.components.teleporter:IsActive() then
            if act.target:HasTag("hamletteleport") and not act.doer:HasTag("playerghost") then
                act.doer.sg:GoToState("hamletteleport", { teleporter = act.target })
            elseif act.target:HasTag("bermudatriangle") then
                act.doer.sg:GoToState("idle")
                return act.target.TeleportTraveler ~= nil and act.target:TeleportTraveler(act.doer) or false
            else
                act.doer.sg:GoToState("jumpin", { teleporter = act.target })
            end
            return true
        end
        act.doer.sg:GoToState("idle")
    end
end
AddAction(JUMPIN)

local OldJumpInMap = ACTIONS.JUMPIN_MAP.fn
ACTIONS.JUMPIN_MAP.fn = function(act)
    if act.target ~= nil and act.target:HasTag("bermudatriangle") then
        return ACTIONS.JUMPIN.fn(act)
    end
    return OldJumpInMap(act)
end

--进出房间动作--
local Oldstrfnjumpin = ACTIONS.JUMPIN.strfn
ACTIONS.JUMPIN.strfn = function(act)
    if act.target ~= nil and act.target:HasTag("hamletteleport") then
        return "HAMLET"
    end
    return Oldstrfnjumpin and Oldstrfnjumpin(act) or "GENERIC"
end

local STORE_strfn = ACTIONS.STORE.strfn
ACTIONS.STORE.strfn = function(act)
    if act.target ~= nil and act.target.prefab == "smelter" then
        return nil -- "SMELT" require STRINGS.ACTIONS.STORE.SMELT
    end
    return STORE_strfn and STORE_strfn(act)
end

local _extra_arrive_dist = ACTIONS.DEPLOY.extra_arrive_dist
local function extra_arrive_dist(doer, dest, bufferedaction, ...)
    if dest and doer:HasTag("aquatic") then
        local invobject = bufferedaction and bufferedaction.invobject or nil
        if invobject:HasTag("boatbuilder") then
            local target_x, _, target_z = dest:GetPoint()
            local is_on_water = not TheWorld.Map:IsPassableAtPoint(target_x, 0, target_z)
            if is_on_water then
                return (invobject.replica.inventoryitem:DeploySpacingRadius() or 0) + 2.0
            end
        end
    end

    return _extra_arrive_dist(doer, dest, bufferedaction, ...)
end

ACTIONS.DEPLOY.extra_arrive_dist = extra_arrive_dist


-- local Oldharvest = ACTIONS.HARVEST.fn
-- ACTIONS.HARVEST.fn = function(act)
--     if act.target.components.breeder and act.target.components.breeder.volume > 0 then
--         return act.target.components.breeder:Harvest(act.doer)
--     end
--     return Oldharvest and Oldharvest(act)
-- end

----------------------------------------------------------------------------------------------------
--活性机甲
local IRONTURNON = Action({ priority = 10, distance = 1.5, mount_valid = true })
IRONTURNON.str = STRINGS.ACTIONS.IRONTURNON
IRONTURNON.id = "IRONTURNON"
IRONTURNON.fn = function(act)
    local inst = act.invobject
    if inst and inst.components.ironmachine and not inst.components.ironmachine:IsOn() then
        inst.components.ironmachine:TurnOn()
        return true
    end
end
AddAction(IRONTURNON)

local IRONTURNOFF = Action({ priority = 10, distance = 1.5, mount_valid = true })
IRONTURNOFF.str = STRINGS.ACTIONS.IRONTURNOFF
IRONTURNOFF.id = "IRONTURNOFF"
IRONTURNOFF.fn = function(act)
    local inst = act.invobject
    if inst and inst.components.ironmachine and inst.components.ironmachine:IsOn() then
        inst.components.ironmachine:TurnOff()
        return true
    end
end
AddAction(IRONTURNOFF)

local CHARGE_UP = Action({ priority = 10, distance = 1.5, mount_valid = true })
CHARGE_UP.str = STRINGS.ACTIONS.CHARGE_UP
CHARGE_UP.id = "CHARGE_UP"
CHARGE_UP.fn = function(act)
    if act.doer:HasTag("ironlord") then
        return true
    end
end
AddAction(CHARGE_UP)
ACTIONS.CHARGE_UP.do_not_locomote = true

local function AddUses(fuel, fueled, uses, doer)
    uses = uses or 0
    local current, max
    if fueled.components.armor then
        current, max = fueled.components.armor.condition, fueled.components.armor.maxcondition
    end
    if not (current and max) then return end
    if fueled.OnTroRepaired then
        fueled:OnTroRepaired(fuel, uses, doer)
    end
    if fueled.components.armor then
        fueled.components.armor:Repair(uses)
    end
    if fuel.components.stackable then
        fuel.components.stackable:Get():Remove()
    else
        fuel:Remove()
    end
    return true
end

local TROREPAIR = Action({ priority = 10, mount_valid = true, paused_valid = true })
TROREPAIR.str = STRINGS.ACTIONS.GIVE.REPAIR
TROREPAIR.id = "TROREPAIR"
TROREPAIR.fn = function (act)
    if act.doer and act.invobject and act.target then
        local uses
        local prefab = act.invobject.prefab
        if act.target.tro_repair and act.target.tro_repair[prefab] then
            uses = act.target.tro_repair[prefab]
        end
        if uses then
            return AddUses(act.invobject, act.target, uses, act.doer)
        end
    end
end
AddAction(TROREPAIR)
--[[
AddAction(nil, "IRONTURNON", STRINGS.ACTIONS.IRONTURNON, function(act)
    local inst = act.invobject
    if inst and inst.components.ironmachine and not inst.components.ironmachine:IsOn() then
        inst.components.ironmachine:TurnOn()
        return true
    end
end)

AddAction(nil, "IRONTURNOFF", STRINGS.ACTIONS.IRONTURNOFF, function(act)
    local inst = act.invobject
    if inst and inst.components.ironmachine and inst.components.ironmachine:IsOn() then
        inst.components.ironmachine:TurnOff()
        return true
    end
end)

AddAction(nil, "CHARGE_UP", STRINGS.ACTIONS.CHARGE_UP, function(act)
    if act.doer:HasTag("ironlord") then
        return true
    end
end)
ACTIONS.CHARGE_UP.do_not_locomote = true
]]
