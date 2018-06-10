--[[--
BQuest add-on for World of Warcraft: Wrath of the Lich King game.
The purpose of the add-on is to allow players to create custom quests
and update them automatically.
It is also planned to implement the ability to share created quests between players.
See:
1. The Power of Ten (http://spinroot.com/gerard/pdf/P10.pdf)
2. LuaCheck (https://github.com/mpeterv/luacheck)
3. LDoc (https://stevedonovan.github.io/ldoc/)
@script bquest
]]

--[[--
Core.
Add-on logic, ignorant of the GUI or CLI or environment it's executed in.
Some of it is exposed via global variables,
to be available via game console and not only GUI.
@section core
]]

local MAX_ATTRIBUTES = 16
local MAX_QUESTS = 256

--[[--
Returns a set of names of all supported quest goals.
@return table of names that are strings
]]
local function getSupportedQuestGoals()
  return {
    'CastSpell', 'CollectItem', 'KillUnit'
  }
end

--[[--
Check if goal of given name is supported by the rest of the add-on.
@function isSupportedQuestGoal
@param targetGoalName non-nil string that is goal name to be checked
@return boolean true if `targetGoalName` was found in `supportedGoals` table;
false otherwise.
]]
local function isSupportedQuestGoal(targetGoalName)
  assert(targetGoalName ~= nil)
  assert("string" == type(targetGoalName))

  local result = false
  local supportedQuestGoals = getSupportedQuestGoals()

  for i = 0, #supportedQuestGoals do
    local supportedQuestGoal = supportedQuestGoals[i]
    if targetGoalName == supportedQuestGoal then
      result = true
      break
    end
  end

  return result
end

--[[--
Check if given quest is well formed.
For example, it ensures that the most mandatory fields are defined.
@function isValidQuest
@param givenQuest a table that is a quest
@return result boolean `true` if the queset is valid; `false` otherwise.
@return optionalErrorMessage string that is to be used in assertions
]]
local function isValidQuest(givenQuest)
  assert(givenQuest ~= nil)
  assert("table" == type(givenQuest))

  local attributesQuantity = 0
  local optionalErrorMessage = nil
  local result = true

  result = givenQuest.goalName ~= nil and result
  if not result then
    optionalErrorMessage = 'Goal name is missing.'
    return result, optionalErrorMessage
  end
  result = "string" == type(givenQuest.goalName) and result
  if not result then
    optionalErrorMessage = 'Goal name must be a string.'
    return result, optionalErrorMessage
  end
  result = isSupportedQuestGoal(givenQuest.goalName) and result
  if not result then
    optionalErrorMessage = 'Goal is not supported.'
    return result, optionalErrorMessage
  end
  result = givenQuest.createdDateTable ~= nil and result
  if not result then
    optionalErrorMessage = 'Creation date is missing.'
    return result, optionalErrorMessage
  end
  result = "table" == type(givenQuest.createdDateTable) and result
  if not result then
    optionalErrorMessage = 'Creation date must be in a format of Lua date table.'
    return result, optionalErrorMessage
  end
  result = givenQuest.questId ~= nil and result
  if not result then
    optionalErrorMessage = 'Quest identifier is missing.'
    return result, optionalErrorMessage
  end
  result = "number" == type(givenQuest.questId) and result
  if not result then
    optionalErrorMessage = 'Quest identifier must be a number.'
    return result, optionalErrorMessage
  end
  if givenQuest.itemId ~= nil and GetItemInfo ~= nil then
    local itemName = GetItemInfo(givenQuest.itemId)
    result = itemName ~= nil and 'string' == type(itemName) and result
    if not result then
      optionalErrorMessage = 'Invalid item identifier.'
      return result, optionalErrorMessage
    end
  end
  for attribute, value in pairs(givenQuest) do
    result = "string" == type(attribute) and result
    if not result then
      optionalErrorMessage = 'All keys must be strings.'
      return result, optionalErrorMessage
    end
    result = value ~= nil and result
    if not result then
      optionalErrorMessage = 'All values must be not null.'
      return result, optionalErrorMessage
    end
    local isDate = "table" == type(value) and "createdDateTable" == attribute
    local isString = "string" == type(value)
    local isNumber = "number" == type(value)
    result = (isString or isNumber or isDate) and result
    if not result then
      optionalErrorMessage = 'Only scalar values and creation date are allowed.'
      return result, optionalErrorMessage
    end
    attributesQuantity = attributesQuantity + 1
  end
  result = attributesQuantity <= MAX_ATTRIBUTES and result
  if not result then
    optionalErrorMessage = 'Maximum amount of attributes is exceeded.'
    return result, optionalErrorMessage
  end

  return result, optionalErrorMessage
end

--[[--
Takes not yet valid quest stub, and then returns a valid quest,
with all add-on metadata added.
@function applyDefaultAttributes
@param newQuest a quest under creation, not yet valid.
]]
local function applyDefaultAttributes(newQuest)
  newQuest.createdDateTable = date("*t")

  local d = newQuest.createdDateTable
  newQuest.questId = math.ceil(string.format('%04d%02d%02d%04d', d.year, d.month, d.day, math.random(1, 9999)))

  if GetRealmName ~= nil and "function" == type(GetRealmName) then
    local assumedRealmName = GetRealmName()
    local len = string.len(assumedRealmName)
    if assumedRealmName ~= nil and "string" == type(assumedRealmName) and len >= 4 and len <= 64 then
      newQuest.realmName = assumedRealmName
    end
  end

  if nil == newQuest.realmName then
    newQuest.realmName = 'UnknownRealm'
  end

  if UnitName ~= nil and "function" == type(UnitName) then
    local assumedAuthor = UnitName("player")
    local len = string.len(assumedAuthor)
    if assumedAuthor ~= nil and "string" == type(assumedAuthor) and len >= 3 and len <= 12 then
      newQuest.authorName = assumedAuthor
    end
  end

  if nil == newQuest.authorName then
    newQuest.authorName = 'UnknownPlayer'
  end

  local defaultAttributesAmount = 4
  local operationsLimit = MAX_ATTRIBUTES - defaultAttributesAmount
  local operationsPerformed = 0
  for attribute, value in pairs(newQuest) do
    newQuest[attribute] = value
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed <= operationsLimit)
  end

  assert(newQuest ~= nil)
  assert(isValidQuest(newQuest))

  return newQuest
end

--[[--
Checks if given number corresponds to an item in the game.
@function isValidItemId
@param itemIdToCheck integer to check for validity
@return result boolean true if valid; false otherwise
@return optionalErrorMessage
@see createQuestCollectItem
@see updateProgressCollectItem
]]
local function isValidItemId(itemIdToCheck)
  assert(itemIdToCheck ~= nil)
  local optionalErrorMessage = nil
  local result = true

  result = "number" == type(itemIdToCheck) and result
  if not result then
    optionalErrorMessage = 'Not a number.'
    return result, optionalErrorMessage
  end

  result = itemIdToCheck >= 1 and itemIdToCheck <= 999999 and result
  if not result then
    optionalErrorMessage = 'Number not in range.'
    return result, optionalErrorMessage
  end

  result = 0 == select(2, math.modf(itemIdToCheck)) and result
  if not result then
    optionalErrorMessage = 'Number not an integer.'
    return result, optionalErrorMessage
  end

  --[[ The `GetItemInfo` check may fail if the item concept exists,
  but was not encountered by the player. ]]--
  result = nil ~= GetItemInfo(itemIdToCheck) and result
  if not result then
    optionalErrorMessage = 'No item concept with the given identifier found.'
    return result, optionalErrorMessage
  end

  return result, optionalErrorMessage
end

--[[--
Create a quest that is a table,
that later can be used to track aquisition of items in the game.
@function createQuestCollectItem
@param givenItemId integer; identifier of an item to be tracked
@param givenItemAmount positive integer; desired amount of the item
@return newQuest
]]
local function createQuestCollectItem(givenItemId, givenItemAmount)
  assert(givenItemId ~= nil)
  assert(isValidItemId(givenItemId))

  assert(givenItemAmount ~= nil)
  assert("number" == type(givenItemAmount))
  assert(givenItemAmount >= 1)
  assert(givenItemAmount <= 1024)

  local newQuest = {
    goalName = 'CollectItem',
    itemId = math.ceil(givenItemId),
    itemAmount = math.min(math.max(math.ceil(givenItemAmount), 1), 1024)
  }
  applyDefaultAttributes(newQuest)

  return newQuest
end

--[[--
Create a quest that is a table,
that later can be used to track destruction of units in the game.
@function createQuestKillUnit
@param givenVictimUnitName string; unit name of the target to be killed in-game
@param givenOptionalKillsAmount positive integer; assumed 1 if `nil` is given
@return newQuest table
]]
local function createQuestKillUnit(givenVictimUnitName, givenOptionalKillsAmount)
  assert(givenVictimUnitName ~= nil)
  assert("string" == type(givenVictimUnitName))
  assert(string.len(givenVictimUnitName) >= 3)
  if nil == givenOptionalKillsAmount then
    givenOptionalKillsAmount = 1
  end
  assert(givenOptionalKillsAmount ~= nil)
  assert("number" == type(givenOptionalKillsAmount))
  assert(givenOptionalKillsAmount >= 1)
  assert(givenOptionalKillsAmount <= 1024)

  local newQuest = {
    goalName = 'KillUnit',
    victimUnitName = givenVictimUnitName,
    killsAmount = math.ceil(math.min(math.max(givenOptionalKillsAmount, 1), 1024))
  }
  applyDefaultAttributes(newQuest)

  return newQuest
end

--[[--
Check if given integer corresponds to a spell indentifier in-game.
@function isValidSpellId
@param spellIdToCheck
@return result
@return optionalErrorMessage
]]
local function isValidSpellId(spellIdToCheck)
  assert(spellIdToCheck ~= nil)
  local optionalErrorMessage = nil
  local result = true

  result = "number" == type(spellIdToCheck) and result
  if not result then
    optionalErrorMessage = 'Not a number.'
    return result, optionalErrorMessage
  end

  result = spellIdToCheck >= 1 and spellIdToCheck <= 999999 and result
  if not result then
    optionalErrorMessage = 'Number not in range.'
    return result, optionalErrorMessage
  end

  result = 0 == select(2, math.modf(spellIdToCheck)) and result
  if not result then
    optionalErrorMessage = 'Number not an integer.'
    return result, optionalErrorMessage
  end

  result = nil ~= GetSpellInfo(spellIdToCheck) and result
  if not result then
    optionalErrorMessage = 'No spell concept with the given identifier found.'
    return result, optionalErrorMessage
  end

  return result, optionalErrorMessage
end

--[[--
Create a quest that can be later used to track spell casts.
Optionally limited to a specific target.
@function createQuestSpellCast
@param givenSkillId positive integer that is spell unique identifier
@param givenUsagesAmount positive integer that is amount of spell casts expected to occurr
@param givenOptionalTargetUnitName string, nullable; limits tracking to this target, if given
]]
local function createQuestCastSpell(givenSkillId, givenUsagesAmount, givenOptionalTargetUnitName)
  assert(givenSkillId ~= nil)
  assert(isValidSpellId(givenSkillId))
  assert(givenUsagesAmount ~= nil)
  assert("number" == type(givenUsagesAmount))
  assert(givenUsagesAmount >= 1)

  if "" == givenOptionalTargetUnitName then
    givenOptionalTargetUnitName = nil
  end
  if givenOptionalTargetUnitName ~= nil then
    assert(givenOptionalTargetUnitName ~= nil)
    assert("string" == type(givenOptionalTargetUnitName))
    assert(string.len(givenOptionalTargetUnitName) >= 3)
  end

  local newQuest = {
    goalName = 'CastSpell',
    spellId = math.ceil(givenSkillId),
    castsAmount = math.ceil(givenUsagesAmount)
  }

  if givenOptionalTargetUnitName ~= nil then
    newQuest.optionalTargetUnitName = givenOptionalTargetUnitName
  end

  applyDefaultAttributes(newQuest)

  return newQuest
end


--[[--
Persistence.
Quests created with functions defined in `core` section are not saved anywhere
by default.
This section defines functions that allow to serialize created quests in plain-text.
To do this, built-in game Saved Variables mechanism is used.
@section persistence
@see http://wowwiki.wikia.com/wiki/SavedVariables
@see http://wowwiki.wikia.com/wiki/Saving_variables_between_game_sessions
]]

BQuestSavedVariables = {}

--[[--
Inserts given valid quest into global table that will end up serialized.
Notice that the script enforces a limit on how many quests can be serialized.
@function persistQuest
@param givenQuest a valid quest that will be persisted
@return result boolean; `true` if the quest ended up in the data source
@return optionalErrorMessage
]]
local function persistQuest(givenQuest)
  assert(givenQuest ~= nil)
  assert(isValidQuest(givenQuest))

  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end

  local optionalErrorMessage = nil

  local persistedQuests = BQuestSavedVariables.quests

  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  local questsAmount = 0
  for _, _ in pairs(persistedQuests) do
    questsAmount = questsAmount + 1
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed <= operationsLimit)
  end

  if nil == persistedQuests[givenQuest.questId] and questsAmount < MAX_QUESTS then
    local givenCreatedDateTable = givenQuest.createdDateTable
    givenQuest.createdDateTable = date("*t", time(givenCreatedDateTable))

    persistedQuests[givenQuest.questId] = givenQuest
  elseif persistedQuests[givenQuest.questId] ~= nil and isValidQuest(persistedQuests[givenQuest.questId]) then
    optionalErrorMessage = "Quest already exists. Try creating and persisting another quest with the same attributes."
  elseif questsAmount >= MAX_QUESTS then
    optionalErrorMessage = 'Maximum amount of quests exceeded.'
  else
    optionalErrorMessage = "Space is not empty or some other error."
  end
  return givenQuest == persistedQuests[givenQuest.questId], optionalErrorMessage
end

--[[--
Remove a valid quest of given identifier from the data storage.
@function wipeQuest
@param givenQuestId positive integer
@return boolean; `true` if quest of given id exited and was removed
]]
local function wipeQuest(givenQuestId)
  assert(givenQuestId ~= nil)
  assert("number" == type(givenQuestId))
  assert(givenQuestId > 0)

  local questExisted = false
  local questWiped = false

  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end
  for nextQuestId, _ in pairs(BQuestSavedVariables.quests) do
    if givenQuestId == nextQuestId then
      BQuestSavedVariables.quests[givenQuestId] = nil

      questExisted = true
      questWiped = true
    end
  end

  return questExisted and questWiped
end

--[[ Public API. ]]--

local function getItemIdFromItemLink(itemLink)
  --[[ http://wowwiki.wikia.com/wiki/ItemLink ]]--
  local exp = "|?c?f?f?(%x*)"
  exp = exp .. "|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*)"
  exp = exp .. ":?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)"
  exp = exp .. "|?h?%[?([^%[%]]*)%]?|?h?|?r?"
  local _, _, _, _, Id = string.find(itemLink, exp)
  return tonumber(Id)
end

local function getSpellIdFromSpellLink(spellLink)
  --[[ http://wowwiki.wikia.com/wiki/ItemLink ]]--
  local exp = "|?c?f?f?(%x*)"
  exp = exp .. "|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*)"
  exp = exp .. ":?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)"
  exp = exp .. "|?h?%[?([^%[%]]*)%]?|?h?|?r?"
  local _, _, _, _, Id = string.find(spellLink, exp)
  return tonumber(Id)
end

--[[--
Used to create and persist quests with arguments passed from the GUI.
@see initGUIHandlerTooltipNavAccept
]]
local function createQuestSmart(givenGoalName, ...)
  --[[
  TODO
  When given invalid entity name or id,
  fail early, that is __here__.
  ]]--
  assert(isSupportedQuestGoal(givenGoalName))

  local newQuest = nil
  local optionalErrorMessage

  if 'CastSpell' == givenGoalName then
    local spellLink = select(1, ...)
    assert(spellLink ~= nil)
    assert('string' == type(spellLink))

    local spellId = getSpellIdFromSpellLink(spellLink)
    assert(spellId ~= nil)
    assert(isValidSpellId(spellId))

    local castsAmount = select(2, ...)
    castsAmount = math.min(math.max(math.ceil(tonumber(castsAmount)), 1), 1024)

    local optionalTargetUnitName = select(3, ...) or nil
    optionalTargetUnitName = string.gsub(optionalTargetUnitName, "^%s*(.-)%s*$", "%1")
    print(optionalTargetUnitName)

    newQuest, optionalErrorMessage = createQuestCastSpell(spellId, castsAmount, optionalTargetUnitName)
  elseif 'CollectItem' == givenGoalName then
    local itemLink = select(1, ...)
    assert(itemLink ~= nil)
    assert('string' == type(itemLink))

    local itemId = getItemIdFromItemLink(itemLink)
    assert(isValidItemId(itemId))

    local itemAmount = select(2, ...)
    itemAmount = tonumber(itemAmount)
    assert(itemAmount ~= nil)
    if 'number' ~= type(itemAmount) then
      itemAmount = 0
    end
    itemAmount = math.max(math.min(itemAmount, 1024), 0)
    itemAmount = math.ceil(itemAmount)

    newQuest, optionalErrorMessage = createQuestCollectItem(itemId, itemAmount)
  elseif 'KillUnit'  == givenGoalName then
    local victimName = select(1, ...)
    assert(victimName ~= nil)
    assert('string' == type(victimName))

    local k0 = select(2, ...)
    local k1 = tonumber(k0)
    local killsAmount = math.min(math.max(k1, 1), 1024)

    newQuest, optionalErrorMessage = createQuestKillUnit(victimName, killsAmount)
  else
    optionalErrorMessage = 'Unsupported quest goal or some other error.'
  end

  local valid = isValidQuest(newQuest)
  assert(valid)
  if valid then
    persistQuest(newQuest)
  end

  return newQuest, optionalErrorMessage
end


--[[--
Query processing.
Functions in this section can be considered as core,
but they rely on the persistence mechamism, that is environment-specific.
These functions are used to read the add-on's data.
@section queries
]]

--[[--
Quickly return a map of all persisted quests,
where keys are positive integers that is quest identifiers,
and values are quest tables, that can possibly be invalid.
@function getQuestsMap
@see getQuestsSet
@see getQuest
]]
local function getQuestsMap()
  if nil == BQuestSavedVariables then
    BQuestSavedVariables = {}
  end
  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end
  return BQuestSavedVariables.quests
end

--[[--
Get a specific valid persisted quest by it's identifier,
if one exists.
@function getQuest
@param questId positive integer that is quest identifier
@return valid quest table or nil
]]
local function getQuest(questId)
  assert(questId ~= nil)
  assert('number' == type(questId))
  assert(questId > 0)

  local quests = getQuestsMap()
  local quest = quests[questId]

  assert(quest == nil or isValidQuest(quest))

  return quest
end

--[[--
Returns a set that represents all valid persisted quests.
Due to additional processing, it is slower than `getQuestsMap`.
Yet it is safer and therefore recommended.
Do not rely on ordering.
@function getQuestsSet
@return table of persisted valid quests
]]
local function getQuestsSet()
  local questsSet = {}
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  for _, quest in pairs(getQuestsMap()) do
    assert(isValidQuest(quest))
    tinsert(questsSet, quest)
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed <= operationsLimit)
  end
  table.sort(questsSet, function(a, b)
  return time(a.createdDateTable) > time(b.createdDateTable)
  end)
  return questsSet
end

--[[--
Events that correspond to a quest are aggregated in a separate from the quest table.
This function returns a progress table
corresponding to a valid persisted quest of given identifier.
Unlike quest tables, progress tables do not have a specified format.
Therefore there is no valid progress table.
However, usually a progress table has the same fields
as the quest progress in which it represents.
@function getQuestProgress
@param posisitve integer; identifier of a valid persisted quest
@see updateProgress
]]
local function getQuestProgress(questId)
  assert(questId ~= nil)
  assert("number" == type(questId))
  assert(questId > 0)

  if nil == BQuestSavedVariables then
    BQuestSavedVariables = {}
  end
  if nil == BQuestSavedVariables.progress then
    BQuestSavedVariables.progress = {}
  end

  local result = BQuestSavedVariables.progress[questId] or {}

  return result
end

local function skip(targetTable, skipAmount)
  assert(targetTable ~= nil)
  assert("table" == type(targetTable))
  assert(skipAmount ~= nil)
  assert("number" == type(skipAmount))
  assert(skipAmount >= 0)

  skipAmount = math.ceil(skipAmount)
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  local filtered = {}
  local skipped = 0
  for _, v in pairs(targetTable) do
    if skipped == skipAmount and v ~= nil then
      --[[
      `tinsert` is intentional.
      `filtered[k] = v` would result in unexpected behaviour later.
      ]]--
      tinsert(filtered, v)
    else
      skipped = skipped + 1
    end
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end

  assert(filtered ~= nil)
  assert('table' == type(filtered))
  local expectedValue = #targetTable - skipAmount
  local errMsg = string.format('%d ~= max(%d, %d)', #filtered, expectedValue, 0)
  assert(#filtered == math.max(#targetTable - skipAmount, 0), errMsg)

  return filtered
end

local function take(targetTable, takeAmount)
  assert(targetTable ~= nil)
  assert("table" == type(targetTable))
  assert(takeAmount ~= nil)
  assert("number" == type(takeAmount))
  assert(takeAmount >= 0)
  takeAmount = math.ceil(takeAmount)

  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0

  local filtered = {}
  local taken = 0
  for _, v in pairs(targetTable) do
    if taken < takeAmount and v ~= nil then
      --[[
      `tinsert` is intentional.
      `filtered[k] = v` would result in unexpected behaviour later.
      ]]--
      tinsert(filtered, v)
    else
      break
    end
    taken = taken + 1
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end

  assert(filtered ~= nil)
  assert('table' == type(filtered))
  assert(#filtered == math.min(#targetTable, takeAmount))

  return filtered
end

--[[--
Deprecated function. Use `GetItemInfo` instead.
]]
local function requestItemName(itemId)
  assert(itemId ~= nil)
  assert("number" == type(itemId))
  itemId = math.ceil(itemId)

  local itemName = GetItemInfo(itemId)
  assert(itemName ~= nil)
  assert("string" == type(itemName))
  return itemName
end

--[[--
Utility function used in updating progress on item-related quests.
@function requestPlayerItems
@return table of item information on items owned by the local player
@see updateProgressCollectItem
]]
local function requestPlayerItems()
  local containers = {-4, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
  local items = {}
  for i = 1, #containers do
    local containerId = containers[i]
    local slots = GetContainerNumSlots(containerId)
    for slotId = 1, slots do
      local containerItemId = GetContainerItemID(containerId, slotId)
      if containerItemId ~= nil then
        local _, containerItemCount = GetContainerItemInfo(containerId, slotId)
        tinsert(items, {
          itemId = containerItemId or 0,
          itemCount = containerItemCount or 1
        })
      end
    end
  end
  return items
end

--[[--
Returns union of a given quest and progress on it
formatted as a string.
Additionally, it aggregates the result using the game's API,
therefore it is environment specific, therefore not in the `core` section.
@function getQuestDescription
@param givenQuest valid quest table
@param givenProgress progress on the given quest
@return string; localized human readeable description of the quest
]]
local function getQuestDescription(givenQuest, givenProgress)
  assert(isValidQuest(givenQuest))
  assert(givenProgress ~= nil)
  assert("table" == type(givenProgress))

  local questDescription
  if 'CastSpell' == givenQuest.goalName then
    local spellName = GetSpellInfo(givenQuest.spellId)
    assert(spellName ~= nil)
    assert('string' == type(spellName))

    if nil == givenQuest.optionalTargetUnitName then
      questDescription = string.format('Cast %s %d times (%d times casted).',
      spellName, givenQuest.castsAmount, givenProgress.castsAmount or 0)
    else
      questDescription = string.format('Cast %s on %s %d times (%d times casted).',
      spellName, givenQuest.optionalTargetUnitName, givenQuest.castsAmount,
      givenProgress.castsAmount or 0)
    end
  elseif 'CollectItem' == givenQuest.goalName then
    local itemName = requestItemName(givenQuest.itemId)
    local itemAmount = givenProgress.itemAmount or 0
    questDescription = string.format('Collect %d of %s (%d collected).',
    givenQuest.itemAmount, itemName, itemAmount)
  elseif 'KillUnit' == givenQuest.goalName then
    local killsAmount = givenProgress.killsAmount or 0
    if 1 == givenQuest.killsAmount then
      if 0 == killsAmount then
        questDescription = string.format('Kill %s (alive).',
        givenQuest.victimUnitName)
      elseif 1 == killsAmount then
        questDescription = string.format('Kill %s (dead).',
        givenQuest.victimUnitName)
      else
        questDescription = string.format('Kill %s (dead %d times).',
        givenQuest.victimUnitName, killsAmount)
      end
    else
      questDescription = string.format('Kill %d of %s (%d killed).',
      givenQuest.killsAmount, givenQuest.victimUnitName, killsAmount)
    end
  else
    questDescription = string.format("Goal: %s. Progress is unknown.",
    givenQuest.goalName)
  end

  assert(questDescription ~= nil)
  assert("string" == type(questDescription))
  return questDescription
end


--[[--
Command processing.
Functions in this section can be considered as core,
but they rely on the persistence mechamism, that is environment-specific.
These functions are used to manipulate the add-on's data.
@section commands
]]

--[[ TODO Refactor and remove callbacks. ]]--
--[[--
For every persisted quest, execute the given callback.
Note that this funcion has limit of operations.
@function forQuests
@param callback to this callback every persisted valid quest is passed
@see updateProgress
]]
local function forQuests(callback)
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  for _, quest in pairs(getQuestsMap()) do
    assert(isValidQuest(quest))
    callback(quest)
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end
end

--[[--
Update (mutate and persist) progress on all quests according to the given callback.
@function updateProgress
@param callback to which quest and it's progress are passed;
it is expected to mutate the progress depending on the quest's data,
and not under any circumstance mutate the quest itself
@see initGUIHandlerRoot
]]
local function updateProgress(callback)
  forQuests(function(quest)
  local progress = getQuestProgress(quest.questId)
  callback(quest, progress)
  BQuestSavedVariables.progress[quest.questId] = progress
  end)
end

--[[--
Reads from the game how many of which items the player posseses,
checks if the player tracks them with this add-on,
and if so, updates the add-on's data accordingly.
@function updateProgressCollectItem
@see updateProgress
@see initGUIHandlerRoot
]]
local function updateProgressCollectItem()
  local items = requestPlayerItems()
  updateProgress(function(quest, progress)
  if 'CollectItem' == quest.goalName then
    progress.itemAmount = 0
    for i = 1, #items do
      local item = items[i]
      if quest.itemId == item.itemId then
        progress.itemAmount = progress.itemAmount + item.itemCount
      end
    end
  end
  end)
end

--[[--
Increments kill count of each quest that tracks kills of the unit,
which name was given.
@function updateProgressKillUnit
@param givenVictimName string that is in-game name of a unit that is tracked
@see updateProgress
@see initGUIHandlerRoot
]]
local function updateProgressKillUnit(givenVictimName)
  assert(givenVictimName ~= nil)
  assert('string' == type(givenVictimName))

  local function updateProgressKillUnitCallback(quest, progress)
    if 'KillUnit' == quest.goalName then
      if quest.victimUnitName == givenVictimName then
        if nil == progress.killsAmount then
          progress.killsAmount = 0
        end
        progress.killsAmount = progress.killsAmount + 1
      end
    end
  end
  updateProgress(updateProgressKillUnitCallback)
end

--[[--
Increments cast count of each quest that tracks casts of the spell,
which identifier was given.
If quest limited itself to specific target only,
then the function is expected to be called with second optional argument,
that is unit's name.
@function updateProgressKillUnit
@param givenSpellId positive integer
@param givenOptionalTargetUnitName nullable string
@see updateProgress
@see initGUIHandlerRoot
]]
local function updateProgressCastSpell(givenSpellId, givenOptionalTargetUnitName)
  assert(givenSpellId ~= nil)
  assert(isValidSpellId(givenSpellId))

  local function updateProgressCastSpellCallback(quest, progress)
    if 'CastSpell' == quest.goalName then
      if quest.spellId == givenSpellId then
        if (nil == quest.optionalTargetUnitName or
        givenOptionalTargetUnitName == quest.optionalTargetUnitName) then
          if nil == progress.castsAmount then
            progress.castsAmount = 0
          end
          progress.castsAmount = progress.castsAmount + 1
        end
      end
    end
  end
  updateProgress(updateProgressCastSpellCallback)
end

--[[ TODO ]]--

--[[--
Public API.
@section api
]]--

--[[--
Expose subset of the add-on's functions via global variables
to the in-game console.
@param root frame of the add-on that is "BQuest"
@see init
]]
local function initAPI(root)
  root.api = {}
  root.api.createQuestCollectItem = createQuestCollectItem
  root.api.createQuestKillUnit = createQuestKillUnit
  root.api.createQuestCastSpell = createQuestCastSpell
  root.api.destroyQuest = wipeQuest
end


--[[--
GUI.
All functions that customize the game GUI,
are defined in this section.
Every function defines it's dependencies as explicitly as possible,
by avoiding using global variables, that is frame names,
whenever possible.
Instead, every frame is passed to every other frame initializer that requires it
as an argument, that is local variable.
However, every frame created by the add-on has a name, that is presence in the table of globals.
This is done so that other developers can extend this add-on without modifying it's code.
@section gui
@see initGUI
@see init
]]

--[[ GUI: Constants. ]]--

local function getDefaultBQuestBackdrop()
  return {
    bgFile   = [[Interface\Dialogframe\ui-dialogbox-background]],
    --bgFile = [[Interface\Achievementframe\ui-achievement-achievementbackground]],
    edgeFile = [[Interface\Glues\common\textpanel-border]],
    tile = true,
    tileSize = 32,
    --tile     = false,
    --tileSize = 512,
    edgeSize = 32,
    insets   = {left = 8, right = 8, top = 8, bottom = 8}
  }
end

local function getQuestBQuestBackdrop()
  return {
    bgFile   = [[Interface\Dialogframe\ui-dialogbox-background]],
    edgeFile = [[Interface\Tooltips\ui-tooltip-border]],
    tile     = true,
    tileSize = 32,
    edgeSize = 16,
    insets   = {left = 4, right = 4, top = 4, bottom = 4}
  }
end

local function getQuestHighlightBQuestBackdrop()
  local b = getQuestBQuestBackdrop()
  b.bgFile = [[Interface\Dialogframe\ui-dialogbox-gold-background]]
  return b
end

local indent = 16

local MAX_QUEST_FRAMES = 8

local GUI_INDENT = 16

local GUI_ROOT_WIDTH  = 512
local GUI_ROOT_HEIGHT = 512

--[[local GUI_MAIN_WIDTH  = GUI_ROOT_WIDTH  - GUI_INDENT * 2]]--
local GUI_MAIN_HEIGHT = GUI_ROOT_HEIGHT - GUI_INDENT * 2

local GUI_SLIDER_WIDTH  = 16
local GUI_SLIDER_HEIGHT = GUI_MAIN_HEIGHT

--[[local GUI_NAV_WIDTH  = GUI_ROOT_WIDTH]]--
local GUI_NAV_HEIGHT = 40

--[[local GUI_NAV_BUTTON_WIDTH  = GUI_NAV_WIDTH / 8]]--
local GUI_NAV_BUTTON_HEIGHT = 20

local GUI_TOOLTIP_LABEL_HEIGHT = 32

--[[ GUI: Static. ]]--

--[[--
Initializes root frame of the add-on.
Main and root frames are distinct!
Root frame holds main frame, as well as most others.
]]
local function initGUIRoot(root)
  root:SetWidth(GUI_ROOT_WIDTH)
  root:SetHeight(GUI_ROOT_HEIGHT)
  root:SetBackdrop(getDefaultBQuestBackdrop())
  root:SetPoint("CENTER", 0, 0)

  --[[ http://wowwiki.wikia.com/wiki/Creating_standard_left-sliding_frames ]]--

  root:SetAttribute("UIPanelLayout-defined",   true)
  root:SetAttribute("UIPanelLayout-enabled",   true)
  root:SetAttribute("UIPanelLayout-area",      "middle")
  root:SetAttribute("UIPanelLayout-pushable",  2)
  root:SetAttribute("UIPanelLayout-width",     GUI_ROOT_WIDTH)
  root:SetAttribute("UIPanelLayout-whileDead", true)

  return root
end

--[[--
Initializes main frame of the add-on.
The main frame holds data entries of the add-on.
The main frame's parent is the root frame.
@see initGUIRoot
@see createQuestFrame
@see getHighlights
@see initGUISlider
]]
local function initGUIMain(root)
  local mainParent = root
  local main = CreateFrame('FRAME', mainParent:GetName() .. 'Main', mainParent)
  main:SetPoint("RIGHT",  mainParent, "RIGHT",  -GUI_SLIDER_WIDTH-indent, 0)
  main:SetPoint("TOP",    mainParent, "TOP",    0, -indent)
  main:SetPoint("LEFT",   mainParent, "LEFT",   indent, 0)
  main:SetPoint("BOTTOM", mainParent, "BOTTOM", 0, GUI_NAV_HEIGHT+indent)
  main.highlights = {}

  return main
end

--[[--
Utility function to create entry frames in the main frame.
@function createQuestFrame
]]
local function createQuestFrame(questParent, newQuestFrameId)
  assert(questParent ~= nil)

  local questHeight = questParent:GetHeight() / MAX_QUEST_FRAMES

  local newQuestFrame = CreateFrame(
  "BUTTON",
  questParent:GetName() .. "Quest" .. newQuestFrameId,
  questParent,
  "SecureHandlerClickTemplate"
  )
  newQuestFrame:SetWidth(questParent:GetWidth())
  newQuestFrame:SetHeight(questHeight)
  newQuestFrame:SetPoint("RIGHT",  questParent, "RIGHT", 0, 0)
  local h1 = -questHeight*(newQuestFrameId-1)
  newQuestFrame:SetPoint("TOP",    questParent, "TOP",   0, h1)
  newQuestFrame:SetPoint("LEFT",   questParent, "LEFT",  0, 0)
  local h2 = -questHeight*(newQuestFrameId)
  newQuestFrame:SetPoint("BOTTOM", questParent, "TOP",   0, h2)
  local b0 = getQuestBQuestBackdrop()
  b0.bgFile = nil
  newQuestFrame:SetBackdrop(b0)

  local fontFrame = newQuestFrame:CreateFontString(
  newQuestFrame:GetName() .. "Text",
  "OVERLAY",
  "GameFontWhite")
  fontFrame:SetAllPoints()
  fontFrame:SetText('Text is missing.')
  fontFrame:Show()
  newQuestFrame.text = fontFrame

  newQuestFrame:RegisterForClicks("AnyUp")
  --[[local b = getQuestBQuestBackdrop()
  newQuestFrame:SetNormalTexture(b.bgFile)
  local bh = getQuestHighlightBQuestBackdrop()
  newQuestFrame:SetPushedTexture(bh.bgFile)
  newQuestFrame:SetHighlightTexture(bh.bgFile)]]--

  newQuestFrame:Show()

  return newQuestFrame
end

--[[--
@function initGUIMainEntries
@see initGUIMain
@see createQuestFrame
]]
local function initGUIMainEntries(main)
  local mainEntries = {}
  for i = 1, MAX_QUEST_FRAMES do
    tinsert(mainEntries, createQuestFrame(main, i))
  end
  return mainEntries
end

--[[--
Initializes simplistic scroll for the main frame's entries.
@function initGUISlider
@see initGUIMain
]]
local function initGUISlider(root)
  local sliderParent = root
  local slider = CreateFrame(
  'SLIDER',
  sliderParent:GetName() .. 'Slider',
  sliderParent,
  'OptionsSliderTemplate')
  slider:SetValue(0)
  slider:SetValueStep(MAX_QUEST_FRAMES)
  slider:SetWidth(GUI_SLIDER_WIDTH)
  slider:SetHeight(GUI_SLIDER_HEIGHT)
  slider:SetPoint("RIGHT",  sliderParent, "RIGHT",  -indent, 0)
  slider:SetPoint("TOP",    sliderParent, "TOP",    0, -indent)
  slider:SetPoint("LEFT",   sliderParent, "RIGHT",  -GUI_SLIDER_WIDTH-indent, 0)
  slider:SetPoint("BOTTOM", sliderParent, "BOTTOM", 0, GUI_NAV_HEIGHT+indent)
  slider:SetOrientation('VERTICAL')
  slider:SetMinMaxValues(0, MAX_QUESTS)
  getglobal(slider:GetName() .. 'Low'):SetText(nil)
  getglobal(slider:GetName() .. 'High'):SetText(nil)
  getglobal(slider:GetName() .. 'Text'):SetText(nil)
  --slider.tooltipText = 'Slide me completely.'
  slider:Enable()
  slider:Show()

  return slider
end

--[[--
Initializes a button responsible for displaying pop-up for creating new quests.
@function initGUINavAdd
@see initGUINav
]]
local function initGUINavAdd(nav)
  local navAdd = CreateFrame(
  'BUTTON',
  nav:GetName() .. 'Add',
  nav,
  'UIPanelButtonTemplate')
  navAdd:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navAdd:SetPoint('LEFT', nav:GetWidth()/5-navAdd:GetWidth()/2, 0)
  navAdd:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navAdd:GetHeight()/2)
  local navAddText = _G[navAdd:GetName() .. 'Text']
  navAddText:SetText('Add')
  navAdd:Show()

  return navAdd
end

--[[--
Initialzes a button responsible for deleting highlighted quests.
@function initGUINavRemove
]]
local function initGUINavRemove(nav)
  local navRemove = CreateFrame(
  'BUTTON',
  nav:GetName() .. 'Remove',
  nav,
  'UIPanelButtonTemplate'
  )
  navRemove:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navRemove:SetPoint('LEFT', nav:GetWidth()/5*2-navRemove:GetWidth()/2, 0)
  navRemove:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navRemove:GetHeight()/2)
  local navRemoveText = _G[navRemove:GetName() .. 'Text']
  navRemoveText:SetText('Remove')
  navRemove:Show()

  return navRemove
end
--[[--
Initialzes a button responsible for sharing highlighted quests with other players.
@function initGUINavShare
]]
local function initGUINavShare(nav)
  local navShare = CreateFrame(
  'BUTTON',
  nav:GetName() .. 'Share',
  nav,
  'UIPanelButtonTemplate')
  navShare:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navShare:SetPoint('LEFT', nav:GetWidth()/5*3-navShare:GetWidth()/2, 0)
  navShare:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navShare:GetHeight()/2)
  local navShareText = _G[navShare:GetName() .. 'Text']
  navShareText:SetText('Share')
  navShare:Show()

  return navShare
end

--[[--
Initialzes a button responsible for hiding the root frame.
@function initGUINavClose
]]
local function initGUINavClose(nav)
  local navClose = CreateFrame(
  'BUTTON',
  nav:GetName() .. 'Close',
  nav,
  'UIPanelButtonTemplate')
  navClose:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navClose:SetPoint('LEFT', nav:GetWidth()/5*4-navClose:GetWidth()/2, 0)
  navClose:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navClose:GetHeight()/2)
  local navCloseText = _G[navClose:GetName() .. 'Text']
  navCloseText:SetText('Close')
  navClose:Show()

  return navClose
end

--[[--
Initialzes a container for main functionality buttons.
@function initGUINav
@see initGUINavAdd
@see initGUINavClose
@see initGUINavShare
@see initGUINavRemove
]]
local function initGUINav(root)
  local navParent = root
  local nav = CreateFrame('FRAME', navParent:GetName() .. 'Nav', navParent)
  nav:SetWidth(navParent:GetWidth())
  nav:SetHeight(GUI_NAV_HEIGHT)
  nav:SetPoint("RIGHT",  navParent, "RIGHT",  0, 0)
  nav:SetPoint("TOP",    navParent, "BOTTOM", 0, nav:GetHeight())
  nav:SetPoint("LEFT",   navParent, "LEFT",   0, 0)
  nav:SetPoint("BOTTOM", navParent, "BOTTOM", 0, 0)
  nav:SetBackdrop(getDefaultBQuestBackdrop())

  return nav
end

--[[--
Initialzes a quest type selector.
@function initGUITooltipRadioButtons
]]
local function initGUITooltipRadioButtons(tooltip)
  assert(tooltip ~= nil)

  local inset = indent
  local radioButtonsParent = CreateFrame('FRAME', nil, tooltip)
  radioButtonsParent:SetWidth(tooltip:GetWidth() - inset * 2)
  radioButtonsParent:SetHeight(tooltip:GetHeight() - inset * 2)
  radioButtonsParent:SetPoint('RIGHT',  tooltip, 'RIGHT',  -inset, 0)
  radioButtonsParent:SetPoint('TOP',    tooltip, 'TOP',    0,      -inset)
  radioButtonsParent:SetPoint('LEFT',   tooltip, 'LEFT',   inset,  0)
  radioButtonsParent:SetPoint('BOTTOM', tooltip, 'BOTTOM', 0,      inset)
  radioButtonsParent:Show()

  local radioButtons = {}
  local supportedQuestGoals = getSupportedQuestGoals()
  local maxColumns = 1
  local column = 0
  local row = 0
  assert(#supportedQuestGoals <= 16)
  for i = 1, #supportedQuestGoals do
    local goalName = supportedQuestGoals[i]
    assert(goalName ~= nil)
    assert('string' == type(goalName))

    local radioButton = CreateFrame(
    'CHECKBUTTON',
    tooltip:GetName() .. 'Radio' .. goalName,
    tooltip,
    'UIRadioButtonTemplate'
    )
    --[[ I know it's crap, I will fix it later. ]]--
    if column >= maxColumns then
      column = 0
      row = row + 1
    end

    radioButton:SetWidth(32)
    radioButton:SetHeight(20)
    local w1 = (column+1)*radioButton:GetWidth()
    radioButton:SetPoint('RIGHT',  radioButtonsParent, 'LEFT', w1, 0)
    local h1 = -row*radioButton:GetHeight()
    radioButton:SetPoint('TOP',    radioButtonsParent, 'TOP',  0, h1)
    local w2 = column*radioButton:GetWidth()
    radioButton:SetPoint('LEFT',   radioButtonsParent, 'LEFT', w2, 0)
    local h2 = (-row-1)*radioButton:GetHeight()
    radioButton:SetPoint('BOTTOM', radioButtonsParent, 'TOP',  0, h2)
    local radioText = getglobal(radioButton:GetName() .. 'Text')
    radioText:SetText(goalName)
    radioButton:Show()

    tinsert(radioButtons, radioButton)
    column = column + 1
  end

  assert(radioButtons ~= nil)
  assert('table' == type(radioButtons))

  return radioButtons
end

--[[--
Initializes a button that is responsible for creating a new quest,
based on earlier entered data.
@function initGUITooltipNavAccept
]]
local function initGUITooltipNavAccept(tooltip, tooltipNav)
  assert(tooltip ~= nil)
  assert(tooltipNav ~= nil)

  local tooltipNavAccept = CreateFrame(
  'BUTTON',
  tooltipNav:GetName() .. 'Accept',
  tooltipNav,
  'UIPanelButtonTemplate'
  )
  tooltipNavAccept:SetSize(64, GUI_NAV_BUTTON_HEIGHT)
  tooltipNavAccept:SetPoint('LEFT', 10, 0)
  tooltipNavAccept:SetPoint('BOTTOM', 0, 10)
  local tooltipNavAcceptText = getglobal(tooltipNavAccept:GetName() .. 'Text')
  tooltipNavAcceptText:SetText('Accept')
  tooltipNavAccept:Show()

  assert(tooltipNavAccept ~= nil)

  return tooltipNavAccept
end

--[[--
Initializes a button that is responsible for hiding quest creation pop-up.
@function initGUITooltipNavReject
]]
local function initGUITooltipNavReject(tooltip, tooltipNav)
  assert(tooltip ~= nil)
  assert(tooltipNav ~= nil)

  local tooltipNavReject = CreateFrame(
  'BUTTON',
  tooltipNav:GetName() .. 'Reject',
  tooltipNav,
  'UIPanelButtonTemplate'
  )
  tooltipNavReject:SetSize(64, GUI_NAV_BUTTON_HEIGHT)
  tooltipNavReject:SetPoint('RIGHT', -10, 0)
  tooltipNavReject:SetPoint('BOTTOM', 0, 10)
  local tooltipNavRejectText = getglobal(tooltipNavReject:GetName() .. 'Text')
  tooltipNavRejectText:SetText('Reject')
  tooltipNavReject:Show()

  assert(tooltipNavReject ~= nil)

  return tooltipNavReject
end

--[[--
@function initGUITooltipNav
@see initGUITooltipNavAccept
@see initGUITooltipNavReject
@see initGUITooltipFields
]]
local function initGUITooltipNav(tooltip)
  assert(tooltip ~= nil)

  local tooltipNav = CreateFrame('FRAME', tooltip:GetName() .. 'Nav', tooltip)
  tooltipNav:SetWidth(tooltip:GetWidth())
  tooltipNav:SetHeight(GUI_NAV_HEIGHT)
  tooltipNav:SetPoint("RIGHT",  tooltip, "RIGHT",  0, 0)
  tooltipNav:SetPoint("TOP",    tooltip, "BOTTOM", 0, tooltipNav:GetHeight())
  tooltipNav:SetPoint("LEFT",   tooltip, "LEFT",   0, 0)
  tooltipNav:SetPoint("BOTTOM", tooltip, "BOTTOM", 0, 0)
  tooltipNav:SetBackdrop(getDefaultBQuestBackdrop())

  return tooltipNav
end

--[[--
Initializes input fields that are used to create new quests.
@function initGUITooltipFields
@see createQuestSmart
]]
local function initGUITooltipFields(tooltip)
  local fields = {}
  local MAX_FIELDS = 4
  local h = GUI_TOOLTIP_LABEL_HEIGHT
  for i = 1, MAX_FIELDS do
    local field = CreateFrame(
    'EDITBOX',
    tooltip:GetName() .. 'Field' .. i,
    tooltip,
    'InputBoxTemplate'
    )
    field:SetWidth(100)
    field:SetHeight(32)
    local offset = (math.floor(MAX_FIELDS / 2) - i)*(field:GetHeight()+h)
    field:SetPoint('CENTER', 0, offset)
    field:Show()
    tinsert(fields, field)
  end
  return fields
end

--[[--
Initializes lables that will contain localized descriptions of input fields.
@function initGUITooltipFieldLabels
@see initGUITooltipFields
]]
local function initGUITooltipFieldLabels(tooltip, fields)
  assert(tooltip ~= nil)

  assert(fields ~= nil)
  assert('table' == type(fields))

  local fieldLabels = {}

  for i = 1, #fields do
    local field = fields[i]
    local label = tooltip:CreateFontString(
    field:GetName() .. "Label",
    "OVERLAY",
    "GameFontWhite"
    )
    label:SetWidth(field:GetWidth())
    label:SetHeight(GUI_TOOLTIP_LABEL_HEIGHT)

    label:SetPoint('RIGHT', field, 'RIGHT', 0, 0)
    label:SetPoint('TOP', field, 'TOP', 0, 32)
    label:SetPoint('LEFT', field, 'LEFT', 0, 0)
    label:SetPoint('BOTTOM', field, 'TOP', 0, 0)

    label:SetText('Empty label')

    label:Show()

    tinsert(fieldLabels, label)
  end

  return fieldLabels
end

--[[--
Initializes a container that will hold input fields and buttons
for creation of new quests.
@function initGUITooltip
@see initGUITooltipFieldLabels
@see initGUITooltipFields
]]
local function initGUITooltip(root)
  assert(root ~= nil)

  local tooltipParent = UIParent
  local tooltip = CreateFrame(
  'FRAME',
  root:GetName() .. 'Tooltip',
  tooltipParent
  )
  tooltip:SetWidth(256)
  tooltip:SetHeight(360)
  tooltip:SetPoint('CENTER', 0, 0)
  tooltip:SetBackdrop(getDefaultBQuestBackdrop())
  tooltip:Hide()

  --[[ http://wowwiki.wikia.com/wiki/Creating_standard_left-sliding_frames ]]--

  tooltip:SetAttribute("UIPanelLayout-defined",   true)
  tooltip:SetAttribute("UIPanelLayout-enabled",   true)
  tooltip:SetAttribute("UIPanelLayout-area",      "middle")
  tooltip:SetAttribute("UIPanelLayout-pushable",  3)
  tooltip:SetAttribute("UIPanelLayout-width",     tooltip:GetWidth())
  tooltip:SetAttribute("UIPanelLayout-whileDead", true)

  assert(tooltip ~= nil)

  return tooltip
end

--[[ GUI: Handlers. ]]--

--[[--
Resizes the scroll (slider) accordingly to the amount of quests persisted.
@function updateSlider
]]
local function updateSlider(slider)
  assert(slider ~= nil)

  local quests = getQuestsSet()
  slider:SetMinMaxValues(0, math.max(#quests-1, 0))
end

--[[--
Returns a set of valid quest identifiers that are
selected in the GUI by the player
to be removed or shared later.
@function getHighlights
]]
local function getHighlights(main)
  assert(main ~= nil)

  if nil == main.highlights or 'table' ~= type(main.highlights) then
    main.highlights = {}
  end

  local highlights = main.highlights
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  assert(#highlights <= MAX_QUESTS)
  for i = 1, #highlights do
    assert(highlights[i] ~= nil)
    assert('number' == type(highlights[i]))
    assert(highlights[i] > 0)
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed <= operationsLimit)
  end

  assert(highlights ~= nil)
  assert('table' == type(highlights))
  assert(#highlights <= MAX_QUESTS)

  return highlights
end

--[[--
Check if the given quest is highlighted in the GUI by the player.
@function isQuestHighlighted
@param main main frame
@param givenQuest valid quest table
@see getHighlights
]]
local function isQuestHighlighted(main, givenQuest)
  assert(main ~= nil)
  assert(givenQuest ~= nil)
  assert('table' == type(givenQuest))

  local result = false
  local highlights = getHighlights(main)
  assert(highlights ~= nil)
  assert('table' == type(highlights))
  for i = 1, #highlights do
    assert(givenQuest.questId ~= nil)
    assert('number' == type(givenQuest.questId))
    assert(givenQuest.questId > 0)
    result = givenQuest.questId == highlights[i] or result
  end

  return result
end

--[[--
Adds the given quest to the highlighted in the GUI by the player.
@function addHighlight
@param main main frame
@param givenQuest valid quest table
]]
local function addHighlight(main, givenQuest)
  assert(main ~= nil)
  assert(givenQuest ~= nil)
  assert(isValidQuest(givenQuest))
  if not isQuestHighlighted(main, givenQuest) then
    local questId = givenQuest.questId
    assert(questId ~= nil)
    assert('number' == type(questId))
    assert(questId > 0)
    tinsert(getHighlights(main), math.ceil(questId))
  end
  return
end

--[[--
Removes the given quest from the highlighted in the GUI by the player.
@function addHighlight
@param main main frame
@param givenQuest valid quest table
]]
local function removeHighlight(main, givenQuest)
  assert(main ~= nil)
  assert(givenQuest ~= nil)
  assert(isValidQuest(givenQuest))
  if isQuestHighlighted(main, givenQuest) then
    local questId = givenQuest.questId
    assert(questId ~= nil)
    assert('number' == type(questId))
    assert(questId > 0)
    local highlights = getHighlights(main)
    local removedIndexes = {}
    for i = 1, #highlights do
      local highlight = highlights[i]
      assert(highlight ~= nil)
      assert('number' == type(highlight))
      assert(highlight > 0)
      if questId == highlight then
        tinsert(removedIndexes, i)
      end
    end
    for j = 1, #removedIndexes do
      tremove(highlights, removedIndexes[j])
    end
  end
  return
end

--[[--
Updates a single main data entry accordingly to the given progress table.
@function updateQuestFrame
]]
local function updateQuestFrame(main, givenFrame, givenQuest, givenProgress)
  assert(main ~= nil)
  assert(givenFrame ~= nil)
  assert(isValidQuest(givenQuest))

  local questDescription = getQuestDescription(givenQuest, givenProgress)
  assert(questDescription ~= nil)
  assert("string" == type(questDescription))

  givenFrame.text:SetText(questDescription)

  givenFrame.questId = givenQuest.questId

  if isQuestHighlighted(main, givenQuest) then
    givenFrame:SetBackdrop(getQuestHighlightBQuestBackdrop())
  else
    givenFrame:SetBackdrop(getQuestBQuestBackdrop())
  end
end

--[[--
Removes highlights and clears data from the given main data entry.
@function cleanQuestFrame
@see updateQuestFrame
]]
local function cleanQuestFrame(main, givenFrame)
  assert(main ~= nil)
  assert(givenFrame ~= nil)

  if givenFrame.questId ~= nil then
    local quest = getQuest(givenFrame.questId)
    if quest ~= nil then
      removeHighlight(main, quest)
    end
  end
  givenFrame.questId = nil
  if givenFrame.text ~= nil then
    givenFrame.text:SetText(nil)
  end
  givenFrame:SetBackdrop(getQuestBQuestBackdrop())
end

--[[--
Updates data in the main entries depending on the position of the scroll.
@function updateQuestFrames
@see cleanQuestFrame
@see updateQuestFrame
]]
local function updateQuestFrames(main, slider, questFrames)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))

  local quests = getQuestsSet()
  local skipAmount = math.max(math.min(slider:GetValue(), #quests-#questFrames), 0)

  local afterSkip = skip(quests, skipAmount)
  local skipZero = (#afterSkip == 0 and #quests == 0)
  assert((#afterSkip == #quests - skipAmount) or skipZero)

  local afterTake = take(afterSkip, #questFrames)
  local takeZero = (#afterTake == 0 and #afterSkip == 0)
  assert((#afterTake == math.min(#questFrames, #afterSkip)) or takeZero)

  for i = 1, math.min(#questFrames, MAX_QUEST_FRAMES) do
    local nextQuestFrame = questFrames[i]
    local quest = afterTake[i]
    if quest ~= nil and isValidQuest(quest) then
      --[[assert(isValidQuest(quest))]]--
      local progress = getQuestProgress(quest.questId)
      updateQuestFrame(main, nextQuestFrame, quest, progress)
    else
      cleanQuestFrame(main, nextQuestFrame)
    end
  end
end

--[[--
Initializes event listener that is used to update progress
for supported quest types.
@function initGUIHandlerRoot
@see updateProgress
]]
local function initGUIHandlerRoot(root, main, slider, questFrames)
  assert(root ~= nil)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))

  root:RegisterEvent('BAG_UPDATE')
  root:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
  local function rootCallback(self, event, ...)
    assert(self ~= nil)
    if 'BAG_UPDATE' == event then
      updateProgressCollectItem()
      updateQuestFrames(main, slider, questFrames)
    elseif 'COMBAT_LOG_EVENT_UNFILTERED' == event then
      local combatEvent = select(2, ...)
      --[[ Use 'UNIT_DIED' for friendly. ]]--
      if 'PARTY_KILL' == combatEvent then
        local victimName = select(7, ...)
        updateProgressKillUnit(victimName)
        updateQuestFrames(main, slider, questFrames)
      elseif 'SPELL_DAMAGE' == combatEvent or 'SPELL_HEAL' == combatEvent then
        local caster = select(4, ...)
        if UnitName('player') == caster then
          local spellId = select(9, ...)
          spellId = tonumber(spellId)
          local targetUnitName = select(7, ...)
          updateProgressCastSpell(spellId, targetUnitName)
          updateQuestFrames(main, slider, questFrames)
        end
      end
    end
  end
  root:SetScript('OnEvent', rootCallback)

  local function rootOnShowHook()
    updateSlider(slider)
    updateQuestFrames(main, slider, questFrames)
  end
  root:HookScript('OnShow', rootOnShowHook)
end

--[[--
Initializes event listener for highlighting main data entries
in the GUI.
@function initGUIHandlerMainEntries
@see isQuestHighlighted
]]
local function initGUIHandlerMainEntries(main, slider, questFrames)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))
  assert(#questFrames == MAX_QUEST_FRAMES)

  local function questFrameOnClickCallback(self)
    local isNumber = 'number' == type(self.questId)
    if self.questId ~= nil and isNumber and self.questId > 0 then
      local quest = getQuest(self.questId)
      assert(quest ~= nil)
      assert(isValidQuest(quest))
      if isQuestHighlighted(main, quest) then
        removeHighlight(main, quest)
      else
        addHighlight(main, quest)
      end
      updateQuestFrames(main, slider, questFrames)
    end
  end
  for i = 1, #questFrames do
    local questFrame = questFrames[i]
    questFrame:SetScript('OnClick', questFrameOnClickCallback)
  end
end

--[[--
Initializes an event listener that manages the scroll.
@function initGUIHandlerSlider
@see updateQuestFrames
]]
local function initGUIHandlerSlider(slider, main, questFrames)
  assert(slider ~= nil)
  assert(main ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))

  local function sliderOnValueChangedCallback(self, skipAmount)
    assert(skipAmount == self:GetValue())
    updateQuestFrames(main, slider, questFrames)
  end
  slider:SetScript('OnValueChanged', sliderOnValueChangedCallback)
end

--[[--
@function initGUIHandlerNavAdd
]]
local function initGUIHandlerNavAdd(navAdd, tooltip)
  assert(navAdd ~= nil)
  assert(tooltip ~= nil)

  local function navAddOnClickCallback()
    ShowUIPanel(tooltip)
  end
  navAdd:SetScript('OnClick', navAddOnClickCallback)
end

--[[--
@function initGUIHandlerNavRemove
]]
local function initGUIHandlerNavRemove(navRemove, main, slider, questFrames)
  assert(navRemove ~= nil)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))

  local function navRemoveOnClickCallback()
    local highlights = getHighlights(main)
    for i = 1, #highlights do
      local highlight = highlights[i]
      if highlight ~= nil then
        assert(highlight ~= nil)
        assert('number' == type(highlight))
        assert(highlight > 0)

        local quest = getQuest(highlight)
        assert(quest ~= nil)
        assert(isValidQuest(quest))

        wipeQuest(quest.questId)
      end
    end
    main.highlights = {}
    updateSlider(slider)
    updateQuestFrames(main, slider, questFrames)
  end
  navRemove:SetScript('OnClick', navRemoveOnClickCallback)
end

--[[--
@function initGUIHandlerNavShare
]]
local function initGUIHandlerNavShare(navShare)
  local function navShareOnClickCallback()
    print('TODO')
  end
  navShare:SetScript('OnClick', navShareOnClickCallback)
end

--[[--
@function initGUIHandlerNavClose
]]
local function initGUIHandlerNavClose(navClose, root)
  local function navCloseOnClickCallback()
    HideUIPanel(root)
  end
  navClose:SetScript('OnClick', navCloseOnClickCallback)
end

--[[--
Returns supported quest goal name that was selected in the GUI by the player.
@function getSelectedGoalName
@param string; name of the selected and supported quest goal that is quest type
]]
local function getSelectedGoalName(radioButtons)
  assert(radioButtons ~= nil)
  assert('table' == type(radioButtons))

  local goalName = nil
  local checkedIndex = 0
  local goals = getSupportedQuestGoals()
  local MAX_GOALS = 16
  assert(#radioButtons <= MAX_GOALS)
  assert(#radioButtons == #goals)
  for i = 1, math.min(#radioButtons, MAX_GOALS) do
    local radioButton = radioButtons[i]
    assert(radioButton ~= nil)

    if radioButton:GetChecked() then
      local onlyOneButtonChecked = 0 == checkedIndex
      assert(onlyOneButtonChecked)
      checkedIndex = i
      goalName = goals[i]
    end
  end

  assert(goalName ~= nil)
  assert('string' == type(goalName))

  return goalName
end

--[[--
Initializes even listener that swithces GUI layout representation on demand.
Namely, displays different labels depending on selected quest type,
in the quest creation pop-up frame (tooltip).
@function initGUIHandlerTooltipRadioButtons
]]
local function initGUIHandlerTooltipRadioButtons(tooltip, radioButtons, fields, fieldLabels)
  assert(tooltip ~= nil)

  assert(radioButtons ~= nil)
  assert('table' == type(radioButtons))
  local MAX_GOALS = 16
  assert(#radioButtons <= MAX_GOALS)

  assert(fields ~= nil)
  assert('table' == type(fields))

  assert(fieldLabels ~= nil)
  assert('table' == type(fieldLabels))

  local function checkRadioButton(self)
    assert(self ~= nil)
    for i = 1, math.min(#radioButtons, MAX_GOALS) do
      local radioButton = radioButtons[i]
      assert(radioButton ~= nil)
      local isChecked = self == radioButton
      radioButton:SetChecked(isChecked)
    end
  end

  local function clearGoalPerspective()
    local emptyString = ""
    for i = 1, #fields do
      fields[i]:Hide()
      --[[ Text needs to be cleared to avoid reading corrupt values. ]]--
      fields[i]:SetText(emptyString)
      fields[i]:SetNumeric(false)
    end
    for i = 1, #fieldLabels do
      fieldLabels[i]:SetText(nil)
    end
  end

  local function applyCollectItemGoalPerspective()
    clearGoalPerspective()
    fields[1]:Show()
    fields[2]:Show()
    fields[2]:SetNumeric(true)
    fieldLabels[1]:SetText('Item link')
    fieldLabels[2]:SetText('Item amount')
  end

  local function applyKillUnitGoalPerspective()
    clearGoalPerspective()
    fields[1]:Show()
    fields[2]:Show()
    fields[2]:SetNumeric(true)
    fieldLabels[1]:SetText("Victim's name")
    fieldLabels[2]:SetText('|cff888888Kills amount|r')
  end

  local function applyCastSpellGoalPerspective()
    clearGoalPerspective()
    fields[1]:Show()
    fields[2]:Show()
    fields[2]:SetNumeric(true)
    fields[3]:Show()
    fieldLabels[1]:SetText('Spell link')
    fieldLabels[2]:SetText('Casts amount')
    fieldLabels[3]:SetText("|cff888888Target's name|r")
  end

  local function applySelectedGoalPerspective()
    local selectedGoalName = getSelectedGoalName(radioButtons)
    assert(selectedGoalName ~= nil)
    assert(isSupportedQuestGoal(selectedGoalName))

    if 'CastSpell' == selectedGoalName then
      applyCastSpellGoalPerspective()
    elseif 'CollectItem' == selectedGoalName then
      applyCollectItemGoalPerspective()
    elseif 'KillUnit' == selectedGoalName then
      applyKillUnitGoalPerspective()
    else
      error('Unknown goal perspective to apply.')
    end
  end

  for i = 1, #radioButtons do
    local radioButton = radioButtons[i]
    assert(radioButton ~= nil)
    radioButton:SetScript('OnClick', checkRadioButton)
    radioButton:HookScript('OnClick', applySelectedGoalPerspective)
  end
end

--[[--
Returns values that are currently held by the GUI input boxes.
@function getArgs
]]
local function getArgs(fields)
  local arg0, arg1, arg2, arg3

  if fields[1]:IsNumeric() then
    arg0 = fields[1]:GetNumber()
  else
    arg0 = fields[1]:GetText()
  end

  if fields[2]:IsNumeric() then
    arg1 = fields[2]:GetNumber()
  else
    arg1 = fields[2]:GetText()
  end

  if fields[3]:IsNumeric() then
    arg2 = fields[3]:GetNumber()
  else
    arg2 = fields[3]:GetText()
  end

  if fields[4]:IsNumeric() then
    arg3 = fields[4]:GetNumber()
  else
    arg3 = fields[4]:GetText()
  end

  return arg0, arg1, arg2, arg3
end

--[[--
Initializes an event handler that reads data from the input fields,
and then creates and persists new quests accordingly.
@function initGUIHandlerTooltipNavAccept
@see createQuestSmart
@see getArgs
@see getSelectedGoalName
@see updateProgress
]]
local function initGUIHandlerTooltipNavAccept(navAccept, tooltip, radioButtons, fields, main, slider, questFrames)
  assert(navAccept ~= nil)
  assert(tooltip ~= nil)
  assert(radioButtons ~= nil)
  assert('table' == type(radioButtons))

  local function navAcceptOnClickCallback()
    local selectedGoalName = getSelectedGoalName(radioButtons)
    assert(selectedGoalName ~= nil)
    assert('string' == type(selectedGoalName))

    local newQuest = createQuestSmart(selectedGoalName, getArgs(fields))
    assert(newQuest ~= nil)
    assert(isValidQuest(newQuest))

    if newQuest ~= nil then
      if 'CollectItem' == selectedGoalName then
        updateProgressCollectItem()
      end
      updateQuestFrames(main, slider, questFrames)
      updateSlider(slider)
    end
  end
  navAccept:SetScript('OnClick', navAcceptOnClickCallback)

  return
end

--[[--
@function initGUIHandlerTooltipNavReject
]]
local function initGUIHandlerTooltipNavReject(navReject, tooltip)
  assert(navReject ~= nil)
  assert(tooltip ~= nil)

  local function navRejetOnClickCallback()
    HideUIPanel(tooltip)
  end
  navReject:SetScript('OnClick', navRejetOnClickCallback)

  return
end

--[[ GUI: Init. ]]--

--[[--
Initializes all of the GUI components.
It also acts as a context holder,
ensuring that every GUI piece is granted access to it's dependencies,
and only it's dependencies.
@function initGUI
]]
local function initGUI(givenRoot)
  local root        = initGUIRoot(givenRoot)
  assert(root ~= nil)

  local nav         = initGUINav(root)
  assert(nav ~= nil)

  local navAdd      = initGUINavAdd(nav)
  assert(navAdd ~= nil)

  local navRemove   = initGUINavRemove(nav)
  assert(navRemove ~= nil)

  local navShare    = initGUINavShare(nav)
  assert(navShare ~= nil)

  local navClose    = initGUINavClose(nav)
  assert(navClose ~= nil)

  local main        = initGUIMain(root)
  assert(main ~= nil)

  local questFrames = initGUIMainEntries(main)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))

  local slider      = initGUISlider(root)
  assert(slider ~= nil)

  local tooltip = initGUITooltip(root)
  assert(tooltip ~= nil)

  local fields = initGUITooltipFields(tooltip)
  assert(fields ~= nil)
  assert('table' == type(fields))

  local fieldLabels = initGUITooltipFieldLabels(tooltip, fields)
  assert(fieldLabels ~= nil)
  assert('table' == type(fieldLabels))

  local radioButtons = initGUITooltipRadioButtons(tooltip)
  assert(radioButtons ~= nil)
  assert('table' == type(radioButtons))

  local tooltipNav = initGUITooltipNav(tooltip)
  assert(tooltipNav ~= nil)

  local tooltipNavAccept = initGUITooltipNavAccept(tooltip, tooltipNav)
  assert(tooltipNavAccept ~= nil)

  local tooltipNavReject = initGUITooltipNavReject(tooltip, tooltipNav)
  assert(tooltipNavReject ~= nil)

  initGUIHandlerRoot(root, main, slider, questFrames)
  initGUIHandlerMainEntries(main, slider, questFrames)
  initGUIHandlerSlider(slider, main, questFrames)
  initGUIHandlerTooltipRadioButtons(tooltip, radioButtons, fields, fieldLabels)
  initGUIHandlerTooltipNavAccept(tooltipNavAccept, tooltip, radioButtons, fields,
  main, slider, questFrames
  )
  initGUIHandlerTooltipNavReject(tooltipNavReject, tooltip)
  initGUIHandlerNavAdd(navAdd, tooltip)
  initGUIHandlerNavRemove(navRemove, main, slider, questFrames)
  initGUIHandlerNavShare(navShare)
  initGUIHandlerNavClose(navClose, root)

  --[[
  http://wowwiki.wikia.com/wiki/API_ChatFrame_OnHyperlinkShow
  http://wowwiki.wikia.com/wiki/Hooking_functions
  ]]--
  local function onChatItemLinkClickUpdateEditBox(self, itemString, itemLink, button)
    assert(fields ~= nil)
    assert('table' == type(fields))

    assert(self ~= nil)
    assert('table' == type(self))

    assert(itemString ~= nil)
    assert('string' == type(itemString))

    assert(itemLink ~= nil)
    assert('string' == type(itemLink))

    assert(button ~= nil)
    assert('string' == type(button))

    for i = 1, #fields do
      local field = fields[i]
      assert(field ~= nil)
      if field:HasFocus() then
        field:SetText(itemLink)
      end
    end
  end
  hooksecurefunc('ChatFrame_OnHyperlinkShow', onChatItemLinkClickUpdateEditBox)

  updateSlider(slider)
  updateQuestFrames(main, slider, questFrames)
end

--[[ CLI. ]]--

local function initCLI()
  --[[ TODO ]]--
end


--[[--
Initialization.
@section init
]]

local bquest = CreateFrame('FRAME', 'BQuest', UIParent) or {}

local function initErrorHandler()
  --[[
    See http://wowwiki.wikia.com/wiki/Creating_simple_pop-up_dialog_boxes
  ]]--
  StaticPopupDialogs['BQUEST_ERROR'] = {
    text = 'Empty error message.',
    button1 = 'Close',
    OnAccept = function()
      StaticPopupDialogs['BQUEST_ERROR'].text = 'Empty error message.'
    end,
    timeout = 32,
    whileDead = true,
    hideOnEscape = true,
    --[[
      avoid some UI taint,
      See http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
    ]]--
    preferredIndex = 3,
  }

  local function logError(errorMessage)
    if nil == BQuestErrors or 'table' ~= type(BQuestErrors) then
      BQuestErrors = {}
    end
    local logEntry = {
      player = UnitName('player'),
      realm = GetRealmName(),
      message = errorMessage,
      date = date()
    }
    tinsert(BQuestErrors, logEntry)
  end

  local function showErrorPopupWithMessage(givenMessage)
    StaticPopupDialogs['BQUEST_ERROR'].text = givenMessage
    StaticPopup_Show('BQUEST_ERROR')
  end

  local oldErrorHandler = geterrorhandler()
  local function errorHandlerCallback(errorMessage, ...)
    logError(errorMessage)

    showErrorPopupWithMessage(errorMessage)

    oldErrorHandler(errorMessage, ...)
  end
  seterrorhandler(errorHandlerCallback)
end

--[[--
Initializes all of the add-on.
It must be called after the persistence mechanism is loaded.
@function init
@see initGUI
]]
local function init(self)
  initGUI(self)
  initAPI(self)
  initCLI(self)
  initErrorHandler()
end

bquest:RegisterEvent("ADDON_LOADED")
local function bquestOnAddonLoadedCallback(self, event)
  if 'ADDON_LOADED' == event then
    self:UnregisterAllEvents()
    init(self)
  end
end
bquest:SetScript('OnEvent', bquestOnAddonLoadedCallback)

bquest:Hide()
