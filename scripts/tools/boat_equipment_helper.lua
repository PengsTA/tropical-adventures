local BoatEquipmentHelper = {}

local FALLBACK_SLOTS = {
    BOAT_SAIL = "sail",
    BOAT_LAMP = "lamp",
}

local SLOT_INDEX = {
    sail = 1,
    lamp = 2,
}

local TAIL_TAGS = {
    sail = true,
    trawlnet = true,
    boat_tail = true,
}

local HEAD_TAGS = {
    boatlight = true,
    quackeringram = true,
    cannon = true,
    boat_head = true,
}

function BoatEquipmentHelper.GetSlots()
    return rawget(_G, "BOATEQUIPSLOTS") or FALLBACK_SLOTS
end

local function HasAnyTag(item, tags)
    if item == nil then
        return false
    end

    for tag in pairs(tags) do
        if item:HasTag(tag) then
            return true
        end
    end

    return false
end

function BoatEquipmentHelper.GetSlotForItem(item)
    if item == nil then
        return nil
    end

    local equippable = item.components ~= nil and item.components.equippable or nil
    if equippable ~= nil and equippable.boatequipslot ~= nil then
        return equippable.boatequipslot
    end

    local replica_equippable = item.replica ~= nil and item.replica.equippable or nil
    if replica_equippable ~= nil and replica_equippable.BoatEquipSlot ~= nil then
        local eslot = replica_equippable:BoatEquipSlot()
        if eslot ~= nil and eslot ~= "INVALID" then
            return eslot
        end
    end

    local slots = BoatEquipmentHelper.GetSlots()
    if HasAnyTag(item, TAIL_TAGS) then
        return slots.BOAT_SAIL
    end
    if HasAnyTag(item, HEAD_TAGS) then
        return slots.BOAT_LAMP
    end
end

function BoatEquipmentHelper.IsBoatEquipment(item)
    return BoatEquipmentHelper.GetSlotForItem(item) ~= nil
end

function BoatEquipmentHelper.IsTailItem(item)
    return HasAnyTag(item, TAIL_TAGS)
end

function BoatEquipmentHelper.IsHeadItem(item)
    return HasAnyTag(item, HEAD_TAGS)
end

function BoatEquipmentHelper.HasBoatEquipSlots(container)
    return container ~= nil and (
        container.HasBoatEquipSlots ~= nil and container:HasBoatEquipSlots()
        or container.hasboatequipslots == true
    )
end

function BoatEquipmentHelper.GetEquippedItem(container, eslot)
    if container == nil then
        return nil
    end
    if container.GetBoatEquippedItem ~= nil then
        return container:GetBoatEquippedItem(eslot)
    end
    if container.GetItemInBoatSlot ~= nil then
        return container:GetItemInBoatSlot(eslot)
    end

    local slots = BoatEquipmentHelper.GetSlots()
    local index = SLOT_INDEX[eslot]
        or (eslot == slots.BOAT_SAIL and 1)
        or (eslot == slots.BOAT_LAMP and 2)
        or nil

    return index ~= nil and container.GetItemInSlot ~= nil and container:GetItemInSlot(index) or nil
end

function BoatEquipmentHelper.GetSail(container)
    return BoatEquipmentHelper.GetEquippedItem(container, BoatEquipmentHelper.GetSlots().BOAT_SAIL)
end

function BoatEquipmentHelper.GetHead(container)
    return BoatEquipmentHelper.GetEquippedItem(container, BoatEquipmentHelper.GetSlots().BOAT_LAMP)
end

function BoatEquipmentHelper.GetBoatContainer(boat)
    if boat == nil then
        return nil
    end
    return boat.components ~= nil and boat.components.container
        or boat.replica ~= nil and boat.replica.container
        or nil
end

function BoatEquipmentHelper.GetBoatForDoer(doer)
    if doer == nil then
        return nil
    end

    local boat = doer.components ~= nil and doer.components.sailor ~= nil and doer.components.sailor:GetBoat() or nil
    if boat == nil and doer.replica ~= nil and doer.replica.sailor ~= nil then
        boat = doer.replica.sailor:GetBoat()
    end

    return boat
end

function BoatEquipmentHelper.HasSail(boat)
    local sail = BoatEquipmentHelper.GetSail(BoatEquipmentHelper.GetBoatContainer(boat))
    return sail ~= nil and sail:HasTag("sail")
end

function BoatEquipmentHelper.SetItemBoat(item, boat)
    if item == nil then
        return
    end

    item.equipped_boat = boat
end

function BoatEquipmentHelper.GetItemBoat(item)
    return item ~= nil and item.equipped_boat or nil
end

function BoatEquipmentHelper.SetItemSailor(item, sailor)
    if item == nil then
        return
    end

    item.equipped_sailor = sailor
end

function BoatEquipmentHelper.GetItemSailor(item)
    return item ~= nil and item.equipped_sailor or nil
end

function BoatEquipmentHelper.ClearItemBoatState(item)
    BoatEquipmentHelper.SetItemBoat(item, nil)
    BoatEquipmentHelper.SetItemSailor(item, nil)
end

return BoatEquipmentHelper
