local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local UPDATE_COUNTER = 0

-- Journal Lister

function RPM_openJournal()
  if RPManager.journalFrame == nil then
    RPManager.journalFrame = RPMForm.drawBaseFrame("RPJournal", "journal", RPM_closeJournalFrame)
    if RPManager.managerFrame ~= nil then
      RPManager.managerFrame:Hide()
    end
  else
    RPManager.journalFrame:ReleaseChildren()
  end

  local f = RPManager.journalFrame
  f.scroll = RPMGui.addScrollBox(f, 420, "List")
  RPM_updateMainJrnFrm()
end

function RPM_closeJournalFrame()
  RPManager.journalFrame:Release()
  RPManager.journalFrame = nil
end

local function getProgress(chapters)
  local s = #chapters
  if chapters[s].visible then
    local finished = true
    for _, chapter in ipairs(chapters) do
      if not chapter.visible then
        finished = false
      end
    end
    if finished then
      return L["progressFinished"], 0.2, 1, 0, false
    end
  end
  if chapters[2] ~= nil and chapters[2].visible then
    return L["progressInProgress"], 1, 0.5, 0, true
  elseif chapters[1] ~= nil and chapters[1].visible then
    return L["progressStarted"], 1, 0.5, 0, true
  end
end

local function activateQuest(questID, activate)
  local quest = RPMCharacterDB.quests[questID]
  if activate then
    for qid, q in pairs(RPMCharacterDB.quests) do
      local _, _, _, _, canActivate = getProgress(q.chapters)
      if RPMUtil.isMyQuest(qid) and canActivate then
        q.active = (qid == questID)
      end
    end
    RPMSynch.queryQuestProgress()
  else
    quest.active = false
  end
  RPM_updateMainJrnFrm()
end

function RPM_updateMainJrnFrm()
  local scroll = RPManager.journalFrame.scroll
  scroll:ReleaseChildren()
  if RPMCharacterDB == nil or RPMUtil.isEmpty(RPMCharacterDB.quests) then
    RPMGui.addLabel(L["noQuests"], scroll, RPMFont.ARIAL, 20)
  else
    for questID, quest in pairs(RPMCharacterDB.quests) do
      local iBox = RPMGui.addInlineGroup("", "Flow", scroll)
      RPMGui.addShortLabel(quest.title, iBox, RPMFont.ARIAL, 452, 20)

      local progress, r, g, b, canActivate = getProgress(quest.chapters)
      local l = RPMGui.addShortLabel(progress, iBox, RPMFont.FRITZ, 150, 16)
      l:SetJustifyH("RIGHT")
      l:SetColor(r, g, b)

      if RPMUtil.isMyQuest(questID) then
        RPMGui.addShortLabel(L["chapters"]..": "..#(quest.chapters),
            iBox, RPMFont.FRITZ, 150, 16)
        if canActivate then
          RPMGui.addShortLabel(L["active"], iBox, RPMFont.FRITZ, 55, 16)
          local c = RPMGui.addCheckbox("", quest.active, iBox, function(self)
            activateQuest(questID, self:GetValue())
          end, L["activeDesc"])
          c:SetWidth(20)
          RPMGui.addSpacer(iBox, 78)
        else
          RPMGui.addSpacer(iBox, 153)
        end
      else
        RPMGui.addShortLabel(L["gm"]..": "..quest.gm,
            iBox, RPMFont.FRITZ, 303, 16)
      end
      RPMGui.addButton(L["open"],150,iBox,function()
        RPM_openQuestJrnFrm(questID)
      end, L["openQuestDesc"])
      RPMGui.addButton(L["delete"],150,iBox,function()
        RPM_deleteQuestFromJournal(questID)
      end, L["deleteQuestDesc"])
    end
  end
  scroll:DoLayout()
end

function RPM_deleteQuestFromJournal(questID)
  RPMDialog.showYesNoDialog(L["deleteQuestQry"], true, function(self)
    RPMCharacterDB.quests[questID] = nil
    RPM_updateMainJrnFrm()
  end)
end


-- Journal Quest Frame

function RPM_openQuestJrnFrm(questID)
  if RPManager.journalFrame == nil then
    RPManager.journalFrame = RPMForm.drawBaseFrame("RPJournal", "journal", RPM_closeJournalFrame)
  else
    RPManager.journalFrame:ReleaseChildren()
  end

  local quest = RPMCharacterDB.quests[questID]
  
  local f = RPManager.journalFrame
  f.title = RPMGui.addLabel(quest.title, f, RPMFont.ARIAL, 20)

  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["synchronize"], 150, grp2, function()
    RPMSynch.queryQuestProgress(questID)
  end, L["synchronizeDesc"])

  --  f.scroll = RPMGui.addScrollBox(f, 383, "List")
  f.scroll = RPMGui.addScrollBox(f, 356, "List")

  RPMGui.addBackButton(f, RPM_openJournal)

  RPM_updateQuestJrnFrm(questID)
end

local function drawChapterTab(questID, chapterNr, unlocked)
  local scroll = RPManager.journalFrame.scroll
  local quest = RPMCharacterDB.quests[questID]
  local chapter = quest.chapters[chapterNr]

  local iBox = RPMGui.addInlineGroup("", "Flow", scroll)
  local label
  if chapter._type == RPManager.CHAPTER_TYPE_NORMAL then
    label = RPMGui.addLabel(chapterNr..") "..chapter.title.." ["..L["chapter"].."]",iBox,RPMFont.ARIAL,20)
    RPMGui.addButton(L["open"],150,iBox,function()
      RPM_openChapterJrnFrm(questID, chapterNr)
    end, L["openChapterDesc"])
  elseif chapter._type == RPManager.CHAPTER_TYPE_ITEM then
    label = RPMGui.addLabel(chapterNr..") "..chapter.title.." ["..L["item"].."]",iBox,RPMFont.ARIAL,20)
    RPMGui.addButton(L["run"],150,iBox,function()
      RPM_openItemJrnFrm(questID, chapterNr)
    end, L["runScriptDesc"])
    RPMGui.addButton(L["copyItemToBag"],150,iBox,function()
      RPMBag.copy2Bag(questID, chapterNr)
    end, L["copyItemToBagDesc"])
  elseif chapter._type == RPManager.CHAPTER_TYPE_SCENE then
    label = RPMGui.addLabel(chapterNr..") "..chapter.title.." ["..L["cutscene"].."]",iBox,RPMFont.ARIAL,20)
    RPMGui.addButton(L["play"],150,iBox,function()
      RPM_openSceneJrnFrm(questID, chapterNr)
    end, L["playCutsceneDesc"])
  elseif chapter._type == RPManager.CHAPTER_TYPE_COMBAT then
    label = RPMGui.addLabel(chapterNr..") "..chapter.title.." ["..L["combat"].."]",iBox,RPMFont.ARIAL,20)
    RPMGui.addButton(L["join"],150,iBox,function()
      RPM_openCombatJrnFrm(questID, chapterNr)
    end, L["joinCombatDesc"])
    if RPMUtil.isMyQuest(questID) then
      RPMGui.addButton(L["reset"],150,iBox,function()
        RPM_resetCombat(questID, chapterNr)
      end, L["resetCombatDesc"])
    end
  end
  if not unlocked then
    label:SetColor(.4, .4, .4)
  end
end

function RPM_updateQuestJrnFrm(questID)
  local scroll = RPManager.journalFrame.scroll
  local quest = RPMCharacterDB.quests[questID]
  scroll:ReleaseChildren()
  if RPMUtil.isEmpty(quest.chapters) then
    RPMGui.addLabel(L["noChapters"], scroll, RPMFont.ARIAL, 20)
  else
    local visible = true
    local firstInvisibleChapter
    for chapterNr, chapter in ipairs(quest.chapters) do
      if chapter.visible and visible then
        drawChapterTab(questID, chapterNr, true)
      elseif not chapter.visible then
        visible = false
        if firstInvisibleChapter == nil then
          firstInvisibleChapter = chapterNr
          if not visible and RPMUtil.isMyQuest(questID) then
            local iBox = RPMGui.addInlineGroup("", "Flow", scroll)
            RPMGui.addSpacer(iBox, 187)
            RPMGui.addButton(L["unlockNextChapter"],250,iBox,function()
              RPMSynch.activateChapter(questID, firstInvisibleChapter, true, true)
            end, L["unlockNextChapterDesc"])
          end
        end
        drawChapterTab(questID, chapterNr, false)
      end
    end
  end
  scroll:DoLayout()
end

function RPM_resetCombat(questID, chapterNr)
  local quest = RPMCharacterDB.quests[questID]
  if quest == nil then
    return
  end
  local chapter = quest.chapters[chapterNr]
  if chapter == nil then
    return
  end
  chapter.save = ""
end

-- Journal Chapter Frame

function RPM_openChapterJrnFrm(questID, chapterNr)
  if RPManager.journalFrame == nil then
    RPManager.journalFrame = RPMForm.drawBaseFrame("RPJournal", "journal", RPM_closeJournalFrame)
  else
    RPManager.journalFrame:ReleaseChildren()
  end
  
  local quest = RPMCharacterDB.quests[questID]
  local chapter = quest.chapters[chapterNr]

  local boxHeight = 383

  local nextChapter = quest.chapters[chapterNr+1]
  local showHint = false
  if nextChapter ~= nil and not nextChapter.visible then
    showHint = true
    boxHeight = boxHeight - 80
    if nextChapter.conditiontype == RPManager.CONDITION_TYPE_QUESTION then
      boxHeight = boxHeight - 27
    end
  end

  local f = RPManager.journalFrame
  f.title = RPMGui.addLabel(chapterNr..") "..chapter.title,f,RPMFont.ARIAL,20)
  f.title:SetImage(chapter.path)

  if RPMUtil.isMyQuest(questID) then
    local grp = RPMGui.addSimpleGroup("Flow", f)
    RPMGui.addButton(L["toChat"], 150, grp, function()
      RPM_sendChapter(questID, chapterNr, false)
    end, L["toChatDesc"])

    RPMGui.addButton(L["toGroup"], 150, grp, function()
      RPM_sendChapter(questID, chapterNr, true)
    end, L["toGroupDesc"])
    boxHeight = boxHeight - 27
  end

  f.scroll = RPMGui.addScrollBox(f, boxHeight, "List")

  for i = 1, #chapter.para do
    local _type = chapter.para[i].type
    local _text = chapter.para[i].text
    if _text ~= "" then
      local r, g, b = 1, 1, 1
      if _type == "TEXT" then
        r, g, b = .7, .7, .7
      elseif _type == "SAY" then
        _text = '"'.._text..'"'
      elseif _type == "YELL" then
        _text = '"'.._text..'"'
        g, b = .25, .25
      elseif _type == "EMOTE" then
        g, b = .5, .25
      end
      local label = RPMGui.addLabel(_text.."\n",f.scroll,RPMFont.FRITZ,18)
      label:SetColor(r, g, b)
    end
  end

  if showHint then
    local iBox = RPMGui.addInlineGroup(L["hint"], "Flow", f)
    if nextChapter.conditiontype == RPManager.CONDITION_TYPE_PERSON then
      RPMGui.addLabel(L["triggerPersonHint"], iBox, RPMFont.FRITZ, 18)
    elseif nextChapter.conditiontype == RPManager.CONDITION_TYPE_POSITION then
      RPMGui.addLabel(L["triggerLocationHint"], iBox, RPMFont.FRITZ, 18)
    elseif nextChapter.conditiontype == RPManager.CONDITION_TYPE_MANUAL then
      RPMGui.addLabel(L["triggerManualHint"], iBox, RPMFont.FRITZ, 18)
    elseif nextChapter.conditiontype == RPManager.CONDITION_TYPE_QUESTION then
      RPMGui.addLabel(L["triggerQuestionHint"], iBox, RPMFont.FRITZ, 18)
--    else
--      print(nextChapter.conditiontype)
    end

    if nextChapter.conditiontype == RPManager.CONDITION_TYPE_QUESTION then
      RPMGui.addButton(L["answerQuestion"], 150, iBox, function()
        RPMDialog.showInputDialog(L["answerQuestionQry"], "", function(self)
          local expected = nextChapter.condition:lower()
          local answer = self.editBox:GetText():lower()
          if expected == answer then
            RPMSynch.activateChapter(questID, chapterNr+1, true, true)
          else
            print(L["answerQuestionWrong"])
          end
        end)
      end, L["answerQuestionDesc"])
    end
  end

  RPMGui.addBackButton(f, function() RPM_openQuestJrnFrm(questID) end)
  RPMUtil.playSound(chapter.soundFileId)
end

local function printParagraph(msgType, msg, toGroup)
  if msg == nil or msg == "" then
    return
  end

  if toGroup then
    local channel = "PARTY"
    if IsInRaid() then
      channel = "RAID"
    elseif not IsInGroup() then
      return
    end

    if msgType == "TEXT" or msgType == "EMOTE" then
      local list = RPMUtil.splitText(msg, 235)
      for _,_line in ipairs(list) do
        RPMIO.sendChatMessage(channel, "*".._line.."*")
      end
      return
    elseif msgType == "YELL" then
      msg = msg:upper()
    end
    RPMIO.sendChatMessage(channel, msg)
  else
    if msgType == "TEXT" or msgType == "EMOTE" then
      local list = RPMUtil.splitText(msg, 235)
      for _,_line in ipairs(list) do
        RPMIO.sendChatMessage("EMOTE", "|| ".._line)
      end
    elseif msgType == "YELL" then
      RPMIO.sendChatMessage("YELL", msg)
    else
      RPMIO.sendChatMessage("SAY", msg)
    end
  end
end

function RPM_sendChapter(questID, chapterNr, group)
  local chapter = RPMCharacterDB.quests[questID].chapters[chapterNr]
  for i = 1, #chapter.para do
    printParagraph(chapter.para[i].type, chapter.para[i].text, group)
  end
end


-- Journal Scene

function RPM_openSceneJrnFrm(questID, chapterNr)
  if RPManager.journalFrame ~= nil then
    RPManager.journalFrame:Hide()
  end
  
  local quest = RPMCharacterDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  RPMMovie.startMovie(chapter.scene, false, function()
    RPM_openQuestJrnFrm(questID)
  end)
end

-- Journal Script

function RPM_openItemJrnFrm(questID, chapterNr)
  if RPManager.journalFrame ~= nil then
    RPManager.journalFrame:Hide()
  end
  
  local quest = RPMCharacterDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  if chapter.itemtype == RPManager.ITEM_TYPE_SCRIPT then
    RunScript(chapter.script)
  elseif chapter.itemtype == RPManager.ITEM_TYPE_MAP then
    
  elseif chapter.itemtype == RPManager.ITEM_TYPE_BOOK then

  elseif chapter.itemtype == RPManager.ITEM_TYPE_EMOTE then

  end
end


-- Journal Combat

function RPM_openCombatJrnFrm(questID, chapterNr, anchor)
  if RPManager.journalFrame ~= nil then
    RPManager.journalFrame:Hide()
  end
  if RPManager.combatJournalFrame ~= nil then
    if RPManager.combatJournalFrame.questID ~= questID or
        RPManager.combatJournalFrame.chapterNr ~= chapterNr then
      RPM_closeCombatJournalFrame()
    end
    return
  end

  local f = RPMForm.drawBaseFrame("RPCombat", "combat", RPM_closeCombatJournalFrame)
  RPManager.combatJournalFrame = f
  f.questID = questID
  f.chapterNr = chapterNr
  
  f:SetLayout("Fill")
  f:SetWidth(RPMCharacterDB.profile["combat"]["w"] or 700)
  f:SetHeight(RPMCharacterDB.profile["combat"]["h"] or 500)
  
  local grp = RPMGui.addSimpleGroup("Flow", f)
  f.map = grp.frame
  local t = grp.frame:CreateTexture(nil,"BACKGROUND")
  f.tex = t
  t:SetAllPoints(grp.frame)
  t:SetHorizTile(true) -- note: SetTexture must also have
  t:SetVertTile(true)  -- both tilings set to true
  
  local quest = RPMCharacterDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  f.tex:SetTexture(RPM_TEXTURE_PATH..chapter.map, true, true)
  if chapter ~= nil and chapter.save ~= "" then
    f.mobList = RPM_mobString2List(chapter.save)
  else
    f.mobList = RPM_mobString2List(chapter.start)
  end

  f.owner = RPMUtil.isMyQuest(questID)
  if f.owner then
    f.anchor = { sx = f.map:GetWidth()/2, sy = f.map:GetHeight()/2 }
    f.anchor.wy, f.anchor.wx = UnitPosition("player")
  else
    f.anchor = anchor
  end
  
  for mobNr, mob in ipairs(f.mobList) do
    RPM_putToken(mob, f)
    if mob.anchor and f.owner then
      f.anchor.sx = mob.x
      f.anchor.sy = mob.y
    end
  end

  f.players = {}
  
  RPManager.combatJournalFrame.frame:SetScript("OnEvent", RPM_onEventCombatJournalFrame)
  RPManager.combatJournalFrame.frame:RegisterEvent("RAID_ROSTER_UPDATE")
  RPManager.combatJournalFrame.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  if f.owner then
    RPM_sendAnchor()
    RPM_sendMobs()
  end
  if f.anchor == nil then
    RPMSynch.synchCombat("joined")
  else
    RPM_drawSelf(f.anchor.sx, f.anchor.sy)
  end
end

function RPM_onUpdateCombatJournalFrame(self, elapsed)
  UPDATE_COUNTER = UPDATE_COUNTER + elapsed
  if UPDATE_COUNTER >= .2 then
    UPDATE_COUNTER = 0
    local wy,wx = UnitPosition("player")
    local sx,sy = RPM_normalizeCoords(wx,wy)
    RPM_updateSelf(sx,sy)
  end
  RPM_checkTokenVisibility(RPManager.combatJournalFrame.mobList, RPManager.combatJournalFrame)
end

function RPM_onEventCombatJournalFrame(self, event)
  if not IsInGroup() then
    return
  end

  for name in pairs(RPManager.combatJournalFrame.players) do -- ging jemand?
    if UnitGUID(name) == nil then
      RPM_removeToken(name)
    end
  end

  if self.owner then -- Neuer Spieler?
    RPM_sendAnchor()
    RPM_sendMobs()
  end
end

function RPM_closeCombatJournalFrame()
  if RPMUtil.isMyQuest(RPManager.combatJournalFrame.questID) then
    RPMSynch.synchCombat("end")
  else
    RPMSynch.synchCombat("left", UnitName("player"))
  end
  if RPManager.combatJournalFrame ~= nil then
    for _, mob in ipairs(RPManager.combatJournalFrame.mobList) do
      RPM_removeToken(mob)
    end
    for _, v in pairs(RPManager.combatJournalFrame.players) do
      v:Hide()
      v = nil
    end
    RPManager.combatJournalFrame.frame:UnregisterEvent("RAID_ROSTER_UPDATE")
    RPManager.combatJournalFrame.frame:UnregisterEvent("GROUP_ROSTER_UPDATE")
    RPManager.combatJournalFrame.frame:SetScript("OnEvent", nil)
    RPManager.combatJournalFrame.frame:SetScript("OnUpdate", nil)
    RPManager.combatJournalFrame.tex:Hide()
    RPManager.combatJournalFrame.tex = nil

    RPManager.combatJournalFrame:Hide()
    RPManager.combatJournalFrame = nil
  end
end