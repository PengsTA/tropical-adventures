AddComponentPostInit("combat", function(self)
    function self:GetWeapon()
        if self.inst.components.inventory ~= nil then
            local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or
                self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            return item ~= nil
                and item.components.weapon ~= nil
                and (item.components.projectile ~= nil or
                    not (self.inst.components.rider ~= nil and
                        self.inst.components.rider:IsRiding()) or
                    item:HasTag("rangedweapon"))
                and item
                or nil
        end
    end
end)

AddClassPostConstruct("components/combat_replica", function(self)
    function self:GetWeapon()
        if self.inst.components.combat ~= nil then
            return self.inst.components.combat:GetWeapon()
        elseif self.inst.replica.inventory ~= nil then
            local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or
                self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if item ~= nil and item:HasTag("weapon") then
                if item:HasTag("projectile") or item:HasTag("rangedweapon") then
                    return item
                end
                local rider = self.inst.replica.rider
                return not (rider ~= nil and rider:IsRiding()) and item or nil
            end
        end
    end
end)

local require = GLOBAL.require
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local resolvefilepath = GLOBAL.resolvefilepath

AddClassPostConstruct("widgets/controls", function(self)
    if self.owner == nil then return end
    local VisorOver = require "widgets/visorover"
    self.visorover = self:AddChild(VisorOver(self.owner))
    self.visorover:MoveToBack()
end)

AddClassPostConstruct("screens/playerhud", function(self)
    local BatSonar = require "widgets/batsonar"
    local TrapMarker = require "widgets/trapmarker"

    local old_CreateOverlays = self.CreateOverlays
    function self:CreateOverlays(owner)
        old_CreateOverlays(self, owner)
        self.batview = self.overlayroot:AddChild(BatSonar(owner))
        self.trapmarker = self.overlayroot:AddChild(TrapMarker(owner))
    end

    local shootview = false
    local old_OnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        old_OnUpdate(self, dt)

        local owner = self.owner
        local inventory = owner and owner.replica.inventory or nil
        if inventory ~= nil then
            if self.batview and self.trapmarker and shootview ~= nil then
                if not (self.batview.shown or self.trapmarker.shown or shootview) and
                    inventory:EquipHasTag("invisiblegoggles") then
                    self.gogglesover.bg:SetTint(1, 1, 1, 0)
                elseif (self.batview.shown or self.trapmarker.shown or shootview) and
                    not inventory:EquipHasTag("invisiblegoggles") then
                    self.gogglesover.bg:SetTint(1, 1, 1, 1)
                end

                if not self.batview.shown and inventory:EquipHasTag("batvision") then
                    self.batview:StartSonar()
                elseif self.batview.shown and not inventory:EquipHasTag("batvision") then
                    self.batview:StopSonar()
                end

                if not self.trapmarker.shown and inventory:EquipHasTag("dangervision") then
                    self.trapmarker:ShowMarker()
                elseif self.trapmarker.shown and not inventory:EquipHasTag("dangervision") then
                    self.trapmarker:HideMarker()
                end

                if not shootview and inventory:EquipHasTag("shootvision") then
                    shootview = true
                elseif shootview and not inventory:EquipHasTag("shootvision") then
                    shootview = false
                end
            end
        end
    end
end)

AddPrefabPostInit("world", function(inst)
    inst:AddComponent("globalcolourmodifier")
end)

AddPlayerPostInit(function(inst)
    local function fn(ent)
        if ent == GLOBAL.TheWorld then --[[
	        local tuning = TUNING.GOGGLES_HEAT.GROUND
			 ent.Map:SetMultColour(unpack(tuning.MULT_COLOUR))
			 ent.Map:SetAddColour(unpack(tuning.ADD_COLOUR))

			 local tuning = TUNING.GOGGLES_HEAT.WAVES
			 local waves = ent.WaveComponent or ent.CloudComponent
			 if waves then
			 	waves:SetMultColour(unpack(tuning.MULT_COLOUR))
			 	waves:SetAddColour(unpack(tuning.ADD_COLOUR))
			 end]]
            return
        end
        if ent.AnimState then
            local tuning
            if not ent:HasTag("shadow") and (ent:HasTag("monster") or ent:HasTag("animal") or ent:HasTag("character") or ent:HasTag("smallcreature") or ent:HasTag("seacreature") or ent:HasTag("oceanfish")) then
                tuning = TUNING.GOGGLES_HEAT.HOT
            else
                tuning = TUNING.GOGGLES_HEAT.COLD
            end
            if tuning.BLOOM then
                ent.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            end
            ent.AnimState:SetMultColour(GLOBAL.unpack(tuning.MULT_COLOUR))
            ent.AnimState:SetAddColour(GLOBAL.unpack(tuning.ADD_COLOUR))
            -- ent.AnimState:SetSaturation(1 - tuning.DESATURATION)
        end
    end

    local function OnPlayerActivated(inst)
        GLOBAL.TheWorld:ListenForEvent("ccoverrides", function()
            inst:DoTaskInTime(0, function()
                if inst.components.playervision.heatvision then
                    if GLOBAL.TheWorld.components.globalcolourmodifier then
                        GLOBAL.TheWorld.components.globalcolourmodifier:SetModifyColourFn(fn)
                    end
                elseif inst.components.playervision.heatvision == false then
                    if GLOBAL.TheWorld.components.globalcolourmodifier then
                        GLOBAL.TheWorld.components.globalcolourmodifier:Reset()
                    end
                end
            end)
        end, inst)
    end

    if not GLOBAL.TheNet:IsDedicated() then
        inst:ListenForEvent("playeractivated", OnPlayerActivated)
    end
end)

AddComponentPostInit("playervision", function(self)
    local BAT_COLOURCUBE = resolvefilepath "images/colour_cubes/bat_vision_on_cc.tex"
    local BAT_COLOURCUBES =
    {
        day = BAT_COLOURCUBE,
        dusk = BAT_COLOURCUBE,
        night = BAT_COLOURCUBE,
        full_moon = BAT_COLOURCUBE,
    }
    local HEATVISION_COLOURCUBE = resolvefilepath("images/colour_cubes/heat_vision_cc.tex")
    local HEATVISION_COLOURCUBES =
    {
        day = HEATVISION_COLOURCUBE,
        dusk = HEATVISION_COLOURCUBE,
        night = HEATVISION_COLOURCUBE,
        full_moon = HEATVISION_COLOURCUBE,
    }
    local SHOOT_COLOURCUBE = resolvefilepath "images/colour_cubes/shooting_goggles_cc.tex"
    local SHOOT_COLOURCUBES =
    {
        day = SHOOT_COLOURCUBE,
        dusk = SHOOT_COLOURCUBE,
        night = SHOOT_COLOURCUBE,
        full_moon = SHOOT_COLOURCUBE,
    }

    local function OnEquipChanged(inst)
        local self = inst.components.playervision
        local inventory = inst.replica.inventory
        if inventory == nil then return end
        local batvision = inventory:EquipHasTag("batvision")
        local heatvision = inventory:EquipHasTag("heatvision")
        local shootvision = inventory:EquipHasTag("shootvision")
        if self.batvision ~= batvision or self.heatvision ~= heatvision or self.shootvision ~= shootvision then
            self.batvision, self.heatvision, self.shootvision = batvision, heatvision, shootvision
            self:UpdateCCTable()
        end
    end

    local function OnInit(inst, self)
        inst:ListenForEvent("equip", OnEquipChanged)
        inst:ListenForEvent("unequip", OnEquipChanged)
        if not GLOBAL.TheWorld.ismastersim then
            inst:ListenForEvent("inventoryclosed", OnEquipChanged)
            if inst.replica.inventory == nil then return end
        end
        OnEquipChanged(inst)
    end

    self.batvision = false
    self.heatvision = false
    self.shootvision = false

    self.inst:DoTaskInTime(0, OnInit, self)

    local old_UpdateCCTable = self.UpdateCCTable
    function self:UpdateCCTable(...)
        if self.RefreshInteriorVision ~= nil then
            self:RefreshInteriorVision()
        end
        if self.inst.replica.inventory and (self.inst.replica.inventory:EquipHasTag("heatvision")) then
            local cctable = (self.batvision and BAT_COLOURCUBES)
                or (self.heatvision and HEATVISION_COLOURCUBES)
                or (self.shootvision and SHOOT_COLOURCUBES)
                or nil
            -- Let the native update restore phase callbacks and honour ghost vision.
            local previous, blend = self.overridecctable, self.blendcctable
            self.overridecctable, self.blendcctable = cctable, nil
            old_UpdateCCTable(self, ...)
            self.overridecctable, self.blendcctable = previous, blend
            return
        end
        old_UpdateCCTable(self, ...)
    end
end)
