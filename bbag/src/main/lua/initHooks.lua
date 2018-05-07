bbag.initHooks = function(bbag)  
  local debug = bbag.debug
  
  ContainerFrame1:HookScript("OnHide", function() bbag.hideIfNecessary() end)
  ContainerFrame1:HookScript("OnShow", function() bbag.show() end)
  ContainerFrame2:HookScript("OnHide", function() bbag.hideIfNecessary() end)
  ContainerFrame2:HookScript("OnShow", function() bbag.show() end)
  ContainerFrame3:HookScript("OnHide", function() bbag.hideIfNecessary() end)
  ContainerFrame3:HookScript("OnShow", function() bbag.show() end)
  ContainerFrame4:HookScript("OnHide", function() bbag.hideIfNecessary() end)
  ContainerFrame4:HookScript("OnShow", function() bbag.show() end)
  ContainerFrame5:HookScript("OnHide", function() bbag.hideIfNecessary() end)
  ContainerFrame5:HookScript("OnShow", function() bbag.show() end)
end