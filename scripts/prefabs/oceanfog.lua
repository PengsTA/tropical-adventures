local TEXTURE = "levels/textures/ds_fog1.tex"
local SHADER = "shaders/vfx_particle.ksh"
local COLOUR = "ta_oceanfog_colour"
local SCALE = "ta_oceanfog_scale"
local RADIUS, LIFETIME = 50, 15
local assets = { Asset("IMAGE", TEXTURE), Asset("SHADER", SHADER) }
local initialized = false

local function InitEnvelopes()
    if initialized then return end
    initialized = true
    EnvelopeManager:AddColourEnvelope(COLOUR, {
        { 0, { 1, 1, 1, 0 } }, { .1, { 1, 1, 1, .24 } },
        { .75, { 1, 1, 1, .24 } }, { 1, { 1, 1, 1, 0 } },
    })
    EnvelopeManager:AddVector2Envelope(SCALE, {
        { 0, { 6, 6 } }, { 1, { 10, 10 } },
    })
end

local function AddVisuals(inst)
    InitEnvelopes()
    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 128)
    effect:SetMaxLifetime(0, LIFETIME)
    effect:SetSpawnVectors(0, -1, 0, 1, 1, 0, 1)
    effect:SetSortOrder(0, 3)
    effect:SetLayer(0, LAYER_BACKGROUND)
    effect:SetColourEnvelope(0, COLOUR)
    effect:SetScaleEnvelope(0, SCALE)
    effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    effect:SetRadius(0, RADIUS + 10)
    local remaining = 0
    local tick_time = TheSim:GetTickTime()
    EmitterManager:AddEmitter(inst, nil, function()
        local state = TheWorld.state
        if not state.isday or state.time == nil or state.time > 2 / 16
            or ThePlayer == nil or ThePlayer:HasTag("region_interior")
            or inst:GetDistanceSqToInst(ThePlayer) > (RADIUS + PLAYER_CAMERA_SEE_DISTANCE)^2 then
            remaining = 0
            return
        end
        local x, _, z = inst.Transform:GetWorldPosition()
        remaining = remaining + 8 * tick_time
        while remaining >= 1 do
            remaining = remaining - 1
            local px, pz = (math.random() * 2 - 1) * RADIUS, (math.random() * 2 - 1) * RADIUS
            if TheWorld.Map:IsOceanTileAtPoint(x + px, 0, z + pz) then
                effect:AddParticle(0, LIFETIME * (.9 + math.random() * .1), px, .4, pz,
                    (math.random() * 2 - 1) * .01, 0, (math.random() * 2 - 1) * .01)
            end
        end
    end)
end

local function OnTimerDone(inst, data)
    -- Accept the old saved timer key, but use the English key for new timers.
    if data.name == "despawn" or data.name == "vaiembora" then
        if GetClosestInstWithTag("player", inst, 25) == nil then
            inst:Remove()
        else
            inst.components.timer:StartTimer("despawn", 10)
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    if not TheNet:IsDedicated() then AddVisuals(inst) end
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst.components.timer:StartTimer("despawn", 80 + math.random() * 80)
    return inst
end

return Prefab("oceanfog", fn, assets)
