local assets =
{
    Asset("ANIM", "anim/pigkingstaff.zip"),
    Asset("ANIM", "anim/swap_pigkingstaff.zip"),
}

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", -- Symbol to override.
        "swap_pigkingstaff",                      -- Animation bank we will use to overwrite the symbol.
        "swap_pigkingstaff")                      -- Symbol to overwrite it with.
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function LightningStrike(Target, n)
    if n == 0 then
        return
    end

    local pos = Target:GetPosition()

    TheWorld:PushEvent("ms_sendlightningstrike", pos)
    if math.random() < 0.1 then
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end

    Target:DoTaskInTime(1,
        function()
            LightningStrike(Target, (n or 5) - 1)
        end)
end

local function MeteorStrike(Target, n)
    if n == 0 then
        return
    end
    SpawnPrefab("shadowmeteor").Transform:SetPosition(Target:GetPosition():Get())

    Target:DoTaskInTime(1,
        function()
            MeteorStrike(Target, (n or 5) - 1)
        end)
end

local function Ignite(Target)
    if Target.components.burnable then
        Target.components.burnable:Ignite(true)
    end
end

local function Horror(Target)
    SpawnPrefab("shadowmeteor").Transform:SetPosition(Target:GetPosition():Get())
end

local function convert_rocks(inst, replacement)
    if inst:IsValid() and replacement ~= nil then
        local goop = SpawnPrefab(replacement)
        if goop ~= nil then
            if goop.components.stackable ~= nil and inst.components.stackable ~= nil then
                goop.components.stackable:SetStackSize(inst.components.stackable.stacksize)
            end
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            local holder = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
            if holder ~= nil then
                local slot = holder:GetItemSlot(inst)
                inst:Remove()
                holder:GiveItem(goop, slot)
            else
                local x, y, z = inst.Transform:GetWorldPosition()
                inst:Remove()
                goop.Transform:SetPosition(x, y, z)
            end
        end
    end
end

local function UseStaff(inst, Target, pos)
    local caster = inst.components.inventoryitem.owner
    if inst.prefab == "pigking" then
        Target = inst
    end

    if Target and (Target.prefab == "flint" or Target.prefab == "rocks") then
        convert_rocks(Target, "goldnugget")
        inst.components.finiteuses:Use(1)
        return true
    end

    if Target and Target:HasTag("boulder") then
        convert_rocks(Target, "rock2")
        inst.components.finiteuses:Use(1)
        return true
    end

    if Target then
        local hitfn = GetRandomItem({ LightningStrike, MeteorStrike, Ignite })
        hitfn(Target)
        if caster ~= nil and Target:IsValid() then
            Target:PushEvent("attacked", { attacker = caster, damage = 0, weapon = inst })
        end
        inst.components.finiteuses:Use(1)
    end

    if Target == nil then
        local prefab = GetRandomItem({ "wildbore" }) --, "acorn_sapling", "acorn_sapling","acorn_sapling","birchnutdrake", "acorn"})
        local nut = SpawnPrefab(prefab)
        if nut == nil then return false end
        local cloud = SpawnPrefab("poopcloud")
        nut.Transform:SetPosition(pos:Get())
        if cloud ~= nil then cloud.Transform:SetPosition(pos:Get()) end
        if caster ~= nil and nut.components.follower:GetLeader() == nil then
            local food = SpawnPrefab("meat")
            if food ~= nil and not nut.components.trader:AcceptGift(caster, food) then
                food:Remove()
            end
        end
        inst.components.finiteuses:Use(1)
    end

    return true
end

local function CanCast(doer, target, pos)
    return true

    --[[
    if target == nil then
        return true
    end

    if target.prefab == "pigking" then
        return false
    end

    if target:HasTag("boulder") then
        return true
    end

    if target.prefab == "flint" or target.prefab == "rocks" then
        return true
    end]]
end

local function init()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("pigkingstaff")
    inst.AnimState:SetBuild("pigkingstaff")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("staff")

    if TheSim:GetGameID() == "DST" then
        inst.entity:AddNetwork()
        if not TheWorld.ismastersim then
            return inst
        end
        inst.entity:SetPristine()
        --MakeHauntableLaunch(inst)
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(30)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst.components.inventoryitem.imagename = "pigkingstaff"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst:AddTag("nopunch")

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(UseStaff)
    inst.components.spellcaster.canuseontargets = true
    --inst.components.spellcaster.canonlyuseonlocomotorspvp = true
    inst.components.spellcaster.canusefrominventory = false
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.CanCast = CanCast

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(20)
    inst.components.finiteuses:SetUses(20)
    inst.components.finiteuses:SetOnFinished(onfinished)

    return inst
end

return Prefab("common/inventory/pigkingstaff", init, assets)
