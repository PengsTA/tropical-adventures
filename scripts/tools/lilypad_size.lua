local M = {}

local SIZES = {
    { name = "small", radius = 2 },
    { name = "med", radius = 3 },
    { name = "big", radius = 4 },
}
local SIZE_IDS = { small = 1, med = 2, big = 3 }
local COLLISION_MESHES = {}

local function GetCollisionMesh(radius)
    if COLLISION_MESHES[radius] == nil then
        local triangles = {}
        -- Match DST's inward-facing boat boundary, at the pad's own radius.
        for segment = 0, 19 do
            local angle0 = (segment - .5) * math.pi / 10
            local angle1 = (segment + .5) * math.pi / 10
            local x0, z0 = math.cos(angle0) * radius, math.sin(angle0) * radius
            local x1, z1 = math.cos(angle1) * radius, math.sin(angle1) * radius
            local wall = { x0, 0, z0, x0, 3, z0, x1, 0, z1,
                x1, 0, z1, x0, 3, z0, x1, 3, z1 }
            for _, value in ipairs(wall) do
                triangles[#triangles + 1] = value
            end
        end
        COLLISION_MESHES[radius] = triangles
    end
    return COLLISION_MESHES[radius]
end

local function ResizeCollision(collision, radius)
    if collision ~= nil and collision:IsValid() then
        collision.Physics:SetTriangleMesh(GetCollisionMesh(radius))
    end
end

function M.ResizeItemCollision(inst)
    ResizeCollision(inst.boat_item_collision, inst:GetPhysicsRadius() + .2)
end

local function ApplySize(inst)
    local size = SIZES[inst._lilypadsize:value()] or SIZES[3]
    inst.size = size.name
    inst.Physics:SetCylinder(size.radius, 3)
    local platform = inst.components.walkableplatform
    platform.platform_radius = size.radius
    inst.components.boatringdata:SetRadius(size.radius)
    if inst.components.hull ~= nil then
        inst.components.hull:SetRadius(size.radius)
    end
    local trail = inst.components.boattrail
    if trail ~= nil then
        trail.radius = size.radius * .75
        trail.scale_x, trail.scale_z = size.radius / 4, size.radius / 4
    end
    ResizeCollision(platform.player_collision, size.radius + .1)
    M.ResizeItemCollision(inst)
end

function M.Configure(inst)
    inst._lilypadsize = net_tinybyte(inst.GUID, "lilypad.size", "lilypadsizedirty")
    inst._lilypadsize:set(3)
    if TheWorld.ismastersim then
        -- Keep Hamlet's original small/medium/large selection probabilities.
        local size = math.random() < .66 and (math.random() < .33 and 2 or 3) or 1
        inst._lilypadsize:set(size)
        local platform = inst.components.walkableplatform
        local SpawnPlayerCollision = platform.SpawnPlayerCollision
        platform.SpawnPlayerCollision = function(self, ...)
            SpawnPlayerCollision(self, ...)
            ResizeCollision(self.player_collision, inst:GetPhysicsRadius() + .1)
        end
    else
        inst:ListenForEvent("lilypadsizedirty", ApplySize)
    end
    ApplySize(inst)
end

function M.ConfigureSaveLoad(inst)
    local OnSave, OnPreLoad = inst.OnSave, inst.OnPreLoad
    inst.OnSave = function(inst, data)
        data.size = inst.size
        if OnSave ~= nil then
            return OnSave(inst, data)
        end
    end
    inst.OnPreLoad = function(inst, data)
        if OnPreLoad ~= nil then
            OnPreLoad(inst, data)
        end
        -- Worldgen records keep the size selected by the prefab constructor.
        -- Legacy saved platforms keep their large radius when size is absent.
        if data ~= nil and (data.size ~= nil or data.walkableplatform ~= nil) then
            inst._lilypadsize:set(SIZE_IDS[data.size] or 3)
        end
        ApplySize(inst)
        inst.AnimState:PlayAnimation(inst.size .. "_idle", true)
    end
end

return M
