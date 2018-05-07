local frame = CreateFrame("FRAME", "BBag", UIParent)
bbag.frame = frame

frame:Hide()

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
  self:UnregisterAllEvents()
  bbag.init(bbag)
end)
--MacroPopupFrame:HookScript("OnHide", MyFunction)