--[[--
BQuest add-on for World of Warcraft: Wrath of the Lich King game.
@script bquest
]]

--[[--
Constants.
@section constants
]]
local MAX_ATTRIBUTES = 8
local MAX_QUESTS = 256

local function getSupportedQuestGoals()
  return {
    'CollectItem', 'KillUnit', 'UseSkill'
  }
end


--[[--
Core.
Add-on logic, ignorant of the GUI or CLI or environment it's executed it.
@section core
]]

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

local function questPrototypeCollectItem(givenItemId, givenItemAmount)
  assert(givenItemId ~= nil)
  assert("number" == type(givenItemId))
  assert(givenItemId > 0)
  assert(givenItemAmount ~= nil)
  assert("number" == type(givenItemAmount))
  assert(givenItemAmount >= 1)

  return {
    goalName = 'CollectItem',
    itemId = math.ceil(givenItemId),
    itemAmount = math.max(math.ceil(givenItemAmount), 1)
  }
end

local function questPrototypeDeliverItem(givenItemId, givenItemAmount, givenAddresseeUnitName)
  assert(givenItemId ~= nil)
  assert("number" == type(givenItemId))
  assert(givenItemId > 0)
  assert(givenItemAmount ~= nil)
  assert("number" == type(givenItemAmount))
  assert(givenItemAmount >= 1)
  assert(givenAddresseeUnitName ~= nil)
  assert("string" == type(givenAddresseeUnitName))
  assert(string.len(givenAddresseeUnitName) >= 3)

  return {
    goalName = 'DeliverItem',
    itemId = math.ceil(givenItemId),
    itemAmount = math.ceil(math.max(givenItemAmount, 1)),
    addresseeUnitName = givenAddresseeUnitName
  }
end

local function questPrototypeKillUnit(givenVictimUnitName, givenOptionalKillsAmount)
  assert(givenVictimUnitName ~= nil)
  assert("string" == type(givenVictimUnitName))
  assert(string.len(givenVictimUnitName) >= 3)
  if nil == givenOptionalKillsAmount then
    givenOptionalKillsAmount = 1
  end
  assert(givenOptionalKillsAmount ~= nil)
  assert("number" == type(givenOptionalKillsAmount))
  assert(givenOptionalKillsAmount >= 1)

  return {
    goalName = 'KillUnit',
    victimUnitName = givenVictimUnitName,
    killsAmount = math.ceil(math.max(givenOptionalKillsAmount, 1))
  }
end

local function questPrototypeLearnSkill(givenSkillId)
  assert(givenSkillId ~= nil)
  assert("number" == type(givenSkillId))
  assert(givenSkillId > 0)

  return {
    goalName = 'LearnSkill',
    skillId = math.ceil(givenSkillId)
  }
end

local function questPrototypeUseSkill(givenSkillId, givenUsagesAmount, givenOptionalTargetUnitName)
  assert(givenSkillId ~= nil)
  assert("number" == type(givenSkillId))
  assert(givenSkillId > 0)
  assert(givenUsagesAmount ~= nil)
  assert("number" == type(givenUsagesAmount))
  assert(givenUsagesAmount >= 1)

  if givenOptionalTargetUnitName ~= nil then
    assert(givenOptionalTargetUnitName ~= nil)
    assert("string" == type(givenOptionalTargetUnitName))
    assert(string.len(givenOptionalTargetUnitName) >= 3)
  end

  local result = {
    goalName = 'UseSkill',
    skillId = math.ceil(givenSkillId),
    usagesAmount = math.ceil(givenUsagesAmount)
  }

  if givenOptionalTargetUnitName ~= nil then
    result.optionalTargetUnitName = givenOptionalTargetUnitName
  end

  return result
end

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

local function createQuest(questPrototype)
  local newQuest = {}

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
  for attribute, value in pairs(questPrototype) do
    newQuest[attribute] = value
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed <= operationsLimit)
  end

  assert(newQuest ~= nil)
  assert(isValidQuest(newQuest))

  return newQuest
end


--[[--
Persistence.
@section persistence
]]

BQuestSavedVariables = {}
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

--[[ Core: progress. ]]--

--[[ TODO ]]--

--[[ Public API. ]]--

local function createQuestCollectItem(itemId, itemAmount)
  return createQuest(questPrototypeCollectItem(itemId, itemAmount))
end

local function getItemIdFromItemLink(itemLink)
  --[[ http://wowwiki.wikia.com/wiki/ItemLink ]]--
  local exp = "|?c?f?f?(%x*)"
  exp = exp .. "|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*)"
  exp = exp .. ":?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)"
  exp = exp .. "|?h?%[?([^%[%]]*)%]?|?h?|?r?"
  local _, _, _, _, Id = string.find(itemLink, exp)
  return tonumber(Id)
end

local function createQuestSmart(givenGoalName, ...)
  --[[
  TODO
  When given invalid entity name or id,
  fail early, that is __here__.
  ]]--
  assert(isSupportedQuestGoal(givenGoalName))

  local newQuest = nil
  local optionalErrorMessage

  if 'CollectItem' == givenGoalName then
    local itemLink = select(1, ...)
    assert(itemLink ~= nil, 'Cannot find the item.')
    assert('string' == type(itemLink))

    local itemId = getItemIdFromItemLink(itemLink)
    assert(itemId ~= nil)
    assert('number' == type(itemId), 'Expected item identifier. Got: ' .. itemId)
    assert(itemId >= 1 and itemId <= 999999)

    local template = 'Cannot find the item concept "%s" (%d).'
    local itemConceptMissingErr = string.format(template, itemLink, itemId)
    assert(GetItemInfo(itemId) ~= nil, itemConceptMissingErr)

    local itemAmount = select(2, ...)
    itemAmount = tonumber(itemAmount)
    assert(itemAmount ~= nil)
    if 'number' ~= type(itemAmount) then
      itemAmount = 0
    end
    itemAmount = math.max(math.min(itemAmount, 1024), 0)
    itemAmount = math.ceil(itemAmount)

    newQuest, optionalErrorMessage = createQuestCollectItem(itemId, itemAmount)
  elseif 'DeliverItem' == givenGoalName then
    newQuest, optionalErrorMessage = createQuest(questPrototypeDeliverItem(...))
  elseif 'KillUnit'  == givenGoalName then
    newQuest, optionalErrorMessage = createQuest(questPrototypeKillUnit(...))
  elseif 'LearnSkill' == givenGoalName then
    newQuest, optionalErrorMessage = createQuest(questPrototypeLearnSkill(...))
  elseif 'UseSkill' == givenGoalName then
    newQuest, optionalErrorMessage = createQuest(questPrototypeUseSkill(...))
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
@section queries
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

local function getQuest(questId)
  assert(questId ~= nil)
  assert('number' == type(questId))
  assert(questId > 0)

  local quests = getQuestsMap()
  local quest = quests[questId]

  assert(quest == nil or isValidQuest(quest))

  return quest
end

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

local function requestItemName(itemId)
  assert(itemId ~= nil)
  assert("number" == type(itemId))
  itemId = math.ceil(itemId)

  local itemName = GetItemInfo(itemId)
  assert(itemName ~= nil)
  assert("string" == type(itemName))
  return itemName
end

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

local function getQuestDescription(givenQuest, givenProgress)
  assert(isValidQuest(givenQuest))
  assert(givenProgress ~= nil)
  assert("table" == type(givenProgress))

  local questDescription
  if 'CollectItem' == givenQuest.goalName then
    local itemName = requestItemName(givenQuest.itemId)
    local itemAmount = givenProgress.itemAmount or 0
    questDescription = string.format('Collect %d of %s (%d collected).',
    givenQuest.itemAmount, itemName, itemAmount)
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
@section commands
]]

--[[ TODO Refactor and remove callbacks. ]]--
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

local function updateProgress(callback)
  forQuests(function(quest)
  local progress = getQuestProgress(quest.questId)
  callback(quest, progress)
  BQuestSavedVariables.progress[quest.questId] = progress
  end)
end

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

--[[ TODO ]]--

--[[ API. ]]--

local function initAPI(root)
  root.getSupportedQuestGoals = getSupportedQuestGoals
  root.isSupportedQuestGoal = isSupportedQuestGoal
  root.isValidQuest = isValidQuest
  root.createQuestSmart = createQuestSmart
  root.wipeQuest = wipeQuest

  root:RegisterEvent('BAG_UPDATE')
  local function rootCallback(self, event)
    assert(self ~= nil)
    if 'BAG_UPDATE' == event then
      updateProgressCollectItem()
    end
  end
  root:SetScript('OnEvent', rootCallback)
end


--[[--
GUI.
@section gui
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

local function initGUIMainEntries(main)
  local mainEntries = {}
  for i = 1, MAX_QUEST_FRAMES do
    tinsert(mainEntries, createQuestFrame(main, i))
  end
  return mainEntries
end

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

local function updateSlider(slider)
  assert(slider ~= nil)

  local quests = getQuestsSet()
  slider:SetMinMaxValues(0, math.max(#quests-1, 0))
end

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

local function initGUIHandlerRoot(root, main, slider, questFrames)
  assert(root ~= nil)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))

  local function rootOnShowHook()
    updateSlider(slider)
    updateQuestFrames(main, slider, questFrames)
  end
  root:HookScript('OnShow', rootOnShowHook)
end

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

local function initGUIHandlerNavAdd(navAdd, tooltip)
  assert(navAdd ~= nil)
  assert(tooltip ~= nil)

  local function navAddOnClickCallback()
    ShowUIPanel(tooltip)
  end
  navAdd:SetScript('OnClick', navAddOnClickCallback)
end

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

local function initGUIHandlerNavShare(navShare)
  local function navShareOnClickCallback()
    print('TODO')
  end
  navShare:SetScript('OnClick', navShareOnClickCallback)
end

local function initGUIHandlerNavClose(navClose, root)
  local function navCloseOnClickCallback()
    HideUIPanel(root)
  end
  navClose:SetScript('OnClick', navCloseOnClickCallback)
end

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
    for i = 1, #fields do
      fields[i]:Hide()
    end
    for i = 1, #fieldLabels do
      fieldLabels[i]:SetText(nil)
    end
  end

  local function applyCollectItemGoalPerspective()
    clearGoalPerspective()
    fields[1]:Show()
    fields[2]:Show()
    fieldLabels[1]:SetText('Item link')
    fieldLabels[2]:SetText('Item amount')
  end

  local function applyKillUnitGoalPerspective()
    clearGoalPerspective()
    fields[1]:Show()
    fields[2]:Show()
    fieldLabels[1]:SetText("Target's name")
    fieldLabels[2]:SetText('Kills amount')
  end

  local function applyUseSkillGoalPerspective()
    clearGoalPerspective()
    fields[1]:Show()
    fields[2]:Show()
    fields[3]:Show()
    fieldLabels[1]:SetText('Skill link')
    fieldLabels[2]:SetText('Uses amount')
    fieldLabels[3]:SetText("|cff888888Target's name|r")
  end

  local function applySelectedGoalPerspective()
    local selectedGoalName = getSelectedGoalName(radioButtons)
    assert(selectedGoalName ~= nil)
    assert(isSupportedQuestGoal(selectedGoalName))

    if 'CollectItem' == selectedGoalName then
      applyCollectItemGoalPerspective()
    elseif 'KillUnit' == selectedGoalName then
      applyKillUnitGoalPerspective()
    elseif 'UseSkill' == selectedGoalName then
      applyUseSkillGoalPerspective()
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

local function getArgs(fields)
  return fields[1]:GetText(), fields[2]:GetText(),
  fields[3]:GetText(), fields[4]:GetText()
end

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

local function init(self)
  initGUI(self)
  initAPI(self)
  initCLI(self)
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
