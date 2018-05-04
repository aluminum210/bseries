local function getItemConcept(itemId)
  local infoName, infoLink, _, _, _, _, _, _, _ = GetItemInfo(itemId)
  return {
  	id = itemId,
    name = infoName,
    link = infoLink
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
    result = {
  	  id = linkData.id,
  	  name = linkData.name,
      quantityInSlot = infoCount,
      containerId = containerId,
      slotId = slotId,
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

local function hide()
end

local function show()
  local report = getReport()
  local i = 1
  print("--")
  for i = 1, #report do
    local entry = report[i] or nil
    if entry ~= nil then
      print(entry.link, "*", entry.quantity)
    end
  end
  print("--")
  return nil 
end

local function update()
  return show()
end

local frame = CreateFrame("FRAME", "BBag")
frame:RegisterEvent("BAG_CLOSED")
frame:RegisterEvent("BAG_OPEN")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, containerId, ...)
  if "BAG_CLOSED" == event and frame.loaded then
    hide()
  elseif "BAG_OPEN" == event and frame.loaded then
    show()
  elseif "BAG_UPDATE" == event and frame.loaded  then
    update()
  elseif "ADDON_LOADED" == event and not frame.loaded then
    frame.loaded = true
    show()
  end
end)