local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function GetItemInBoatSlot(inst, eslot)
    local parent = inst._parent
    local container = parent ~= nil and parent.replica ~= nil and parent.replica.container or nil
    if container ~= nil and container.hasboatequipslots and container.boatcontainerequips ~= nil then
        local slot = container.boatcontainerequips[eslot]
        return slot ~= nil and inst:GetItemInSlot(slot) or nil
    end
end

AddPrefabPostInit("container_classified", function(inst)
    inst.GetItemInBoatSlot = GetItemInBoatSlot
end)
