local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler

local ActionHandler = ActionHandler
local EventHandler = EventHandler
local State = State
local TimeEvent = TimeEvent

local FRAMES = FRAMES
local ACTIONS = ACTIONS
local EQUIPSLOTS = EQUIPSLOTS
local BoatEquip = require("tools/boat_equipment_helper")

local TIMEOUT = 2


local function ConfigureSailState(inst)
    local boat = inst.replica.sailor ~= nil and inst.replica.sailor:GetBoat() or nil
    local has_sail = inst:HasTag("sail") or BoatEquip.HasSail(boat)
    if inst.replica.inventory:IsHeavyLifting() then
        inst.sg.statemem.heavy = true
        inst.sg.statemem.heavy_fast = inst:HasTag("mightiness_mighty")
    elseif inst:GetStormLevel() >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
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
    local inventory = inst.replica.inventory
    if inventory ~= nil then
        for k, v in pairs(inventory:GetEquips()) do
            if v.foleysound ~= nil then
                inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
            end
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.foleysound ~= nil then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat_paddle")
end

local function DoRowSounds(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat_paddle")
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
            return not inst.sg:HasStateTag("prechop") and "chop_start" or nil
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
            return not inst.sg:HasStateTag("prechop") and "chop_start" or nil
        end
    ),

    ActionHandler(ACTIONS.SLEEPIN,
        function(inst, action)
            if action and action.target and action.target:HasTag("cama") then
                local x, y, z = action.target.Transform:GetWorldPosition()
                action.doer.Transform:SetPosition(x + 0.02, y, z + 0.02)
            end
            return action.invobject ~= nil and "bedroll" or action.target:HasTag("cama") and "bedroll1" or "tent"
        end
    ),
    ActionHandler(ACTIONS.TROREPAIR, "give"),
}

local eventhandlers = {
    EventHandler("sanity_stun",
        function(inst, data)
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
        end)
}

local states = {


    State { name = "jumponboatstart_pre",
        tags = { "doing", "busy", "nointerrupt" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            local heavy = inst.replica.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(heavy and "heavy_jump_pre" or "jump_pre")
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State { name = "pan_start",
        tags = { "prepan", "panning", "working" },
        server_states = { "pan_start", "pan" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst.sg:ServerStateMatches() then
                inst.AnimState:PlayAnimation("pan_pre")
                inst.AnimState:PushAnimation("pan_loop", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pan_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State { name = "investigate_start",
        tags = { "preinvestigate", "investigating", "working" },
        server_states = { "investigate_start", "investigate", "investigate_post" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst:HasTag("investigating") then
                inst.AnimState:PlayAnimation("lens")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("lens_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State { name = "shear_start",
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

    State { name = "shear",
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

    State { name = "death_boat",
        tags = { "busy", "nopredict", "nomorph", "drowning", "nointerrupt" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            --   inst.AnimState:Hide("swap_arm_carry")
            --   inst.AnimState:PlayAnimation("sink")
            inst.AnimState:SetSortOrder(0)
            if inst.components.inventory ~= nil then
                inst.components.inventory:DropEverything(true)
            end
        end,
        timeline = {
            TimeEvent(2 * FRAMES, function(inst) inst.DynamicShadow:Enable(false) end),
            TimeEvent(3 * FRAMES, function(inst) inst.sg:GoToState("idle") end)

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
        onexit = function(inst)
            inst.DynamicShadow:Enable(true)
            --			inst.components.health:SetVal(0, "drowning")
        end
    },

    State { name = "tap",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")
            inst.AnimState:PlayAnimation("tamp_pre")
            inst.AnimState:PushAnimation("tamp_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("tamp_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("tamp_pst")
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make_preview")
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

            --heavy lifting
            TimeEvent(1 * FRAMES, function(inst)
                PlayFootstep(inst, nil, true)
                DoFoleySounds(inst)
            end),
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

    State { name = "row_loop", ----删掉似乎都没关系
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

            TimeEvent(15 * FRAMES, function(inst)
                if not inst.sg.statemem.heavy then
                    DoRowSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("row_loop")
        end,

        events = {
            EventHandler("trawl_item", function(inst) inst.sg:GoToState("trawlover") end),
        },
    },

    State { name = "trawlover",
        tags = { "moving", "running", "canrotate", "sailing" },
        onenter = function(inst)
            ConfigureSailState(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("trawlover")
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        events = {
            EventHandler("trawl_item", function(inst) inst.sg:GoToState("trawlover") end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("row_loop")
        end,
    },

    State { name = "row_stop",
        tags = { "canrotate", "idle", "sailing", "aparece" },
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
    }
    ,
    State { name = "brake",
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
        tags = { "bedroll", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.Transform:SetRotation(180)
            inst.AnimState:PlayAnimation("bedroll_sleep_loop")

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") or inst:HasTag("sleeping") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State { name = "speargun",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.Transform:SetFourFaced()
            end
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("speargun")
            if inst.sg.prevstate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetTime(5 * FRAMES)
            end

            if inst.replica.combat ~= nil then
                inst.replica.combat:StartAttack()
                inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES,
                    inst.replica.combat:MinAttackPeriod() + .5 * FRAMES))
            end

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                end
            end

            if (equip.projectiledelay or 0) > 0 then
                --V2C: Projectiles don't show in the initial delayed frames so that
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
                    inst:ClearBufferedAction()
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
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),



            TimeEvent(15 * FRAMES, function(inst)
                if not inst.sg.statemem.chained then
                    if inst.replica.combat:GetWeapon() and inst.replica.combat:GetWeapon():HasTag("blunderbuss") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/weapon/blunderbuss_shoot")
                        if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
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
                    inst:ClearBufferedAction()
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
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
            if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.Transform:SetSixFaced()
            end
        end,
    },

    State { name = "peertelescope",
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
            if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.AnimState:PlayAnimation("player_atk_pre")
                inst.AnimState:PushAnimation("player_atk_lag", false)
            elseif inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("telescope") then
                inst.sg:GoToState("peertelescope")
            else
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State { name = "hamletteleport",
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
                inst:PerformPreviewBufferedAction()
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

}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson_client", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilson_client", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson_client", state)
end

AddStategraphState("wilson_client",
    State {
        name = "goggleattack", --激光眼镜
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()
                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                    inst.sg.statemem.retarget = buffaction.target
                end
            end
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if (equip ~= nil and equip.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES -
                    equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
            inst.replica.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("goggle_fast")
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetFrame(5)
            end
            inst.AnimState:PushAnimation("goggle_fast_pst", false)

            inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES,
                inst.replica.combat:MinAttackPeriod()))
        end,

        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
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
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.replica.combat:CancelAttack()
            end
        end,
    }
)

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
        }
    },

    states = { -- State.onenter = function(inst)

    },
}

local Utils = require("tools/utils")
AddStategraphPostInit("wilson_client", function(sg)
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

AddStategraphPostInit("wilson_client", function(sg)
    local actionHandler_attack = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.replica.health:IsDead()) then
            local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            local hand = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
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
        if not (inst.sg:HasStateTag("attack") and action and action.target == inst.sg.statemem.attacktarget or inst.replica.health:IsDead()) then
            local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon and (weapon:HasTag("blunderbuss") or weapon:HasTag("speargun")) then
                return "speargun"
            end
        end
        return _attack_deststate and _attack_deststate(inst, action, ...)
    end

    local _light_deststate = sg.actionhandlers[ACTIONS.LIGHT].deststate
    sg.actionhandlers[ACTIONS.LIGHT].deststate = function(inst, ...)
        local equipped = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equipped and equipped:HasTag("magnifying_glass") then
            return "investigate_start"
        else
            return _light_deststate(inst, ...)
        end
    end
end)


AddStategraphPostInit("wilson_client", function(sg)
    local _locomote_eventhandler = sg.events.locomote.fn
    sg.events.locomote.fn = function(inst, data)
        if inst.sg:HasStateTag("busy") or inst:HasTag("busy") then
            return
        end
        local is_attacking = inst.sg:HasStateTag("attack")
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        local should_run = inst.components.locomotor:WantsToRun()

        if inst:HasTag("aquatic") then
            if not is_attacking then
                if is_moving and not should_move then
                    inst.sg:GoToState("row_stop")
                elseif not is_moving and should_move or (is_moving and should_move and is_running ~= should_run) then
                    inst.sg:GoToState("row_start")
                end
            end
        end
        _locomote_eventhandler(inst, data)
    end
end)


AddStategraphPostInit("wilson_client", function(sg)
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
