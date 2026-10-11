-- ta_seaworthy_traveler.lua
-- Server component for Seaworthy teleportation device
local _G = _G

-- Global registry for all local seaworthy entities
local TA_ALL_SEAWORTHY = rawget(_G, "TA_ALL_SEAWORTHY") or {}
_G.TA_ALL_SEAWORTHY = TA_ALL_SEAWORTHY

local SANITY_DISTANCE = 160
local MAX_SANITY_COST = 30
local CROSS_WORLD_SANITY_COST = 15 + 30

local Chair = require "tools/ta_seaworthy"
local IsSkyChair = Chair.IsSkyChair
local GetWorldDisplayName = Chair.GetWorldDisplayName

local function LocalDestination(comp, worldid)
    local inst = comp.inst
    if Chair.IsAvailable(inst) then
        local x, y, z = inst.Transform:GetWorldPosition()
        return { id = tostring(inst.GUID), worldid = worldid, inst = inst, x = x, y = y, z = z,
            name = Chair.GetName(inst), is_broken = comp:IsBroken() }
    end
end

local function IsNearDanger(traveler)
    local hounded = _G.TheWorld.components.hounded
    if hounded ~= nil and (hounded:GetWarning() or hounded:GetAttacking()) then
        return true
    end
    local burnable = traveler.components.burnable
    if burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
        return true
    end
    return _G.FindEntity(traveler, 10, function(target)
        return target.components.combat ~= nil and
            target.components.combat.target == traveler
    end,
    { "_combat", "_health" },
    { "INLIMBO", "player" },
    nil) ~= nil
end

local function DistToCost(dist)
    local cost_sanity = 1 + dist / SANITY_DISTANCE

    if _G.TheWorld.state.season == "winter" then
        cost_sanity = cost_sanity * 1.25
    elseif _G.TheWorld.state.season == "summer" then
        cost_sanity = cost_sanity * 0.75
    end

    return math.min(MAX_SANITY_COST, math.ceil(cost_sanity))
end

local TaSeaworthyTraveler = Class(function(self, inst)
    self.inst = inst
    self.is_broken = false
    self.traveler = nil
    self.destinations = {}
    self.screen = nil
    self._cached_infos = ""

    self.onclosepopups = function(traveler)
        if traveler == self.traveler then
            self:EndTravel()
        end
    end

    table.insert(TA_ALL_SEAWORTHY, self)

    self.inst:DoTaskInTime(0, function()
        self:SyncBrokenStateToReplica()
    end)
end)

function TaSeaworthyTraveler:SetBroken(is_broken)
    self.is_broken = (is_broken == true)
    self:SyncBrokenStateToReplica()
    Chair.NotifyChanged()
end

function TaSeaworthyTraveler:IsBroken()
    return self.is_broken
end

function TaSeaworthyTraveler:SyncBrokenStateToReplica()
    local replica = self.inst.replica.ta_seaworthy_traveler
    if replica ~= nil then
        replica:SetBroken(self.is_broken)
    end
end

function TaSeaworthyTraveler:FindDestination(id, worldid)
    local _, current_worldid = GetWorldDisplayName()
    if worldid == current_worldid then
        for _, comp in ipairs(TA_ALL_SEAWORTHY) do
            local inst = comp.inst
            if tostring(inst.GUID) == id then
                return LocalDestination(comp, worldid)
            end
        end
    elseif Shard_IsWorldAvailable(worldid) then
        local response = TA_SEAWORTHY_REMOTE_CACHE[worldid]
        for _, dest in ipairs(response and response.travelables or {}) do
            if dest.id == id then
                return { id = id, worldid = worldid, x = dest.x, y = dest.y, z = dest.z,
                    name = dest.name, is_broken = dest.is_broken }
            end
        end
    end
end

function TaSeaworthyTraveler:GetSanityCost(dest)
    local _, worldid = GetWorldDisplayName()
    if dest.inst == self.inst then return -1 end
    if dest.worldid ~= worldid then return CROSS_WORLD_SANITY_COST end
    local x, _, z = self.inst.Transform:GetWorldPosition()
    return DistToCost(math.sqrt((x - dest.x) ^ 2 + (z - dest.z) ^ 2))
end

function TaSeaworthyTraveler:RefreshDestinationsData(silent)
    if not self.traveler then return end
    local current_worldname, current_worldid = GetWorldDisplayName()
    self.destinations = {}
    for _, comp in ipairs(TA_ALL_SEAWORTHY) do
        local dest = LocalDestination(comp, current_worldid)
        if dest then
            dest.worldname = current_worldname
            table.insert(self.destinations, dest)
        end
    end
    for worldid, response in pairs(TA_SEAWORTHY_REMOTE_CACHE) do
        if worldid ~= current_worldid and Shard_IsWorldAvailable(worldid) then
            for _, dest in ipairs(response.travelables) do
                table.insert(self.destinations, { id = dest.id, worldid = worldid, worldname = response.worldname,
                    name = dest.name, is_broken = dest.is_broken, x = dest.x, y = dest.y, z = dest.z })
            end
        end
    end
    table.sort(self.destinations, function(a, b)
        local world_a = tostring(a.worldid or "")
        local world_b = tostring(b.worldid or "")
        local is_cur_a = (world_a == tostring(current_worldid))
        local is_cur_b = (world_b == tostring(current_worldid))

        if is_cur_a and not is_cur_b then
            return true
        elseif not is_cur_a and is_cur_b then
            return false
        end

        if world_a ~= world_b then
            return world_a < world_b
        end

        local name_a = a.name or ""
        local name_b = b.name or ""
        return string.lower(name_a) < string.lower(name_b)
    end)

    local lines = {}
    for _, dest in ipairs(self.destinations) do
        local sanity = self:GetSanityCost(dest)
        -- Keep names from introducing delimiters into the wire format.
        local name = (dest.name ~= "" and dest.name or self.inst:GetDisplayName()):gsub("[\t\r\n]", " ")
        table.insert(lines, table.concat({ dest.id, name, sanity, dest.worldid,
            dest.worldname, dest.is_broken and "1" or "0" }, "\t"))
    end
    self._cached_infos = table.concat(lines, "\n")
    if silent then return end
    if self.screen then
        self.screen:UpdateInfos(self._cached_infos)
    elseif self.traveler.userid then
        SendModRPCToClient(GetClientModRPC("TA_SeaWorthy", "UpdateDests"), self.traveler.userid,
            self.inst, self._cached_infos)
    end
end

function TaSeaworthyTraveler:BeginTravel(traveler)
    if not traveler or not traveler:IsValid() or not traveler:HasTag("player")
        or traveler:HasTag("playerghost") or not traveler:IsNear(self.inst, 5)
        or (traveler.components.health and traveler.components.health:IsDead())
        or (traveler.components.rider and traveler.components.rider:IsRiding())
        or not Chair.IsAvailable(self.inst) then return false end

    local talk = traveler.components.talker

    if self.is_broken then
        if talk then talk:Say("这具海洋之椅损坏了，无法作为发射装置。") end
        return false
    end

    if self.traveler ~= nil and self.traveler ~= traveler then
        if self.traveler:IsValid()
            and not (self.traveler.components.health and self.traveler.components.health:IsDead())
            and self.traveler:IsNear(self.inst, 5) then
            if talk then talk:Say("请排队，正在被其他人使用。") end
            return false
        else
            self:EndTravel()
        end
    end

    if IsNearDanger(traveler) then
        if talk then talk:Say("附近太危险了，暂时无法使用海洋之椅！") end
        return false
    end

    if self.traveler == traveler then self:EndTravel() end
    self.open_time = _G.GetTime()
    self.traveler = traveler

    self.inst:StartUpdatingComponent(self)
    self:RefreshDestinationsData(true)
    TA_SEAWORTHY_REQUEST_ALL_REMOTES()

    self.inst:ListenForEvent("ms_closepopups", self.onclosepopups, traveler)
    self.inst:ListenForEvent("onremove", self.onclosepopups, traveler)
    self.inst:ListenForEvent("death", self.onclosepopups, traveler)

    if self.on_list_changed then
        self.inst:RemoveEventCallback("ta_seaworthy_list_changed", self.on_list_changed, _G.TheWorld)
    end
    self.on_list_changed = function()
        if self.traveler == traveler then
            self:RefreshDestinationsData()
        end
    end
    self.inst:ListenForEvent("ta_seaworthy_list_changed", self.on_list_changed, _G.TheWorld)

    if traveler.HUD ~= nil and traveler.HUD.ShowSeaWorthyScreen ~= nil then
        self.screen = traveler.HUD:ShowSeaWorthyScreen(self.inst, self._cached_infos)
    elseif _G.GetClientModRPC and traveler.userid then
        local open_rpc = _G.GetClientModRPC("TA_SeaWorthy", "OpenScreen")
        if open_rpc then
            _G.SendModRPCToClient(open_rpc, traveler.userid, self.inst, self._cached_infos or "")
        end
    end
    return true
end

local function GetLandingPoint(dest)
    if not dest.inst then return end
    local pt = Vector3(dest.x, 0, dest.z)
    if not TheWorld.Map:IsPassableAtPoint(pt:Get()) then return end
    local offset = FindWalkableOffset(pt, math.random() * TWOPI, dest.inst:GetPhysicsRadius(1) + .5,
        8, false, true, function(point) return not TheWorld.Map:IsPointNearHole(point) end)
    return offset and pt + offset or nil
end

function TaSeaworthyTraveler:Travel(traveler, id, worldid)
    -- A forged or delayed request must never close another player's session.
    if traveler == nil or self.traveler ~= traveler or type(id) ~= "string" or type(worldid) ~= "string" then
        return false
    end
    local talk = traveler.components.talker
    local function Fail(message)
        if talk then talk:Say(message) end
        self:EndTravel()
        return false
    end
    if not traveler:IsValid() or traveler:HasTag("playerghost")
        or (traveler.components.health and traveler.components.health:IsDead())
        or (traveler.sg and traveler.sg:HasStateTag("busy"))
        or (traveler.components.rider and traveler.components.rider:IsRiding())
        or not traveler:IsNear(self.inst, 5) or self:IsBroken() or not Chair.IsAvailable(self.inst) then
        return Fail("距离海洋之椅太远了！")
    end
    if IsNearDanger(traveler) then return Fail("附近太危险了，传送中止！") end
    local selected
    for _, dest in ipairs(self.destinations) do
        if dest.id == id and dest.worldid == worldid then selected = dest; break end
    end
    local dest = selected and self:FindDestination(id, worldid)
    if dest and dest.inst == self.inst then return Fail("你已经在这里了！") end
    if not dest then return Fail("目标世界当前不可用或未连接。") end
    local _, current_worldid = GetWorldDisplayName()
    local is_cross = worldid ~= current_worldid
    if not is_cross and not GetLandingPoint(dest) then return Fail("目标位置已被阻挡或不可到达！") end
    self:EndTravel()
    Chair.PlayActivation(self.inst)

    local function DoPerformTeleport(doer)
        if not doer:IsValid() or not Chair.IsAvailable(self.inst) or self:IsBroken()
            or doer:HasTag("playerghost") or not doer:IsNear(self.inst, 5)
            or (doer.components.health and doer.components.health:IsDead()) or IsNearDanger(doer) then
            return false
        end
        -- Revalidate after the jump animation, before consuming anything.
        dest = self:FindDestination(id, worldid)
        if not dest then return false end
        local landing = not is_cross and GetLandingPoint(dest) or nil
        if not is_cross and not landing then return false end
        local sanity = self:GetSanityCost(dest)
        if doer.components.sanity then doer.components.sanity:DoDelta(-sanity) end
        if is_cross then
            doer._ta_seaworthy_arrival = worldid
            TheWorld:PushEvent("ms_playerdespawnandmigrate", { player = doer, worldid = worldid,
                x = dest.x, y = dest.y, z = dest.z })
            return true
        end
        local xf, yf, zf = landing:Get()
        Chair.PlayActivation(dest.inst)
        if doer.components.leader and doer.components.leader.followers then
            for follower, _ in pairs(doer.components.leader.followers) do
                if follower and follower:IsValid() then
                    if follower.Physics ~= nil then
                        follower.Physics:Teleport(xf + 1, 0, zf)
                    else
                        follower.Transform:SetPosition(xf + 1, 0, zf)
                    end
                end
            end
        end

        local xi, yi, zi = self.inst.Transform:GetWorldPosition()
        if xi ~= nil and zi ~= nil then
            local heavy_items = _G.TheSim:FindEntities(xi, yi or 0, zi, 3.5, { "heavy" }, { "INLIMBO" })
            for _, item in ipairs(heavy_items) do
                if item and item:IsValid() and item.components.equippable
                    and item.components.inventoryitem and item.components.inventoryitem.owner == nil then
                    if item.Physics ~= nil then
                        item.Physics:Teleport(xf + 1, 0, zf + 1)
                    else
                        item.Transform:SetPosition(xf + 1, 0, zf + 1)
                    end
                end
            end
        end

        if doer.Physics ~= nil then
            doer.Physics:Teleport(xf, 0, zf)
        else
            doer.Transform:SetPosition(xf, 0, zf)
        end

        local vortex_prefab = IsSkyChair(dest.inst) and "ta_skyworthy_vortex_fx" or "ta_seaworthy_vortex_fx"
        local arr_vortex = _G.SpawnPrefab(vortex_prefab)
        if arr_vortex then
            arr_vortex.Transform:SetPosition(xf, 0, zf)
        end

        if doer.sg then
            doer.sg:GoToState("ta_seaworthy_jumpout")
        end

        return true
    end
    if traveler.sg then
        traveler.sg:GoToState("ta_seaworthy_sit", { teleporter = self.inst,
            is_sky = IsSkyChair(self.inst), cb = DoPerformTeleport })
    else
        DoPerformTeleport(traveler)
    end
    return true
end

function TaSeaworthyTraveler:EndTravel()
    if self.traveler ~= nil then
        self.inst:StopUpdatingComponent(self)

        if self.screen ~= nil then
            self.screen:Close()
            self.screen = nil
        elseif _G.GetClientModRPC and self.traveler.userid then
            local close_rpc = _G.GetClientModRPC("TA_SeaWorthy", "CloseScreen")
            if close_rpc then
                _G.SendModRPCToClient(close_rpc, self.traveler.userid, self.inst)
            end
        end

        self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, self.traveler)
        self.inst:RemoveEventCallback("onremove", self.onclosepopups, self.traveler)
        self.inst:RemoveEventCallback("death", self.onclosepopups, self.traveler)

        if self.on_list_changed then
            self.inst:RemoveEventCallback("ta_seaworthy_list_changed", self.on_list_changed, _G.TheWorld)
            self.on_list_changed = nil
        end

        self.traveler = nil
        self.open_time = nil
    elseif self.screen ~= nil then
        if self.screen.inst and self.screen.inst:IsValid() then
            self.screen:Kill()
        end
        self.screen = nil
    end
end

function TaSeaworthyTraveler:OnUpdate(dt)
    if self.traveler == nil then
        self.inst:StopUpdatingComponent(self)
    elseif not (self.traveler:IsValid()
            and not (self.traveler.components.health and self.traveler.components.health:IsDead())
            and self.traveler:IsNear(self.inst, 5)
            and _G.CanEntitySeeTarget(self.traveler, self.inst)) then
        self:EndTravel()
    elseif self.open_time and (_G.GetTime() - self.open_time > 60) then
        self:EndTravel()
    end
end

function TaSeaworthyTraveler:OnRemoveFromEntity()
    self:EndTravel()
    for i, comp in ipairs(TA_ALL_SEAWORTHY) do
        if comp == self then
            table.remove(TA_ALL_SEAWORTHY, i)
            break
        end
    end
    Chair.NotifyChanged()
end

return TaSeaworthyTraveler
