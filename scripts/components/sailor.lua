local OceanWrap = require("tools/ocean_wrap")

local Sailor = Class(function(self, inst)
    self.inst = inst
    self.boat = nil
    self.pending_boat = nil

    inst:ListenForEvent("death", function()
        self:ForceDisembark("death")
    end)
    inst:ListenForEvent("ms_becameghost", function()
        self:ForceDisembark("ghost")
    end)
    inst:ListenForEvent("transform_wereplayer", function()
        self:ForceDisembark("wereplayer")
    end)
    inst:ListenForEvent("onremove", function()
        self:CacheBoatSaveRecord()
        if not inst._despawning then
            self:ForceDisembark("remove")
        end
    end)
    inst:ListenForEvent("attacked", function(_, data)
        local boat = self.boat
        local damage = data ~= nil and data.damageresolved or 0
        if boat ~= nil and boat:IsValid() and boat.components.boathealth ~= nil and damage > 0 then
            boat.components.boathealth:DoDelta(-damage, "combat", data.attacker)
        end
    end)
end)

local function SyncBoat(self)
    if self.inst.replica.sailor ~= nil then
        self.inst.replica.sailor._boat:set(self.boat)
    end
end

function Sailor:IsSailing()
    return self.boat ~= nil
end

function Sailor:GetBoat()
    return self.boat
end

function Sailor:IsLoadingBoat()
    return self.loading_boat == true
end

function Sailor:CacheBoatSaveRecord()
    if self.boat ~= nil and self.boat:IsValid() then
        self.cached_boat_record, self.cached_boat_refs = self.boat:GetSaveRecord()
    elseif not self.loading_boat then
        self.cached_boat_record = nil
        self.cached_boat_refs = nil
    end
end

function Sailor:GetBoatSaveRecord()
    self:CacheBoatSaveRecord()
    return self.cached_boat_record, self.cached_boat_refs
end

function Sailor:GetTail()
    return self.boat ~= nil and self.boat.components.boatequipment ~= nil and
        self.boat.components.boatequipment:GetTail() or nil
end

function Sailor:GetHead()
    return self.boat ~= nil and self.boat.components.boatequipment ~= nil and
        self.boat.components.boatequipment:GetHead() or nil
end

function Sailor:NotifyTrawlItem()
    self.inst:PushEvent("trawl_item")
    if self.inst.replica.sailor ~= nil and self.inst.replica.sailor._trawl_item ~= nil then
        self.inst.replica.sailor._trawl_item:push()
    end
end

local function ShouldForceDisembark(inst)
    return inst:HasTag("playerghost")
        or inst:HasTag("wereplayer")
        or inst:HasTag("beaver")
        or inst:HasTag("weremoose")
        or inst:HasTag("weregoose")
end

local function SetBoatJumpPhysics(inst)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function PushPlayerTowardPoint(inst, x, y, z)
    local px, py, pz = inst.Transform:GetWorldPosition()
    local dist = math.sqrt((x - px) * (x - px) + (z - pz) * (z - pz))
    inst.Physics:SetMotorVel(dist * 1.67, 0, 0)
end

local function IsBoatOverLand(boat)
    local x, y, z = boat.Transform:GetWorldPosition()
    return TheWorld.Map:IsPassableAtPoint(x, y, z)
end

local function ResetBoatAnimation(boat)
    if boat ~= nil and boat:IsValid() and boat.AnimState ~= nil then
        boat.AnimState:SetBank(boat.banc or "rowboat")
        boat.AnimState:ClearOverrideBuild("player_actions_paddle")
        if not boat.AnimState:IsCurrentAnimation("run_loop") then
            boat.AnimState:PlayAnimation("run_loop", true)
        end
        if boat.SoundEmitter ~= nil then
            boat.SoundEmitter:KillSound("sailmove")
        end
    end
end

function Sailor:Embark(boat)
    if boat == nil or boat.components.sailable == nil or boat.components.sailable:IsOccupied() then
        return false
    end

    if self.boat ~= nil then
        self:Disembark(nil, true)
    end

    self.boat = boat
    SyncBoat(self)

    -- Boat entry also covers players created before the loaded map was ready.
    if OceanWrap.IsEnabled(TheWorld) then
        if self.inst.components.mapwrapper == nil then self.inst:AddComponent("mapwrapper") end
        self.inst.components.mapwrapper:Refresh()
    end

    -- Keep the occupied boat persistent as a fallback. The player session also
    -- stores a boat record, but world persistence prevents total boat loss if a
    -- load-protection path moves the player before sailor restore completes.
    boat.persists = true

    self.inst:AddTag("aquatic")
    self.inst:AddTag("sailing")
    self.inst:AddTag("sailor")

    if self.inst.components.rowboatwakespawner == nil then
        self.inst:AddComponent("rowboatwakespawner")
    end

    local x, y, z = boat.Transform:GetWorldPosition()
    self.inst.Transform:SetPosition(x, y, z)
    self.inst:AddChild(boat)
    boat.Transform:SetPosition(0, -0.1, 0)
    boat.Transform:SetRotation(0)

    if boat.components.container ~= nil then
        -- Reopen to replace a shore-inspection widget with the sailing HUD.
        boat.components.container:Close(self.inst)
        boat.components.container:Open(self.inst)
    end

    boat.components.sailable:OnEmbarked(self.inst)
    self.inst:PushEvent("embarkboat", { target = boat })
    self.inst:StartUpdatingComponent(self)
    return true
end

function Sailor:BoatJump(boat)
    if boat == nil or boat.components.sailable == nil or boat.components.sailable:IsOccupied() then
        return false
    end

    if self.boat ~= nil then
        self:Disembark(nil, true)
    end

    self.pending_boat = boat
    self.inst:AddTag("pulando")
    SetBoatJumpPhysics(self.inst)

    local x, y, z = boat.Transform:GetWorldPosition()
    self.inst:ForceFacePoint(x, y, z)
    PushPlayerTowardPoint(self.inst, x, y, z)

    if self.inst.sg ~= nil then
        self.inst.sg:GoToState("jumponboatstart", boat)
    else
        return self:FinishBoatJump()
    end

    return true
end

function Sailor:FinishBoatJump()
    local boat = self.pending_boat
    self.pending_boat = nil
    self.inst:RemoveTag("pulando")
    if boat == nil or not boat:IsValid() then
        return false
    end
    return self:Embark(boat)
end

function Sailor:ForceDisembark(reason)
    self.pending_boat = nil
    self.inst:RemoveTag("pulando")
    if self.boat == nil then
        self.cached_boat_record = nil
        self.cached_boat_refs = nil
        return false
    end
    return self:Disembark(nil, true, reason)
end

function Sailor:BoatDismount(pos)
    if self.boat == nil or pos == nil then
        return false
    end

    self.inst:AddTag("pulando")
    SetBoatJumpPhysics(self.inst)
    self.inst:ForceFacePoint(pos.x, pos.y, pos.z)
    PushPlayerTowardPoint(self.inst, pos.x, pos.y, pos.z)

    if self.inst.components.health ~= nil then
        self.inst.components.health:SetInvincible(false)
    end

    if self.inst.sg ~= nil then
        self.inst.sg:GoToState("jumponboatdismount")
    end

    return self:Disembark(nil, true, "dismount")
end

function Sailor:Disembark(pos, keep_boat, reason)
    local boat = self.boat
    if boat == nil then
        return false
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    self.inst:RemoveChild(boat)
    boat.Transform:SetPosition(x, y, z)
    boat.Transform:SetRotation(self.inst.Transform:GetRotation())
    boat.persists = true

    if boat.components.container ~= nil then
        boat.components.container:Close(self.inst)
    end
    ResetBoatAnimation(boat)

    if boat.components.sailable ~= nil then
        boat.components.sailable:OnDisembarked(self.inst)
    end

    if pos ~= nil then
        self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)
    end

    self.inst:RemoveTag("aquatic")
    self.inst:RemoveTag("sailing")
    self.inst:RemoveTag("sailor")

    if self.inst.components.rowboatwakespawner ~= nil then
        self.inst.components.rowboatwakespawner:StopSpawning()
    end

    self.boat = nil
    self.cached_boat_record = nil
    self.cached_boat_refs = nil
    SyncBoat(self)
    self.inst:StopUpdatingComponent(self)
    self.inst:PushEvent("disembarkboat", { target = boat, pos = pos, reason = reason })
    return true
end

function Sailor:OnStageGraph(moving)
    local boat = self.boat
    if boat == nil or not boat:IsValid() or boat.AnimState == nil then
        return
    end

    local sail = self:GetTail()
    local has_sail = sail ~= nil and sail:HasTag("sail")
    local sound = has_sail and (sail.sail_sound or "dontstarve_DLC002/common/sail_LP_cloth") or nil

    if moving and has_sail then
        boat.AnimState:SetBank("wilson")
        boat.AnimState:AddOverrideBuild("player_actions_paddle")
        if not boat.AnimState:IsCurrentAnimation("sail_loop") then
            boat.AnimState:PlayAnimation("sail_loop", true)
        end
        if sound ~= nil and not boat.SoundEmitter:PlayingSound("sailmove") then
            boat.SoundEmitter:PlaySound(sound, "sailmove")
        end
    else
        ResetBoatAnimation(boat)
    end
end

function Sailor:OnUpdate(dt)
    if self.boat == nil or not self.boat:IsValid() then
        self.boat = nil
        self.cached_boat_record = nil
        self.cached_boat_refs = nil
        SyncBoat(self)
        self.inst:RemoveTag("aquatic")
        self.inst:RemoveTag("sailing")
        self.inst:RemoveTag("sailor")
        if self.inst.components.rowboatwakespawner ~= nil then
            self.inst.components.rowboatwakespawner:StopSpawning()
        end
        self.inst:StopUpdatingComponent(self)
        return
    end

    if ShouldForceDisembark(self.inst) then
        self:ForceDisembark("state")
        return
    end

    if IsBoatOverLand(self.boat) then
        self:ForceDisembark("land_contact")
        return
    end

    local moving = self.inst.components.locomotor ~= nil and
        (self.inst.components.locomotor.wantstomoveforward or self.inst.components.locomotor.isrunning)

    if self.boat.components.boathealth ~= nil then
        self.boat.components.boathealth:SetIsMoving(moving)
    end

    if self.boat.components.sailable ~= nil then
        self.boat.components.sailable:SetIsMoving(moving)
        self.boat.components.sailable:RefreshSailorTags()
    end
    self:OnStageGraph(moving)

    if self.inst.components.rowboatwakespawner ~= nil then
        if moving then
            self.inst.components.rowboatwakespawner:StartSpawning()
        else
            self.inst.components.rowboatwakespawner:StopSpawning()
        end
    end
end

function Sailor:OnRemoveFromEntity()
    self:CacheBoatSaveRecord()
    if not self.inst._despawning then
        self:ForceDisembark("remove")
    end
end

function Sailor:OnSave()
    local is_active = self:IsSailing() or self:IsLoadingBoat()
    if not is_active and not (self.inst._despawning and self.cached_boat_record ~= nil) then
        self.cached_boat_record = nil
        self.cached_boat_refs = nil
        return nil
    end
    local boatrecord, refs = self:GetBoatSaveRecord()
    return boatrecord ~= nil and { boat = boatrecord } or nil, refs
end

function Sailor:OnLoad(data)
    if data ~= nil and data.boat ~= nil then
        self.cached_boat_record = data.boat
        self.cached_boat_refs = nil
        self.loading_boat = true
        self.inst:AddTag("aquatic")
        self.inst:AddTag("sailing")
        self.inst:AddTag("sailor")

        self.inst:DoTaskInTime(0, function(inst)
            if not inst:IsValid() then
                return
            end

            local x, y, z = inst.Transform:GetWorldPosition()
            if TheWorld ~= nil and TheWorld.Map ~= nil and TheWorld.Map:IsPassableAtPoint(x, 0, z) then
                inst:RemoveTag("aquatic")
                inst:RemoveTag("sailing")
                inst:RemoveTag("sailor")
                self.loading_boat = nil
                self.cached_boat_record = nil
                self.cached_boat_refs = nil
                return
            end

            local boat = FindEntity(inst, 3, function(ent)
                return ent.prefab == data.boat.prefab
                    and ent.components.sailable ~= nil
                    and not ent.components.sailable:IsOccupied()
            end, { "boatsw" }, { "INLIMBO" })

            boat = boat or SpawnSaveRecord(data.boat)
            if boat ~= nil then
                boat.Transform:SetPosition(x, y, z)
                self:Embark(boat)
                self.loading_boat = nil
                self.cached_boat_record = nil
                self.cached_boat_refs = nil
            else
                inst:RemoveTag("aquatic")
                inst:RemoveTag("sailing")
                inst:RemoveTag("sailor")
                self.loading_boat = nil
                self.cached_boat_record = nil
                self.cached_boat_refs = nil
            end
        end)
    end
end

return Sailor
