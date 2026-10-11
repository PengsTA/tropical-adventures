local texture = "fx/hail.tex"
local shader = "shaders/particle.ksh"
local colour_envelope_name = "tropical_hurricane_hail_colour"
local scale_envelope_name = "tropical_hurricane_hail_scale"

local assets = {
    Asset("IMAGE", texture),
    Asset("SHADER", shader),
}

local initialized = false

local function InitEnvelopes()
    if initialized or EnvelopeManager == nil then
        return
    end

    initialized = true
    EnvelopeManager:AddColourEnvelope(colour_envelope_name, {
        { 0, { 1, 1, 1, 1 } },
        { 1, { 1, 1, 1, 1 } },
    })
    EnvelopeManager:AddVector2Envelope(scale_envelope_name, {
        { 0, { .4, .4 } },
        { 1, { .4, .4 } },
    })
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddParticleEmitter()
    inst:AddTag("FX")

    InitEnvelopes()

    local emitter = inst.ParticleEmitter
    emitter:SetRenderResources(texture, shader)
    emitter:SetRotationStatus(true)
    emitter:SetMaxNumParticles(4800)
    emitter:SetMaxLifetime(2)
    emitter:SetColourEnvelope(colour_envelope_name)
    emitter:SetScaleEnvelope(scale_envelope_name)
    emitter:SetBlendMode(BLENDMODE.Premultiplied)
    emitter:SetSortOrder(3)
    emitter:SetDragCoefficient(.2)
    emitter:EnableDepthTest(true)
    emitter:SetAcceleration(0, -9.8, 0)

    local tick_time = TheSim:GetTickTime()
    local emitter_shape = CreateBoxEmitter(-10, 20, -10, 10, 20, 10)
    inst.particles_per_tick = 0
    inst.num_particles_to_emit = 0

    function inst:SetRate(rate)
        self.particles_per_tick = math.max(0, rate or 0) * 30 * tick_time
        if self.particles_per_tick <= 0 then
            self.num_particles_to_emit = 0
        end
    end

    EmitterManager:AddEmitter(inst, nil, function()
        while inst.num_particles_to_emit > 0 do
            local x, y, z = emitter_shape()
            emitter:AddRotatingParticle(
                2,
                x, y, z,
                0, -1.25 - UnitRand(), 0,
                0, 0
            )
            inst.num_particles_to_emit = inst.num_particles_to_emit - 1
        end
        inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
    end)

    return inst
end

return Prefab("hurricane_hailfx", fn, assets)
