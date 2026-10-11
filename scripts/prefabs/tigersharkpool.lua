local function InitializeEncounter(inst)
    TheWorld.components.tigersharker:RegisterHome(inst:GetPosition())
    inst:Remove()
end

local function spawnpointfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.persists = false
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- Wait for saved boss references and cooldowns before registering the point.
    inst:DoTaskInTime(0, InitializeEncounter)
    return inst
end

local function wallfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.Transform:SetEightFaced()

    inst:AddTag("blocker")
    inst:AddTag("wall_room")
    local phys = inst.entity:AddPhysics()
    phys:SetMass(0)
    phys:SetCollisionGroup(COLLISION.WORLD)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
    phys:CollidesWith(COLLISION.FLYERS)
    phys:SetCapsule(0.5, 50)
    inst:AddTag("NOCLICK")
    return inst
end

-- Old saves load the pool as a temporary marker and remove it after registration.
return Prefab("wall_invisible", wallfn),
    Prefab("tigersharkpool", spawnpointfn, nil, { "tigershark" }),
    Prefab("tigershark_spawnpoint", spawnpointfn, nil, { "tigershark" })
