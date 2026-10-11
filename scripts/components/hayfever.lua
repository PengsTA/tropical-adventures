local function Check(inst)
    local climate = inst.components.regionalclimate
    if TUNING.hayfever and climate ~= nil and climate:IsPollenActive() then
        inst.components.hayfever:Enable()
    else
        inst.components.hayfever:Disable()
    end
end


--- 哈姆雷特花粉症
local Hayfever = Class(function(self, inst)
    self.inst          = inst

    self.enabled       = false
    self.sneezed       = false
    self.wantstosneeze = false
    self.nextsneeze    = self:GetNextSneezTimeInitial() --下一次打喷嚏时间

    inst:ListenForEvent("regionalclimatechanged", Check)
    inst:DoTaskInTime(0, Check)
end)

function Hayfever:SyncNextSneeze()
    local classified = self.inst.player_classified
    if classified ~= nil and classified._tropical_nextsneeze ~= nil then
        classified._tropical_nextsneeze:set(self.enabled and GetTime() + math.max(self.nextsneeze, 0) or -1)
    end
end

function Hayfever:GetNextSneezTime()
    return math.random(10, 20) -- / TheWorld.state.pollendustrate
end

function Hayfever:GetNextSneezTimeInitial()
    return math.random(30, 50)
end

function Hayfever:SetNextSneezeTime(newtime)
    if self.nextsneeze < newtime then
        self.nextsneeze = newtime
        self:SyncNextSneeze()
    end
end

function Hayfever:CanSneeze()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local climate = self.inst.components.regionalclimate
    return climate ~= nil and climate:IsPollenActive() and not self.inst:HasTag("has_gasmask")
        and not self.inst:HasTag("has_hayfeverhat")
        and #TheSim:FindEntities(x, y, z, TUNING.FAN_RANGE, { "prevents_hayfever" }) <= 0 --工作的摆动风扇旁边
end

function Hayfever:OnUpdate(dt)
    -- -- print("hayfever component update")
    -- -- print(self.nextsneeze)
    if self:CanSneeze() then
        if self.nextsneeze <= 0 then
            if not self.inst.sg:HasStateTag("sneeze") then
                if self.sneezed == false and math.random() > 0.7 then
                    self.nextsneeze = 1
                    self.sneezed = true
                else
                    self.nextsneeze = self:GetNextSneezTime()
                    self.sneezed = false
                end
                self:SyncNextSneeze()
                self.inst:PushEvent("sneeze")
            end
        else
            self.nextsneeze = self.nextsneeze - dt
        end
    else
        if self.nextsneeze < 50 then
            self.nextsneeze = self.nextsneeze + (dt * 5)
        end
    end
end

Hayfever.LongUpdate = Hayfever.OnUpdate

function Hayfever:OnSave()
    local data = {}
    local references = {}

    data.sneezed = self.sneezed
    data.nextsneeze = self.nextsneeze

    return data, references
end

function Hayfever:OnLoad(data, newents)
    if data then
        if data.sneezed then
            self.sneezed = data.sneezed
        end
        if data.nextsneeze then
            self.nextsneeze = data.nextsneeze
            -- -- print("hayfever component load nextsneeze")
            -- -- print(data.nextsneeze)
        end
    end
end

-- function Hayfever:OnProgress()
--     if self.enabled then
--         self.inst:PushEvent("updatehayfever", { sneezetime = nil })
--         self:SetNextSneezeTime(self:GetNextSneezTimeInitial())
--     end

--     self.enabled = false
--     self.inst:StopUpdatingComponent(self)
-- end

function Hayfever:Enable()
    if not self.hayfeverimune then
        if not self.enabled then
            self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_HAYFEVER"))
        end

        self.enabled = true

        self.inst:StartUpdatingComponent(self)
        self:SyncNextSneeze()
    end
end

function Hayfever:Disable()
    if self.enabled then
        -- self.inst:PushEvent("updatehayfever", { sneezetime = nil })
        self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_HAYFEVER_OFF"))

        self.nextsneeze = math.max(self.nextsneeze, self:GetNextSneezTimeInitial())
    end

    self.enabled = false
    self.inst:StopUpdatingComponent(self)
    self:SyncNextSneeze()
end

function Hayfever:GetDebugString()
    return "nextsneeze" .. self.nextsneeze
end

function Hayfever:DoSneezeEffects()
    self.inst.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY * 3)

    -- cause player to drop stuff here.
    local itemstodrop = 0

    if math.random() < 0.6 then
        itemstodrop = itemstodrop + 1
    end

    if math.random() < 0.1 then
        itemstodrop = itemstodrop + 1
    end

    if itemstodrop > 0 then
        local findItems = self.inst.components.inventory:FindItems(function(item) return not item:HasTag("nosteal") end)
        for _ = 1, itemstodrop do
            if #findItems > 0 then
                local itemnum = math.random(1, #findItems)
                local item = findItems[itemnum]

                table.remove(findItems, itemnum)

                if item then
                    local direction = Vector3(math.random() * 2 - 1, 0, math.random() * 2 - 1)
                    self.inst.components.inventory:DropItem(item, false, direction:GetNormalized())
                end
            end
        end
    end
end

function Hayfever:OnRemoveEntity()
    self:Disable()
    self.inst:RemoveEventCallback("regionalclimatechanged", Check)
end

return Hayfever
