bbag = {}
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

bbag.filterFactories = {}
bbag.filterFactories.filterCategory = function(targetCategory)
  return function(filteredItem)
    return filteredItem ~= nil and targetCategory == filteredItem.category 
  end
end

-- Request game server for data on items that the local player owns.
-- Then apply given filter and do basic processing (aggregation),
-- that is converting the data to the addon's preferred (internal) representation.
bbag.requestPlayerItems = function(filter) 
  if nil == filter then
    filter = function(filteredItem)
      return filteredItem ~= nil
    end
  end
  
  local items = {}
  local MAX_CONTAINERS = 16
  local MAX_SLOTS_PER_CONTAINER = 128

  for containerId = 0, MAX_CONTAINERS do
    for slotId = 0, MAX_SLOTS_PER_CONTAINER do
      local item = bbag.requestPlayerItem(containerId, slotId)
      if item ~= nil and filter(item) then
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

-- Facade. 
bbag.newReport = function(filter, sorter, alternativeItemsProvider)
  local itemsProvider = bbag.requestPlayerItems
  if alternativeItemsProvider ~= nil then
    itemsProvider = alternativeItemsProvider
  end
  local report = {}
  local items = itemsProvider(filter)
  -- Map a map of items to a set of items.
  for itemId, item in pairs(items) do
    tinsert(report, item)
  end
  
  if nil == sorter then
    sorter = function(a, b)
      return (a.name or "") < (b.name or "")
    end
  end
  table.sort(report, sorter)
  
  return report
end