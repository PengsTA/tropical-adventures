local assets = { Asset("ANIM", "anim/pig_ruins_well.zip"), }

local currency = {
    oinc = 1,
    oinc10 = 10,
    oinc100 = 100,
    goldnugget = 20,
    dubloon = 5,
}

local function CurrencyTest(inst, item) return item and currency[item.prefab] ~= nil end

local function FountainOnAccept(inst, giver, item)
    local value = item and currency[item.prefab] or 0

    inst.AnimState:PlayAnimation("splash")
    inst.AnimState:PushAnimation("idle_full", true)

    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")

    if math.random() * 25 < value then
        inst:DoTaskInTime(1, function()
            TroRemovePoison(giver)
            if giver.components.health and giver.components.health:GetPercent() < 1 then
                giver.components.health:DoDelta(value * 5, false, inst.prefab)
                giver:PushEvent("celebrate")
            end
        end)
    end
end

local function EndsOnAccept(inst, giver, item)
    if item == nil then return end
    inst.AnimState:PlayAnimation("vortex_splash")
    inst.AnimState:PlayAnimation("vortex_empty")
    inst.AnimState:PushAnimation("vortex_idle_full", true)
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")

    local gem = 0
    if item:HasTag("gem") and item.prefab ~= "purplegem" then
        gem = math.random() > .5 and 1 or gem
    elseif item.prefab == "nightmarefuel" then
        gem = math.random() > .5 and 3 or 1
    else
        gem = math.random() > .99 and 1 or gem
    end

    if gem <= 0 then
        inst:DoTaskInTime(1, function()
            local mob = SpawnAt(math.random() < .6 and "crawlingnightmare" or "nightmarebeak", inst)
            if mob ~= nil and mob.components.combat ~= nil then
                mob.components.combat:SuggestTarget(giver)
            end
        end)
    else
        inst.AnimState:PlayAnimation("vortex_splash")
        inst.AnimState:PushAnimation("vortex_idle_full", true)
        inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
        for _ = 1, gem do
            LaunchAt(SpawnPrefab("purplegem"), inst, nil, 2, 3, 1)
        end
    end
end

local function fountain()
    local inst = CreateEntity()
    inst.entity:AddNetwork()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    anim:SetBuild("pig_ruins_well")
    anim:SetBank("pig_ruins_well")
    anim:PlayAnimation("idle_full", true)
    --        anim:SetOrientation(ANIM_ORIENTATION.RotatingBillboard)

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("pig_ruins_well.png")

    inst:AddTag("blocker")
    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCylinder(2, 4.0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    inst:AddTag("watersource")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(CurrencyTest)
    inst.components.trader.onaccept = FountainOnAccept

    inst:AddComponent("inspectable")

    anim:SetTime(math.random() * anim:GetCurrentAnimationLength())

    return inst
end

local function endswell()
    local inst = CreateEntity()
    inst.entity:AddNetwork()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    anim:SetBuild("pig_ruins_well")
    anim:SetBank("pig_ruins_well")
    anim:PlayAnimation("vortex_idle_full", true)

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("pig_ruins_well_vortex.png")

    inst:AddTag("blocker")
    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCylinder(2, 4.0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("trader")
    inst.components.trader.onaccept = EndsOnAccept

    inst:AddComponent("inspectable")

    anim:SetTime(math.random() * anim:GetCurrentAnimationLength())

    return inst
end

return Prefab("deco_ruins_fountain", fountain, assets),
    Prefab("deco_ruins_endswell", endswell, assets)
