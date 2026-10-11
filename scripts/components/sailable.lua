local Sailable = Class(function(self, inst)
    self.inst = inst
    self.sailor = nil
    self.is_moving = false
    self.speedmult = 1
    self.accelmult = 1
    self.inst:AddTag("sailable")
end)

local BoatEquip = require("tools/boat_equipment_helper")

local LAND_CHECK_Y_OFFSET = 0
local function DoLandAutoReturn(boat)
    if boat == nil then
        return
    end

    if boat.OnHammer ~= nil then
        boat:OnHammer()
        return
    end

    if boat.OnHammered ~= nil then
        boat:OnHammered()
        return
    end

    SpawnAt("collapse_small", boat)
    if boat.components ~= nil and boat.components.container ~= nil then
        boat.components.container:DropEverything()
    end
    if boat.SoundEmitter ~= nil then
        boat.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    end
    boat:Remove()
end

function Sailable:GetSailor()
    return self.sailor
end

function Sailable:IsOccupied()
    return self.sailor ~= nil
end

function Sailable:GetSail()
    return BoatEquip.GetSail(BoatEquip.GetBoatContainer(self.inst))
end

function Sailable:GetIsSailEquipped()
    return BoatEquip.HasSail(self.inst)
end

function Sailable:RefreshSailorTags()
    if self.sailor == nil then
        return
    end
    if self:GetIsSailEquipped() then
        self.sailor:AddTag("sail")
    else
        self.sailor:RemoveTag("sail")
    end
end

function Sailable:GetSpeedMultiplier()
    local sail = self:GetSail()
    return (sail ~= nil and sail.sail_speed_mult ~= nil and 1 + sail.sail_speed_mult) or self.speedmult
end

function Sailable:GetAccelerationMultiplier()
    local sail = self:GetSail()
    return (sail ~= nil and sail.sail_accel_mult) or self.accelmult
end

local function IsBoatOverLand(inst)
    if inst == nil or inst.Transform == nil then
        return false
    end

    local map = TheWorld and TheWorld.Map
    if map == nil or map.IsPassableAtPoint == nil then
        return false
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    return map:IsPassableAtPoint(x, LAND_CHECK_Y_OFFSET, z)
end

function Sailable:CheckAndAutoReturn()
    if not (TheWorld ~= nil and TheWorld.ismastersim) then
        return
    end
    if self.sailor ~= nil then
        return
    end
    if self.inst.components.boathealth == nil or self.inst.components.boathealth:IsEmpty() then
        return
    end
    if IsBoatOverLand(self.inst) then
        DoLandAutoReturn(self.inst)
    end
end

function Sailable:OnEmbarked(sailor)
    self.sailor = sailor
    self.inst:AddTag("boat_occupied")
    self:SetIsMoving(false)

    if self.inst.components.workable ~= nil then
        self.inst.components.workable.workable = false
    end
    if self.inst.components.boathealth ~= nil then
        self.inst.components.boathealth:StartConsuming()
    end
    if self.inst.components.boatequipment ~= nil then
        self.inst.components.boatequipment:SetSailor(sailor)
    end

    self:RefreshSailorTags()
    self.inst:PushEvent("embarked", { sailor = sailor })
end

function Sailable:OnDisembarked(sailor)
    if self.sailor == sailor then
        self.sailor = nil
    end
    self.inst:RemoveTag("boat_occupied")
    self:SetIsMoving(false)

    if self.inst.components.workable ~= nil then
        self.inst.components.workable.workable = true
    end
    if self.inst.components.boathealth ~= nil then
        self.inst.components.boathealth:StopConsuming()
    end
    if self.inst.components.boatequipment ~= nil then
        self.inst.components.boatequipment:SetSailor(nil)
    end

    if sailor ~= nil then
        sailor:RemoveTag("sail")
    end

    self:CheckAndAutoReturn()
    self.inst:PushEvent("disembarked", { sailor = sailor })
end

function Sailable:SetIsMoving(moving)
    local ismoving = moving == true
    if self.is_moving == ismoving then
        return
    end

    self.is_moving = ismoving
    if self.inst.components.boatequipment ~= nil then
        self.inst.components.boatequipment:SetConsuming(ismoving)
    end
end

function Sailable:OnRemoveFromEntity()
    self.inst:RemoveTag("sailable")
    self.inst:RemoveTag("boat_occupied")
end

return Sailable
