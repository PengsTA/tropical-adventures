local OceanWrap = require("tools/ocean_wrap")
local TEXTURE = "levels/textures/ds_fog1.tex"
local SHADER = "shaders/vfx_particle.ksh"
local COLOUR_ENVELOPE = "ta_ocean_edgefog_colour"
local SCALE_ENVELOPE = "ta_ocean_edgefog_scale"
local LIFETIME = 5
local assets = { Asset("IMAGE", TEXTURE), Asset("SHADER", SHADER) }
local initialized = false

local function InitEnvelopes()
    if initialized then return end
    initialized = true
    EnvelopeManager:AddColourEnvelope(COLOUR_ENVELOPE, {
        { 0, { .9, .9, .9, 0 } },
        { .15, { .9, .9, .9, .85 } },
        { .75, { .9, .9, .9, .85 } },
        { 1, { .9, .9, .9, 0 } },
    })
    EnvelopeManager:AddVector2Envelope(SCALE_ENVELOPE, {
        { 0, { 6, 6 } }, { 1, { 10, 10 } },
    })
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false
    if TheNet:IsDedicated() then return inst end
    inst.entity:SetCanSleep(false)

    InitEnvelopes()
    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 256)
    effect:SetMaxLifetime(0, LIFETIME)
    effect:SetSpawnVectors(0, -1, 0, 1, 1, 0, 1)
    effect:SetSortOrder(0, 3)
    effect:SetLayer(0, LAYER_WORLD)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE)
    effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    effect:SetRadius(0, OceanWrap.FOG_VIEW_TILES * TILE_SCALE + 40)

    local remaining = 0
    local tick_time = TheSim:GetTickTime()
    function inst:SetBoundary(bounds, player)
        local x, _, z = player.Transform:GetWorldPosition()
        if self.last_x ~= nil and (x - self.last_x)^2 + (z - self.last_z)^2 > 40^2 then
            effect:ClearAllParticles(0)
            remaining = 0
        end
        self.bounds, self.last_x, self.last_z, self.player = bounds, x, z, player
        self.Transform:SetPosition(x, 0, z)
    end

    EmitterManager:AddEmitter(inst, nil, function()
        local bounds, player = inst.bounds, inst.player
        if bounds == nil or player == nil or not player:IsValid() then return end
        local x, _, z = player.Transform:GetWorldPosition()
        -- Keep world axes: parenting to a turning sailor can rotate the fog band.
        inst.Transform:SetPosition(x, 0, z)
        local view = OceanWrap.FOG_VIEW_TILES * TILE_SCALE
        local xnear = bounds.x - math.abs(x) <= view
        local znear = bounds.z - math.abs(z) <= view
        if not xnear and not znear then remaining = 0; return end
        remaining = remaining + 20 * tick_time
        while remaining >= 1 do
            remaining = remaining - 1
            local px, pz
            local depth = (-OceanWrap.FOG_OUTSIDE_TILES
                + math.random() * (OceanWrap.FOG_BAND_TILES + OceanWrap.FOG_OUTSIDE_TILES)) * TILE_SCALE
            if xnear and (not znear or math.random() < .5) then
                px = (x < 0 and -1 or 1) * (bounds.x - depth)
                pz = z + (math.random() - .5) * 80
            else
                px = x + (math.random() - .5) * 80
                pz = (z < 0 and -1 or 1) * (bounds.z - depth)
            end
            local distance = OceanWrap.Distance(bounds, px, pz)
            -- Include the outer void to hide the water's end, but never cover land.
            if distance >= -OceanWrap.FOG_OUTSIDE_TILES * TILE_SCALE
                and (distance < OceanWrap.GUARD_TILES * TILE_SCALE
                    or TheWorld.Map:IsOceanTileAtPoint(px, 0, pz)) then
                effect:AddParticle(0, LIFETIME, px - x, .4, pz - z, .03, 0, .03)
            end
        end
    end)
    return inst
end

return Prefab("edgefog", fn, assets)
