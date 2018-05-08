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
  local groupIcons = {
    'Interface\\Icons\\INV_Helmet_03',
    'Interface\\Icons\\INV_Potion_07',
    'Interface\\Icons\\INV_Box_01',
    'Interface\\Icons\\INV_Stone_03',
    
    'Interface\\Icons\\Spell_Fire_SunKey',
    'Interface\\Icons\\INV_Misc_Rune_01',
    'Interface\\Icons\\INV_Misc_Coin_06',
    'Interface\\Icons\\Ability_Miling',
    
    'Interface\\Icons\\INV_Scroll_06',
    'Interface\\Icons\\Ability_PierceDamage',
    'Interface\\Icons\\INV_Misc_Map_01',
    'Interface\\Icons\\INV_Misc_Quiver_01',
    
    'Interface\\Icons\\INV_Fabric_Linen_01',
    'Interface\\Icons\\Ability_MeleeDamage'
  }
  local tabFrameWidth = 40
  local tabsFrame = CreateFrame("FRAME", "BBagGroupTabs", frame)
  tabsFrame:SetWidth(frame:GetWidth())
  tabsFrame:SetHeight(tabFrameWidth*2)
  tabsFrame:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  tabsFrame:SetPoint("TOP", frame, "TOP", 0, 0)
  tabsFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
  tabsFrame:SetPoint("BOTTOM", frame, "TOP", 0, -tabsFrame:GetHeight())
  tabsFrame:Show()
  local i = 0
  for row = 0, 1 do
    for column = 0, 7 do
      i = i + 1
      if i > #groupNames then
        break
      end
      local groupTabFrame = CreateFrame("BUTTON", "BBagGroupTab"..i, tabsFrame, "SecureHandlerClickTemplate")
      groupTabFrame:SetWidth(tabFrameWidth)
      groupTabFrame:SetHeight(tabFrameWidth)
      groupTabFrame:SetPoint("RIGHT", tabsFrame, "LEFT", groupTabFrame:GetWidth()*(column+1), 0)
      groupTabFrame:SetPoint("TOP", tabsFrame, "TOP", 0, -groupTabFrame:GetHeight()*row)
      groupTabFrame:SetPoint("LEFT", tabsFrame, "LEFT", groupTabFrame:GetWidth()*column, 0)
      groupTabFrame:SetPoint("BOTTOM", tabsFrame, "TOP", 0, -groupTabFrame:GetHeight()*(row+1))
      local groupName = groupNames[i] or "Consumable"
      groupTabFrame:RegisterForClicks("AnyUp")
      groupTabFrame:SetScript('OnClick', function(self, event, ...)
        frame.selectedGroup = groupName
        bbag.upToDate = false
        bbag.updateIfNecessary(frame)
      end)  
      groupTabFrame:SetNormalTexture(groupIcons[i])
      groupTabFrame:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
      groupTabFrame:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
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
  for j = 1, 16 do
    local entryFrame = CreateFrame("BUTTON", "BBagEntry"..j, entriesFrame, "SecureHandlerClickTemplate")
    entryFrame:RegisterForClicks("AnyUp")
    entryFrame:SetWidth(entriesFrame:GetWidth())
    entryFrame:SetHeight(40)
    entryFrame:SetPoint("RIGHT", entriesFrame, "RIGHT", 0, 0)
    entryFrame:SetPoint("TOP", entriesFrame, "TOP", 0, -entryFrame:GetHeight()*(j-1))
    entryFrame:SetPoint("LEFT", entriesFrame, "LEFT", 0, 0)
    entryFrame:SetPoint("BOTTOM", entriesFrame, "TOP", 0, -entryFrame:GetHeight()*j)
    
    local iconWidth = 64
    
    local fieldQuantityWidth = 64
    local fieldName = entryFrame:CreateFontString(entryFrame:GetName().."Name", "OVERLAY", "GameFontNormalLargeLeft")
    -- fieldName:SetFont("Fonts\\FRIZQT__.TTF", entryFrame:GetHeight())
    fieldName:SetWidth(entriesFrame:GetWidth()-fieldQuantityWidth-iconWidth)
    fieldName:SetHeight(entryFrame:GetHeight())
    fieldName:SetPoint("RIGHT", entryFrame, "LEFT", iconWidth+fieldName:GetWidth(), 0)
    fieldName:SetPoint("TOP", entryFrame, "TOP", 0, 0)
    fieldName:SetPoint("LEFT", entryFrame, "LEFT", iconWidth, 0)
    fieldName:SetPoint("BOTTOM", entryFrame, "BOTTOM", 0, 0)
    fieldName:Show()
    entryFrame.fieldName = fieldName
    
    local fieldQuantity = entryFrame:CreateFontString(entryFrame:GetName().."Quantity", "OVERLAY", "GameFontNormalLarge")
    -- fieldQuantity:SetFont("Fonts\\FRIZQT__.TTF", entryFrame:GetHeight())
    fieldQuantity:SetWidth(fieldQuantityWidth)
    fieldQuantity:SetHeight(entryFrame:GetHeight())
    fieldQuantity:SetPoint("RIGHT", entryFrame, "LEFT", iconWidth+fieldName:GetWidth()+fieldQuantity:GetWidth(), 0)
    fieldQuantity:SetPoint("TOP", entryFrame, "TOP", 0, 0)
    fieldQuantity:SetPoint("LEFT", entryFrame, "LEFT", iconWidth+fieldName:GetWidth(), 0)
    fieldQuantity:SetPoint("BOTTOM", entryFrame, "BOTTOM", 0, 0)
    fieldQuantity:Show()
    entryFrame.fieldQuantity = fieldQuantity
    
    entryFrame:Show()
    entryFrames[j] = entryFrame
  end
  frame.entriesFrame = entriesFrame
  frame.entriesFrame.entryFrames = entryFrames
  
  bbag.nativeItemButtons = {}
  
  local function getNativeItemButton(containerId, slotId)
    slotId = math.max(slotId, 0)
    local c = containerId + 1
    local i = GetContainerNumSlots(containerId) - slotId + 1
    local f = nil
    if (containerId == 0 or 
      containerId == 1 or 
      containerId == 2 or
      containerId == 3 or
      containerId == 4) then
      f = _G['ContainerFrame' .. (containerId + 1) .. 'Item' .. i]
    elseif false then
        --[[Substitude with bank, keyring, etc. frame.]]--
    end
    if f ~= nil then
      bbag.nativeItemButtons[f:GetName()] = f
    end
    bbag.debug('getNativeItemButton', 'containerId', containerId, 'slotId', slotId, 'c', c, 'i', i, 'f', f)
    return f
  end
  
  local function hideAllNativeItemButtons()
    for k, v in pairs(bbag.nativeItemButtons) do
      v:Hide()
    end
  end
  
  local function loadItemIcons()
  end
  
bbag.update = function(givenFrame)
  givenFrame = givenFrame or bbag.frame
  local targetCategory = givenFrame.selectedGroup
  if nil == targetCategory then
    targetCategory = "Consumable"
  end 
  hideAllNativeItemButtons()
  local filter = bbag.filterFactories.filterCategory(targetCategory)
  local report = bbag.newReport(filter)
  for i = 1, #givenFrame.entriesFrame.entryFrames do
    local entry = report[i]    
    local entryFrame = givenFrame.entriesFrame.entryFrames[i]
    local n = nil
    local q = nil
    
    if entry ~= nil then
      n = entry.name
      q = entry.quantity
      
      local bagItemFrame = getNativeItemButton(entry.containerId, entry.slotId)
      entryFrame.nativeBagItemFrame = bagItemFrame
      bbag.debug('bagItemFrame', bagItemFrame, "containerId", entry.containerId)
      --[[bagItemFrame:SetWidth(entryFrame.fieldIco:GetWidth())]]--
      --[[bagItemFrame:SetHeight(entryFrame.fieldIco:GetHeight())]]--
      bagItemFrame:SetPoint("RIGHT", entryFrame, "LEFT", bagItemFrame:GetWidth()+bagItemFrame:GetWidth()/2, 0)
      bagItemFrame:SetPoint("TOP", entryFrame, "TOP", 0, 0)
      bagItemFrame:SetPoint("LEFT", entryFrame, "LEFT", bagItemFrame:GetWidth()/2, 0)
      bagItemFrame:SetPoint("BOTTOM", entryFrame, "TOP", 0, -bagItemFrame:GetHeight())
      bagItemFrame:Show()
    end
    
    entryFrame.fieldName:SetText(n)
    entryFrame.fieldQuantity:SetText(q)
    entryFrame:SetScript('OnClick', function(self, ...)
      if "Armor" == entry.category or "Weapon" == entry.category then
        bbag.debug("equipping", entry.name)
        EquipItemByName(entry.id)
      elseif IsShiftKeyDown() then
        bbag.debug("picking", entry.name, "in", entry.containerId, entry.slotId)
        PickupContainerItem(entry.containerId, entry.slotId)
      else
        bbag.debug("using", entry.name, "in", entry.containerId, entry.slotId)
        --[[UseContainerItem(entry.containerId, entry.slotId)]]--
      end
    end)
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