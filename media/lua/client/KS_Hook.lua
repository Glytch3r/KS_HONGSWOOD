
local ISTakePillActionHook = ISTakePillAction.perform
TrailingHeat = TrailingHeat or {}
function ISTakePillAction:perform()
    if self.item and self.item:getModData()['isCanCauseHeat'] ~= nil then
        TrailingHeat.doTrailingHeat(30)
    end
    return ISTakePillActionHook(self)
end
