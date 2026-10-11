local wilson_health = 150
ARMOR_OXHAT = wilson_health * 4
ARMOR_OXHAT_ABSORPTION = .85


local function generic_perish(inst)
    inst:Remove()
end

local function MakeHat(name, bankparam, prefabnameparam)
    local fns = {}
    local fname = "hat_" .. name
    local symname = bankparam or name .. "hat"
    local prefabname = prefabnameparam or symname

    local function onequip(inst, owner, symbol_override)
        local skin_build = inst:GetSkinBuild()
        local symbol_override = symbol_override and "swap_hat" or "swap_hat"

        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, symbol_override, inst.GUID,
                fname)
        else
            owner.AnimState:OverrideSymbol("swap_hat", fname, symbol_override)
        end
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
        end

        if not owner:HasTag("equipmentmodel") then
            if inst.components.fueled ~= nil then
                inst.components.fueled:StartConsuming()
            end
        end
    end

    local function onunequip(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end

        owner.AnimState:ClearOverrideSymbol("swap_hat")
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
        end

        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end
    end

    local function opentop_onequip(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, fname)
        else
            owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
        end

        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
        end

        if not owner:HasTag("equipmentmodel") then
            if inst.components.fueled ~= nil then
                inst.components.fueled:StartConsuming()
            end
        end
    end

    local function simple(custom_init)
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst.AnimState:SetBank(symname)
        inst.AnimState:SetBuild(fname)
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("hat")
        inst:AddTag("aquatic")

        if custom_init ~= nil then
            custom_init(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")


        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD

        inst.components.equippable:SetOnEquip(onequip)

        inst.components.equippable:SetOnUnequip(onunequip)

        MakeHauntableLaunch(inst)

        return inst
    end

    function fns.pirate()
        local inst = simple()

        inst.AnimState:SetBank("piratehat")
        inst.AnimState:SetBuild("hat_pirate")
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("waterproofer")

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.TOPHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(0.3)

        return inst
    end

    function fns.captain()
        local inst = simple()

        inst.AnimState:SetBank("captainhat")
        inst.AnimState:SetBuild("hat_captain")
        inst.AnimState:PlayAnimation("anim")

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.TOPHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

        return inst
    end

    function fns.ox()
        local inst = simple()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALLMED)

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(ARMOR_OXHAT, ARMOR_OXHAT_ABSORPTION)

        -- TODO: inst.components.equippable.poisonblocker = true

        return inst
    end

    function fns.snakeskin()
        local inst = simple()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.RAINHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_LARGE)

        inst.components.equippable.insulated = true

        return inst
    end

    -- local function double_umbrella_updatesound(inst)
    --     local soundShouldPlay = GetSeasonManager():IsRaining() and inst.components.equippable:IsEquipped()
    --     if soundShouldPlay ~= inst.SoundEmitter:PlayingSound("umbrellarainsound") then
    --         if soundShouldPlay then
    --             inst.SoundEmitter:PlaySound("dontstarve/rain/rain_on_umbrella", "umbrellarainsound")
    --         else
    --             inst.SoundEmitter:KillSound("umbrellarainsound")
    --         end
    --     end
    -- end

    local function double_umbrella_onequip(inst, owner)
        opentop_onequip(inst, owner)

        -- double_umbrella_updatesound(inst)

        owner.DynamicShadow:SetSize(2.2, 1.4)
    end

    local function double_umbrella_onunequip(inst, owner)
        onunequip(inst, owner)
        -- double_umbrella_updatesound(inst)

        owner.DynamicShadow:SetSize(1.3, 0.6)
    end

    local function double_umbrella_perish(inst)
        inst.SoundEmitter:KillSound("umbrellarainsound")
        if inst.components.inventoryitem and inst.components.inventoryitem.owner then
            inst.components.inventoryitem.owner.DynamicShadow:SetSize(1.3, 0.6)
        end
        inst:Remove()
    end

    function fns.double_umbrella()
        local inst = simple()
        inst.AnimState:SetBank("hat_double_umbrella")
        inst.AnimState:SetBuild("hat_double_umbrella")
        inst.AnimState:PlayAnimation("anim")
        inst.entity:AddSoundEmitter()

        inst:AddTag("waterproofer")
        inst:AddTag("umbrella")


        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(12 * 60 * 8) --TUNING.EYEBRELLA_PERISHTIME)
        inst.components.fueled:SetDepletedFn(double_umbrella_perish)

        inst.components.equippable:SetOnEquip(double_umbrella_onequip)
        inst.components.equippable:SetOnUnequip(double_umbrella_onunequip)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
        inst.components.insulator:SetSummer()

        inst.components.equippable.insulated = true

        return inst
    end

    function fns.gas()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst.AnimState:SetBank("gashat")
        inst.AnimState:SetBuild("hat_gas")
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("hat")

        -- inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")


        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD

        inst.components.equippable:SetOnEquip(onequip)

        inst.components.equippable:SetOnUnequip(onunequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(2400)
        inst.components.fueled:SetDepletedFn(generic_perish)

        MakeHauntableLaunch(inst)

        return inst
    end

    function fns.aerodynamic()
        local inst = simple()

        inst.AnimState:SetBank("hat_aerodynamic")
        inst.AnimState:SetBuild("hat_aerodynamic")
        inst.AnimState:PlayAnimation("anim")
        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.walkspeedmult = 1.25

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(48 * 30)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst:AddComponent("windproofer")
        inst.components.windproofer:SetEffectiveness(TUNING.WINDPROOFNESS_MED or 0.5)

        return inst
    end


    local function bunny_equip(inst, owner)
        onequip(inst, owner)
        owner:AddTag("bunnyfriend")
    end

    local function bunny_unequip(inst, owner)
        onunequip(inst, owner)
        owner:RemoveTag("bunnyfriend")
    end

    local function bunny_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    function fns.bunny()
        local inst = simple(bunny_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable:SetOnEquip(bunny_equip)
        inst.components.equippable:SetOnUnequip(bunny_unequip)

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.BEEFALOHAT_PERISHTIME * 0.75) -- TMP TODO
        inst.components.fueled:SetDepletedFn(generic_perish)

        return inst
    end

    local function brainjelly_onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAT_HAIR")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        owner:AddTag("brainjelly")

        inst._onbuilt = function(owner) inst.components.finiteuses:Use() end
        inst:ListenForEvent("builditem", inst._onbuilt, owner)
        inst:ListenForEvent("buildstructure", inst._onbuilt, owner)
    end

    local function brainjelly_onunequip(inst, owner)
        onunequip(inst, owner)
        owner:RemoveTag("brainjelly")

        if inst._onbuilt then
            inst:RemoveEventCallback("builditem", inst._onbuilt, owner)
            inst:RemoveEventCallback("buildstructure", inst._onbuilt, owner)
            inst._onbuilt = nil
        end
    end

    function fns.brainjelly()
        local inst = simple()

        inst:AddTag("brainjelly")

        if not TheWorld.ismastersim then
            return inst
        end

        inst._onbuilt = nil

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(4)
        inst.components.finiteuses:SetPercent(1)
        inst.components.finiteuses.onfinished = inst.Remove

        inst.components.equippable:SetOnEquip(brainjelly_onequip)
        inst.components.equippable:SetOnUnequip(brainjelly_onunequip)

        return inst
    end

    local SHARK_TEETHHAT_DAPPERNESS = 0
    local SHARK_TEETHHAT_DAPPERNESS_OCEAN = TUNING.DAPPERNESS_LARGE

    local function shark_teethhat_calculation(inst, target)
        local is_over_ground = TheWorld.Map:IsVisualGroundAtPoint(target:GetPosition():Get())
        return (is_over_ground and SHARK_TEETHHAT_DAPPERNESS) or SHARK_TEETHHAT_DAPPERNESS_OCEAN
    end

    function fns.shark_teeth()
        local inst = simple()

        inst.AnimState:SetBank("hat_shark_teeth")
        inst.AnimState:SetBuild("hat_shark_teeth")
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("regal")

        -- inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.SHARK_HAT_PERISHTIME)
        -- inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
        inst.components.fueled:SetDepletedFn(generic_perish)

        inst.components.equippable:SetDappernessFn(shark_teethhat_calculation)

        inst.components.equippable:SetOnEquip(opentop_onequip)

        return inst
    end

    local assets = { Asset("ANIM", "anim/" .. fname .. ".zip") }
    local prefabs = nil

    return Prefab(prefabname, fns[name], assets, prefabs)
end

return MakeHat("pirate"),
       MakeHat("captain"),
       MakeHat("double_umbrella"),
       MakeHat("snakeskin"),
       MakeHat("ox"),
       MakeHat("aerodynamic"),
       MakeHat("brainjelly"),
       MakeHat("gas"),
       MakeHat("shark_teeth")
--    MakeHat("bunny", "beefalohat", "bunnyhat")
