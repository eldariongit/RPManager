if RPMSynch ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local questCheckTimer
local newElement = {}

local function copyElement(id)
  local tempTable = RPMUtil.stringToTable(newElement[id])
  newElement[id] = nil
  return tempTable
end

local function addElementPart(msgFields)
  local type
  local id
  if msgFields.itemID ~= nil then
    id = msgFields.itemID
    type = "item"
  else
    id = msgFields.questID
    if msgFields.chapterNr > 0 then
      type = "chapter"
    else
      type = "quest"
    end
  end

  if msgFields.current == 1 then
    newElement[id] = msgFields.part
    RPMProgressBar.addBar(id, msgFields.max, type, "receive")
  else
    if msgFields.part == nil then
      print(id, "is nil")
    else
      newElement[id] = newElement[id]..msgFields.part
    end
    RPMProgressBar.inc(id)
  end
end

local function send(questID, chapterNr, receiver)
  if questID == nil or questID == "" then
    return
  end

  local quest = RPMAccountDB.quests[questID]
  local msgType, list

  if chapterNr == 0 then
    msgType = RPMIO.MSG_SEND_QUEST
    list = RPMIO.splitElement(RPMUtil.shallowCopy(quest))
  else
    msgType = RPMIO.MSG_SEND_CHAPTER
    list = RPMIO.splitElement(quest.chapters[chapterNr])
  end

  for i, part in ipairs(list) do
    RPMIO.sendAddonMessage(msgType, {questID, chapterNr, i, #list, part}, receiver)
  end
end

local function checkSendersQuestProgress(msgFields)
  local quest = RPMCharacterDB.quests[msgFields.questID]
  if quest == nil then
    return
  end

  for i = 1, math.min(#quest.chapters, msgFields.currentChapter) do
    RPMSynch.activateChapter(msgFields.questID, i, false, false)
  end

  if msgFields.lastChapter < #quest.chapters then
    send(msgFields.questID, 0, msgFields.sender)
    for i, _ in ipairs(quest.chapters) do
      send(msgFields.questID, i, msgFields.sender)
    end
  end
end

local function findCurrentAndLastChapter(questID)
  local currChapter = 0
  local lastChapter = 0
  local quest = RPMCharacterDB.quests[questID]
  if quest ~= nil then
    local firstInvisibleChapterReached = false
    for i, chapter in ipairs(quest.chapters) do
      if chapter.visible and not firstInvisibleChapterReached then
        currChapter = i
      elseif not chapter.visible then
        firstInvisibleChapterReached = true
      end
    end
    lastChapter = #quest.chapters
  end
  return currChapter, lastChapter
end

local function replaceOldChapter(questID, chapterNr)
  local quest = RPMCharacterDB.quests[questID]
  if quest == nil then
    return
  end
  RPMCharacterDB.quests[questID].chapters[chapterNr] = copyElement(questID)
  local id = RPMCharacterDB.quests[questID].chapters[chapterNr].id
  if RPMUtil.contains(RPMCharacterDB.unlockedchapters, id) then
    RPMCharacterDB.quests[questID].chapters[chapterNr].visible = true
  end
end

local function sendItemPermission(itemID, receiver, query)
--  if query == nil then
--    RPMIO.sendAddonMessage(RPMIO.MSG_SEND_ITEM_PERM, { itemID }, receiver)
--  else
    RPMDialog.showYesNoDialog(query, true,
      function() RPMIO.sendAddonMessage(RPMIO.MSG_SEND_ITEM_PERM, { "true", itemID }, receiver) end,
      function() RPMIO.sendAddonMessage(RPMIO.MSG_SEND_ITEM_PERM, { "false", itemID }, receiver) end)
--  end
end


RPMSynch = {
  queryQuestProgressDelayed = function()
    if questCheckTimer == nil then
      questCheckTimer = RPManager:ScheduleTimer(function()
        questCheckTimer = nil
        RPMSynch.queryQuestProgress()
      end, 5)
    end
  end,

  -- Querys progress of active quest from group members
  -- called when joining group and when activating new quest
  queryQuestProgress = function(syncQuestID)
    for id, quest in pairs(RPMCharacterDB.quests) do
      if (quest.active and syncQuestID == nil) or id == syncQuestID then
        local currChapter, lastChapter = findCurrentAndLastChapter(id)
        RPMIO.sendAddonMessage(RPMIO.MSG_SYNCH_QRY, {id, currChapter, lastChapter})
        return
      end
    end
  end,

  -- Sends the current chapter number as answer to the query
  sendQuestProgress = function(msgFields)
    local questID = msgFields.questID
    checkSendersQuestProgress(msgFields)

    -- send answer
    local currChapter, lastChapter = findCurrentAndLastChapter(questID)
    RPMIO.sendAddonMessage(RPMIO.MSG_SYNCH_ANS, {questID, currChapter,lastChapter}, sender)
  end,

  receiveQuestProgress = function(msgFields)
    checkSendersQuestProgress(msgFields)
  end,

  -- synch - immediately synchronizes with other players
  -- show - opens the new chapter
  activateChapter = function(questID, chapterNr, synch, show)
    local quest = RPMCharacterDB.quests[questID]
    if quest == nil then
      return
    end
    local chapter = quest.chapters[chapterNr]
    if chapter == nil then
      return
    end

    if not chapter.visible then
      if not RPMUtil.contains(RPMCharacterDB.unlockedchapters, chapter.id) then
        table.insert(RPMCharacterDB.unlockedchapters, chapter.id)
      end
      chapter.visible = true
    end

    if synch then
      local currChapter, lastChapter = findCurrentAndLastChapter(questID)
      RPMIO.sendAddonMessage(RPMIO.MSG_SYNCH_ANS, {questID, currChapter, lastChapter})
    end

    if not show then
      return
    end

    if chapter._type == RPManager.CHAPTER_TYPE_NORMAL then
      RPM_openChapterJrnFrm(questID, chapterNr)
    elseif chapter._type == RPManager.CHAPTER_TYPE_ITEM then
      RPM_openItemJrnFrm(questID, chapterNr)
    elseif chapter._type == RPManager.CHAPTER_TYPE_SCENE then
      RPM_openSceneJrnFrm(questID, chapterNr)
    elseif chapter._type == RPManager.CHAPTER_TYPE_COMBAT then
      RPM_openCombatJrnFrm(questID, chapterNr)
    end
    if synch then
      RPMIO.sendAddonMessage(RPMIO.MSG_SHOW_CHAPTER, {questID, chapterNr})
    end
  end,

  receiveNewQuest = function(msgFields)
    addElementPart(msgFields)
    if msgFields.current == msgFields.max then
      RPMCharacterDB.quests[msgFields.questID] = copyElement(msgFields.questID)
    end
  end,

  receiveNewChapter = function(msgFields)
    addElementPart(msgFields)
    if msgFields.current == msgFields.max then
      replaceOldChapter(msgFields.questID, msgFields.chapterNr)
    end
  end,

  sendItem = function(itemID, target, currentDB, deleteAfterSend, slot)
    local item = currentDB.items[itemID]
    local itemType = RPMItem.getItemType(item)
    if itemType == nil then
      RPMUtil.msg(L["itemManipulated"])
      return
    end
    RPMIO.sendAddonMessage(RPMIO.MSG_SEND_ITEM_REQ, {itemID, item.name, itemType}, target)
    RPMItem.addItemInTransfer(itemID, deleteAfterSend, slot)
  end,

  receivedItemSendRequest = function(msgFields)
    local itemID, itemName, itemType, sender = msgFields.itemID, msgFields.itemName, msgFields.itemType, msgFields.sender
    if RPMUtil.isIgnored(msgFields.sender) then
      return
    end

    local itemExists = RPMCharacterDB.items[itemID] ~= nil
    if not itemExists then
      local slot = RPMBag.getFirstEmptySlot(RPMCharacterDB)
      if slot == 0 then
        RPMUtil.msg(string.format(L["bagFull"], sender))
        return
      end
    end

    local it = RPMItem.colorItemType(itemType)
    if itemExists then
      local query = string.format(L["sendItemUpdateQry"], sender, itemName, it)
      sendItemPermission(itemID, sender, query)
--    elseif RPMUtil.isFriend(sender) then
--      sendItemPermission(itemID, sender)
    else
      local query = string.format(L["sendItemNewQry"], sender, itemName, it)
      sendItemPermission(itemID, sender, query)
    end
  end,

  receivedItemSendPermission = function(msgFields)
    local item = RPMAccountDB.items[msgFields.itemID]
    if msgFields.permission == "true" then
      local list = RPMIO.splitElement(item)
      for i, part in ipairs(list) do
        RPMIO.sendAddonMessage(RPMIO.MSG_SEND_ITEM,
            {msgFields.itemID, i, #list, part}, msgFields.sender)
      end
      RPMItem.progressItemInTransfer(msgFields.itemID, #list)
    else
      RPMItem.cancelItemInTransfer(msgFields.itemID)
      RPMUtil.msg(L["cancelItemTrade"])
    end
  end,

  receiveNewItem = function(msgFields)
    addElementPart(msgFields)
    RPMIO.sendAddonMessage(RPMIO.MSG_SEND_ITEM_STAT,
        { msgFields.itemID, msgFields.current }, msgFields.sender)
    if msgFields.current == msgFields.max then
      local isNewItem = (RPMCharacterDB.items[msgFields.itemID] == nil)
      local tempItem = copyElement(msgFields.itemID)

      local itemType = RPMItem.getItemType(tempItem)
      if itemType == nil then
        RPMUtil.msg(L["itemManipulatedDel"])
        return
      end

      RPMCharacterDB.items[msgFields.itemID] = tempItem
      if isNewItem then
        local slot = RPMBag.getFirstEmptySlot(RPMCharacterDB)
        RPMCharacterDB.bag[slot].item = msgFields.itemID
        RPMBag.updateBag()
      end
    end
  end,

  receiveItemSendStatusUpdate = function(msgFields)
    RPMItem.progressItemInTransfer(msgFields.itemID, msgFields.current)
  end,

  synchCombat = function(...)
    local tokens = { ... }
    local data = ""
    for _, val in ipairs(tokens) do
      data = data..tostring(val)..";"
    end
    RPMIO.sendAddonMessage(RPMIO.MSG_COMBAT_DATA, { data })
  end,
}
