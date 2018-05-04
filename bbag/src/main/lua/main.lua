bbag = {}

bbag.tinsert = table.insert
bbag.sfind = string.find

bbag.main = function()
  return nil
end

local defaultStorage = {}

bbag.getStorage = function()
  return defaultStorage
end

bbag.addItem = function(ownerName, itemName, itemsQuantity)
end

bbag.removeItem = function(ownerName, itemName, itemsQuantity)
  return bbag.addItem(ownerName, itemName, -itemsQuantity)
end

bbag.getBagByOwner = function(ownerName)
  local storage = getStorage()
  local bag = storage[ownerName] or {}
  return bag
end

bbag.getAllCategories = function()
  return {
    "Trade Goods", 
    "Equipment", "Uncommon Equipment", "Rare Equipment", "Epic Equipment",
    "Trash"
  }
end

bbag.getCategoryId = function(categoryName)
  local result = 0 
  local i = 1
  local t = bbag.getAllCategories()

  for i, #t do
    if t[i] == categoryName and t[i] ~= nil and t[i] ~= "" then
      result = i
    end
  end

  return result
end

bbag.getCategoryName = function(categoryId)
  local t = bbag.getAllCategories()
  return t[categoryId] or ""
end

bbag.getItemCategoriesMap = function()
  return {
    ["Silk Cloth"] = {1}
  }
end

bbag.getItemCategories = function(targetItemName)
  local map = bbag.getItemCategoriesMap()
  local result = map[targetItemName] or {}
  return result 
end

bbag.predicateFactories = {}
bbag.predicateFactories.itemName = function(targetItemName)
  return function(filteredItem)
    local nameMatches = false
    local filteredItemName = filteredItem.name or nil
    nameMatches = bbag.sfind(filteredItemName, targetItemName) ~= nil
    return nameMatches
  end
end
bbag.predicateFactories.anyCategory = function(givenCategories)
  return function(filteredItem)
    local result = false
    local targetCategories = givenCategories or {}
    local itemName = filteredItem.name or nil
    local filteredItemCategories = bbag.getItemCategories(itemName) or {}
    local i = 1
    local j = 1
    for i, #targetCategories do
      for j, #filteredItemCategories do
	result = targetCategories[i] == filteredItemCategories[j] or result 
      end
    end
    return result
  end
end

bbag.getSubset = function(ownerName, predicate)
  local subset = {}
  local bag = bbag.getBagByOwner(ownerName) 
  local i = 1
  for i, #bag do
    if predicate(bag[i]) then
      bbag.tinsert(subset, bag[i])
    end
  end
  return subset
end

return bbag
