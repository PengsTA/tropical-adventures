require("stategraphs/commonstates")

local function BeginIdle(inst)
    inst.sg:GoToState("idle")
end

local states = {
    State {
        name = "rise",
        tags = { "rising" },

        onenter = function(inst)
            inst.waveactive = false
            inst.AnimState:PlayAnimation("appear")
        end,

        timeline = {
            TimeEvent(5 * FRAMES, function(inst)
                if inst.soundrise ~= nil then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/rogue_waves/" .. inst.soundrise)
                end
                if inst.soundloop ~= nil then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/rogue_waves/" .. inst.soundloop, inst.soundloop)
                end
            end),
        },

        events = {
            EventHandler("animover", BeginIdle),
        },
    },

    State {
        name = "instant_rise",
        tags = { "rising" },

        onenter = function(inst)
            inst.waveactive = true
            inst.AnimState:PlayAnimation("appear")
            inst.AnimState:SetFrame(10)
        end,

        events = {
            EventHandler("animover", BeginIdle),
        },
    },

    State {
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            inst.waveactive = true
            inst:activate_collision()
            inst.AnimState:PlayAnimation("idle", false)
            inst.sg:SetTimeout(inst.idle_time or 5)
        end,

        ontimeout = function(inst)
            -- Finish the crest cycle before switching to its authored end pose.
            inst.sg.statemem.waitingtolower = true
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.waitingtolower then
                    inst.sg:GoToState("lower")
                else
                    inst.AnimState:PlayAnimation("idle", false)
                end
            end),
        },
    },

    State {
        name = "lower",
        tags = { "lowering" },

        onenter = function(inst)
            inst.waveactive = false
            inst.Physics:ClearCollisionMask()
            inst.AnimState:Resume()
            inst.AnimState:PlayAnimation("disappear")
            if inst.soundloop ~= nil then
                inst.SoundEmitter:KillSound(inst.soundloop)
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },
}

return StateGraph("wave", states, {}, "rise")
