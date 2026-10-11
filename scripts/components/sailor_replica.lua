local Sailor = Class(function(self, inst)
    self.inst = inst
    self._boat = net_entity(inst.GUID, "ta_sailor._boat", "boatdirty")
    self._trawl_item = net_event(inst.GUID, "ta_sailor.trawl_item", "ta_sailor.trawl_itemdirty")

    if not TheWorld.ismastersim then
        inst:ListenForEvent("ta_sailor.trawl_itemdirty", function()
            inst:PushEvent("trawl_item")
        end)
    end
end)

local BoatEquip = require("tools/boat_equipment_helper")

function Sailor:GetBoat()
    return self.inst.components.sailor ~= nil and self.inst.components.sailor:GetBoat() or self._boat:value()
end

function Sailor:IsSailing()
    return self:GetBoat() ~= nil
end

function Sailor:GetSpeedMultiplier()
    local boat = self:GetBoat()
    local sail = BoatEquip.GetSail(BoatEquip.GetBoatContainer(boat))
    if sail ~= nil and sail:HasTag("sail") then
        return sail.sail_speed_mult ~= nil and 1 + sail.sail_speed_mult or 1.2
    end
    return 1
end

return Sailor
