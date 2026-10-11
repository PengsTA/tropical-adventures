local easing = require("easing")
local PollenOver = require("widgets/pollenover")
local FogOver = require("widgets/fogover")
local VolcanoSmokeOver = require("widgets/volcanosmokeover")
local PlayerHud = require("screens/playerhud")
local _CreateOverlays = PlayerHud.CreateOverlays
local RegionDefs = require("tools/regiondefs")

local function IsOwnerInShipwreckedExterior(owner)
    return owner ~= nil
        and RegionDefs.HasPrimaryRegion(owner, RegionDefs.PRIMARY.shipwrecked)
        and not owner:HasTag(RegionDefs.INTERIOR_TAG)
end

function PlayerHud:CreateOverlays(owner, ...)
    _CreateOverlays(self, owner, ...)

    self.fogover = self.overlayroot:AddChild(FogOver(owner))
    -- self.fogover:MoveToBack()
    self.fogover:Hide()
    self.inst:ListenForEvent("updatefoggroggy",
        function(inst, data)
            -- print("updatefoggroggy in playerhud")
            -- print(data.foggroggylevel)
            return self.fogover:UpdateState(data.foggroggylevel)
        end,
        self.owner)
    local classified = owner.player_classified
    if classified ~= nil and classified._tropical_foggroggylevel ~= nil then
        self.fogover:UpdateState(classified._tropical_foggroggylevel:value() / 100)
    end

    self.pollenover = self.overlayroot:AddChild(PollenOver(owner))
    self.pollenover:Hide()
    self.inst:ListenForEvent("updatehayfever",
        function(inst, data)
            return self.pollenover:UpdateState(data.sneezetime)
        end,
        self.owner)
    if classified ~= nil and classified._tropical_nextsneeze ~= nil then
        local deadline = classified._tropical_nextsneeze:value() or -1
        self.pollenover:UpdateState(deadline >= 0 and math.max(0, deadline - GetTime()) or 999)
    end

    self.volcanosmokeover = self.overlayroot:AddChild(VolcanoSmokeOver())
    local function RefreshVolcanoSmoke()
        local network = TheWorld ~= nil and TheWorld.net or nil
        local rate = network ~= nil and network._tropical_volcano_smokerate ~= nil
            and network._tropical_volcano_smokerate:value() / 100
            or 0
        self.volcanosmokeover:SetRate(IsOwnerInShipwreckedExterior(owner) and rate or 0)
    end
    self.inst:ListenForEvent("tropicalvolcanostatechanged", RefreshVolcanoSmoke, TheWorld)
    owner:ListenForEvent("regionchange_client", RefreshVolcanoSmoke)
    owner:DoTaskInTime(0, RefreshVolcanoSmoke)
end
