local BoatEquip = require("tools/boat_equipment_helper")

local SLOT_DEFS =
{
    {
        key = "tail_item",
        defaultsymbol = "swap_sail",
        testfn = BoatEquip.IsTailItem,
        boattag = "sail",
        ownertag = "sail",
    },
    {
        key = "head_item",
        defaultsymbol = "swap_lantern",
        testfn = BoatEquip.IsHeadItem,
    },
}

local BoatEquipment = Class(function(self, inst)
    self.inst = inst
    self.head_item = nil
    self.tail_item = nil

    self.inst:ListenForEvent("itemget", function(_, data) self:OnItemGet(data) end)
    self.inst:ListenForEvent("itemlose", function(_, data) self:OnItemLose(data) end)
end)

function BoatEquipment:GetHead()
    return self.head_item
end

function BoatEquipment:GetTail()
    return self.tail_item
end

local function IsBoatSlot(inst, slot)
    local container = inst.components.container
    return container == nil
        or container.IsBoatSlot == nil
        or slot == nil
        or container:IsBoatSlot(slot)
end

function BoatEquipment:SetItemConsuming(item, consuming)
    if item == nil then
        return
    end

    -- Only propulsion equipment consumes fuel as part of sailing. Boat lights
    -- own their toggle state and must not be forced on by embark/disembark.
    if item.boat_consumes_while_sailing and item.components.fueled ~= nil then
        if consuming then
            item.components.fueled:StartConsuming()
        else
            item.components.fueled:StopConsuming()
        end
    end

    item:PushEvent(consuming and "boat_startconsuming" or "boat_stopconsuming")
end

function BoatEquipment:SetConsuming(consuming)
    for _, def in ipairs(SLOT_DEFS) do
        self:SetItemConsuming(self[def.key], consuming)
    end
end

function BoatEquipment:SetSailor(sailor)
    for _, def in ipairs(SLOT_DEFS) do
        local item = self[def.key]
        if item ~= nil then
            BoatEquip.SetItemSailor(item, sailor)
            item:PushEvent(sailor ~= nil and "boat_embarked" or "boat_disembarked", {
                boat = self.inst,
                sailor = sailor,
            })
        end
    end
end

function BoatEquipment:UpdateVisuals()
    local model = self.inst

    model.AnimState:ClearOverrideSymbol("swap_sail")
    model.AnimState:ClearOverrideSymbol("swap_propeller")
    model.AnimState:ClearOverrideSymbol("swap_lantern")
    model.AnimState:ClearOverrideSymbol("swap_trawlnet")

    for _, def in ipairs(SLOT_DEFS) do
        local item = self[def.key]
        if item ~= nil then
            model.AnimState:OverrideSymbol(
                item.symboltooverride or def.defaultsymbol,
                item.AnimState:GetBuild() or item.build,
                item.symbol
            )
        end
    end
end

function BoatEquipment:RefreshSailorTags()
    if self.inst.components.sailable ~= nil then
        self.inst.components.sailable:RefreshSailorTags()
    end
end

local function GetOwner(inst)
    return inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
end

local function GetSlotDef(item)
    for _, def in ipairs(SLOT_DEFS) do
        if def.testfn(item) then
            return def
        end
    end
end

function BoatEquipment:SetSlotItem(def, item)
    local owner = GetOwner(self.inst)
    self[def.key] = item
    BoatEquip.SetItemBoat(item, self.inst)
    if def.boattag ~= nil then
        self.inst:AddTag(def.boattag)
    end
    if def.ownertag ~= nil and owner ~= nil then
        owner:AddTag(def.ownertag)
    end
    if def.itemtag ~= nil then
        item:AddTag(def.itemtag)
    end
end

function BoatEquipment:ClearSlotItem(def, item)
    local owner = GetOwner(self.inst)
    self[def.key] = nil
    if def.boattag ~= nil then
        self.inst:RemoveTag(def.boattag)
    end
    if def.ownertag ~= nil and owner ~= nil then
        owner:RemoveTag(def.ownertag)
    end
    if def.itemtag ~= nil then
        item:RemoveTag(def.itemtag)
    end
    BoatEquip.ClearItemBoatState(item)
end

function BoatEquipment:OnItemGet(data)
    local item = data ~= nil and data.item or nil
    if item == nil or not IsBoatSlot(self.inst, data.slot) then
        return
    end

    local def = GetSlotDef(item)
    if def == nil then
        return
    end
    self:SetSlotItem(def, item)

    local sailable = self.inst.components.sailable
    if sailable ~= nil then
        self:SetItemConsuming(item, sailable.is_moving)
    end

    local sailor = self.inst.components.sailable ~= nil and self.inst.components.sailable:GetSailor() or nil
    BoatEquip.SetItemSailor(item, sailor)
    item:PushEvent("boatequipped", { boat = self.inst, sailor = sailor })

    self:UpdateVisuals()
    self:RefreshSailorTags()
end

function BoatEquipment:OnItemLose(data)
    local item = data ~= nil and data.prev_item or nil
    if item == nil or not IsBoatSlot(self.inst, data.slot) then
        return
    end

    local def = GetSlotDef(item)
    if def == nil or self[def.key] ~= item then
        return
    end

    self:SetItemConsuming(item, false)
    item:PushEvent("boatunequipped", { boat = self.inst })
    self:ClearSlotItem(def, item)

    self:UpdateVisuals()
    self:RefreshSailorTags()
end

return BoatEquipment
