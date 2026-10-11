-- ta_seaworthy_traveler_replica.lua
-- Replica component for client-side prediction and data synchronization

local TaSeaworthyTraveler = Class(function(self, inst)
    self.inst = inst

    self._is_broken = net_bool(inst.GUID, "ta_seaworthy_traveler._is_broken", "ta_seaworthy_is_brokendirty")
end)

function TaSeaworthyTraveler:SetBroken(is_broken)
    self._is_broken:set(is_broken == true)
end

function TaSeaworthyTraveler:IsBroken()
    return self._is_broken:value()
end

function TaSeaworthyTraveler:CanTravel(doer)
    return not self:IsBroken() and doer ~= nil and not doer:HasTag("playerghost")
end

return TaSeaworthyTraveler
