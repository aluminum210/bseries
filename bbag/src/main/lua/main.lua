
--[[ bbag.lua ]]--
local bbag = {}
bbag.isDebugEnabled = true
bbag.debug = function(...)
  if bbag.isDebugEnabled then
    print("DEBUG: ", ...)
  end 
end

bbag.requestItemConcept = function(itemId)
  local infoName, infoLink, _, _, infoType, infoCategory, _, texture, _ = GetItemInfo(itemId)
  return {
  	id = itemId,
    name = infoName,
    link = infoLink,
    class = infoType,
    category = infoCategory
  }
end

bbag.unpackItemLink = function(givenLink)
  -- http://wowwiki.wikia.com/wiki/ItemLink
  local link = givenLink or ""
  local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4,
    Suffix, Unique, LinkLvl, Name = string.find(link,
    "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
  return {
    id = Id or 0,
    name = Name or ""
  }
end

bbag.requestPlayerItem = function(containerId, slotId)
  local result = nil
  local _, infoCount, _, _, _, _, infoLink = GetContainerItemInfo(containerId, slotId)
  if (infoCount or 0) > 0 then
    local linkData = bbag.unpackItemLink(infoLink)
    local concept = bbag.requestItemConcept(linkData.id)
    result = {
  	  id = concept.id,
  	  name = concept.name,
      quantityInSlot = infoCount,
      containerId = containerId,
      slotId = slotId,
      class = concept.class,
      category = concept.category,
      link = infoLink
    }
  end
  return result
end

-- Request game server for data on items that the local player owns.
-- Then apply given filter and do basic processing (aggregation),
-- that is converting the data to the addon's preferred (internal) representation.
local requestPlayerItems = function(givenContainers)  
  local items = {}

  for i = 1, #givenContainers do
    local containerId = givenContainers[i]
    for slotId = 1, GetContainerNumSlots(containerId) do
      local item = bbag.requestPlayerItem(containerId, slotId)
      if item ~= nil then
        local prevItemQuantity = 0
        --[[ Avoid possible override. ]]--
        local thisQuantityInSlot = item.quantityInSlot
        if items[item.id] ~= nil then 
          prevItemQuantity = items[item.id].quantity
        --[[ Save data on the smallest stack of the item,
             to later use on item usage requests. ]]--
          if items[item.id].quantityInSlot < item.quantityInSlot then
            item.quantityInSlot = items[item.id].quantityInSlot
            item.containerId = items[item.id].containerId
            item.slotId = items[item.id].slotId
          end
        end
        item.quantity = thisQuantityInSlot + prevItemQuantity
        items[item.id] = item
      end
    end
  end

  return items 
end

bbag.requestPlayerItemsFromBags = function()
  --[[ http://wowwiki.wikia.com/wiki/BagId ]]-- 
  local bags = {
      --[[ Backpack and bags. ]]--
  	  0, 1, 2, 3, 4,
  	  --[[ Keyring and tokens. ]]--
  	  -2, -4
  }
  return requestPlayerItems(bags)
end

bbag.requestPlayerItemsFromBank = function()
  --[[ http://wowwiki.wikia.com/wiki/BagId ]]--
  local bankSlots = {
      --[[ Bank. ]]--
  	  -1, 5, 6, 7, 8, 9, 10, 11
  }
  return requestPlayerItems(bankSlots)
end

-- Facade. 
  --[[ TODO Substitude BAGS with BANK when desired. ]]--
bbag.newReport = function()  
  local report = {}
  local items = bbag.requestPlayerItemsFromBags()
  -- Map a map of items to a set of items.
  for itemId, item in pairs(items) do
    tinsert(report, item)
  end
  
  return report
end

--[[ Report filters. ]]--

local reportSort = function(givenReport, sortCallback)
  --[[ Sort in-place. ]]--
  table.sort(givenReport, sortCallback)
  return givenReport
end

bbag.reportSortByName = function(givenReport)
  return reportSort(givenReport, function(a, b)
    return (a.name or "") < (b.name or "")
  end)
end

--[[ Report filters. ]]--

local reportFilter = function(givenReport, filterCallback)
  local filteredEntries = {}
  
  for i = 1, #givenReport do
    local nextEntry = givenReport[i]
    if filterCallback(nextEntry) then
      tinsert(filteredEntries, nextEntry)
    end
  end
  
  return filteredEntries  
end

bbag.reportFilterByCategory = function(givenReport, givenCategories)
  return reportFilter(givenReport, function(filteredEntry)
    local result = false
    for i = 1, #givenCategories do
      local nextCategory = givenCategories[i]
      result = filteredEntry.category == nextCategory or result
    end
    return result
  end)
end

bbag.reportFilterByName = function(givenReport, givenSearchQuery)
  local isPlainSearch = true
  return reportFilter(givenReport, function(filteredEntry)
    return string.find(filteredEntry.name, givenSearchQuery, 1, isPlainSearch) ~= nil
  end)
end
--[[ end bbag.lua ]]--

--[[ initGUI.lua ]]--
bbag.initGUI = function(bbag)
  
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
        --[[ TODO Substitude with bank, keyring, etc. frame.]]--
    end
    bbag.debug('getNativeItemButton', 'containerId', containerId, 'slotId', slotId, 'c', c, 'i', i, 'f', f:GetName())
    return f
  end
  
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
    
    local fieldIco = CreateFrame('FRAME', entryFrame:GetName()..'Icon', entryFrame) 
    fieldIco:SetWidth(iconWidth)
    fieldIco:SetHeight(entryFrame:GetHeight())
    fieldIco:SetPoint("RIGHT",  entryFrame, "LEFT", entryFrame:GetWidth()+entryFrame:GetWidth()/2, 0)
    fieldIco:SetPoint("TOP",    entryFrame, "TOP",  0, 0)
    fieldIco:SetPoint("LEFT",   entryFrame, "LEFT", entryFrame:GetWidth()/2, 0)
    fieldIco:SetPoint("BOTTOM", entryFrame, "TOP",  0, -entryFrame:GetHeight())
    fieldIco:Show()
    entryFrame.fieldIco = fieldIco
    
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
    
    entryFrame:SetScript('OnEnter', function(self, ...)
      print('e')
      if self.entry ~= nil then
        GameTooltip:SetBagItem(self.entry.containerId, self.entry.slotId)
        GameTooltip:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        GameTooltip:Show(self:IsShown())
      end
    end)
    
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
  local report = bbag.newReport()
  report = bbag.reportFilterByCategory(report, {targetCategory})
  report = bbag.reportSortByName(report)
  for i = 1, #givenFrame.entriesFrame.entryFrames do
    local entry = report[i]    
    local entryFrame = givenFrame.entriesFrame.entryFrames[i]
    entryFrame.entry = entry
    
    local n = nil
    local q = nil
      
    if entry ~= nil then
      n = entry.name
      q = entry.quantity
      entryFrame:Show()
    else
      entryFrame:Hide()
    end
    
    entryFrame.fieldName:SetText(n)
    entryFrame.fieldQuantity:SetText(q)
    --[[entryFrame:SetScript('OnClick', function(self, ...)
      if "Armor" == entry.category or "Weapon" == entry.category then
        bbag.debug("equipping", entry.name)
        EquipItemByName(entry.id)
      elseif IsShiftKeyDown() then
        bbag.debug("picking", entry.name, "in", entry.containerId, entry.slotId)
        PickupContainerItem(entry.containerId, entry.slotId)
      else
        bbag.debug("using", entry.name, "in", entry.containerId, entry.slotId)
        --UseContainerItem(entry.containerId, entry.slotId)
      end
    end)]]--
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
--[[ end initGUI.lua ]]--

--[[ initHooks.lua ]]--
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
--[[ end initHooks.lua ]]--

--[[ initEventHandler.lua ]]--
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
--[[ end initEventHandler.lua ]]--

--[[ init.lua ]]--
bbag.init = function(bbag)  
  bbag.upToDate = false
  
  -- The order is relevant.
  bbag.initGUI(bbag)
  bbag.initHooks(bbag)
  bbag.initEventHandler(bbag)
end
--[[ end init.lua ]]--

--[[ main.lua ]]--
local frame = CreateFrame("FRAME", "BBag", UIParent)
bbag.frame = frame

frame:Hide()

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
  self:UnregisterAllEvents()
  bbag.init(bbag)
end)
--MacroPopupFrame:HookScript("OnHide", MyFunction)

return frame
--[[ end main.lua ]]--
