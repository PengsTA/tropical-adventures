local ClimateProfiles = require("tools/climateprofiles")

local Bloomable = Class(function(self, inst)
    self.inst = inst
    self.season = false
    self.blooming = false
    self.time = 0
    self.timevarriance = TUNING.TOTAL_DAY_TIME / 2

    self.inst:WatchWorldState("season", function(data) self:SeasonChange(data) end)
end)

function Bloomable:IsBloomSeason()
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local primary = TheWorld.Map:GetPrimaryRegionAtPoint(x, 0, z)
    if primary == "hamlet" then
        return ClimateProfiles.IsHamletLush(TheWorld.state)
    elseif primary == "shipwrecked" then
        return ClimateProfiles.IsShipwreckedMonsoon(TheWorld.state)
    end
    return TheWorld.state.isspring
end

function Bloomable:SetCanBloom(fn)
    self.canbloom = fn
end

function Bloomable:SetStartBloomFn(fn)
    self.bloomfunction = fn
end

function Bloomable:SetStopBloomFn(fn)
    self.unbloomfunction = fn
end

function Bloomable:StartBloom()
    if self.unbloomtask then
        self.unbloomtask:Cancel()
        self.unbloomtask = nil
    end
    self.unbloomtaskinfo = nil

    self.blooming = true
    self.inst:AddTag("blooming")

    if self.bloomtask then
        self.bloomtask:Cancel()
        self.bloomtask = nil
    end
    self.bloomtaskinfo = nil

    if self.bloomfunction then
        self.bloomfunction(self.inst)
    end
end

function Bloomable:SetDoBloom(fn)
    self.dobloomfn = fn
end

function Bloomable:DoBloom()
    if self.dobloomfn then
        self.dobloomfn(self.inst)
    end
end

function Bloomable:StopBloom(inst)
    if self.bloomtask then
        self.bloomtask:Cancel()
        self.bloomtask = nil
    end
    self.bloomtaskinfo = nil

    self.blooming = false
    self.inst:RemoveTag("blooming")
    if self.unbloomtask then
        self.unbloomtask:Cancel()
        self.unbloomtask = nil
    end
    self.unbloomtaskinfo = nil

    if self.unbloomfunction then
        self.unbloomfunction(self.inst)
    end
end

function Bloomable:SeasonChange(data)
    if self:CanBloom() then
        if self:IsBloomSeason() and not self.blooming then
            -- print("OHHHH")
            self:DoStartBloomTask(self.time + math.random() * self.timevarriance)
        elseif not self:IsBloomSeason() and self.blooming then
            self:DoStopBloomTask(self.time + math.random() * self.timevarriance)
        end
    end
end

function Bloomable:CanBloom()
    local canbloom = true
    if self.canbloom then
        canbloom = self.canbloom(self.inst)
    end
    return canbloom
end

function Bloomable:OnSave()
    local data = {}

    data.blooming = self.blooming

    if self.bloomtaskinfo then
        data.bloomtask = self.inst:TimeRemainingInTask(self.bloomtaskinfo)
    end
    if self.unbloomtaskinfo then
        data.unbloomtask = self.inst:TimeRemainingInTask(self.unbloomtaskinfo)
    end

    return data
end

function Bloomable:DoStartBloomTask(time)
    if self.bloomtask then
        self.bloomtask:Cancel()
        self.bloomtask = nil
    end
    self.bloomtaskinfo = nil
    self.bloomtask, self.bloomtaskinfo = self.inst:ResumeTask(time, function() self:StartBloom() end)
end

function Bloomable:DoStopBloomTask(time)
    if self.unbloomtask then
        self.unbloomtask:Cancel()
        self.unbloomtask = nil
    end
    self.unbloomtaskinfo = nil
    self.unbloomtask, self.unbloomtaskinfo = self.inst:ResumeTask(time, function() self:StopBloom() end)
end

function Bloomable:OnLoad(data)
    if data then
        self.blooming = data.blooming

        if data.bloomtask then
            self:DoStartBloomTask(data.bloomtask)
        end
        if data.unbloomtask then
            self:DoStopBloomTask(data.unbloomtask)
        end
    end

    if self.blooming then
        self:StartBloom()
    end
end

function Bloomable:GetDebugString()
    local string = ""
    if self.bloomtaskinfo then
        string = string .. "  bloomtask: " .. self.inst:TimeRemainingInTask(self.bloomtaskinfo)
    end
    if self.unbloomtaskinfo then
        string = string .. "  unbloomtask: " .. self.inst:TimeRemainingInTask(self.unbloomtaskinfo)
    end
    return string
end

return Bloomable
