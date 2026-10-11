-- main/ta_seaworthy_setup.lua
-- Initialization module for Seaworthy teleportation system

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local ActionHandler = GLOBAL.ActionHandler
local TaSeaworthyScreen = require "screens/ta_seaworthy_screen"
local Chair = require "tools/ta_seaworthy"

STRINGS.NAMES.SEAWORTHY = "海洋之椅"
STRINGS.NAMES.SEAWORTHY_BROKEN = "损坏的海洋之椅"
STRINGS.RECIPE_DESC.SEAWORTHY = "跨越次元与海域的航行信标。"

STRINGS.NAMES.SKYWORTHY = "天空之椅"
STRINGS.NAMES.SKYWORTHY_BROKEN = "损坏的天空之椅"
STRINGS.RECIPE_DESC.SKYWORTHY = "跨越次元与云层的飞行信标。"

if not STRINGS.NAMES.SUNKEN_BOAT_TRINKET_4 then
    STRINGS.NAMES.SUNKEN_BOAT_TRINKET_4 = "海洋仪"
end
if not STRINGS.NAMES.TRINKET_GIFTSHOP_4 then
    STRINGS.NAMES.TRINKET_GIFTSHOP_4 = "杂耍彩带罐"
end

STRINGS.ACTIONS.TA_SEAWORTHY_TRAVEL = {
    GENERIC = "使用传送之椅",
    SEAWORTHY = "使用海洋之椅",
    SKYWORTHY = "使用天空之椅",
}
STRINGS.ACTIONS.TA_SEAWORTHY_RENAME = "修改名称"

AddReplicableComponent("ta_seaworthy_traveler")

local writeables = require "writeables"
local function AddChairWriteLayout(prefabs, prompt, random_names)
    local layout = {
        prompt = prompt,
        animbank = "ui_board_5x3",
        animbuild = "ui_board_5x3",
        menuoffset = GLOBAL.Vector3(6, -70, 0),
        cancelbtn = { text = STRINGS.SIGNS.MENU.CANCEL, control = GLOBAL.CONTROL_CANCEL },
        middlebtn = {
            text = STRINGS.SIGNS.MENU.RANDOM,
            cb = function(inst, doer, widget)
                widget:OverrideText(random_names[math.random(#random_names)])
            end,
            control = GLOBAL.CONTROL_MENU_MISC_2,
        },
        acceptbtn = { text = STRINGS.SIGNS.MENU.ACCEPT, control = GLOBAL.CONTROL_ACCEPT },
    }
    for _, prefab in ipairs(prefabs) do writeables.AddLayout(prefab, layout) end
end
AddChairWriteLayout({ "seaworthy", "seaworthy_broken", "ligamundosw" }, "为海洋之椅命名",
    { "海难母港", "亚特兰蒂斯", "藏宝湾", "风暴角", "珊瑚礁站", "海妖之眼", "旧神群岛", "虚空海流", "热带航站" })
AddChairWriteLayout({ "skyworthy", "skyworthy_broken" }, "为天空之椅命名",
    { "天空之城", "云端母港", "斯瓦罗普", "高地航站", "雷鸟之巢", "大遗迹站", "雾林航站", "浮空群岛" })

AddAction("TA_SEAWORTHY_TRAVEL", STRINGS.ACTIONS.TA_SEAWORTHY_TRAVEL.GENERIC, function(act)
    if act.doer ~= nil and act.target ~= nil and act.doer:HasTag("player") then
        local traveler_comp = act.target.components.ta_seaworthy_traveler
        if traveler_comp and not act.target:HasTag("burnt") and not act.target:HasTag("fire") then
            return traveler_comp:BeginTravel(act.doer)
        end
    end
    return false
end)

ACTIONS.TA_SEAWORTHY_TRAVEL.strfn = function(act)
    if Chair.IsSkyChair(act.target) then
        return "SKYWORTHY"
    end
    return "SEAWORTHY"
end

ACTIONS.TA_SEAWORTHY_TRAVEL.priority = 1
ACTIONS.TA_SEAWORTHY_TRAVEL.mount_valid = false

AddAction("TA_SEAWORTHY_RENAME", STRINGS.ACTIONS.TA_SEAWORTHY_RENAME, function(act)
    if act.doer ~= nil and act.target ~= nil and act.target.components.writeable then
        if not act.target:HasTag("burnt") and not act.target:HasTag("fire") then
            act.target.components.writeable:BeginWriting(act.doer)
            return true
        end
    end
    return false
end)
ACTIONS.TA_SEAWORTHY_RENAME.priority = 2
ACTIONS.TA_SEAWORTHY_RENAME.mount_valid = false

AddComponentAction("SCENE", "ta_seaworthy_traveler", function(inst, doer, actions, right)
    if right then
        if not inst:HasTag("burnt") and not inst:HasTag("fire") then
            local replica = inst.replica and inst.replica.ta_seaworthy_traveler
            if replica and replica:CanTravel(doer) then
                table.insert(actions, ACTIONS.TA_SEAWORTHY_TRAVEL)
            end
        end
    end
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    if right and (inst.prefab == "featherpencil" or inst.prefab == "charcoal" or inst:HasTag("drawingtool")) then
        if target and target:HasTag("ta_seaworthy_chair") then
            if not target:HasTag("burnt") and not target:HasTag("fire") then
                table.insert(actions, ACTIONS.TA_SEAWORTHY_RENAME)
            end
        end
    end
end)

-- 5. Stategraph States & Action Handlers
local function RestoreChairPhysics(inst)
    inst.Physics:SetCollisionMask(GLOBAL.COLLISION.WORLD, GLOBAL.COLLISION.OBSTACLES,
        GLOBAL.COLLISION.SMALLOBSTACLES, GLOBAL.COLLISION.CHARACTERS, GLOBAL.COLLISION.GIANTS)
end

local function FinishJumpIn(inst)
    inst.sg:GoToState("ta_seaworthy_transit", inst.sg.statemem.onjumpinfn)
end

local function AddSeaworthyStategraphStates()
    local sit_state = GLOBAL.State{
        name = "ta_seaworthy_sit",
        tags = { "doing", "busy", "nopredict", "nomorph" },
        onenter = function(inst, data)
            local chair = data and data.teleporter
            if not Chair.IsAvailable(chair) then
                inst.sg:GoToState("idle")
                return
            end
            inst.sg.statemem.data = data
            inst.sg.statemem.target = chair
            if inst.components.health then
                inst.sg.statemem.was_invincible = inst.components.health.invincible
                inst.components.health:SetInvincible(true)
            end
            inst.sg.statemem.build = data.is_sky and "player_portal_hamlet" or "player_portal_shipwrecked"
            if inst.components.locomotor then inst.components.locomotor:Stop() end
            inst.Physics:Stop()
            inst.Physics:SetCollisionMask(GLOBAL.COLLISION.GROUND)
            inst.Physics:Teleport(chair.Transform:GetWorldPosition())
            inst.Transform:SetRotation(0)
            chair:Hide()
            inst.AnimState:AddOverrideBuild(inst.sg.statemem.build)
            local anim = data.is_sky and "hamlet_portal" or "shipwrecked_portal"
            inst.AnimState:PlayAnimation(anim .. "_pre")
            inst.AnimState:PushAnimation(anim .. "_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/portal/sit")
            inst.SoundEmitter:PlaySound(data.is_sky and "dontstarve_DLC003/common/crafted/skyworthy/LP"
                or "dontstarve_DLC002/common/portal/ride_LP", "ta_chair_ride")
            inst.sg:SetTimeout(2)
        end,
        ontimeout = function(inst)
            local data = inst.sg.statemem.data
            inst.sg:GoToState(Chair.IsAvailable(data and data.teleporter) and "ta_seaworthy_jumpin" or "idle", data)
        end,
        onexit = function(inst)
            if inst.sg.statemem.data == nil then return end
            local chair = inst.sg.statemem.target
            if chair and chair:IsValid() then chair:Show() end
            if inst.sg.statemem.build then inst.AnimState:ClearOverrideBuild(inst.sg.statemem.build) end
            inst.SoundEmitter:KillSound("ta_chair_ride")
            RestoreChairPhysics(inst)
            if inst.components.health then
                inst.components.health:SetInvincible(inst.sg.statemem.was_invincible == true)
            end
        end,
    }

    local transit_state = GLOBAL.State{
        name = "ta_seaworthy_transit",
        tags = { "doing", "busy", "nopredict", "nomorph" },
        onenter = function(inst, callback)
            inst.sg.statemem.callback = callback
            inst.Physics:Stop()
            if inst.components.health then
                inst.sg.statemem.was_invincible = inst.components.health.invincible
                inst.components.health:SetInvincible(true)
            end
            local controller = inst.components.playercontroller
            if controller then
                inst.sg.statemem.controller_enabled = controller.classified == nil
                    or controller.classified.iscontrollerenabled:value()
                controller:Enable(false)
            end
            inst:Hide()
            inst.DynamicShadow:Enable(false)
            inst:ScreenFade(false, .5)
            inst.sg:SetTimeout(.75)
        end,
        ontimeout = function(inst)
            local callback = inst.sg.statemem.callback
            inst.sg.statemem.callback = nil
            -- A successful migration retains this state until the player despawns.
            inst.sg:SetTimeout(10)
            if callback == nil or not callback(inst) then inst.sg:GoToState("idle") end
        end,
        onexit = function(inst)
            inst:Show()
            inst.DynamicShadow:Enable(true)
            inst:SnapCamera()
            inst:ScreenFade(true, .5)
            if inst.components.health then
                inst.components.health:SetInvincible(inst.sg.statemem.was_invincible == true)
            end
            if inst.components.playercontroller then
                inst.components.playercontroller:Enable(inst.sg.statemem.controller_enabled)
            end
        end,
    }

    local jumpin_state = GLOBAL.State{
        name = "ta_seaworthy_jumpin",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

        onenter = function(inst, data)
            if inst.components.locomotor then
                inst.components.locomotor:Stop()
            end

            inst.sg.statemem.target = data and data.teleporter
            inst.Physics:SetCollisionMask(GLOBAL.COLLISION.GROUND)
            inst.sg.statemem.onjumpinfn = data and data.cb
            inst.sg.statemem.heavy = inst.replica.inventory and inst.replica.inventory:IsHeavyLifting()

            inst.sg:SetTimeout(3)
            if inst.components.health then
                inst.sg.statemem.was_invincible = inst.components.health.invincible
                inst.components.health:SetInvincible(true)
            end

            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_jump" or "jump")

            local x, y, z = inst.Transform:GetWorldPosition()
            local vortex_prefab = (data and data.is_sky) and "ta_skyworthy_vortex_fx" or "ta_seaworthy_vortex_fx"
            local vortex = GLOBAL.SpawnPrefab(vortex_prefab)
            if vortex then
                vortex.Transform:SetPosition(x, 0, z)
            end

            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
            end
        end,

        timeline = {
            GLOBAL.TimeEvent(15 * GLOBAL.FRAMES, function(inst)
                if inst.DynamicShadow then
                    inst.DynamicShadow:Enable(false)
                end
            end),
        },

        events = {
            GLOBAL.EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    FinishJumpIn(inst)
                end
            end),
        },

        ontimeout = function(inst) inst.sg:GoToState("idle") end,

        onexit = function(inst)
            RestoreChairPhysics(inst)
            if inst.components.health then
                inst.components.health:SetInvincible(inst.sg.statemem.was_invincible == true)
            end
            if inst.DynamicShadow then
                inst.DynamicShadow:Enable(true)
            end
        end,
    }

    local jumpout_state = GLOBAL.State{
        name = "ta_seaworthy_jumpout",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:Stop()
            end

            inst.sg.statemem.heavy = inst.replica.inventory and inst.replica.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_jumpout" or "jumpout")

            if inst.DynamicShadow then
                inst.DynamicShadow:Enable(true)
            end

            inst.Physics:SetMotorVel(3, 0, 0)
        end,

        timeline = {
            GLOBAL.TimeEvent(10 * GLOBAL.FRAMES, function(inst)
                inst.Physics:SetMotorVel(1, 0, 0)
            end),
            GLOBAL.TimeEvent(15 * GLOBAL.FRAMES, function(inst)
                inst.Physics:Stop()
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
        },

        events = {
            GLOBAL.EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.Physics:Stop()
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.Physics:Stop()
        end,
    }

    local jumpin_client = GLOBAL.State{
        name = "ta_seaworthy_jumpin",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:Stop()
            end
            inst.AnimState:PlayAnimation("jump")
        end,
    }

    local jumpout_client = GLOBAL.State{
        name = "ta_seaworthy_jumpout",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:Stop()
            end
            inst.AnimState:PlayAnimation("jumpout")
        end,
        events = {
            GLOBAL.EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    }

    AddStategraphState("wilson", jumpin_state)
    AddStategraphState("wilson", sit_state)
    AddStategraphState("wilson", transit_state)
    AddStategraphState("wilson", jumpout_state)
    AddStategraphState("wilson_client", jumpin_client)
    AddStategraphState("wilson_client", jumpout_client)
end
AddSeaworthyStategraphStates()

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TA_SEAWORTHY_TRAVEL, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TA_SEAWORTHY_TRAVEL, "give"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TA_SEAWORTHY_RENAME, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TA_SEAWORTHY_RENAME, "give"))

AddClassPostConstruct("screens/playerhud", function(self, anim, owner)
    self.ShowSeaWorthyScreen = function(_, attach, cached_infos)
        if attach == nil then
            return nil
        else
            if self.ta_seaworthy_screen then
                local old_screen = self.ta_seaworthy_screen
                self.ta_seaworthy_screen = nil
                old_screen:Close()
            end
            self.ta_seaworthy_screen = TaSeaworthyScreen(self.owner, attach, cached_infos)
            self:OpenScreenUnderPause(self.ta_seaworthy_screen)
            return self.ta_seaworthy_screen
        end
    end

    self.CloseSeaWorthyScreen = function(_)
        local screen = self.ta_seaworthy_screen
        if screen then
            self.ta_seaworthy_screen = nil
            screen:Close()
        end
    end
end)

AddModRPCHandler("TA_SeaWorthy", "Travel", function(player, inst, id, worldid)
    if inst and inst:IsValid() and inst.components.ta_seaworthy_traveler then
        inst.components.ta_seaworthy_traveler:Travel(player, id, worldid)
    end
end)

AddModRPCHandler("TA_SeaWorthy", "Rename", function(player, inst)
    if inst and inst:IsValid() and inst.components.writeable and player and player:IsValid() then
        if player:IsNear(inst, 6) and not inst:HasTag("burnt") and not inst:HasTag("fire") then
            inst.components.writeable:BeginWriting(player)
        end
    end
end)

AddModRPCHandler("TA_SeaWorthy", "CloseScreen", function(player, inst)
    if inst and inst:IsValid() and inst.components.ta_seaworthy_traveler then
        if inst.components.ta_seaworthy_traveler.traveler == player then
            inst.components.ta_seaworthy_traveler:EndTravel()
        end
    end
end)

AddClientModRPCHandler("TA_SeaWorthy", "OpenScreen", function(inst, cached_infos)
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and GLOBAL.ThePlayer.HUD.ShowSeaWorthyScreen then
        GLOBAL.ThePlayer.HUD:ShowSeaWorthyScreen(inst, cached_infos)
    end
end)

AddClientModRPCHandler("TA_SeaWorthy", "UpdateDests", function(inst, cached_infos)
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and GLOBAL.ThePlayer.HUD.ta_seaworthy_screen
        and GLOBAL.ThePlayer.HUD.ta_seaworthy_screen.attach == inst and GLOBAL.ThePlayer.HUD.ta_seaworthy_screen.isopen then
        GLOBAL.ThePlayer.HUD.ta_seaworthy_screen:UpdateInfos(cached_infos)
    end
end)

AddClientModRPCHandler("TA_SeaWorthy", "CloseScreen", function(inst)
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and GLOBAL.ThePlayer.HUD.ta_seaworthy_screen
        and GLOBAL.ThePlayer.HUD.ta_seaworthy_screen.attach == inst then
        GLOBAL.ThePlayer.HUD:CloseSeaWorthyScreen()
    end
end)

local SHARD_RPC_NAMESPACE = "TA_SeaWorthy_Shard"
local CACHE_TTL = 60
local REQUEST_TIMEOUT = 5
local last_broadcast_time = -2
local broadcast_pending = false

GLOBAL.TA_ALL_SEAWORTHY = rawget(GLOBAL, "TA_ALL_SEAWORTHY") or {}
GLOBAL.TA_SEAWORTHY_REMOTE_CACHE = {}
GLOBAL.TA_SEAWORTHY_REMOTE_TIMESTAMPS = {}
GLOBAL.TA_SEAWORTHY_REMOTE_PENDING = {}

local function GetAvailableRemoteShardIds()
    local result = {}
    if GLOBAL.TheShard then
        local my_id = tostring(GLOBAL.TheShard:GetShardId())
        for worldid in pairs(GLOBAL.Shard_GetConnectedShards()) do
            local id = tostring(worldid)
            if id ~= my_id then result[id] = true end
        end
    end
    return result
end

local function InvalidateRemote(id)
    GLOBAL.TA_SEAWORTHY_REMOTE_CACHE[id] = nil
    GLOBAL.TA_SEAWORTHY_REMOTE_TIMESTAMPS[id] = nil
    GLOBAL.TA_SEAWORTHY_REMOTE_PENDING[id] = nil
    if GLOBAL.TheWorld then GLOBAL.TheWorld:PushEvent("ta_seaworthy_list_changed") end
end

GLOBAL.TA_SEAWORTHY_NOTIFY_ALL_SHARDS = function()
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then return end
    local now = GLOBAL.GetTime()
    if now - last_broadcast_time < 2 then broadcast_pending = true; return end
    last_broadcast_time = now
    broadcast_pending = false
    local rpc = GetShardModRPC(SHARD_RPC_NAMESPACE, "NotifyChange")
    if rpc then
        for id in pairs(GetAvailableRemoteShardIds()) do SendModRPCToShard(rpc, id) end
    end
end

GLOBAL.TA_SEAWORTHY_REQUEST_REMOTE = function(worldid)
    if not GLOBAL.TheShard or worldid == nil then return false end
    local id = tostring(worldid)
    if id == tostring(GLOBAL.TheShard:GetShardId()) or not GLOBAL.Shard_IsWorldAvailable(id) then
        return false
    end
    local now = GLOBAL.GetTime()
    local cached = GLOBAL.TA_SEAWORTHY_REMOTE_TIMESTAMPS[id]
    if cached and now - cached < CACHE_TTL then return false end
    local pending = GLOBAL.TA_SEAWORTHY_REMOTE_PENDING[id]
    if pending and now - pending < REQUEST_TIMEOUT then return false end
    local rpc = GetShardModRPC(SHARD_RPC_NAMESPACE, "ReqList")
    if not rpc then return false end
    GLOBAL.TA_SEAWORTHY_REMOTE_PENDING[id] = now
    SendModRPCToShard(rpc, id)
    return true
end

GLOBAL.TA_SEAWORTHY_REQUEST_ALL_REMOTES = function()
    for id in pairs(GetAvailableRemoteShardIds()) do GLOBAL.TA_SEAWORTHY_REQUEST_REMOTE(id) end
end

AddShardModRPCHandler(SHARD_RPC_NAMESPACE, "ReqList", function(sender)
    local world, shard = GLOBAL.TheWorld, GLOBAL.TheShard
    if not world or not world.ismastersim or not shard then return end
    local worldname, worldid = Chair.GetWorldDisplayName()
    local id = tostring(sender)
    if id == worldid or not GLOBAL.Shard_IsWorldAvailable(id) then return end
    local travelables = {}
    for _, comp in ipairs(GLOBAL.TA_ALL_SEAWORTHY) do
        local inst = comp.inst
        if Chair.IsAvailable(inst) then
            local x, y, z = inst.Transform:GetWorldPosition()
            table.insert(travelables, { id = tostring(inst.GUID), name = Chair.GetName(inst),
                x = x, y = y, z = z, is_broken = comp:IsBroken() })
        end
    end
    SendModRPCToShard(GetShardModRPC(SHARD_RPC_NAMESPACE, "ResList"), id,
        GLOBAL.DataDumper({ worldid = worldid, worldname = worldname, travelables = travelables }, nil, true))
end)

local function IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

AddShardModRPCHandler(SHARD_RPC_NAMESPACE, "ResList", function(sender, payload)
    local world = GLOBAL.TheWorld
    if not world or not world.ismastersim or type(payload) ~= "string" then return end
    local id = tostring(sender)
    if not GLOBAL.Shard_IsWorldAvailable(id) then return end
    local ok, response = GLOBAL.RunInSandboxSafe(payload)
    if not ok or type(response) ~= "table" or response.worldid ~= id
        or type(response.worldname) ~= "string" or type(response.travelables) ~= "table" then return end
    for _, dest in ipairs(response.travelables) do
        if type(dest) ~= "table" or type(dest.id) ~= "string" or type(dest.name) ~= "string"
            or not IsFinite(dest.x) or not IsFinite(dest.y) or not IsFinite(dest.z) then return end
    end
    GLOBAL.TA_SEAWORTHY_REMOTE_CACHE[id] = response
    GLOBAL.TA_SEAWORTHY_REMOTE_TIMESTAMPS[id] = GLOBAL.GetTime()
    GLOBAL.TA_SEAWORTHY_REMOTE_PENDING[id] = nil
    world:PushEvent("ta_seaworthy_list_changed")
end)

AddShardModRPCHandler(SHARD_RPC_NAMESPACE, "NotifyChange", function(sender)
    local world = GLOBAL.TheWorld
    if not world or not world.ismastersim then return end
    local id = tostring(sender)
    if not GLOBAL.Shard_IsWorldAvailable(id) then return end
    InvalidateRemote(id)
    GLOBAL.TA_SEAWORTHY_REQUEST_REMOTE(id)
end)

-- Persist a migration marker so ordinary logins near chairs do not trigger arrival.
AddPlayerPostInit(function(player)
    if not GLOBAL.TheWorld.ismastersim then return end
    local old_save, old_load = player.OnSave, player.OnLoad
    player.OnSave = function(inst, data, ...)
        data.ta_seaworthy_arrival = inst._ta_seaworthy_arrival
        if old_save then return old_save(inst, data, ...) end
    end
    player.OnLoad = function(inst, data, ...)
        inst._ta_seaworthy_arrival = data and data.ta_seaworthy_arrival
        if old_load then return old_load(inst, data, ...) end
    end
end)

AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then return end
    inst:DoTaskInTime(1, GLOBAL.TA_SEAWORTHY_REQUEST_ALL_REMOTES)
    inst:DoPeriodicTask(REQUEST_TIMEOUT, function()
        if broadcast_pending then GLOBAL.TA_SEAWORTHY_NOTIFY_ALL_SHARDS() end
        local connected = GetAvailableRemoteShardIds()
        for id in pairs(GLOBAL.TA_SEAWORTHY_REMOTE_CACHE) do
            local timestamp = GLOBAL.TA_SEAWORTHY_REMOTE_TIMESTAMPS[id]
            if not connected[id] or (timestamp and GLOBAL.GetTime() - timestamp >= CACHE_TTL) then
                InvalidateRemote(id)
            end
        end
        for id in pairs(GLOBAL.TA_SEAWORTHY_REMOTE_PENDING) do
            if not connected[id] then InvalidateRemote(id) end
        end
        GLOBAL.TA_SEAWORTHY_REQUEST_ALL_REMOTES()
    end)
    inst:ListenForEvent("ms_playerjoined", function(_, player)
        if not player or not player:IsValid() then return end
        player:DoTaskInTime(0.1, function()
            local arrival = player._ta_seaworthy_arrival
            player._ta_seaworthy_arrival = nil
            if arrival ~= tostring(GLOBAL.TheShard:GetShardId()) or not player:IsValid()
                or not player.components.health or player.components.health:IsDead() then return end
            local chair = GLOBAL.FindEntity(player, 4, Chair.IsAvailable, { "ta_seaworthy_chair" })
            if not chair then return end
            Chair.PlayActivation(chair)
            local fx = GLOBAL.SpawnPrefab(Chair.IsSkyChair(chair) and "ta_skyworthy_vortex_fx" or "ta_seaworthy_vortex_fx")
            if fx then fx.Transform:SetPosition(player.Transform:GetWorldPosition()) end
            if player.sg then
                player:SnapCamera()
                -- Keep the engine's loading fade and its world activation callback.
                player.sg:GoToState("ta_seaworthy_jumpout")
            end
        end)
    end)
end)

if GLOBAL.Shard_UpdateWorldState then
    local old_update = GLOBAL.Shard_UpdateWorldState
    GLOBAL.Shard_UpdateWorldState = function(worldid, state, ...)
        local ret = old_update(worldid, state, ...)
        local world = GLOBAL.TheWorld
        if world and world.ismastersim then
            InvalidateRemote(tostring(worldid))
            if state == GLOBAL.REMOTESHARDSTATE.READY then
                world:DoTaskInTime(.5, function() GLOBAL.TA_SEAWORTHY_REQUEST_REMOTE(worldid) end)
            end
        end
        return ret
    end
end
