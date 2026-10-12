return Class(function(self, inst)
    local _world = TheWorld
    local _aporkalypse = _world.components.aporkalypse
    local _begindate = _aporkalypse.begin_date
    self.inst = inst

    function self:OnSaveProxyData()
        return { from = inst.worldprefab, begin_date = _begindate }
    end

    local function InitProxy()
    end

    function self:OnPostInit()
        local data = ShardGameIndex.dsa_extradata and ShardGameIndex.dsa_extradata.dsa_aporkalypse_proxy
        if inst.ismastershard and data and data.from ~= inst.worldprefab then
            if _aporkalypse == nil then
                _begindate = 0
            else
                if data.begin_date ~= nil then
                    _aporkalypse.begin_date = data.begin_date
                end
            end
        end
        InitProxy()
    end

    function self:SetDate(date)
        _begindate = date
    end

    function self:OnSave(data)
        return { begin_date = _begindate }
    end

    function self:OnLoad(data)
        if data and data.begin_date then
            _begindate = data.begin_date
        end
    end

    function self:GetDebugString()
        return string.format("Aporkalypse begin date: %d", _begindate)
    end
end)
