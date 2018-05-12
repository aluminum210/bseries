--[[ Constants. ]]--
local MAX_QUEST_FRAMES = 8
local MAX_ATTRIBUTES = 8
local MAX_QUESTS = 256

--[[ Core: quests. ]]--

local getSupportedQuestGoals = function()
  return {
	'CollectItem', 'DeliverItem', 'KillUnit', 
	'LearnSkill', 'UseSkill'
  }
end

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

--[[ Persistence. ]]--

BQuestSavedVariables = {}
local persistQuest = function(givenQuest)
  assert(isValidQuest(givenQuest))
  
  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end
  
  local persistedQuests = BQuestSavedVariables.quests
  
  local optionalErrorMessage = nil
  if nil == persistedQuests[givenQuest.questId] then
    local givenCreatedDateTable = givenQuest.createdDateTable 
    givenQuest.createdDateTable = date("*t", time(givenCreatedDateTable))
    
    persistedQuests[givenQuest.questId] = givenQuest
  elseif persistedQuests[givenQuest.questId] ~= nil and isValidQuest(persistedQuests[givenQuest.questId]) then
    optionalErrorMessage = "Quest already exists. Try creating and persisting another quest with the same attributes."
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

--[[ Query processing. ]]--

local getQuests = function()
  if nil == BQuestSavedVariables then
    BQuestSavedVariables = {}
  end
  if nil == BQuestSavedVariables.quests then
    BQuestSavedVariables.quests = {}
  end
  return BQuestSavedVariables.quests
end

local getQuestsSet = function()
  local questsSet = {}
  for questId, quest in pairs(getQuests()) do
    assert(isValidQuest(quest))
    tinsert(questsSet, quest)
  end
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
    if skipped >= skipAmount and v ~= nil then
      filtered[k] = v
    end
    skipped = skipped + 1
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end
  
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
    if taken <= takeAmount and v ~= nil then
      filtered[k] = v
    end
    taken = taken + 1
    operationsPerformed = operationsPerformed + 1
    assert(operationsPerformed < operationsLimit, 'Operations limit exceeded.')
  end
  
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

--[[ Command processing. ]]--

local forQuests = function(callback)
  local operationsLimit = MAX_QUESTS
  local operationsPerformed = 0
  for questId, quest in pairs(getQuests()) do
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

--[[ GUI. ]]--

local initGUI = function(self)
  self:SetWidth(512)
  self:SetHeight(640)
  self:SetBackdrop(StaticPopup1:GetBackdrop())
  self:SetPoint("CENTER", 0, 0)

  local indent = 16
  local questFrames = {}
  local h = self:GetHeight() / MAX_QUEST_FRAMES
  local createQuestFrame = function(questFramesContainer)
    assert(questFramesContainer ~= nil)
    assert(#questFrames <= MAX_QUEST_FRAMES)
  
    local newQuestFrameId = #questFrames + 1
    local newQuestFrame = CreateFrame("FRAME", questFramesContainer:GetName() .. "Quest" .. newQuestFrameId, questFramesContainer)
    newQuestFrame:SetWidth(questFramesContainer:GetWidth())
    newQuestFrame:SetHeight(h)
    newQuestFrame:SetPoint("RIGHT", questFramesContainer, "RIGHT", -indent, 0)
    newQuestFrame:SetPoint("TOP", questFramesContainer, "TOP", 0, -h*(newQuestFrameId-1)-indent)
    newQuestFrame:SetPoint("LEFT", questFramesContainer, "LEFT", indent, 0)
    newQuestFrame:SetPoint("BOTTOM", questFramesContainer, "TOP", 0, -h*(newQuestFrameId)-indent)
    local fontFrame = newQuestFrame:CreateFontString(newQuestFrame:GetName() .. "Name", "OVERLAY", "GameFontWhite")
    fontFrame:SetAllPoints()
    fontFrame:SetText('Text is missing.')
    fontFrame:Show()
    newQuestFrame.fontFrame = fontFrame
    newQuestFrame:Show()
  
    return newQuestFrame
  end
  for i = 1, MAX_QUEST_FRAMES do
    tinsert(questFrames, createQuestFrame(self))
  end
  self.questFrames = questFrames
  
  local getQuestDescription = function(givenQuest, givenProgress)
    assert(isValidQuest(givenQuest))
    assert(givenProgress ~= nil)
    assert("table" == type(givenProgress))
    
    local questDescription = nil
    if 'CollectItem' == givenQuest.goalName then
      local itemName = requestItemName(givenQuest.itemId)
      questDescription = string.format('Collect %d of %s (%d collected).', givenQuest.itemAmount, itemName, givenProgress.itemAmount)
    else
      questDescription = string.format("Goal: %s. Progress is unknown.", givenQuest.goalName)
    end
    
    assert(questDescription ~= nil)
    assert("string" == type(questDescription))
    return questDescription
  end
  
  local updateQuestFrame = function(givenFrame, givenQuest, givenProgress)
    assert(givenFrame ~= nil)
    assert(isValidQuest(givenQuest))
    
    local questDescription = getQuestDescription(givenQuest, givenProgress)    
    assert(questDescription ~= nil)
    assert("string" == type(questDescription))
    
    givenFrame.fontFrame:SetText(questDescription)
  end
  
  local updateQuestFrames = function()
    local quests = getQuestsSet()
    for i = 1, #quests do
      local quest = quests[i]
      assert(isValidQuest(quest))
      local nextQuestFrame = self.questFrames[i]
      local progress = getQuestProgress(quest.questId)
      updateQuestFrame(nextQuestFrame, quest, progress)
    end
  end
  
  self:HookScript("OnShow", function(self, ...)
    print('OnShow')
    updateQuestFrames()
  end)
end

--[[ CLI. ]]--

local initCLI = function(self)
  --[[ TODO ]]--
end

--[[ Init. ]]--

local bquest = CreateFrame("Frame", "BQuest", UIParent) or {}

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