bbag.initGUI = function(bbag)
  local frame = bbag.frame
  
  frame:SetWidth(512)
  frame:SetHeight(640)
  frame:SetBackdrop(StaticPopup1:GetBackdrop())
  frame:SetPoint("CENTER", UIParent)
  
  local groupTabFrames = {}
  -- https://wow.gamepedia.com/ItemType
  local groupNames = {
    "Armor", "Consumable", "Container", "Gem",
    "Key", "Miscellaneous", "Money", "Reagent",
    "Recipe", "Projectile", "Quest", "Quiver",
    "Trade Goods", "Weapon"
  }
  local tabsFrame = CreateFrame("FRAME", "BBagGroupTabs", frame)
  tabsFrame:SetWidth(frame:GetWidth())
  tabsFrame:SetHeight(32*5)
  tabsFrame:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  tabsFrame:SetPoint("TOP", frame, "TOP", 0, 0)
  tabsFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
  tabsFrame:SetPoint("BOTTOM", frame, "TOP", 0, -tabsFrame:GetHeight())
  tabsFrame:Show()
  local i = 0
  for row = 0, 3 do
    for column = 0, 3 do
      i = i + 1
      if i > #groupNames then
        break
      end
      local groupTabFrame = CreateFrame("BUTTON", "BBagGroupTab"..i, tabsFrame, "UIPanelButtonTemplate")
      groupTabFrame:SetWidth(128)
      groupTabFrame:SetHeight(32)
      groupTabFrame:SetPoint("RIGHT", tabsFrame, "LEFT", groupTabFrame:GetWidth()*(column+1), 0)
      groupTabFrame:SetPoint("TOP", tabsFrame, "TOP", 0, -groupTabFrame:GetHeight()*row)
      groupTabFrame:SetPoint("LEFT", tabsFrame, "LEFT", groupTabFrame:GetWidth()*column, 0)
      groupTabFrame:SetPoint("BOTTOM", tabsFrame, "TOP", 0, -groupTabFrame:GetHeight()*(row+1))
      groupTabFrame.text = _G[groupTabFrame:GetName().."Text"]
      local groupName = groupNames[i] or "Consumable"
      groupTabFrame.text:SetText(groupName)
      groupTabFrame:SetScript('OnClick', function(self, event, ...)
        frame.selectedGroup = groupName
        bbag.upToDate = false
        bbag.updateIfNecessary(frame)
      end)
      groupTabFrame:Show()
      groupTabFrames[i] = groupTabFrame
    end
  end
  frame.tabsFrame = tabsFrame
  frame.tabsFrame.groupTabFrames = groupTabFrames
  
  local entryFrames = {}
  local entriesFrame = CreateFrame("FRAME", "BBagEntries", frame)
  entriesFrame:SetWidth(frame:GetWidth())
  entriesFrame:SetHeight(frame:GetHeight()-tabsFrame:GetHeight())
  entriesFrame:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  entriesFrame:SetPoint("TOP", frame, "TOP", 0, -tabsFrame:GetHeight())
  entriesFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
  entriesFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
  entriesFrame:Show()
  for j = 1, 32 do
    local entryFrame = CreateFrame("FRAME", "BBagEntry"..j, entriesFrame)
    entryFrame:SetWidth(entriesFrame:GetWidth())
    entryFrame:SetHeight(16)
    entryFrame:SetPoint("RIGHT", entriesFrame, "RIGHT", 0, 0)
    entryFrame:SetPoint("TOP", entriesFrame, "TOP", 0, -entryFrame:GetHeight()*(j-1))
    entryFrame:SetPoint("LEFT", entriesFrame, "LEFT", 0, 0)
    entryFrame:SetPoint("BOTTOM", entriesFrame, "TOP", 0, -entryFrame:GetHeight()*j)
    
    local fieldIco = CreateFrame("FRAME", entryFrame:GetName().."Icon", entryFrame)
    fieldIco:SetWidth(16)
    fieldIco:SetHeight(entryFrame:GetHeight())
    fieldIco:SetPoint("RIGHT", entryFrame, "LEFT", fieldIco:GetWidth(), 0)
    fieldIco:SetPoint("TOP", entryFrame, "TOP", 0, 0)
    fieldIco:SetPoint("LEFT", entryFrame, "LEFT", 0, 0)
    fieldIco:SetPoint("BOTTOM", entryFrame, "BOTTOM", 0, 0)
    fieldIco:Show()
    entryFrame.fieldIco = fieldIco
    
    local fieldQuantityWidth = 64
    local fieldName = entryFrame:CreateFontString(entryFrame:GetName().."Name", "OVERLAY", "GameFontNormalLargeLeft")
    -- fieldName:SetFont("Fonts\\FRIZQT__.TTF", entryFrame:GetHeight())
    fieldName:SetWidth(entriesFrame:GetWidth()-fieldQuantityWidth-fieldIco:GetWidth())
    fieldName:SetHeight(entryFrame:GetHeight())
    fieldName:SetPoint("RIGHT", entryFrame, "LEFT", fieldIco:GetWidth()+fieldName:GetWidth(), 0)
    fieldName:SetPoint("TOP", entryFrame, "TOP", 0, 0)
    fieldName:SetPoint("LEFT", entryFrame, "LEFT", fieldIco:GetWidth(), 0)
    fieldName:SetPoint("BOTTOM", entryFrame, "BOTTOM", 0, 0)
    fieldName:Show()
    entryFrame.fieldName = fieldName
    
    local fieldQuantity = entryFrame:CreateFontString(entryFrame:GetName().."Quantity", "OVERLAY", "GameFontNormalLarge")
    -- fieldQuantity:SetFont("Fonts\\FRIZQT__.TTF", entryFrame:GetHeight())
    fieldQuantity:SetWidth(fieldQuantityWidth)
    fieldQuantity:SetHeight(entryFrame:GetHeight())
    fieldQuantity:SetPoint("RIGHT", entryFrame, "LEFT", fieldIco:GetWidth()+fieldName:GetWidth()+fieldQuantity:GetWidth(), 0)
    fieldQuantity:SetPoint("TOP", entryFrame, "TOP", 0, 0)
    fieldQuantity:SetPoint("LEFT", entryFrame, "LEFT", fieldIco:GetWidth()+fieldName:GetWidth(), 0)
    fieldQuantity:SetPoint("BOTTOM", entryFrame, "BOTTOM", 0, 0)
    fieldQuantity:Show()
    entryFrame.fieldQuantity = fieldQuantity
    
    entryFrame:Show()
    entryFrames[j] = entryFrame
  end
  frame.entriesFrame = entriesFrame
  frame.entriesFrame.entryFrames = entryFrames
  
bbag.update = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  local targetCategory = givenFrame.selectedGroup
  if nil == targetCategory then
    targetCategory = "Consumable"
  end 
  local filter = bbag.filterFactories.filterCategory(targetCategory)
  local report = bbag.newReport(filter)
  for i = 1, #givenFrame.entriesFrame.entryFrames do
    local entry = report[i]
    local n = nil
    local q = nil
    if entry ~= nil then
      n = entry.name
      q = entry.quantity
    end
    
    local entryFrame = givenFrame.entriesFrame.entryFrames[i]
    entryFrame.fieldName:SetText(n)
    entryFrame.fieldQuantity:SetText(q)
    entryFrame:Show()
  end
  
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