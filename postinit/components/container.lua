local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container")
local BoatEquip = require("tools/boat_equipment_helper")

local function RestoreSailingBoatContainer(doer, closed_container)
    if doer == nil or doer.components.sailor == nil then
        return
    end

    if doer._ta_boat_ui_task ~= nil then
        doer._ta_boat_ui_task:Cancel()
    end

    doer._ta_boat_ui_task = doer:DoTaskInTime(0, function()
        doer._ta_boat_ui_task = nil

        local sailor = doer.components.sailor
        local boat = sailor ~= nil and sailor:GetBoat() or nil
        if boat == nil or not boat:IsValid() or boat == closed_container or boat.components.container == nil then
            return
        end

        -- Opening another container closes the boat first. Wait until that
        -- container is actually closed before restoring the sailing HUD.
        local inventory = doer.components.inventory
        if inventory ~= nil then
            for container in pairs(inventory.opencontainers) do
                if container ~= boat then
                    return
                end
            end
        end

        if not boat.components.container:IsOpenedBy(doer) then
            boat.components.container:Open(doer)
        end
    end)
end

function Container:ForceOpen(doer, ...)
    self.forceopen = true
    self:Open(doer, ...)
end

local _Close = Container.Close
function Container:Close(doer, ...)
    if self.forceopen then
        return
    end
    local result = _Close(self, doer, ...)
    RestoreSailingBoatContainer(doer, self.inst)
    return result
end

function Container:ForceClose(doer, ...)
    self.forceopen = false
    self:Close(doer, ...)
end

function Container:GetItemInBoatSlot(eslot)
    if not self.hasboatequipslots then
        return nil
    end
    local slot = self.boatcontainerequips ~= nil and self.boatcontainerequips[eslot] or nil
    return slot ~= nil and self:GetItemInSlot(slot) or nil
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

function Container:BoatEquip(item, doer)
    if not self.hasboatequipslots or item == nil then
        return false
    end

    local eslot = BoatEquip.GetSlotForItem(item)
    local slot = eslot ~= nil and self.boatcontainerequips ~= nil and self.boatcontainerequips[eslot] or nil
    if slot == nil then
        return false
    end

    local old_item = self:GetItemInSlot(slot)
    if old_item ~= nil then
        if old_item.components.equippable ~= nil and old_item.components.equippable.ShouldPreventUnequipping ~= nil and old_item.components.equippable:ShouldPreventUnequipping() then
            return false
        end
        self:BoatUnequip(eslot, doer)
    end

    local owner = item.components.inventoryitem ~= nil and item.components.inventoryitem.owner or nil
    local inventory = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
    if inventory ~= nil then
        inventory:RemoveItem(item)
    end

    return self:GiveItem(item, slot)
end

function Container:BoatUnequip(eslot, doer)
    if not self.hasboatequipslots then
        return nil
    end

    local slot = self.boatcontainerequips ~= nil and self.boatcontainerequips[eslot] or nil
    local item = slot ~= nil and self:GetItemInSlot(slot) or nil
    if item ~= nil then
        self:DropItem(item)
        if doer ~= nil and doer.components.inventory ~= nil then
            doer.components.inventory:GiveItem(item)
        end
    end
    return item
end

local _GetSpecificSlotForItem = Container.GetSpecificSlotForItem
function Container:GetSpecificSlotForItem(item, ...)
    if self.hasboatequipslots then
        local eslot = BoatEquip.GetSlotForItem(item)
        local slot = eslot ~= nil and self.boatcontainerequips ~= nil and self.boatcontainerequips[eslot] or nil
        if slot ~= nil and self:GetItemInSlot(slot) == nil then
            return slot
        end
    end
    return _GetSpecificSlotForItem(self, item, ...)
end

local function OnGetItem(inst, data)
    local container = inst.components.container
    if container == nil or not container.hasboatequipslots or data == nil or data.item == nil then
        return
    end
    if container:IsBoatSlot(data.slot) then
        local item = data.item
        if item.components.equippable ~= nil and item.components.equippable.Equip ~= nil then
            item.components.equippable:Equip(inst)
        end
    end
end

local function OnLoseItem(inst, data)
    local container = inst.components.container
    if container == nil or not container.hasboatequipslots or data == nil or data.prev_item == nil then
        return
    end
    if container:IsBoatSlot(data.slot) then
        local item = data.prev_item
        if item.components.equippable ~= nil and item.components.equippable.Unequip ~= nil then
            item.components.equippable:Unequip(inst)
        end
    end
end

AddComponentPostInit("container", function(self)
    self.inst:ListenForEvent("itemget", OnGetItem)
    self.inst:ListenForEvent("itemlose", OnLoseItem)
end)
