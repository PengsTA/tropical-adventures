local Widget = require "widgets/widget"

local TrapMarker = Class(Widget, function(self, owner)
     self.owner = owner
     Widget._ctor(self, "TrapMarker")
     self:SetClickable(false)
     self:Hide()
     
     self.markers = {}
end)

function TrapMarker:ShowMarker()
     self:ClearMarker()
     self:StartUpdating()
     self:Show()
end

function TrapMarker:HideMarker()
     self:ClearMarker()
     self:StopUpdating()
     self:Hide()
end

local function SafeErodeAndRemove(fx, time)
     if not fx or not fx:IsValid() then return end
     if fx._safe_eroding then return end
     fx._safe_eroding = true
     fx:StartThread(function()
          local ticks = 0
          local tick_time = TheSim:GetTickTime()
          local time_to_erode = time or 0.5
          while ticks * tick_time < time_to_erode do
               if not fx:IsValid() then return end
               local erode_amount = ticks * tick_time / time_to_erode
               if fx.AnimState then
                    fx.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
               end
               ticks = ticks + 1
               Yield()
          end
          if fx:IsValid() then
               fx:Remove()
          end
     end)
end

function TrapMarker:ClearMarker()
     for t,m in pairs(self.markers) do
          if m:IsValid() then
               m:Remove()
          end
          self.markers[t] = nil
     end
end

function TrapMarker:OnUpdate(dt)
     if TheNet:IsServerPaused() then return end
     
     local old_markers = {}
     for t,m in pairs(self.markers) do old_markers[t] = true end

     local x, y, z = ThePlayer.Transform:GetWorldPosition()
     local traps = TheSim:FindEntities(x, y, z, TUNING.SCAN_DISTANCE, {"tentacle", "invisible"})

     for i,t in ipairs(traps) do
          if self.markers[t] == nil then
               local fx = SpawnPrefab("hiddendanger_fx")
               fx.Transform:SetPosition(t.Transform:GetWorldPosition())
               self.markers[t] = fx
          else
               old_markers[t] = false
          end
     end

     for t,m in pairs(self.markers) do
          if not t:IsValid() then
               if m:IsValid() then m:Remove() end
               self.markers[t] = nil
          elseif not t:HasTag("invisible") then
               SafeErodeAndRemove(m, 0.5)
               self.markers[t] = nil
          elseif old_markers[t] == true then
               if m:IsValid() then m:Remove() end
               self.markers[t] = nil
          end
     end
end

return TrapMarker
