local assets = {
    Asset("ANIM", "anim/volcano.zip"),
    Asset("MINIMAP_IMAGE", "volcano"),
    Asset("MINIMAP_IMAGE", "volcano_active"),
}

local function SetActivity(inst, active)
    if active then
        inst:AddTag("ativo")
        inst.MiniMapEntity:SetIcon("volcano_active.tex")
        if not inst.sg:HasStateTag("atacando") then
            inst.sg:GoToState("active")
        end
    else
        inst:RemoveTag("ativo")
        inst.MiniMapEntity:SetIcon("volcano.tex")
        if not inst.sg:HasStateTag("atacando") then
            inst.sg:GoToState("dormant")
        end
    end
end

local function OnWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano/volcano_external_amb", "volcano")
    inst.SoundEmitter:SetParameter("volcano", "volcano_state", inst:HasTag("ativo") and 1 or 0)
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("volcano")
end

local function SpawnEntrance(inst)
    if inst.entrada == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local entrance = SpawnPrefab("vulcano_entrance")
        if entrance ~= nil then
            entrance.Transform:SetPosition(x + 1.5, y, z + 1.5)
        end
        inst.entrada = true
    end
end

local function OnSave(inst, data)
    data.entrada = inst.entrada
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst.entrada = data.entrada
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(0.5, 0.5, 0.5)
    inst.entity:AddLight()
    inst.Light:SetFalloff(0.4)
    inst.Light:SetIntensity(0.7)
    inst.Light:SetRadius(10)
    inst.Light:SetColour(249 / 255, 130 / 255, 117 / 255)
    inst.Light:Enable(true)

    inst.AnimState:SetBank("volcano")
    inst.AnimState:SetBuild("volcano")
    inst.AnimState:PlayAnimation("dormant_idle", true)
    inst.MiniMapEntity:SetIcon("volcano.tex")
    inst:AddTag("FX")
    inst:AddTag("vulcaomigrador")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:SetDeployExtraSpacing(12)
    inst:SetStateGraph("SGvolcano")
    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("volcanoactivechanged", function(_, data)
        SetActivity(inst, data.active)
    end, TheWorld)
    inst:ListenForEvent("volcanowarning", function()
        if inst:HasTag("ativo") then
            inst.sg:GoToState("rumble")
        end
    end, TheWorld)
    inst:ListenForEvent("volcanoeruptionbegin", function()
        inst.sg:GoToState("erupt")
    end, TheWorld)
    inst:ListenForEvent("volcanoeruptionend", function()
        SetActivity(inst, TheWorld.components.volcanomanager ~= nil and TheWorld.components.volcanomanager:IsActive())
    end, TheWorld)

    inst:DoTaskInTime(0, function()
        local manager = TheWorld.components.volcanomanager
        SetActivity(inst, manager ~= nil and manager:IsActive())
        SpawnEntrance(inst)
    end)

    return inst
end

return Prefab("volcano", fn, assets)
