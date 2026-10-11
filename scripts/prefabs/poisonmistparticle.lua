local assets =
{
    Asset("ANIM", "anim/mist_fx.zip"),
}


local function ApplyPoisonMist(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, 5, nil, { "INLIMBO", "playerghost" }, { "player", "insect" })
    for _, target in ipairs(targets) do
        local health = target.components.health
        if health ~= nil and not health:IsDead() then
            if target:HasTag("player") then
                local inventory = target.components.inventory
                local hat = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if hat == nil or (hat.prefab ~= "gasmaskhat" and hat.prefab ~= "gashat") then
                    TroApplyPoison(target, -2, 1, 2)
                end
            elseif target:HasTag("insect") and not health:IsInvincible() then
                health:Kill()
            end
        end
    end
end

local function OnEntityWake(inst)
    if inst.updatetask then
        inst.updatetask:Cancel()
        inst.updatetask = nil
    end
    inst.updatetask = inst:DoPeriodicTask(1, ApplyPoisonMist)
end

local function OnEntitySleep(inst)
    if inst.updatetask then
        inst.updatetask:Cancel()
        inst.updatetask = nil
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    anim:SetBuild("mist_fx")
    anim:SetBank("mist_fx")
    anim:PlayAnimation("idle", true)

    local cloudScale = (math.random() * 1.5) + 1.5
    inst.Transform:SetScale(cloudScale, cloudScale, cloudScale)
    inst.AnimState:SetMultColour(50 / 255, 205 / 255, 50 / 255, 1)
    inst:AddTag("NOCLICK")
    anim:SetTime(math.random() * anim:GetCurrentAnimationLength())

    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    inst.OnRemoveEntity = OnEntitySleep

    return inst
end

return Prefab("common/fx/poisonmist", fn, assets)
