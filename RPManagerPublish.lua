local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

if RPMPublish ~= nil then
  return
end

local function resetChapters(questID)
  local quest = RPMAccountDB.quests[questID]
  for chapterNr, chapter in ipairs(quest.chapters) do
    chapter.id = RPMUtil.createID()
    chapter.published = false
    chapter.visible = (chapterNr == 1)
  end
end

RPMPublish = {
--  publish = function(questID, receiver, synch)
--    local mgrQuest = RPMAccountDB.quests[questID]
--    if not synch then
--      for i = 1, #mgrQuest.chapters do
--        local chapter = mgrQuest.chapters[i]
--        chapter.published = true
--      end
--    end
--    RPMCharacterDB.quests[questID] = RPMUtil.deepCopy(mgrQuest)
--
--    local jrnQuest = RPMCharacterDB.quests[questID]
--    for chapterNr, chapter in ipairs(jrnQuest.chapters) do
--      if RPMUtil.contains(RPMCharacterDB.unlockedchapters, chapter.id) then
--        chapter.visible = true
--      end
--    end
--
--    send(questID, 0, receiver)
--    RPMUtil.msg(string.format(L["questPublished"], mgrQuest.title))
--    for i = 1, #mgrQuest.chapters do
--      if (synch and mgrQuest.chapters[i].published) or
--          not synch then
--        send(questID, i, receiver)
--        RPMUtil.msg(string.format(L["chapterPublished"], mgrQuest.chapters[i].title))
--      end
--    end
--  end,

  -- Publishes the latest version of the quest in the local journal
  publish = function(questID)
    local mgrQuest = RPMAccountDB.quests[questID]
    for _, chapter in ipairs(mgrQuest.chapters) do
      chapter.published = true
    end
    RPMCharacterDB.quests[questID] = RPMUtil.deepCopy(mgrQuest)

    local jrnQuest = RPMCharacterDB.quests[questID]
    for chapterNr, chapter in ipairs(jrnQuest.chapters) do
      if RPMUtil.contains(RPMCharacterDB.unlockedchapters, chapter.id) then
        chapter.visible = true
      end
    end
    RPMUtil.msg(string.format(L["questPublished"], mgrQuest.title))
  end,

  restart = function(questID)
    RPMDialog.showYesNoDialog(L["restartQry1"].." "..L["restartQry2"].." "..L["restartQry3"], true, function(self)
      -- remove in journal
      RPMCharacterDB.quests[questID] = nil
      -- new chapter ids in manager
      resetChapters(questID)
    end)
  end,

  duplicate = function(questID)
    local quest = RPMAccountDB.quests[questID]
    local newQuestID = RPMUtil.createID()

    RPMAccountDB.quests[newQuestID] = RPMUtil.deepCopy(quest)
    RPMAccountDB.quests[newQuestID].title =
        string.format(L["copyOf"], quest.title)
    resetChapters(newQuestID)
    RPMUtil.msg(string.format(L["questDuplicated"], quest.title))
  end
}