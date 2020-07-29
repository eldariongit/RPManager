local isFirstStart = false
local title = "Hol' mir ma' 'ne Flasche Bier (Intro-Quest)"

local function setIntroQuest()
  local questID = RPMUtil.createID()
  RPMAccountDB.quests[questID] = {}
  RPMAccountDB.quests[questID].title = title
  RPMAccountDB.quests[questID].gm = UnitName("player")
  RPMAccountDB.quests[questID].quest = questID
  RPMAccountDB.quests[questID].gfx = "interface/lfgframe/lfgicon-brew"
  RPMAccountDB.quests[questID].chapters = {}
  RPMAccountDB.quests[questID].chapters[1] = {}
  RPMAccountDB.quests[questID].chapters[1]._type = RPManager.CHAPTER_TYPE_NORMAL
  RPMAccountDB.quests[questID].chapters[1].title = "Ein durstiger Zwerg"
  RPMAccountDB.quests[questID].chapters[1].path = "interface/icons/achievement_boss_emperordagranthaurissan"
  local snd = "Sound/Character/Dwarf/DwarfMale/DwarfMaleCry01.ogg"
  RPMAccountDB.quests[questID].chapters[1].sound = snd
  RPMAccountDB.quests[questID].chapters[1].sound = RPManager:getFileId(string.lower(snd))
  RPMAccountDB.quests[questID].chapters[1].published = false
  RPMAccountDB.quests[questID].chapters[1].text1 = "Brand Brondson war kein Zwerg von Feingefühl. Laut brüllte er durch die Kneipe."
  RPMAccountDB.quests[questID].chapters[1].type1 = "EMOTE"
  RPMAccountDB.quests[questID].chapters[1].text2 = "Wo bleibt mein Bier! Ich will mein Kharanos Urquell und zwar jetzt!"
  RPMAccountDB.quests[questID].chapters[1].type2 = "YELL"
  RPMAccountDB.quests[questID].chapters[1].text3 = "Johann der Wirt wendet sich betrübt zu dir."
  RPMAccountDB.quests[questID].chapters[1].type3 = "EMOTE"
  RPMAccountDB.quests[questID].chapters[1].text4 = "Kannst du im Keller nachschauen, ob wir noch welches haben? Ich muss den Trunkenbold im Auge behalten, bevor er noch alles kurz und klein schlägt."
  RPMAccountDB.quests[questID].chapters[1].type4 = "SAY"
  RPMAccountDB.quests[questID].chapters[1].text5 = ""
  RPMAccountDB.quests[questID].chapters[1].type5 = "EMOTE"
  RPMAccountDB.quests[questID].chapters[1].visible = true
  RPMAccountDB.quests[questID].chapters[1].condition = ""
  RPMAccountDB.quests[questID].chapters[1].conditiontype = ""
end

local function copyDefaultQuest2Journal()
  for _, quest in pairs(RPMCharacterDB.quests) do
    if quest.title == title then
      return
    end
  end

  for questID, quest in pairs(RPMAccountDB.quests) do
    if quest.title == title then
      RPMCharacterDB.quests[questID] = RPMUtil.deepCopy(RPMAccountDB.quests[questID])
    end
  end
end

function RPManager:resetIntroQuest()
  RPMDialog.showYesNoDialog(L["deleteQuestQry"], true, function()
    for questID, quest in pairs(RPMAccountDB.quests) do
      if quest.title == title then
        RPMAccountDB.quests[questID] = nil
        break
      end
    end
    for questID, quest in pairs(RPMCharacterDB.quests) do
      if quest.title == title then
        RPMCharacterDB.quests[questID] = nil
        break
      end
    end
    setIntroQuest()
    copyDefaultQuest2Journal()
  end)
end

function RPManager:initAccountDB()
  if RPMAccountDB == nil then
    RPMAccountDB = {}
    isFirstStart = true
  end
  if RPMAccountDB.quests == nil then
    RPMAccountDB.quests = {}
  end
  if RPMAccountDB.dicetracker == nil then
    RPMAccountDB.dicetracker = {}
  end

  -- account bag
  if RPMAccountDB.bag == nil then
    RPMAccountDB.bag = {}
    for i = 1, RPManager.BAG_SIZE do
      RPMAccountDB.bag[i] = {}
    end
  end
  if RPMAccountDB.items == nil then
    RPMAccountDB.items = {}
  end

  if isFirstStart then
    setIntroQuest()
  end
end

function RPManager:initCharDB()
  if RPMCharacterDB == nil then
    RPMCharacterDB = {}
  end

  if RPMCharacterDB.profile == nil then
    RPMCharacterDB.profile = {}
  end
  if RPMCharacterDB.profile.minimap == nil then
    RPMCharacterDB.profile.minimap = {
      hide = false,
      minimapPos = 180.0
    }
  end
  if RPMCharacterDB.profile.toolbar == nil then
    RPMCharacterDB.profile.toolbar = {
      hide = false
    }
  end

  if RPMCharacterDB.unlockedchapters == nil then
    RPMCharacterDB.unlockedchapters = {}
  end
  if RPMCharacterDB.quests == nil then
    RPMCharacterDB.quests = {}
    copyDefaultQuest2Journal()
  end

  -- personal bag
  if RPMCharacterDB.bag == nil then
    RPMCharacterDB.bag = {}
    for i = 1, RPManager.BAG_SIZE*9 do
      RPMCharacterDB.bag[i] = {}
    end
    RPMCharacterDB.profile.activeBag = RPManager.BAG_TYPE_ACCOUNT
    RPMCharacterDB.profile.numBags = 1
  end
--  if RPMCharacterDB.profile.scriptPermissions == nil then
--    RPMCharacterDB.profile.scriptPermissions = "blockScript"
--  end
  if RPMCharacterDB.profile.scriptPermissions ~= nil then
    RPMCharacterDB.profile.scriptPermissions = nil
  end
  if RPMCharacterDB.items == nil then
    RPMCharacterDB.items = {}
  end
  -- 9 bags
  while #RPMCharacterDB.bag < RPManager.BAG_SIZE*9 do
    RPMCharacterDB.bag[#RPMCharacterDB.bag+1] = {}
  end
end

function RPManager:initTRPCheck()
  self.trpChecker = self:ScheduleRepeatingTimer(function()
    if IsAddOnLoaded("totalRP3") then
      RPMTRP.setTrpLoaded(true)
      self:CancelTimer(self.trpChecker)
    end
  end, 5)
end

function RPManager:initRPMItemsCheck()
  self.rpmiChecker = self:ScheduleRepeatingTimer(function()
    if IsAddOnLoaded("RPManagerItems") then
      RPMItem.setRPMItemsAvailable(true)
      self:CancelTimer(self.rpmiChecker)
    end
  end, 5)
end
