bbag.initGUI = function(bbag)
  local frame = bbag.frame
  local FONT_SIZE = 16
  
  frame:SetWidth(512)
  frame:SetHeight(640)
  frame:SetBackdrop(StaticPopup1:GetBackdrop())
  frame:SetPoint("CENTER", UIParent)
	
  frame.column1 = frame:CreateFontString("BBagColumn1", "OVERLAY")
  frame.column1:SetWidth(frame:GetWidth() * 0.64)
  frame.column1:SetHeight(frame:GetHeight())
  frame.column1:SetPoint("RIGHT", frame, "LEFT", frame.column1:GetWidth(), 0)
  frame.column1:SetPoint("TOP", frame, "TOP", 0, 0)
  frame.column1:SetPoint("LEFT", frame, "LEFT", 0, 0)
  frame.column1:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
	-- The main font, the roundish one, is called Friz Quadrata. 
	-- The one used in the chat window is Arial Narrow. 
	-- The one used for in-game mail is Morpheus. The damage font is Skurri.
	-- ARIALN.ttf
	-- FRIZQT__.ttf
	-- MORPHEUS.ttf
	-- SKURRI.ttf
  frame.column1:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE)
  frame.column1:SetWordWrap(true)
  frame.column1:Show()
	
  frame.column2 = frame:CreateFontString("BBagColumn2", "OVERLAY")
  frame.column2:SetWidth(frame:GetWidth() * 0.33)
  frame.column2:SetHeight(frame:GetHeight())
  frame.column2:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  frame.column2:SetPoint("TOP", frame, "TOP", 0, 0)
  frame.column2:SetPoint("LEFT", frame.column1, "RIGHT", 0, 0)
  frame.column2:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
  frame.column2:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE)
  frame.column2:SetWordWrap(true)
  frame.column2:Show()
  
bbag.update = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  local report = bbag.newReport()
    
  local groups = {}
  for i = 1, #report do
    local entry = report[i] or nil
    if entry ~= nil then
      if nil == groups[entry.category] then 
        groups[entry.category] = {}
      end
      tinsert(groups[entry.category], entry)
    end
  end
    
  local col1 = ""
  local col2 = ""
  for groupName, items in pairs(groups) do
    col1 = col1 .. "|n" .. groupName .. ":|n"
    col2 = col2 .. "|n|n"
    for j = 1, #items do
      local item = items[j]
      col1 = col1 .. item.link .. "|n"
      col2 = col2 .. item.quantity .. "|n"
    end
  end
  givenFrame.column1:SetText(col1)
  givenFrame.column2:SetText(col2)
  givenFrame.column1:Show()
  givenFrame.column2:Show()
  bbag.upToDate = true
end

bbag.updateIfNecessary = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  if givenFrame:IsVisible() and not bbag.upToDate then
	bbag.update(givenFrame)
  end
end

bbag.hide = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  givenFrame:Hide()
end

bbag.checkIfAllBagsAreClosed = function()
  local allBagsClosed = not ContainerFrame1:IsVisible() and
    not ContainerFrame2:IsVisible() and
    not ContainerFrame3:IsVisible() and
    not ContainerFrame4:IsVisible() and
    not ContainerFrame5:IsVisible()
  bbag.debug("allBagsClosed", allBagsClosed)
  return allBagsClosed
end

bbag.hideIfNecessary = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  local allBagsClosed = bbag.checkIfAllBagsAreClosed() 
  if allBagsClosed then
    bbag.hide(givenFrame)
  end
end

-- Show and update if necessary.
bbag.show = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  givenFrame:Show(givenFrame)
  if not (bbag.upToDate or false) then
    bbag.update(givenFrame)
  end
end

bbag.toggle = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  if givenFrame:IsVisible() then
    givenFrame.hide(givenFrame)
  else
    givenFrame.show(givenFrame)
  end 
end

bbag.toggleIfNecessary = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  local allBagsClosed = bbag.checkIfAllBagsAreClosed()
  local someBagsAreOpen = not allBagsAreClosed
  if givenFrame:IsVisible() and allBagsClosed then
    bbag.hide(givenFrame)
  elseif not givenFrame:IsVisible() and someBagsAreOpen then
    bbag.show(givenFrame)
  end
end

end