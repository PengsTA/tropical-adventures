AddClassPostConstruct("components/embarker", function(self)
    function self:GetEmbarkPosition()
        if self.embarkable ~= nil and self.embarkable:IsValid() then
            local my_x, _, my_z = self.inst.Transform:GetWorldPosition()
            if self.embarkable.components.walkableplatform then
                return self.embarkable.components.walkableplatform:GetEmbarkPosition(my_x, my_z, self.embarker_min_dist)
            end

            local embarkable_radius = 0.1
            local embarkable_x, _, embarkable_z = self.embarkable.Transform:GetWorldPosition()
            local embark_x, embark_z = GLOBAL.VecUtil_Normalize(my_x - embarkable_x, my_z - embarkable_z)
            return embarkable_x + embark_x * embarkable_radius, embarkable_z + embark_z * embarkable_radius
        end

        local x, z = self.disembark_x or self.last_embark_x, self.disembark_z or self.last_embark_z
        if x == nil or z == nil then
            local my_x, _, my_z = self.inst.Transform:GetWorldPosition()
            x, z = my_x, my_z
        end
        return x, z
    end
end)
