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

local getSupportedQuestGoals = function()
  return {
	'CollectItem', 'DeliverItem', 'KillUnit', 
	'LearnSkill', 'UseSkill'
  }
end


--[[--
  Core.
  @section core
]]

--[[--
  Check if goal of given name is supported by the rest of the add-on.
  @function isSupportedQuestGoal
  @param targetGoalName non-nil string that is goal name to be checked
  @return boolean true if `targetGoalName` was found in `supportedGoals` table;
    false otherwise.
]]
local isSupportedQuestGoal = function(targetGoalName)
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

local questPrototypeCollectItem = function(givenItemId, givenItemAmount)
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

local questPrototypeDeliverItem = function(givenItemId, givenItemAmount, givenAddresseeUnitName)
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

local questPrototypeKillUnit = function(givenVictimUnitName, givenOptionalKillsAmount)
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

local questPrototypeLearnSkill = function(givenSkillId)
  assert(givenSkillId ~= nil)
  assert("number" == type(givenSkillId))
  assert(givenSkillId > 0)
  
  return {
    goalName = 'LearnSkill',
    skillId = math.ceil(givenSkillId)
  }
end

local questPrototypeUseSkill = function(givenSkillId, givenUsagesAmount, givenOptionalTargetUnitName)
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

local isValidQuest = function(givenQuest)
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
    result = "string" == type(value) or "number" == type(value) or ("table" == type(value) and "createdDateTable" == attribute) and result
    if not result then 
      optionalErrorMessage = 'Only string and number and creation date values are allowed.' 
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

local createQuest = function(questPrototype)
  local newQuest = {}
  
  newQuest.createdDateTable = date("*t")
  local d = newQuest.createdDateTable
  newQuest.questId = math.ceil(string.format('%04d%02d%02d%04d', d.year, d.month, d.day, math.random(1, 9999)))
  newQuest.realmName = GetRealmName()
  
  if UnitName ~= nil and "function" == type(UnitName) then
    local assumedAuthor = UnitName("player")
    if assumedAuthor ~= nil and "string" == type(assumedAuthor) and string.len(assumedAuthor) > 3 then
      newQuest.author = assumedAuthor
    end
  end
  
  for attribute, value in pairs(questPrototype) do
    newQuest[attribute] = value
  end
  
  assert(isValidQuest(newQuest))
  
  return newQuest
end


--[[--
  Persistence.
  @section persistence
]]

BQuestSavedVariables = {}
local persistQuest = function(givenQuest)
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
  for questId, quest in pairs(persistedQuests) do
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

local wipeQuest = function(givenQuestId)
  assert(givenQuestId ~= nil)
  assert("number" == type(givenQuestId))
  assert(givenQuestId > 0)
  
  local questExisted = false
  local questWiped = false
  
  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end
  for nextQuestId, nextQuest in pairs(BQuestSavedVariables.quests) do
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

local createQuestSmart = function(givenGoalName, ...)
  --[[ TODO When given invalid entity name or id, fail early, that is __here__. ]]--
  assert(isSupportedQuestGoal(givenGoalName))
  
  local newQuest = nil
  local optionalErrorMessage = nil
  
  if 'CollectItem' == givenGoalName then
    newQuest, optionalErrorMessage = createQuest(questPrototypeCollectItem(...))
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

local getQuestsMap = function()
  if nil == BQuestSavedVariables then
    BQuestSavedVariables = {}
  end
  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end
  return BQuestSavedVariables.quests
end

local getQuest = function(questId)
  assert(questId ~= nil)
  assert('number' == type(questId))
  assert(questId > 0)
  
  local quests = getQuestsMap()
  local quest = quests[questId]
  
  assert(quest == nil or isValidQuest(quest))
  
  return quest
end

local getQuestsSet = function()
  local questsSet = {}
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  for questId, quest in pairs(getQuestsMap()) do
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

local getQuestProgress = function(questId)
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

local skip = function(targetTable, skipAmount)
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
  for k, v in pairs(targetTable) do
    if skipped == skipAmount and v ~= nil then
      tinsert(filtered, v)
    else
      skipped = skipped + 1
    end
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end
  
  assert(filtered ~= nil)
  assert('table' == type(filtered))
  assert(#filtered == math.max(#targetTable - skipAmount, 0), string.format('%d ~= max(%d, %d)', #filtered, #targetTable - skipAmount, 0))
  
  return filtered
end

local take = function(targetTable, takeAmount)
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
  for k, v in pairs(targetTable) do
    if taken < takeAmount and v ~= nil then
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

local requestItemName = function(itemId)
  assert(itemId ~= nil)
  assert("number" == type(itemId))
  itemId = math.ceil(itemId)
  
  local itemName = GetItemInfo(itemId)
  assert(itemName ~= nil)
  assert("string" == type(itemName))
  return itemName
end

local requestPlayerItems = function()
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
  
local getQuestDescription = function(givenQuest, givenProgress)
  assert(isValidQuest(givenQuest))
  assert(givenProgress ~= nil)
  assert("table" == type(givenProgress))
    
  local questDescription = nil
  if 'CollectItem' == givenQuest.goalName then
    local itemName = requestItemName(givenQuest.itemId)
    local itemAmount = givenProgress.itemAmount or 0
    questDescription = string.format('Collect %d of %s (%d collected).', givenQuest.itemAmount, itemName, itemAmount)
  else
    questDescription = string.format("Goal: %s. Progress is unknown.", givenQuest.goalName)
  end
   
  assert(questDescription ~= nil)
  assert("string" == type(questDescription))
  return questDescription
end


--[[--
  Command processing.
  @section commands
]]

local forQuests = function(callback)
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  for questId, quest in pairs(getQuestsMap()) do
    assert(isValidQuest(quest))
    callback(quest)
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end
end

local updateProgress = function(callback)
  forQuests(function(quest)
    local progress = getQuestProgress(quest.questId)
    callback(quest, progress)
    BQuestSavedVariables.progress[quest.questId] = progress
  end)
end

local updateProgressCollectItem = function()
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

local initAPI = function(self)    
  self.getSupportedQuestGoals = getSupportedQuestGoals
  self.isSupportedGoal = isSupportedGoal
  self.isValidQuest = isValidQuest
  self.createQuestSmart = createQuestSmart
  self.wipeQuest = wipeQuest
  BQuest = self
  
  self:RegisterEvent('BAG_UPDATE')
  self:SetScript('OnEvent', function(self, event, ...)
    if 'BAG_UPDATE' == event then
      updateProgressCollectItem()
    end
  end)
end


--[[--
  GUI.
  @section gui
]]

--[[ GUI: Constants. ]]--

local getDefaultBQuestBackdrop = function()
  return {
    bgFile   = [[Interface\Dialogframe\ui-dialogbox-background]],
    edgeFile = [[Interface\Dialogframe\ui-dialogbox-border]],
    tile     = true,
    tileSize = 32,
    edgeSize = 32,
    insets   = {left = 8, right = 8, top = 8, bottom = 8}
  }
end

local getTooltipBQuestBackdrop = function()
  return {
    bgFile   = [[Interface\Tooltips\ui-tooltip-background]],
    edgeFile = [[Interface\Tooltips\ui-tooltip-border]],
    tile     = true,
    tileSize = 32,
    edgeSize = 16,
    insets   = {left = 4, right = 4, top = 4, bottom = 4}
  }
end

local getQuestBQuestBackdrop = function()
  return {
    bgFile   = [[Interface\Dialogframe\ui-dialogbox-background]],
    edgeFile = [[Interface\Tooltips\ui-tooltip-border]],
    tile     = true,
    tileSize = 32,
    edgeSize = 16,
    insets   = {left = 4, right = 4, top = 4, bottom = 4}
  }
end

local getQuestHighlightBQuestBackdrop = function()
  local b = getQuestBQuestBackdrop()
  b.bgFile = [[Interface\Dialogframe\ui-dialogbox-gold-background]]
  return b
end

local indent = 16

local MAX_QUEST_FRAMES = 8

local GUI_INDENT = 16

local GUI_ROOT_WIDTH  = 512
local GUI_ROOT_HEIGHT = 512

local GUI_MAIN_WIDTH  = GUI_ROOT_WIDTH  - GUI_INDENT * 2
local GUI_MAIN_HEIGHT = GUI_ROOT_HEIGHT - GUI_INDENT * 2

local GUI_SLIDER_WIDTH  = 16
local GUI_SLIDER_HEIGHT = GUI_MAIN_HEIGHT

local GUI_NAV_WIDTH  = GUI_ROOT_WIDTH
local GUI_NAV_HEIGHT = 40

--[[local GUI_NAV_BUTTON_WIDTH  = GUI_NAV_WIDTH / 8]]--
local GUI_NAV_BUTTON_HEIGHT = 20

--[[ GUI: Static. ]]--

local initGUIRoot = function(root)
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

local initGUIMain = function(root)
  local mainParent = root
  local main = CreateFrame('FRAME', mainParent:GetName() .. 'Main', mainParent)
  main:SetPoint("RIGHT",  mainParent, "RIGHT",  -GUI_SLIDER_WIDTH-indent, 0)
  main:SetPoint("TOP",    mainParent, "TOP",    0, -indent)
  main:SetPoint("LEFT",   mainParent, "LEFT",   indent, 0)
  main:SetPoint("BOTTOM", mainParent, "BOTTOM", 0, GUI_NAV_HEIGHT+indent)
  main.highlights = {}
  
  return main
end

local createQuestFrame = function(main, questParent, newQuestFrameId)
  assert(questParent ~= nil)
    
  local questHeight = questParent:GetHeight() / MAX_QUEST_FRAMES
 
  local newQuestFrame = CreateFrame("BUTTON", questParent:GetName() .. "Quest" .. newQuestFrameId, questParent, "SecureHandlerClickTemplate")
  newQuestFrame:SetWidth(questParent:GetWidth())
  newQuestFrame:SetHeight(questHeight)
  newQuestFrame:SetPoint("RIGHT",  questParent, "RIGHT", 0, 0)
  newQuestFrame:SetPoint("TOP",    questParent, "TOP",   0, -questHeight*(newQuestFrameId-1))
  newQuestFrame:SetPoint("LEFT",   questParent, "LEFT",  0, 0)
  newQuestFrame:SetPoint("BOTTOM", questParent, "TOP",   0, -questHeight*(newQuestFrameId))
  local b0 = getQuestBQuestBackdrop()
  b0.bgFile = nil
  newQuestFrame:SetBackdrop(b0)
  
  local fontFrame = newQuestFrame:CreateFontString(newQuestFrame:GetName() .. "Text", "OVERLAY", "GameFontWhite")
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

local initGUIMainEntries = function(main)
  local mainEntries = {}
  for i = 1, MAX_QUEST_FRAMES do
    tinsert(mainEntries, createQuestFrame(main, main, i))
  end
  return mainEntries
end

local initGUISlider = function(root)
  local sliderParent = root
  local slider = CreateFrame('SLIDER', sliderParent:GetName() .. 'Slider', sliderParent, 'OptionsSliderTemplate')
  slider:SetValue(0)
  slider:SetValueStep(MAX_QUEST_FRAMES)
  slider:SetWidth(GUI_SLIDER_WIDTH)
  slider:SetHeight(GUI_SLIDER_HEIGHT)
  slider:SetPoint("RIGHT",  sliderParent, "RIGHT",  -indent, 0)
  slider:SetPoint("TOP",    sliderParent, "TOP",    0, -indent)
  slider:SetPoint("LEFT",   sliderParent, "RIGHT",   -GUI_SLIDER_WIDTH-indent, 0)
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
  
local initGUINavAdd = function(nav)
  local navAdd = CreateFrame('BUTTON', nav:GetName() .. 'Add', nav, 'UIPanelButtonTemplate')
  navAdd:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navAdd:SetPoint('LEFT', nav:GetWidth()/5-navAdd:GetWidth()/2, 0)
  navAdd:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navAdd:GetHeight()/2)
  local navAddText = _G[navAdd:GetName() .. 'Text']
  navAddText:SetText('Add')
  navAdd:Show()
  
  return navAdd
end

local initGUINavRemove = function(nav)
  local navRemove = CreateFrame('BUTTON', nav:GetName() .. 'Remove', nav, 'UIPanelButtonTemplate')
  navRemove:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navRemove:SetPoint('LEFT', nav:GetWidth()/5*2-navRemove:GetWidth()/2, 0)
  navRemove:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navRemove:GetHeight()/2)
  local navRemoveText = _G[navRemove:GetName() .. 'Text']
  navRemoveText:SetText('Remove')
  navRemove:Show()
  
  return navRemove
end

local initGUINavShare = function(nav)
  local navShare = CreateFrame('BUTTON', nav:GetName() .. 'Share', nav, 'UIPanelButtonTemplate')
  navShare:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navShare:SetPoint('LEFT', nav:GetWidth()/5*3-navShare:GetWidth()/2, 0)
  navShare:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navShare:GetHeight()/2)
  local navShareText = _G[navShare:GetName() .. 'Text']
  navShareText:SetText('Share')
  navShare:Show()
  
  return navShare
end

local initGUINavClose = function(nav)
  local navClose = CreateFrame('BUTTON', nav:GetName() .. 'Close', nav, 'UIPanelButtonTemplate')
  navClose:SetSize(nav:GetWidth()/8, GUI_NAV_BUTTON_HEIGHT)
  navClose:SetPoint('LEFT', nav:GetWidth()/5*4-navClose:GetWidth()/2, 0)
  navClose:SetPoint('BOTTOM', 0, nav:GetHeight()/2-navClose:GetHeight()/2)
  local navCloseText = _G[navClose:GetName() .. 'Text']
  navCloseText:SetText('Close')
  navClose:Show()
  
  return navClose
end

local initGUINav = function(root)
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

--[[ GUI: Handlers. ]]--

local updateSlider = function(slider)
  assert(slider ~= nil)
  
  local quests = getQuestsSet()
  slider:SetMinMaxValues(0, math.max(#quests-1, 0))
end  

local getHighlights = function(main)
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

local isQuestHighlighted = function(main, givenQuest)
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

local addHighlight = function(main, givenQuest)
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

local removeHighlight = function(main, givenQuest)
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

local updateQuestFrame = function(main, givenFrame, givenQuest, givenProgress)
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
  
local cleanQuestFrame = function(main, givenFrame)
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
  
local updateQuestFrames = function(main, slider, questFrames)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))
  
  local quests = getQuestsSet()
  skipAmount = math.max(math.min(slider:GetValue(), #quests-#questFrames), 0)
    
  local afterSkip = skip(quests, skipAmount)
  assert((#afterSkip == #quests - skipAmount) or (#afterSkip == 0 and #quests == 0))
    
  local afterTake = take(afterSkip, #questFrames)
  assert((#afterTake == math.min(#questFrames, #afterSkip)) or (#afterTake == 0 and #afterSkip == 0))
    
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

local show = function()
  ShowUIPanel(BQuest)
end

local hide = function()
  HideUIPanel(BQuest)
end

local initGUIHandlerRoot = function(root, main, slider, questFrames)
  assert(root ~= nil)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))
  
  root:HookScript('OnShow', function(self, ...)
    updateSlider(slider)
    updateQuestFrames(main, slider, questFrames)
  end)
end

local initGUIHandlerMain = function(main)
  return nil
end

local initGUIHandlerMainEntries = function(main, slider, questFrames)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))
  assert(#questFrames == MAX_QUEST_FRAMES)
  
  for i = 1, #questFrames do
    local questFrame = questFrames[i]
    questFrame:SetScript('OnClick', function(self, event, ...)
      if self.questId ~= nil and 'number' == type(self.questId) and self.questId > 0 then
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
    end)
  end
end

local initGUIHandlerSlider = function(slider, main, questFrames)
  assert(slider ~= nil)
  assert(main ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))
  
  slider:SetScript('OnValueChanged', function(self, skipAmount, ...)
    assert(skipAmount == self:GetValue())
    updateQuestFrames(main, slider, questFrames) 
  end)
end  

local initGUIHandlerNavAdd = function(navAdd)  
  navAdd:SetScript('OnClick', function(self, event, ...)
    print('TODO')
  end)
end

local initGUIHandlerNavRemove = function(navRemove, main, slider, questFrames)
  assert(navRemove ~= nil)
  assert(main ~= nil)
  assert(slider ~= nil)
  assert(questFrames ~= nil)
  assert('table' == type(questFrames))
  
  navRemove:SetScript('OnClick', function(self, event, ...)
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
  end)
end

local initGUIHandlerNavShare = function(navShare)
  navShare:SetScript('OnClick', function(self, event, ...)
    print('TODO')
  end)
end

local initGUIHandlerNavClose = function(navClose, root)
  navClose:SetScript('OnClick', function(self, event, ...)
    root:Hide()
  end)
end

--[[ GUI: Init. ]]--

local initGUI = function(self)
  local root        = initGUIRoot(self)
  local nav         = initGUINav(root)
  local navAdd      = initGUINavAdd(nav)
  local navRemove   = initGUINavRemove(nav)
  local navShare    = initGUINavShare(nav)
  local navClose    = initGUINavClose(nav)
  local main        = initGUIMain(root)
  local questFrames = initGUIMainEntries(main)
  local slider      = initGUISlider(root)
  initGUIHandlerRoot(root, main, slider, questFrames)
  initGUIHandlerMain(main)
  initGUIHandlerMainEntries(main, slider, questFrames)
  initGUIHandlerSlider(slider, main, questFrames)
  initGUIHandlerNavAdd(navAdd)
  initGUIHandlerNavRemove(navRemove, main, slider, questFrames)
  initGUIHandlerNavShare(navShare)
  initGUIHandlerNavClose(navClose, root)
  
  updateSlider(slider)
  updateQuestFrames(main, slider, questFrames)
end

--[[ CLI. ]]--

local initCLI = function(self)
  --[[ TODO ]]--
end


--[[--
  Initialization.
  @section init
]]

local bquest = CreateFrame('FRAME', 'BQuest', UIParent) or {}

local init = function(self)
  initGUI(self)
  initAPI(self)
  initCLI(self)
end

bquest:RegisterEvent("ADDON_LOADED")
bquest:SetScript('OnEvent', function(self, event, ...)
  if 'ADDON_LOADED' == event then
    self:UnregisterAllEvents()
    init(self)
  end
end)

bquest:Hide()