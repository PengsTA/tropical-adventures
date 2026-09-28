--[[
    毒素施加组件（攻击者侧）。
    旧的施加路径是受害者的 poisonable 组件包装 combat.onhitfn 反查攻击者；
    现在 poisonable 已移除，改为在本组件添加时挂到攻击者的 combat.onhitotherfn 上，
    只有带本组件的单位付出 hook 成本，受害方不再需要任何预注入。
]]

local Poisonous = Class(function(self, inst)
    self.inst = inst
    self.poisontestfn = nil -- nil 表示必然命中中毒
    self.dmg = nil
    self.interval = nil
    self.duration = nil

    -- 延后到预制件构造完成后挂接，保证 combat 已存在
    inst:DoTaskInTime(0, function()
        local combat = self.inst.components.combat
        if combat ~= nil then
            local oldonhitother = combat.onhitotherfn
            combat.onhitotherfn = function(attacker, target, ...)
                if oldonhitother ~= nil then
                    oldonhitother(attacker, target, ...)
                end
                self:OnAttack(target)
            end
        end
    end)
end)

function Poisonous:OnAttack(target, dmg)
    if target == nil or not target:IsValid() then return end
    if self.poisontestfn ~= nil and not self.poisontestfn(self.inst, target) then return end

    if target:HasTag("player") then
        local cabeca = target.components.inventory ~= nil and
            target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
        -- 毒气类来源（剧毒魟）由防毒面具抵挡，护甲类抵挡在 TroApplyPoison 内统一处理
        if cabeca and cabeca.prefab == "gasmaskhat" and self.inst.prefab == "stungray" then return end
        if cabeca and cabeca.prefab == "gashat" and self.inst.prefab == "stungray" then return end
    end

    TroApplyPoison(target, self.dmg, self.interval, self.duration)
end

function Poisonous:SetPoisonTestFn(fn)
    self.poisontestfn = fn
end

return Poisonous
