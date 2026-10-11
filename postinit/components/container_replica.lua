local Container = require "components/container_replica"
local Utils = require "tools/utils"
local BoatEquip = require "tools/boat_equipment_helper"

function Container:GetItemInBoatSlot(eslot)
    if self.inst.components.container ~= nil and self.inst.components.container.GetItemInBoatSlot ~= nil then
        return self.inst.components.container:GetItemInBoatSlot(eslot)
    end
    return self.opener ~= nil and self.classified ~= nil and self.classified.GetItemInBoatSlot ~= nil and self.classified:GetItemInBoatSlot(eslot) or nil
end

function Container:GetBoatEquippedItem(eslot)
    return self:GetItemInBoatSlot(eslot)
end

function Container:HasBoatEquipSlots()
    return self.hasboatequipslots == true
end

function Container:IsBoatSlot(slot)
    if not self.hasboatequipslots or self.boatcontainerequips == nil then
        return false
    end
    for _, index in pairs(self.boatcontainerequips) do
        if slot == index then
            return true
        end
    end
    return false
end

function Container:GetBoatEquipmentSlotForItem(item)
    return BoatEquip.GetSlotForItem(item)
end

Utils.FnDecorator(Container, "GetWidget", nil, function(rets, self)
    local sailor = ThePlayer ~= nil and ThePlayer.replica ~= nil and ThePlayer.replica.sailor or nil
    if self.inst:HasTag("boat_occupied") or (sailor ~= nil and sailor:GetBoat() == self.inst) then
        return rets
    end

    return self.inst.replica.inventoryitem ~= nil and
           self.inst.replica.inventoryitem:IsHeld() ~= true and
           self.widgetinspect ~= nil and { self.widgetinspect } or rets
end)
