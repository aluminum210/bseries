bbag.init = function(bbag)
  bbag.upToDate = false
  
  -- The order is relevant.
  bbag.initGUI(bbag)
  bbag.initHooks(bbag)
  bbag.initEventHandler(bbag)
end