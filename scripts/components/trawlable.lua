local Trawlable = Class(function(self, inst)
    self.inst = inst
    self.trawlfn = nil
    self.ignoreposition = false
    self.ignorevisibility = false
    inst:AddTag("trawltarget")
end)

function Trawlable:OnRemoveFromEntity()
    self.inst:RemoveTag("trawltarget")
end

Trawlable.OnRemoveEntity = Trawlable.OnRemoveFromEntity

function Trawlable:SetTrawlFn(fn)
    self.trawlfn = fn
end

function Trawlable:SetIgnorePosition(ignore)
    self.ignoreposition = ignore == true
end

function Trawlable:SetIgnoreVisibility(ignore)
    self.ignorevisibility = ignore == true
end

function Trawlable:CanBeTrawledBy(sailor, isbehind, isvisible)
    return (self.ignoreposition or isbehind)
        and (self.ignorevisibility or isvisible)
end

function Trawlable:Trawl(sailor)
    return self.trawlfn ~= nil and self.trawlfn(self.inst, sailor) or nil
end

return Trawlable
