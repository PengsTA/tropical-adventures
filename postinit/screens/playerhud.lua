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
            return self.fogover:UpdateState(TheWorld._ta_config_ready and data.foggroggylevel or 0)
        end,
        self.owner)
    local classified = owner.player_classified
    if TheWorld._ta_config_ready and classified ~= nil and classified._tropical_foggroggylevel ~= nil then
        self.fogover:UpdateState(classified._tropical_foggroggylevel:value() / 100)
    end

    self.pollenover = self.overlayroot:AddChild(PollenOver(owner))
    self.pollenover:Hide()
    self.inst:ListenForEvent("updatehayfever",
        function(inst, data)
            return self.pollenover:UpdateState(TheWorld._ta_config_ready and data.sneezetime or 999)
        end,
        self.owner)
    if TheWorld._ta_config_ready and classified ~= nil and classified._tropical_nextsneeze ~= nil then
        local deadline = classified._tropical_nextsneeze:value() or -1
        self.pollenover:UpdateState(deadline >= 0 and math.max(0, deadline - GetTime()) or 999)
    end

    self.volcanosmokeover = self.overlayroot:AddChild(VolcanoSmokeOver())
    local function RefreshVolcanoSmoke()
        local network = TheWorld ~= nil and TheWorld.net or nil
        local rate = network ~= nil and network._tropical_volcano_smokerate ~= nil
            and network._tropical_volcano_smokerate:value() / 100
            or 0
        self.volcanosmokeover:SetRate(TheWorld._ta_config_ready and TUNING.volcano
            and IsOwnerInShipwreckedExterior(owner) and rate or 0)
    end
    local function RefreshWeatherOverlays()
        if not TheWorld._ta_config_ready then return end
        local current = owner.player_classified
        if current ~= nil then
            if current._tropical_foggroggylevel ~= nil then
                self.fogover:UpdateState(current._tropical_foggroggylevel:value() / 100)
            end
            if current._tropical_nextsneeze ~= nil then
                local deadline = current._tropical_nextsneeze:value() or -1
                self.pollenover:UpdateState(deadline >= 0 and math.max(0, deadline - GetTime()) or 999)
            end
        end
        RefreshVolcanoSmoke()
    end
    self.inst:ListenForEvent("taconfigready", RefreshWeatherOverlays, TheWorld)
    self.inst:ListenForEvent("tropicalvolcanostatechanged", RefreshVolcanoSmoke, TheWorld)
    owner:ListenForEvent("regionchange_client", RefreshVolcanoSmoke)
    owner:DoTaskInTime(0, RefreshWeatherOverlays)
end
