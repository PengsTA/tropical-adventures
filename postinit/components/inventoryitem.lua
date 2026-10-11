AddComponentPostInit("inventoryitem", function(self)
    local function SyncOwner(self, owner)
        local props = rawget(self, "_")
        if props ~= nil and props.owner ~= nil then
            props.owner[1] = owner
        else
            rawset(self, "owner", owner)
        end

        if self.inst ~= nil and self.inst.replica ~= nil and self.inst.replica.inventoryitem ~= nil then
            self.inst.replica.inventoryitem:SetOwner(owner)
        end
    end

    -- Keep the component "owner" field writable on items whose replica is gone.
    -- This avoids crashes when clearing owner for invalid/inlimbo items.
    if type(addsetter) == "function" then
        local props = rawget(self, "_")
        if props ~= nil and props.owner ~= nil then
            addsetter(self, "owner", function(owner_inst, owner)
                local owner_props = rawget(owner_inst, "_")
                if owner_props ~= nil and owner_props.owner ~= nil then
                    owner_props.owner[1] = owner
                end

                local inst = owner_inst.inst
                if inst ~= nil and inst.replica ~= nil and inst.replica.inventoryitem ~= nil then
                    inst.replica.inventoryitem:SetOwner(owner)
                end
            end)
        end
    end

    self.inst:AddTag("isinventoryitem")

    self.inst:ListenForEvent("onremove", function()
        if self.inst.onshelf then
            local shelf = self.inst.onshelf
            local item = shelf.components.shelfer:GetGift()
            -- doing this check to save players from a bug that was fixed, but some items may still suffer from it
            if item and item.GUID == self.inst.GUID then
                shelf.components.shelfer:GiveGift()
            end
        end
    end)

    function self:OnPickup(pickupguy, src_pos)
        -- not only the player can have inventory!

        self:SetLanded(false, false)

        if self.isnew and self.inst.prefab and pickupguy:HasTag("player") then
            ProfileStatsAdd("collect_" .. self.inst.prefab)
            self.isnew = false
        end

        if self.inst.components.burnable and self.inst.components.burnable:IsSmoldering() then
            self.inst.components.burnable:StopSmoldering()
            if pickupguy.components.health ~= nil then
                pickupguy.components.health:DoFireDamage(TUNING.SMOTHER_DAMAGE, nil, true)
                pickupguy:PushEvent("burnt")
            end
        end

        if self.inst.bookshelf then
            self:TakeOffShelf()
        end

        self.inst:PushEvent("onpickup", { owner = pickupguy })
        return self.onpickupfn and self.onpickupfn(self.inst, pickupguy, src_pos)
    end

    function self:SetOwner(owner)
        SyncOwner(self, owner)
    end

    function self:ClearOwner()
        SyncOwner(self, nil)
    end

    function self:TakeOffShelf()
        local shelf_slot = SpawnPrefab("shelf_slot")
        shelf_slot.components.inventoryitem:PutOnShelf(self.inst.bookshelf, self.inst.bookshelfslot)
        shelf_slot.components.shelfer:SetShelf(self.inst.bookshelf, self.inst.bookshelfslot)

        self.inst:RemoveTag("bookshelfed")
        self.inst.bookshelfslot = nil
        self.inst.bookshelf = nil
        self.inst.follower:FollowSymbol(0, "dumb", 0, 0, 0)
        if self.inst.Physics then
            self.inst.Physics:SetActive(true)
        end
    end

    function self:PutOnShelf(shelf, slot)
        self.inst:AddTag("bookshelfed")
        self.inst.bookshelfslot = slot
        self.inst.bookshelf = shelf
        if self.inst.Physics then
            self.inst.Physics:SetActive(false)
        end
        local follower = self.inst.entity:AddFollower()
        follower:FollowSymbol(shelf.GUID, slot, 10, 0, 0.6)
        self.inst.follower = follower
    end

    function self:OnSave()
        local data = {}
        local refs = {}

        if self.inst:HasTag("bookshelfed") and self.inst.bookshelf then
            data.bookshelfGUID = self.inst.bookshelf.GUID
            data.bookshelfslot = self.inst.bookshelfslot
            table.insert(refs, self.inst.bookshelf.GUID)
        end

        if self.canbepickedup then
            data.canbepickedup = self.canbepickedup
        end

        if self.inst.onshelf then
            data.onshelf = self.inst.onshelf.GUID
            table.insert(refs, self.inst.onshelf.GUID)
        end

        return data, refs
    end

    function self:OnLoad(data)
        if data.canbepickedup then
            self.canbepickedup = data.canbepickedup
        end
    end

    function self:LoadPostPass(newents, data)
        if data and data.bookshelfGUID then
            if newents[data.bookshelfGUID] then
                local bookshelf = newents[data.bookshelfGUID].entity
                self:PutOnShelf(bookshelf, data.bookshelfslot)
            end
        end
        if data and data.onshelf then
            if newents[data.onshelf] and newents[data.onshelf].entity:IsValid() then
                self.inst.onshelf = newents[data.onshelf].entity
                -- fixup for items that misremembered they were on a shelf.
                self.inst:DoTaskInTime(1, function()
                    if self.inst.onshelf then
                        local shelfitem = self.inst.onshelf and self.inst.onshelf.components and
                            self.inst.onshelf.components.shelfer and self.inst.onshelf.components.shelfer:GetGift()
                        if self.inst ~= shelfitem then
                            -- we thought we were on a shelf. Alas, we were not
                            self.inst.onshelf = nil
                        end
                    end
                end)
            end
        end
    end
end)
