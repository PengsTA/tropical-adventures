local assets =
{
    Asset("ANIM", "anim/staff_obsidian.zip"),
    Asset("ANIM", "anim/swap_staff_obsidian.zip"),
    Asset("ANIM", "anim/staffs1.zip"),
    Asset("ANIM", "anim/swap_obsidi.zip"),
}

local prefabs =
{
    "firerain",
    "gaze_beam2",
}

local VOLCANOSTAFF_USES = 5
local VOLCANOSTAFF_FIRERAIN_COUNT = 8
local VOLCANOSTAFF_FIRERAIN_RADIUS = 5
local VOLCANOSTAFF_FIRERAIN_DELAY = 0.5
local VOLCANOSTAFF_ASH_TIMER = 10.0

---------VOLCANO STAFF------------
local function cancreateeruption(staff, caster, target, pos)
    return cancreatelight(staff, caster, target, pos)
end

local function createeruption(staff, target, pos)
    if pos == nil then
        return
    end

    local delay = 0.0
    for i = 1, VOLCANOSTAFF_FIRERAIN_COUNT, 1 do
        local x, y, z = VOLCANOSTAFF_FIRERAIN_RADIUS * UnitRand() + pos.x, pos.y,
            VOLCANOSTAFF_FIRERAIN_RADIUS * UnitRand() + pos.z
        TheWorld:DoTaskInTime(delay, function()
            local firerain = SpawnPrefab("firerain")
            firerain.Transform:SetPosition(x, y, z)
            firerain:StartStep()
        end)
        delay = delay + VOLCANOSTAFF_FIRERAIN_DELAY
    end

    staff.components.finiteuses:Use(1)

    --    TheWorld.components.volcanomanager:StartStaffEffect(VOLCANOSTAFF_ASH_TIMER)
end

---------COMMON FUNCTIONS---------

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onunequip_skinned(inst, owner)
    if inst:GetSkinBuild() ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    onunequip(inst, owner)
end

local function commonfn(colour, tags, hasskin)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("tornado_stick")
    inst.AnimState:SetBuild("staffobsidian")
    inst.AnimState:PlayAnimation("idle")

    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    if colour == "volcanostaff" then
        inst:AddComponent("reticule")
        inst.components.reticule.targetfn = function()
            return Vector3(ThePlayer.entity:LocalToWorldSpace(5, 0, 0))
        end
        inst.components.reticule.ease = true
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")



    inst:AddComponent("tradable")

    inst:AddComponent("equippable")


    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_staffobsidian", "swap_tornado_stick")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end)
    inst.components.equippable:SetOnUnequip(onunequip)


    return inst
end


---------COLOUR SPECIFIC CONSTRUCTIONS---------
local function volcanostaff()
    local inst = commonfn("volcanostaff", { "nosteal", "nopunch", "castonpoint" })

    inst:AddTag("nosteal")
    inst.fxcolour = { 223 / 255, 208 / 255, 69 / 255 }
    inst.castsound = "dontstarve/common/staffteleport"

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createeruption)
    --   inst.components.spellcaster:SetSpellTestFn(cancreateeruption)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canusefrominventory = false

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetMaxUses(VOLCANOSTAFF_USES)
    inst.components.finiteuses:SetUses(VOLCANOSTAFF_USES)
    inst:AddTag("nopunch")

    return inst
end


local function spawngaze(x, y, z, rotation, radius, host)
    local beam = SpawnPrefab("gaze_beam2")
    local angle = rotation * DEGREES
    local scale = 0.2 + 0.053 * radius
    beam.Transform:SetScale(scale, scale, scale)
    beam.Transform:SetPosition(x + radius * math.cos(angle), y, z - radius * math.sin(angle))
    beam.host = host ~= nil and host:IsValid() and host or nil
    beam.Transform:SetRotation(rotation)
end

local function getspawnlocation(inst, target)
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    return x1 + .15 * (x2 - x1), 0, z1 + .15 * (z2 - z1)
end


local function spawntornado(inst, target, pos)
    if target == nil or not target:IsValid() then
        return
    end
    local x, y, z = target.Transform:GetWorldPosition()
    local rotation = inst:GetAngleToPoint(x, y, z)
    local ox, oy, oz = inst.Transform:GetWorldPosition()
    local host = inst.components.inventoryitem:GetGrandOwner()
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/gaze_LP", "gazor")
    for i = 1, 5 do
        local radius = i * 3
        TheWorld:DoTaskInTime(i * 0.2, function()
            spawngaze(ox, oy, oz, rotation, radius, host)
        end)
    end
    inst.components.finiteuses:Use(1)
end


local function bone()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    anim:SetBank("staffs1")
    anim:SetBuild("staffs1")
    anim:PlayAnimation("bonestaff")

    inst:AddTag("nopunch")
    inst:AddTag("nosteal")
    inst:AddTag("quickcast")
    inst.fxcolour = { 223 / 255, 208 / 255, 69 / 255 }
    inst.spelltype = "SCIENCE"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.TORNADOSTAFF_USES * 3)
    inst.components.finiteuses:SetUses(TUNING.TORNADOSTAFF_USES * 3)
    inst.components.finiteuses:SetOnFinished(inst.Remove)


    --    inst:AddComponent("spellcaster")
    --    inst.components.spellcaster:SetSpellFn(creategaze)
    --    inst.components.spellcaster.canuseonpoint = true
    --    inst.components.spellcaster.canusefrominventory = false
    --	inst.components.spellcaster.quickcast = true
    --	inst.components.spellcaster.canuseonpoint_water = true	

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster.canonlyuseoncombat = true
    inst.components.spellcaster.quickcast = true
    inst.components.spellcaster:SetSpellFn(spawntornado)
    inst.components.spellcaster.castingstate = "castspell_tornado"

    MakeHauntableLaunch(inst)

    inst:AddTag("show_spoilage")

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")



    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_obsidi", "bonestaff")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("common/inventory/volcanostaff", volcanostaff, assets, prefabs),
    Prefab("common/inventory/bonestaff", bone, assets, prefabs)
