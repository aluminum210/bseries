local function getItemConcept(itemId)
  local infoName, infoLink, _, _, infoType, infoCategory, _, texture, _ = GetItemInfo(itemId)
  return {
  	id = itemId,
    name = infoName,
    link = infoLink,
    class = infoType,
    category = infoCategory
  }
end

local function unpackItemLink(givenLink)
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

local function getPlayerItem(containerId, slotId)
  local result = nil
  local _, infoCount, _, _, _, _, infoLink = GetContainerItemInfo(containerId, slotId)
  if (infoCount or 0) > 0 then
    local linkData = unpackItemLink(infoLink)
    local concept = getItemConcept(linkData.id)
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

local function getPlayerItems()
  local items = {}
  local MAX_CONTAINERS = 16
  local MAX_SLOTS_PER_CONTAINER = 128

  for containerId = 0, MAX_CONTAINERS do
    for slotId = 0, MAX_SLOTS_PER_CONTAINER do
      local item = getPlayerItem(containerId, slotId)
      if item ~= nil then
        local prevItemQuantity = 0
        if items[item.id] ~= nil and "table" == type(items[item.id]) then
          prevItemQuantity = (items[item.id].quantity or 0)
        end
        item.quantity = item.quantityInSlot + prevItemQuantity
        items[item.id] = item
      end
    end
  end

  return items 
end

local function getReport(filter, sorter)
  local report = {}
 
  local items = getPlayerItems()  
  if nil == filter then
    filter = function(filteredItem)
      return filteredItem ~= nil
    end
  end
  for itemId, item in pairs(items) do
    if filter(item) then
      -- local itemConcept = getItemConcept(itemId)
      tinsert(report, item)
    end
  end
  
  if nil == sorter then
    sorter = function(a, b)
      return (a.name or "") < (b.name or "")
    end
  end
  table.sort(report, sorter)
  
  return report
end

--
local frame = CreateFrame("FRAME", "BBag", UIParent)
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
frame.column1:SetFont("Fonts\\FRIZQT__.TTF", 16)
frame.column1:SetWordWrap(true)
frame.column1:Show()

frame.column2 = frame:CreateFontString("BBagColumn2", "OVERLAY")
frame.column2:SetWidth(frame:GetWidth() * 0.33)
frame.column2:SetHeight(frame:GetHeight())
frame.column2:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
frame.column2:SetPoint("TOP", frame, "TOP", 0, 0)
frame.column2:SetPoint("LEFT", frame.column1, "RIGHT", 0, 0)
frame.column2:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
frame.column2:SetFont("Fonts\\FRIZQT__.TTF", 16)
frame.column2:SetWordWrap(true)
frame.column2:Show()

frame:Hide()

local function hide()
  frame:Hide()
end

local function show()
  if frame.isAddonLoaded then
    local report = getReport()
    
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
    frame.column1:SetText(col1)
    frame.column2:SetText(col2)
    frame:Show()
  end 
end

local function update()
  show()
end

frame:RegisterEvent("BAG_CLOSED")
frame:RegisterEvent("BAG_OPEN")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, containerId, ...)
  if "BAG_CLOSED" == event then
    hide()
  elseif "BAG_OPEN" == event then
    show()
  elseif "BAG_UPDATE" == event then
    update()
  elseif "ADDON_LOADED" == event then
    frame.isAddonLoaded = true
  end
end)

hooksecurefunc('CloseBackpack', function()
  hide()
end)
hooksecurefunc('CloseAllBags', function()
  hide()
end)
hooksecurefunc('CloseAllWindows', function()
  hide()
end)
hooksecurefunc('OpenBag', function()
  show()
end)
hooksecurefunc('ToggleBag', function()
  if frame:IsShown() then
    hide()
  else
    show()
  end
end)
--MacroPopupFrame:HookScript("OnHide", MyFunction)