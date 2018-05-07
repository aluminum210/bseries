bbag.initEventHandler = function(bbag)
  local frame = bbag.frame
  frame:RegisterEvent("BAG_CLOSED")
  frame:RegisterEvent("BAG_OPEN")
  frame:RegisterEvent("BAG_UPDATE")
    
  frame:SetScript("OnEvent", function(self, event, containerId, ...)
	if "BAG_CLOSED" == event then
	  bbag.hideIfNecessary(self)
	elseif "BAG_OPEN" == event then
	  bbag.show(self)
	elseif "BAG_UPDATE" == event then
	  bbag.upToDate = false
	  bbag.updateIfNecessary(self)
	end
  end)
end