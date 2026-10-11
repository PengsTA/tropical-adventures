AddComponentPostInit("deployable", function(self, inst)
    self.ForceDeploy = function(self, pt, deployer)
        -- if not self:CanDeploy(pt) then
        --  return
        -- end
        local prefab = self.inst.prefab
        if self.ondeploy ~= nil then
            self.ondeploy(self.inst, pt, deployer)
        end
        -- self.inst is removed during ondeploy
        if deployer and deployer.IsValid and deployer:IsValid() then
            deployer:PushEvent("deployitem", { prefab = prefab })
        end
        return true
    end
end)

AddComponentPostInit("playeractionpicker", function(PlayerActionPicker)
    local function GetActiveBoat(inst)
        local sailor = inst ~= nil and inst.replica ~= nil and inst.replica.sailor or nil
        local boat = sailor ~= nil and sailor:GetBoat() or nil
        if boat ~= nil then
            return boat
        end
        return inst and inst.replica and inst.replica.inventory
            and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.BARCO) or nil
    end

    local GetRightClickActions = PlayerActionPicker.GetRightClickActions

    function PlayerActionPicker:GetRightClickActions(position, target, spellbook)
        local boat = GetActiveBoat(self.inst)
        local acts = GetRightClickActions(self, position, target, spellbook) or {}

        if #acts <= 0 and boat then
            local pointActs = self:GetPointActions(position, boat, true)
            if pointActs and #pointActs > 0 then
                acts = pointActs
            end
        end
        return acts
    end

    local GetLeftClickActions = PlayerActionPicker.GetLeftClickActions
    function PlayerActionPicker:GetLeftClickActions(position, target)
        local boat = GetActiveBoat(self.inst)
        local acts = GetLeftClickActions(self, position, target) or {}

        if #acts <= 0 and boat and position and TheWorld.Map:IsPassableAtPoint(position:Get()) then
            local pointActs = self:GetPointActions(position, boat, nil)
            if pointActs and #pointActs > 0 then
                acts = pointActs
            end
        end
        return acts
    end
end)

AddComponentPostInit("fueled", function(self)
    function self:CanAcceptFuelItem(item)
        if not self.accepting or not item then return false end
        if self.fueltype == "TAR" and item:HasTag("tar") then return true end

        local fuel = item.components and item.components.fuel
        return fuel and (fuel.fueltype == self.fueltype or fuel.fueltype == self.secondaryfueltype)
    end
end)
