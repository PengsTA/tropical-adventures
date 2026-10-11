local Chair = require "tools/ta_seaworthy"

return function(config)
    local plans = CONSTRUCTION_PLANS[config.name]
    local repair_amounts = {}
    for _, material in ipairs(plans) do
        repair_amounts[material.type] = material.amount
    end

    local function SetupLoot(dropper)
        local loot = {}
        for _, material in ipairs(AllRecipes[config.name].ingredients) do
            local amount = material.amount
            if dropper.inst.is_broken then
                amount = amount - (repair_amounts[material.type] or 0)
            end
            for _ = 1, math.max(0, amount) do
                table.insert(loot, material.type)
            end
        end
        dropper:SetLoot(loot)
    end

    local function RepairStatus(inst)
        local counts = {}
        for _, material in ipairs(plans) do
            table.insert(counts, inst.components.constructionsite:GetMaterialCount(material.type))
            table.insert(counts, material.amount)
        end
        return string.format(config.status, unpack(counts))
    end

    local function SetBroken(inst, broken)
        inst.is_broken = broken == true
        if inst.is_broken then
            inst:AddTag("ta_seaworthy_broken")
        else
            inst:RemoveTag("ta_seaworthy_broken")
            inst:RemoveTag("constructionsite")
            if inst.components.constructionsite then
                inst:RemoveComponent("constructionsite")
            end
            if inst.components.trader then
                inst:RemoveComponent("trader")
            end
        end
        inst.AnimState:PlayAnimation(inst.is_broken and config.broken_anim or "idle_on", true)
        inst.components.ta_seaworthy_traveler:SetBroken(inst.is_broken)
    end

    local function Upgrade(inst, doer)
        -- Refund materials saved under the previous repair plan before removing it.
        local site = inst.components.constructionsite
        for prefab, material in pairs(site.materials) do
            if repair_amounts[prefab] == nil then
                local amount = site:RemoveMaterial(prefab, material.amount)
                for _ = 1, amount do inst.components.lootdropper:SpawnLootPrefab(prefab) end
            end
        end
        SetBroken(inst, false)
        Chair.PlayActivation(inst)
        inst.components.talker:Say(config.repaired)
        if doer and not inst.components.writeable:IsWritten() then
            inst.components.writeable:BeginWriting(doer)
        end
    end

    local function OnConstructed(inst, doer)
        if inst.components.constructionsite:IsComplete() then
            Upgrade(inst, doer)
        end
    end

    local function SetupRepair(inst)
        inst:AddComponent("constructionsite")
        inst.components.constructionsite:SetConstructionPrefab("construction_container")
        inst.components.constructionsite:SetOnConstructedFn(OnConstructed)
        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(function(_, item, giver)
            if not inst.is_broken or inst.components.constructionsite:HasBuilder() then
                return false
            end
            for _, material in ipairs(plans) do
                if material.type == item.prefab then
                    return inst.components.constructionsite:GetMaterialCount(item.prefab) < material.amount
                end
            end
            if giver and giver.components.talker then
                giver.components.talker:Say(config.wrong_item)
            end
            return false
        end)
        inst.components.trader.onaccept = function(_, giver, item)
            inst.components.constructionsite:AddMaterial(item.prefab, 1)
            inst.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
            if inst.components.constructionsite:IsComplete() then
                Upgrade(inst, giver)
            elseif giver and giver.components.talker then
                giver.components.talker:Say(config.progress .. RepairStatus(inst))
            end
        end
    end

    local function OnPreLoad(inst, data)
        if data and data.is_broken ~= nil then
            if data.is_broken and not inst.components.constructionsite then
                SetupRepair(inst)
            end
            SetBroken(inst, data.is_broken)
        end
    end

    local function CommonFn(broken)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()
        MakeObstaclePhysics(inst, 1)
        inst.MiniMapEntity:SetIcon(config.icon)
        inst.AnimState:SetBank(config.bank)
        inst.AnimState:SetBuild(config.build)
        inst.is_broken = broken
        inst.AnimState:PlayAnimation(broken and config.broken_anim or "idle_on", true)
        inst:AddTag("structure")
        inst:AddTag("antlion_sinkhole_blocker")
        inst:AddTag("ta_seaworthy_chair")
        if broken then
            inst:AddTag("ta_seaworthy_broken")
            inst:AddTag("constructionsite")
            inst:AddTag("trader")
        end
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.descriptionfn = function()
            return inst.is_broken and (config.broken_description .. RepairStatus(inst)) or config.description
        end
        inst:AddComponent("talker")
        inst.components.talker.fontsize = 28
        inst.components.talker.font = TALKINGFONT
        inst.components.talker.colour = config.colour
        inst.components.talker.offset = Vector3(0, -300, 0)
        inst:AddComponent("writeable")
        inst.components.writeable:SetAutomaticDescriptionEnabled(false)
        inst.components.writeable:SetOnWrittenFn(Chair.NotifyChanged)
        inst:AddComponent("lootdropper")
        inst.components.lootdropper.droprecipeloot = false
        inst.components.lootdropper:SetLootSetupFn(SetupLoot)
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(function()
            if inst.components.constructionsite then
                inst.components.constructionsite:ForceStopConstruction()
                inst.components.constructionsite:DropAllMaterials()
            end
            inst.components.lootdropper:DropLoot()
            local fx = SpawnPrefab("collapse_small")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
            inst:Remove()
        end)
        inst.components.workable:SetOnWorkCallback(Chair.PlayActivation)
        inst:AddComponent("ta_seaworthy_traveler")
        inst.components.ta_seaworthy_traveler:SetBroken(broken)
        if broken then SetupRepair(inst) end
        inst.OnSave = function(_, data) data.is_broken = inst.is_broken end
        inst.OnPreLoad = OnPreLoad
        inst:ListenForEvent("onbuilt", function(_, data)
            Chair.PlayActivation(inst)
            Chair.NotifyChanged()
            if data and data.builder and not inst.components.writeable:IsWritten() then
                inst.components.writeable:BeginWriting(data.builder)
            end
        end)
        return inst
    end

    return function() return CommonFn(false) end, function() return CommonFn(true) end
end
