local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit

local ActionHandler = ActionHandler
local EventHandler = EventHandler
local State = State
local TimeEvent = TimeEvent

local FRAMES = FRAMES
local ACTIONS = ACTIONS
local EQUIPSLOTS = EQUIPSLOTS
local BoatEquip = require("tools/boat_equipment_helper")


local function ConfigureSailState(inst)
    local boat = inst.replica.sailor ~= nil and inst.replica.sailor:GetBoat() or nil
    local has_sail = inst:HasTag("sail") or BoatEquip.HasSail(boat)
    if inst.components.inventory:IsHeavyLifting() then
        inst.sg.statemem.heavy = true
        inst.sg:AddStateTag("noslip")
    elseif inst:IsInAnyStormOrCloud() and not inst.components.playervision:HasGoggleVision() then
        inst.sg.statemem.sandstorm = true
    elseif inst:HasTag("groggy") then
        inst.sg.statemem.groggy = true
    elseif inst:HasTag("surf") then
        inst.sg.statemem.surf = true
    elseif has_sail then
        inst.sg.statemem.sail = true
    elseif inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and
        inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("oar")
    then
        inst.sg.statemem.oar = true
    else
        inst.sg.statemem.normal = true
    end
end


local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound ~= nil then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat_paddle")
end


local function DoRowSounds(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat_paddle")
end


local function SetSleeperSleepState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:AddImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:IgnoreAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Disable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false)
        inst.components.playercontroller:Enable(false)
    end
    inst:OnSleepIn()
    inst.components.inventory:Hide()
    inst:PushEvent("ms_closepopups")
    inst:ShowActions(false)
end

local function SetSleeperAwakeState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:RemoveImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Enable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst:OnWakeUp()
    inst.components.inventory:Show()
    inst:ShowActions(true)
end

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local actionhandlers = {
    ActionHandler(ACTIONS.ACTIVATESAIL, "doshortaction"),
    ActionHandler(ACTIONS.COMPACTPOOP, "doshortaction"),
    ActionHandler(ACTIONS.DESACTIVATESAIL, "doshortaction"),
    ActionHandler(ACTIONS.BOATEQUIP, "doshortaction"),
    ActionHandler(ACTIONS.BOATUNEQUIP, "doshortaction"),
    ActionHandler(ACTIONS.BOATMOUNT, "jumponboatstart_pre"),
    ActionHandler(ACTIONS.BOATREPAIR, "dolongaction"),
    ActionHandler(ACTIONS.OPENTUNA, "dolongaction"),
    ActionHandler(ACTIONS.BOATCANNON, "doshortaction"),
    ActionHandler(ACTIONS.RETRIEVE, "dolongaction"),
    ActionHandler(ACTIONS.SHOP, "doshortaction"),
    ActionHandler(ACTIONS.SMELT, "doshortaction"),
    ActionHandler(ACTIONS.GIVE2, "give"),
    ActionHandler(ACTIONS.DISLODGE, "tap"),
    ActionHandler(ACTIONS.GAS, "crop_dust"),
    ActionHandler(ACTIONS.SURF, "surfando"),
    ActionHandler(ACTIONS.INVESTIGATEGLASS, "investigate_start"),
    ActionHandler(
        ACTIONS.BOATDISMOUNT,
        function(inst, action)
            local xm, ym, zm = action:GetActionPoint():Get()
            local passable = TheWorld.Map:IsPassableAtPoint(xm, ym, zm)
            if inst:HasTag("player") and passable == true then
                inst.posx = xm
                inst.posz = zm
                inst:ForceFacePoint(xm, ym, zm)
                return "jumponboatstart_pre"
            end
        end
    ),
    ActionHandler(
        ACTIONS.HACK,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end

            local equipamento = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equipamento and equipamento.prefab == "shears" then
                if not inst.sg:HasStateTag("preshear") then
                    if inst.sg:HasStateTag("shearing") then
                        return "shear"
                    else
                        return "shear_start"
                    end
                end
            end


            return not inst.sg:HasStateTag("prechop") and (inst.sg:HasStateTag("chopping") and "chop" or "chop_start") or
                nil
        end
    ),
    ActionHandler(
        ACTIONS.PAN,
        function(inst)
            if not inst.sg:HasStateTag("panning") then
                return "pan_start"
            end
        end
    ),
    ActionHandler(
        ACTIONS.HACK1,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("prechop") and (inst.sg:HasStateTag("chopping") and "chop" or "chop_start") or
                nil
        end
    ),

    ActionHandler(ACTIONS.SLEEPIN,
        function(inst, action)
            if action.invobject ~= nil then
                if action.invobject.onuse ~= nil then
                    action.invobject:onuse(inst)
                end
                return "bedroll"
            elseif action.target:HasTag("cama") then
                local x, y, z = action.target.Transform:GetWorldPosition()
                action.doer.Transform:SetPosition(x + 0.02, y, z + 0.02)
                return "bedroll1"
            else
                return "tent"
            end
        end
    ),
    ActionHandler(ACTIONS.TROREPAIR, "give"),
}

local eventhandlers = {

    EventHandler("cower", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("frozen")) then
            inst.sg:GoToState("cower", data)
        end
    end),

    EventHandler("grabbed", function(inst)
        if not (inst.components.health:IsDead() or inst.components.health:IsInvincible() or
            --[[inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("frozen") or]] inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("grabbed")
        end
    end),

    EventHandler("disgrabbed", function(inst)
        inst.sg:GoToState("disgrabbed")
    end),

    EventHandler("sanity_stun", function(inst, data)
        --            if not inst.components.inventory:IsItemNameEquipped("earmuffshat") then
        inst.sanity_stunned = true
        inst.sg:GoToState("sanity_stun")
        inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)

        inst:DoTaskInTime(data.duration, function()
            if inst.sg.currentstate.name == "sanity_stun" then
                inst.sg:GoToState("idle")
                inst.sanity_stunned = false
                inst:PushEvent("sanity_stun_over")
            end
        end)
        --          end
    end),

    EventHandler("sneeze", function(inst, data)
        -- print("check sneeze event!!!!!!!!!")
        -- print(inst.sg:HasStateTag("busy"))
        if not inst.components.health:IsDead() and not inst.components.health.invincible then
            inst.sg:GoToState("sneeze")
        end
    end)

}

local states = {


    State { name = "cower",
        tags = { "cower", "nopredict", "pausepredict" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("cower")
            inst.components.talker:Say("要被吃掉了!") --GetString(inst, "ANNOUNCE_QUAKE")
        end,

    },

    State { name = "grabbed",
        tags = { "busy", "nopredict", "pausepredict" },

        onenter = function(inst, data)
            if inst.components.playercontroller then
                inst.components.playercontroller:Enable(false)
            end
            if inst.player_classified and inst.player_classified.MapExplorer then
                inst.player_classified.MapExplorer:EnableUpdate(false)
            end
            -- inst.AnimState:SetFinalOffset(-10)
            inst.components.sanity:DoDelta(-TUNING.SANITY_MED)
            -- inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("grab_loop")
            -- inst:ShakeCamera(CAMERASHAKE.FULL, 2, .06, .25) -- duration, speed, scale
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst:Hide()
                if inst.HUD then
                    inst.HUD:Hide()
                end

                if inst.DynamicShadow then
                    inst.DynamicShadow:Enable(false)
                end

                -- inst:SnapCamera(5)
                -- -- inst:ScreenFade(true, 2)
                -- inst:DoTaskInTime(5, function()
                --     local nest = TheSim:FindFirstEntityWithTag("roc_nest")
                --     local nest_pos = nest and Vector3(nest.Transform:GetWorldPosition()) or { 0, 0, 0 }
                --     inst.Transform:SetPosition(nest_pos:Get())
                --     inst:PushEvent("disgrabbed")
                -- end)
            end),
        },
    },

    State { name = "disgrabbed",
        tags = { "busy", "pausepredict", "nopredict", "nomorph", "nodangle", "doing" },

        onenter = function(inst)
            -- inst:ScreenFade(false, 2)

            inst:Show()


            if inst.DynamicShadow then
                inst.DynamicShadow:Enable(true)
            end


            inst.AnimState:PlayAnimation("bucked")
            -- inst.AnimState:PushAnimation("buck_pst", false)
            -- inst.AnimState:PushAnimation("idle", false)
        end,



        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
                -- inst.components.health:DoDelta(-TUNING.HEALING_MED) --血量
            end),

            TimeEvent(60 * FRAMES, function(inst)

            end),

            TimeEvent(30 * FRAMES, function(inst)
                inst.AnimState:PushAnimation("wakeup", false)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:IsCurrentAnimation("wakeup") then
                    -- inst.components.health:SetInvincible(false)
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.HUD then
                inst.HUD:Show()
            end

            if inst.components.playercontroller then
                inst.components.playercontroller:Enable(true)
            end
            if inst.player_classified and inst.player_classified.MapExplorer then
                inst.player_classified.MapExplorer:EnableUpdate(true)
            end
            -- inst.components.playercontroller:Enable(true)
            -- inst.player_classified.MapExplorer:EnableUpdate(true)
        end,
    },

    State { name = "jumponboatstart_pre",
        tags = { "doing", "busy", "nointerrupt" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            local heavy = inst.replica.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(heavy and "heavy_jump_pre" or "jump_pre")
            inst.sg:SetTimeout(FRAMES * 18)
        end,
        events = {
            EventHandler(
                "animover",
                function(inst)
                    if TheWorld.ismastersim then
                        inst:PerformBufferedAction()
                    end
                    if not TheWorld.ismastersim then
                        inst:PerformPreviewBufferedAction()
                    end
                end
            )
        },
        onupdate = function(inst)
            if not TheWorld.ismastersim then
                if inst:HasTag("doing") then
                    if inst.entity:FlattenMovementPrediction() then
                        inst.sg:GoToState("idle", "noanim")
                    end
                elseif inst.bufferedaction == nil then
                    inst.sg:GoToState("idle", true)
                end
            end
        end,
        ontimeout = function(inst)
            if not TheWorld.ismastersim then -- client
                inst:ClearBufferedAction()
            end
            inst.sg:GoToState("idle")
        end,
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
            inst.sg.statemem.action = nil
        end
    },

    State { name = "jumponboatstart",
        tags = { "doing", "nointerupt", "busy", "canrotate", "nomorph", "nopredict" },
        onenter = function(inst, target)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.GROUND)
            inst.Physics:CollidesWith(COLLISION.GIANTS)

            inst.sg.statemem.heavy = inst.replica.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_jumpout" or "jump")

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(17 * FRAMES)
        end,
        timeline = {
            TimeEvent(
                15.2 * FRAMES,
                function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
                end
            ),
            TimeEvent(
                18 * FRAMES,
                function(inst)
                    inst.Physics:Stop()
                end
            )
        },

        events = {
            EventHandler(
                "animqueueover",
                function(inst)
                    if inst.AnimState:AnimDone() then
                        ChangeToCharacterPhysics(inst)
                        inst.sg:GoToState("idle")
                    end
                end
            )
        },

        ontimeout = function(inst)
            if not TheWorld.ismastersim then -- client
                inst:ClearBufferedAction()
            end
            ChangeToCharacterPhysics(inst)
            inst.sg:GoToState("idle")
        end,

        onexit = function(inst)
            ChangeToCharacterPhysics(inst)
            if inst.components.sailor ~= nil and inst.components.sailor.pending_boat ~= nil then
                inst.components.sailor:FinishBoatJump()
            end
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
            inst.sg.statemem.action = nil
        end
    },

    State { name = "jumponboatdismount",
        tags = { "doing", "nointerupt", "busy", "canrotate", "nomorph", "nopredict" },
        onenter = function(inst)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.GROUND)
            inst.Physics:CollidesWith(COLLISION.GIANTS)

            inst.sg.statemem.heavy = inst.replica.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_jumpout" or "jump")

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(17 * FRAMES)
        end,
        timeline = {
            TimeEvent(
                15.2 * FRAMES,
                function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
                end
            ),
            TimeEvent(
                18 * FRAMES,
                function(inst)
                    inst.Physics:Stop()
                end
            )
        },
        events = {
            EventHandler(
                "animqueueover",
                function(inst)
                    --          local x,y,z = inst.Transform:GetWorldPosition()
                    if inst.AnimState:AnimDone() then
                        ChangeToCharacterPhysics(inst)
                        --              inst.Transform:SetPosition(inst.posx,0,inst.posz)
                        inst.sg:GoToState("idle")
                    end
                end
            )
        },
        ontimeout = function(inst)
            if not TheWorld.ismastersim then -- client
                inst:ClearBufferedAction()
            end
            ChangeToCharacterPhysics(inst)
            --      local x,y,z = inst.Transform:GetWorldPosition()
            --      inst.Transform:SetPosition(inst.posx,0,inst.posz)
            inst.sg:GoToState("idle")
        end,
        onexit = function(inst)
            inst:RemoveTag("pulando")
            ChangeToCharacterPhysics(inst)
            --      local x,y,z = inst.Transform:GetWorldPosition()
            --      inst.Transform:SetPosition(inst.posx,0,inst.posz)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
            inst.sg.statemem.action = nil
        end
    },

    State { name = "crop_dust", --完全一致
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("cropdust_pre")
            inst.AnimState:PushAnimation("cropdust_loop")
            inst.AnimState:PushAnimation("cropdust_loop")
            inst.AnimState:PushAnimation("cropdust_loop")
            inst.AnimState:PushAnimation("cropdust_pst")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/bugrepellent")
            end),

            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),

            TimeEvent(20 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events = {
            EventHandler(
                "animover",
                function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end
            )
        },
    },

    State { name = "surfando", --完全一致
        tags = { "canrotate" },

        onenter = function(inst)
            local action = inst:GetBufferedAction()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("surf_loop")
        end,

        timeline =
        {

            TimeEvent(2 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),



        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("surfando") end),
        },
    },

    State { name = "pan_start", --完全一致
        tags = { "prepan", "panning", "working" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pan_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("pan") end),
        },
    },

    State { name = "pan", --完全一致
        tags = { "prepan", "panning", "working", "busy" },
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pan_loop", true)
            inst.sg:SetTimeout(1 + math.random())
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),
            TimeEvent(14 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),

            TimeEvent((6 + 15) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),
            TimeEvent((14 + 15) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),

            TimeEvent((6 + 30) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),
            TimeEvent((14 + 30) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),

            TimeEvent((6 + 45) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),
            TimeEvent((14 + 45) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),

            TimeEvent((6 + 60) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),
            TimeEvent((14 + 60) * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC003/common/harvested/pool/pan")
            end),
        },


        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle", "pan_pst")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle", "pan_pst") end),
            --EventHandler("animover", function(inst)
            --    inst.sg:GoToState("idle","pan_pst")
            --end ),
        },
    },

    State { name = "investigate_start", --完全一致
        tags = { "preinvestigate", "investigating", "working" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.sg:GoToState("investigate")
            --inst.AnimState:PlayAnimation("chop_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("investigate") end),
        },
    },

    State { name = "investigate", --完全一致
        tags = { "preinvestigate", "investigating", "working" },
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("lens")
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("preinvestigate")
            end),


            TimeEvent(16 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("investigating")
            end),

            TimeEvent(45 * FRAMES, function(inst)
                -- this covers both mystery and lighting now
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                inst.sg:GoToState("investigate_post")
            end),
        },
    },

    State { name = "investigate_post", --完全一致
        tags = { "investigating", "working" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("lens_pst")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State { name = "shear_start", --完全一致
        tags = { "preshear", "shearing", "working" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("cut_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("shear") end),
        },
    },

    State { name = "shear", --完全一致
        tags = { "preshear", "shearing", "working" },
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("cut_loop")
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/grass_tall/shears")
                inst:PerformBufferedAction()
            end),


            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("preshear")
            end),

            TimeEvent(14 * FRAMES, function(inst)
                if
                    inst.components.playercontroller ~= nil and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_PRIMARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ACTION) and
                    inst.sg.statemem.action and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                    inst.sg.statemem.action.target.components.shearable then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),

            TimeEvent(16 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("shearing")
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                --inst.AnimState:PlayAnimation("chop_pst")
                inst.sg:GoToState("shear_end")
            end),
        },
    },

    State { name = "shear_end",
        tags = { "working" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("cut_pst")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

    },

    State { name = "sanity_stun",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_sanity_pre", false)
            inst.AnimState:PushAnimation("idle_sanity_loop", true)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State { name = "tap",
        tags = { "doing", "busy" },

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onenter = function(inst, timeout)
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("tamp_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("tap_loop") end),
        },
    },

    State { name = "tap_loop",
        tags = { "doing" },

        onenter = function(inst, timeout)
            local targ = inst:GetBufferedAction() and inst:GetBufferedAction().target or nil
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()
            inst.AnimState:PushAnimation("tamp_loop", true)
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/tamping_tool")
            end),
            TimeEvent(8 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/tamping_tool")
            end),
            TimeEvent(16 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/tamping_tool")
            end),
            TimeEvent(24 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/tamping_tool")
            end),
            TimeEvent(32 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/tamping_tool")
            end),
        },

        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.AnimState:PlayAnimation("tamp_pst")
            inst.sg:GoToState("idle", false)
        end,
    },

    State { name = "row_start",
        tags = { "moving", "running", "canrotate", "autopredict", "sailing" },
        onenter = function(inst)
            ConfigureSailState(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:AddOverrideBuild("player_actions_paddle")

            if inst.sg.statemem.heavy then
                inst.AnimState:PlayAnimation("heavy_idle")
            elseif inst.sg.statemem.surf then
                inst.AnimState:PlayAnimation("surf_pre")
            elseif inst.sg.statemem.sail then
                inst.AnimState:PlayAnimation("sail_pre")
            else
                inst.AnimState:PlayAnimation("row_pre")
            end
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        timeline = {
            TimeEvent(1 * FRAMES,
                function(inst)
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            ),

        },
        events = {
            EventHandler(
                "animover",
                function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("row_loop")
                    end
                end
            )
        }
    },

    State { name = "row_loop",
        tags = { "moving", "running", "canrotate", "sailing" },
        onenter = function(inst)
            ConfigureSailState(inst)
            inst.components.locomotor:RunForward()
            local anim


            if inst.sg.statemem.heavy then
                anim = "heavy_idle"
            elseif inst.sg.statemem.surf then
                anim = "surf_loop"
            elseif inst.sg.statemem.sail then
                anim = "sail_loop"
            elseif inst.sg.statemem.oar then
                anim = "row_medium"
            else
                anim = "row_loop"
            end


            if not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
        end,

        timeline = {

            TimeEvent(
                15 * FRAMES,
                function(inst)
                    if not inst.sg.statemem.heavy then
                        DoRowSounds(inst)
                        DoFoleySounds(inst)
                    end
                end
            ),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("row_loop")
        end,

        events = {
            EventHandler("trawl_item", function(inst) inst.sg:GoToState("trawlover") end),
        },

    },

    State { name = "trawlover",
        tags = { "moving", "running", "canrotate", "sailing", "autopredict" },
        onenter = function(inst)
            ConfigureSailState(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("trawlover")
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        events = {
            EventHandler("trawl_item", function(inst) inst.sg:GoToState("trawlover") end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("row_loop")
        end,
    },

    State { name = "row_stop",
        tags = { "canrotate", "idle", "sailing" },
        onenter = function(inst)
            ConfigureSailState(inst)
            inst.components.locomotor:Stop()
            if inst.sg.statemem.heavy then
                inst.AnimState:PlayAnimation("heavy_idle")
            elseif inst.sg.statemem.surf then
                inst.AnimState:PlayAnimation("surf_pst")
            elseif inst.sg.statemem.sail then
                inst.AnimState:PlayAnimation("sail_pst")
            else
                inst.AnimState:PlayAnimation("row_pst")
            end
        end,


        events = {
            EventHandler(
                "animover",
                function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle") --end
                    end


                    inst.AnimState:ClearOverrideBuild("player_actions_paddle")
                end
            )
        }
    },

    State { name = "brake", --完全一致
        tags = { "idle", "canrotate", "boating", "sailing", "aparece" },
        onenter = function(inst)
        end,

        onexit = function(inst)

        end,

        events = {
            EventHandler(
                "animover",
                function(inst)
                    if inst.AnimState:GetCurrentAnimationTime() > 3 then
                        inst.sg:GoToState("idle")
                    end
                end
            )
        }
    },

    State { name = "bedroll1",
        tags = { "bedroll", "busy", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.Transform:SetRotation(180)

            local failreason =
                (TheWorld.state.isday and
                    (TheWorld:HasTag("cave") and "ANNOUNCE_NODAYSLEEP_CAVE" or "ANNOUNCE_NODAYSLEEP")
                )
                -- you can still sleep if your hunger will bottom out, but not absolutely
                or (inst.components.hunger.current < TUNING.CALORIES_MED and "ANNOUNCE_NOHUNGERSLEEP")
                or nil

            if failreason ~= nil then
                inst:PushEvent("performaction", { action = inst.bufferedaction })
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, failreason))
                end
                return
            end
            inst.AnimState:PlayAnimation("bedroll_sleep_loop")

            SetSleeperSleepState(inst)
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bedroll")
            end),
        },

        events =
        {
            EventHandler("firedamage", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                end
            end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    if TheWorld.state.isday or
                        (inst.components.health ~= nil and inst.components.health.takingfiredamage) or
                        (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
                        inst:PushEvent("performaction", { action = inst.bufferedaction })
                        inst:ClearBufferedAction()
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    elseif inst:GetBufferedAction() then
                        inst:PerformBufferedAction()
                        if inst.components.playercontroller ~= nil then
                            inst.components.playercontroller:Enable(true)
                        end
                        inst.sg:AddStateTag("sleeping")
                        inst.sg:AddStateTag("silentmorph")
                        inst.sg:RemoveStateTag("nomorph")
                        inst.sg:RemoveStateTag("busy")
                        inst.AnimState:PlayAnimation("bedroll_sleep_loop", true)
                    else
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sleepingbag ~= nil then
                --Interrupted while we are "sleeping"
                inst.sleepingbag.components.sleepingbag:DoWakeUp(true)
                inst.sleepingbag = nil
                SetSleeperAwakeState(inst)
            elseif not inst.sg.statemem.iswaking then
                --Interrupted before we are "sleeping"
                SetSleeperAwakeState(inst)
            end
        end,
    },

    State { name = "sneeze",
        tags = { "busy", "sneeze", "pausepredict" },

        onenter = function(inst)
            -- print("check sneeze state!!!!!!!!!")
            local usehit = inst.components.rider:IsRiding() or inst:HasTag("wereplayer")
            local stun_frames = usehit and 6 or 9
            inst.wantstosneeze = false
            inst:ClearBufferedAction()
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit", nil, .02)


            if inst.components.rider ~= nil and not inst.components.rider:IsRiding() then
                inst.AnimState:PlayAnimation("sneeze")
            end

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction(stun_frames <= 7 and stun_frames or nil)
            end

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/sneeze")
            if inst.prefab ~= "wes" then
                inst.components.talker:Say(STRINGS.CHARACTERS.GENERIC.ANNOUNCE_SNEEZE)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                if inst.components.hayfever then
                    inst.components.hayfever:DoSneezeEffects()
                end
            end),

        },

    },

    State { name = "speargun",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            if inst.components.rider:IsRiding() then
                inst.Transform:SetFourFaced()
            end
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("speargun")
            if inst.sg.prevstate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetTime(5 * FRAMES)
            end

            inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES,
                inst.components.combat.min_attack_period + .5 * FRAMES))

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
            end

            if (equip ~= nil and equip.projectiledelay or 0) > 0 then
                --V2C: Projectiles don't show in the initial delayed FRAMES so that
                --     when they do appear, they're already in front of the player.
                --     Start the attack early to keep animation in sync.
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES -
                    equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
        end,

        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),



            TimeEvent(15 * FRAMES, function(inst)
                if not inst.sg.statemem.chained then
                    if inst.components.combat:GetWeapon() and inst.components.combat:GetWeapon():HasTag("blunderbuss") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/weapon/blunderbuss_shoot")
                        if inst.components.rider:IsRiding() then
                            local cloud = SpawnPrefab("cloudpuff")
                            local pt = Vector3(inst.Transform:GetWorldPosition())
                            cloud.Transform:SetPosition(pt.x, 4.5, pt.z)
                        else
                            local cloud = SpawnPrefab("cloudpuff")
                            local pt = Vector3(inst.Transform:GetWorldPosition())
                            cloud.Transform:SetPosition(pt.x, 2, pt.z)
                        end
                    else
                        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/use_speargun")
                    end
                end
            end),

            TimeEvent(16 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
            if inst.components.rider:IsRiding() then
                inst.Transform:SetSixFaced()
            end
        end,
    },

    State { name = "peertelescope", --完全一致
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst, data)
            local act
            inst.sg.statemem.action = inst:GetBufferedAction()
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil and buffaction.pos ~= nil then
                act = buffaction:GetActionPoint()
            end
            inst:ForceFacePoint(act.x, act.y, act.z)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("telescope", false)
            inst.AnimState:PushAnimation("telescope_pst", false)

            inst.components.locomotor:Stop()
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(
                    "dontstarve_DLC002/common/use_spyglass")
            end),
        },

        onexit = function(inst)
            inst.components.playercontroller:Enable(true)
        end,

        events = {
            EventHandler("animover", function(inst)
                inst:PerformBufferedAction()
            end),
            EventHandler("animqueueover", function(inst)
                --                local telescope = inst.sg.statemem.action.invobject or inst.sg.statemem.action.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                --                if telescope and telescope.components.finiteuses then
                -- this is here because the telescope still needs to exist while playing the put away animation
                --telescope.components.finiteuses:Use()
                --                end

                inst.sg:GoToState("idle")
            end),
        },
    },

    State { name = "quickcastspell",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst.components.rider:IsRiding() then
                inst.AnimState:PlayAnimation("player_atk_pre")
                inst.AnimState:PushAnimation("player_atk", false)
            elseif inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("telescope") then
                inst.sg:GoToState("peertelescope")
            else
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
            end
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State { name = "use_fan",
        tags = { "doing" },

        onenter = function(inst)
            local invobject = nil
            if inst.bufferedaction ~= nil then
                invobject = inst.bufferedaction.invobject
                if invobject ~= nil and invobject.components.fan ~= nil and invobject.components.fan:IsChanneling() then
                    inst.sg.statemem.item = invobject
                    inst.sg.statemem.target = inst.bufferedaction.target or inst.bufferedaction.doer
                    inst.sg:AddStateTag("busy")
                end
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("fan", false)
            local skin_build = invobject:GetSkinBuild()
            local src_symbol = invobject ~= nil and invobject.components.fan ~= nil and
                invobject.components.fan.overridesymbol or "swap_fan"
            if skin_build ~= nil then
                inst.AnimState:OverrideItemSkinSymbol("fan01", skin_build, src_symbol, invobject.GUID, "fan")
            else
                inst.AnimState:OverrideSymbol("fan01", "fan", src_symbol)
            end


            if invobject and invobject.components.fan and invobject.components.fan.overridebuild then
                inst.AnimState:OverrideSymbol(
                    "fan01",
                    invobject.components.fan.overridebuild or "fan",
                    invobject.components.fan.overridesymbol or "swap_fan"
                )
            end







            inst.components.inventory:ReturnActiveActionItem(invobject)
        end,

        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst)
                if inst.sg.statemem.item ~= nil and
                    inst.sg.statemem.item:IsValid() and
                    inst.sg.statemem.item.components.fan ~= nil then
                    inst.sg.statemem.item.components.fan:Channel(inst.sg.statemem.target ~= nil and
                        inst.sg.statemem.target:IsValid() and inst.sg.statemem.target or inst)
                end
            end),
            TimeEvent(50 * FRAMES, function(inst)
                if inst.sg.statemem.item ~= nil and
                    inst.sg.statemem.item:IsValid() and
                    inst.sg.statemem.item.components.fan ~= nil then
                    inst.sg.statemem.item.components.fan:Channel(inst.sg.statemem.target ~= nil and
                        inst.sg.statemem.target:IsValid() and inst.sg.statemem.target or inst)
                end
            end),
            TimeEvent(70 * FRAMES, function(inst)
                if inst.sg.statemem.item ~= nil then
                    inst.sg:RemoveStateTag("busy")
                end
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State { name = "hamletteleport", --完全一致
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

        onenter = function(inst, data)
            ToggleOffPhysics(inst)
            inst.components.locomotor:Stop()

            inst.sg.statemem.target = data.teleporter
            inst.sg.statemem.heavy = inst.components.inventory:IsHeavyLifting()

            if data.teleporter ~= nil and data.teleporter.components.teleporter ~= nil then
                data.teleporter.components.teleporter:RegisterTeleportee(inst)
            end

            inst.AnimState:PlayAnimation("idle")

            local pos = data ~= nil and data.teleporter and data.teleporter:GetPosition() or nil

            local MAX_JUMPIN_DIST = 0
            local MAX_JUMPIN_DIST_SQ = MAX_JUMPIN_DIST * MAX_JUMPIN_DIST
            local MAX_JUMPIN_SPEED = 0

            local dist
            if pos ~= nil then
                inst:ForceFacePoint(pos:Get())
                local distsq = inst:GetDistanceSqToPoint(pos:Get())
                if distsq <= .25 * .25 then
                    dist = 0
                    inst.sg.statemem.speed = 0
                elseif distsq >= MAX_JUMPIN_DIST_SQ then
                    dist = MAX_JUMPIN_DIST
                    inst.sg.statemem.speed = MAX_JUMPIN_SPEED
                else
                    dist = math.sqrt(distsq)
                    inst.sg.statemem.speed = MAX_JUMPIN_SPEED * dist / MAX_JUMPIN_DIST
                end
            else
                inst.sg.statemem.speed = 0
                dist = 0
            end

            inst.Physics:SetMotorVel(inst.sg.statemem.speed * .5, 0, 0)

            inst.sg.statemem.teleportarrivestate = "idle"
        end,

        timeline =
        {
            TimeEvent(.5 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(inst.sg.statemem.speed * (inst.sg.statemem.heavy and .55 or .75), 0, 0)
            end),
            TimeEvent(1 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(
                    inst.sg.statemem.heavy and inst.sg.statemem.speed * .6 or inst.sg.statemem.speed, 0, 0)
            end),

            --Heavy lifting
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:SetMotorVel(inst.sg.statemem.speed * .5, 0, 0)
                end
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:SetMotorVel(inst.sg.statemem.speed * .4, 0, 0)
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:SetMotorVel(inst.sg.statemem.speed * .3, 0, 0)
                end
            end),

            --Normal
            TimeEvent(15 * FRAMES, function(inst)
                if not inst.sg.statemem.heavy then
                    inst.Physics:Stop()
                end

                -- this is just hacked in here to make the sound play BEFORE the player hits the wormhole
                if inst.sg.statemem.target ~= nil then
                    if inst.sg.statemem.target:IsValid() then
                        inst.sg.statemem.target:PushEvent("starttravelsound", inst)
                    else
                        inst.sg.statemem.target = nil
                    end
                end
            end),

            --Heavy lifting
            TimeEvent(20 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    inst.Physics:Stop()
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg.statemem.target ~= nil and
                        inst.sg.statemem.target:IsValid() and
                        inst.sg.statemem.target.components.teleporter ~= nil then
                        --Unregister first before actually teleporting
                        inst.sg.statemem.target.components.teleporter:UnregisterTeleportee(inst)
                        if inst.sg.statemem.target.components.teleporter:Activate(inst) then
                            inst.sg.statemem.isteleporting = true
                            inst.components.health:SetInvincible(true)
                            if inst.components.playercontroller ~= nil then
                                inst.components.playercontroller:Enable(false)
                            end
                            inst:Hide()
                            inst.DynamicShadow:Enable(false)
                            return
                        end
                    end
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end

            if inst.sg.statemem.isteleporting then
                inst.components.health:SetInvincible(false)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                inst:Show()
                inst.DynamicShadow:Enable(true)
            elseif inst.sg.statemem.target ~= nil
                and inst.sg.statemem.target:IsValid()
                and inst.sg.statemem.target.components.teleporter ~= nil then
                inst.sg.statemem.target.components.teleporter:UnregisterTeleportee(inst)
            end
        end,
    },

    State { name = "goggleattack",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            if inst.components.rider:IsRiding() then
                inst.Transform:SetFourFaced()
            end
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if (equip ~= nil and equip.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES -
                    equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("goggle_fast")
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetFrame(5)
            end
            inst.AnimState:PushAnimation("goggle_fast_pst", false)

            inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES,
                inst.components.combat.min_attack_period))

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
                inst.sg.statemem.retarget = target
            end
        end,

        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                    if inst.components.moisture and inst.components.moisture:GetMoisture() > 0 and not inst.components.inventory:IsInsulated() then
                        inst.components.health:DoDelta(-TUNING.HEALING_MEDSMALL, false, "Shockwhenwet", nil, true)
                        inst.sg:GoToState("electrocute")
                    end
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
            if inst.components.rider:IsRiding() then
                inst.Transform:SetSixFaced()
            end
        end,
    },

}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilson", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson", state)
end

-- 函数表函数参数与FnDecorator函数参数一致
local statedecos = {
    actions = { -- Action.deststate = function(inst, action)

    },

    events = { -- EventHandler.fn = function(inst, data)
        ["armorbroke"] = {
            before = function(inst, data)
                if data and data.armor and (data.armor:HasTag("vortex_cloak") or data.armor:HasTag("void_cloak")) and data.armor._ontakedmg then
                    return nil, true
                end
            end,
        },
    },

    states = {         -- State.onenter = function(inst)
        ["attack"] = { -- TODO: 写成独立的sg
            before = function(inst)
                if inst.components.rider:IsRiding() then return end
                local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                local cooldown = inst.components.combat.min_attack_period
                if equip and equip.prefab == "shard_beak" then
                    if not inst._beakSweepCount or not inst.AnimState:IsCurrentAnimation("atk") then
                        inst._beakSweepCount = 2
                    end
                    if inst._beakSweepCount == 0 then
                        inst.sg:GoToState("scythe") -- 直接使用收割动作
                        inst._beakSweepTrigger = true
                        inst._beakSweepCount = 2
                    else
                        inst.AnimState:PlayAnimation("atk_pre")
                        inst.AnimState:PushAnimation("atk", false)
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                        inst._beakSweepCount = inst._beakSweepCount - 1
                        inst.sg:SetTimeout(cooldown)
                    end
                else
                    inst._beakSweepCount = nil
                    return
                end
                return nil, true
            end,
        },
        ["use_fan"] = {
            after = function(rets, inst)
                local invobject = nil
                if inst.bufferedaction ~= nil then
                    invobject = inst.bufferedaction.invobject
                end
                local src_symbol = invobject ~= nil and invobject.components.fan ~= nil and
                    invobject.components.fan.overridesymbol
                if src_symbol == "fan01" then
                    inst.AnimState:OverrideSymbol("fan01", "fan_tropical", src_symbol)
                end
            end,
        },
    },
}

local Utils = require("tools/utils")
AddStategraphPostInit("wilson", function(sg)
    for action, fns in pairs(statedecos.actions) do
        if sg.actionhandlers[action] then
            Utils.FnDecorator(sg.actionhandlers[action], "deststate", fns.before, fns.after)
        end
    end
    for event, fns in pairs(statedecos.events) do
        if sg.events[event] then
            Utils.FnDecorator(sg.events[event], "fn", fns.before, fns.after)
        end
    end
    for state, fns in pairs(statedecos.states) do
        if sg.states[state] then
            Utils.FnDecorator(sg.states[state], "onenter", fns.before, fns.after)
        end
    end
end)

AddStategraphPostInit("wilson", function(sg)
    local actionHandler_attack = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.components.health:IsDead()) then
            local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            local hand = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if hand == nil and weapon and weapon.prefab == "gogglesshoothat" then
                return "goggleattack"
            end
        end
        return actionHandler_attack(inst, action, ...)
    end

    local actionHandler_blink = sg.actionhandlers[ACTIONS.BLINK].deststate
    sg.actionhandlers[ACTIONS.BLINK].deststate = function(inst, action, ...)
        if inst:IsInHamRoom() then
            return false
        end
        return actionHandler_blink(inst, action, ...)
    end

    local _attack_deststate = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon()
        if weapon and (weapon:HasTag("blunderbuss") or weapon:HasTag("speargun")) then
            return "speargun"
        end
        return _attack_deststate and _attack_deststate(inst, action, ...)
    end

    local _light_deststate = sg.actionhandlers[ACTIONS.LIGHT].deststate
    sg.actionhandlers[ACTIONS.LIGHT].deststate = function(inst, ...)
        local equipped = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equipped and equipped:HasTag("magnifying_glass") then
            return "investigate_start"
        else
            return _light_deststate(inst, ...)
        end
    end
end)

AddStategraphPostInit("wilson", function(sg)
    local _locomote_eventhandler = sg.events.locomote.fn
    sg.events.locomote.fn = function(inst, data, ...)
        local is_attacking = inst.sg:HasStateTag("attack")

        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        local should_run = inst.components.locomotor:WantsToRun()

        if inst.sg:HasStateTag("busy") or inst:HasTag("busy") or inst.sg:HasStateTag("overridelocomote") then
            return _locomote_eventhandler(inst, data, ...)
        end
        if inst:HasTag("aquatic") then
            if not is_attacking then
                if is_moving and not should_move then
                    inst.sg:GoToState("row_stop")
                elseif not is_moving and should_move or (is_moving and should_move and is_running ~= should_run) then
                    inst.sg:GoToState("row_start")
                end
            end
            return
        end
        return _locomote_eventhandler(inst, data, ...)
    end
end)


AddStategraphPostInit("wilson", function(sg)
    local _run_monkey_start_onenter = sg.states["run_monkey_start"].onenter
    local _ConfigureRunState = Upvaluehelper.GetUpvalue(_run_monkey_start_onenter, "ConfigureRunState")
    local ConfigureRunState = function(inst)
        _ConfigureRunState(inst)
        inst.sg.statemem.normalwonkey = inst.sg.statemem.normalwonkey or inst:HasTag("wilbur") or nil
    end

    local _run_start_onenter = sg.states["run_start"].onenter
    local _run_onupdate = sg.states["run"].onupdate
    local _run_onenter = sg.states["run"].onenter

    Upvaluehelper.SetUpvalue(_run_start_onenter, ConfigureRunState, "ConfigureRunState")
    Upvaluehelper.SetUpvalue(_run_onupdate, ConfigureRunState, "ConfigureRunState")
    Upvaluehelper.SetUpvalue(_run_onenter, ConfigureRunState, "ConfigureRunState")
end)
