local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local libIco = LibStub("LibAdvancedIconSelector-1.0")

-- Manager Lister

function RPM_openManager()
  if RPManager.managerFrame == nil then
    RPManager.managerFrame = RPMForm.drawBaseFrame("RPManager", "manager", RPM_closeManagerFrame)
    if RPManager.journalFrame ~= nil then
      RPManager.journalFrame:Hide()
    end
  else
    RPManager.managerFrame:ReleaseChildren()
  end
  
  local f = RPManager.managerFrame
  RPMGui.addButton(L["newQuest"],200,f,function()
    RPMTemplate.setNewQuest()
    RPM_updateMainManFrm()
  end, L["newQuestDesc"])
  f.scroll = RPMGui.addScrollBox(f, 390, "List")
  RPM_updateMainManFrm()
end

function RPM_closeManagerFrame()
  RPManager.managerFrame:Release()
  RPManager.managerFrame = nil
end

function RPM_updateMainManFrm()
  local scroll = RPManager.managerFrame.scroll
  scroll:ReleaseChildren()
  if RPMAccountDB == nil or RPMUtil.isEmpty(RPMAccountDB.quests) then
    RPMGui.addLabel(L["noQuests"],scroll,RPMFont.ARIAL,20)
  else
    for questID, quest in pairs(RPMAccountDB.quests) do
      local iBox = RPMGui.addInlineGroup("", "Flow", scroll)
      RPMGui.addLabel(quest.title,iBox,RPMFont.ARIAL,20)

      RPMGui.addShortLabel(L["chapters"]..": "..#(quest.chapters),
          iBox, RPMFont.FRITZ, 301, 16)

      RPMGui.addButton(L["edit"],150,iBox,function()
        RPM_openQuestManFrm(questID)
      end, L["editQuestDesc"])
      RPMGui.addButton(L["delete"],150,iBox,function()
        RPM_deleteQuestFromManager(questID)
      end, L["deleteQuestDesc"])
    end
  end
  scroll:DoLayout()
end

function RPM_deleteQuestFromManager(questID)
  RPMDialog.showYesNoDialog(L["deleteQuestQry"], true, function(self)
    RPMAccountDB.quests[questID] = nil
    RPMCharacterDB.quests[questID] = nil
    RPM_updateMainManFrm()
  end)
end


-- Manager Quest Frame

function RPM_openQuestManFrm(questID)
  if RPManager.managerFrame == nil then
    RPManager.managerFrame = RPMForm.drawBaseFrame("RPManager", "manager", RPM_closeManagerFrame)
  else
    RPManager.managerFrame:ReleaseChildren()
  end
  
  local quest = RPMAccountDB.quests[questID]
  local f = RPManager.managerFrame
  
  local grp1 = RPMGui.addSimpleGroup("Flow",f)
  f.title = RPMGui.addEditBox("",quest.title,300,100,grp1,function(self)
    quest.title = self:GetText()
  end)
  
  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["publish"],150,grp2,function()
    RPMPublish.publish(questID)
  end, L["publishDesc"])
  RPMGui.addButton(L["restartQuest"],150,grp2,function()
    RPMPublish.restart(questID)
  end, L["restartQuestDesc"])
  RPMGui.addButton(L["duplicateQuest"],150,grp2,function()
    RPMPublish.duplicate(questID)
  end, L["duplicateQuestDesc"])


  local grp3 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["newChapter"],150,grp3,function() RPM_addChapter(RPManager.CHAPTER_TYPE_NORMAL,questID) end, L["newChapterDesc"])
  RPMGui.addButton(L["newCutscene"],150,grp3,function() RPM_addChapter(RPManager.CHAPTER_TYPE_SCENE,questID) end, L["newCutsceneDesc"])
  RPMGui.addButton(L["newCombat"],150,grp3,function() RPM_addChapter(RPManager.CHAPTER_TYPE_COMBAT,questID) end, L["newCombatDesc"])
--  RPMGui.addButton(L["newItem"],150,grp3,function() RPM_addChapter(RPManager.CHAPTER_TYPE_ITEM,questID) end, L["newItemDesc"])
  
  f.scroll = RPMGui.addScrollBox(f, 329, "List")
  
  RPMGui.addBackButton(f, RPM_openManager)

  RPM_updateQuestManFrm(questID)
end

local function moveChapterDown(questID, chapterNr)
  local quest = RPMAccountDB.quests[questID]
  local chapters = quest.chapters
  if chapterNr == #chapters then
    return
  end
  chapters[chapterNr], chapters[chapterNr+1] = chapters[chapterNr+1], chapters[chapterNr]
  RPM_updateQuestManFrm(questID)
end

local function moveChapterUp(questID, chapterNr)
  local quest = RPMAccountDB.quests[questID]
  local chapters = quest.chapters
  if chapterNr == 1 then
    return
  end
  chapters[chapterNr], chapters[chapterNr-1] = chapters[chapterNr-1], chapters[chapterNr]
  RPM_updateQuestManFrm(questID)
end

function RPM_updateQuestManFrm(questID)
  local scroll = RPManager.managerFrame.scroll
  local quest = RPMAccountDB.quests[questID]
  scroll:ReleaseChildren()
  if RPMUtil.isEmpty(quest.chapters) then
    RPMGui.addLabel(L["noChapters"],scroll,RPMFont.ARIAL,20)
  else
    for chapterNr, chapter in ipairs(quest.chapters) do
      local iBox = RPMGui.addInlineGroup("", "Flow", scroll)
      RPMGui.addShortLabel(chapterNr..") "..chapter.title,
          iBox, RPMFont.ARIAL, 464, 20)

      RPMGui.addSpacer(iBox, 10)

      local pub = (chapter.published and L["published"]) or ""
      local l = RPMGui.addShortLabel(pub, iBox, RPMFont.ARIAL, 100, 16)
      l:SetJustifyH("RIGHT")
      l:SetColor(1,0.5,0)

      RPMGui.addSpacer(iBox, 5)
      RPMGui.addIconButton("interface/addons/RPManager/img/up", 23, iBox, function()
        moveChapterUp(questID, chapterNr)
      end, L["upDesc"], 0, 23/32, 0, 23/32)


      local cond = L[chapter.conditiontype]
      RPMGui.addShortLabel(L["triggerCondition"]..": "..cond,
        iBox, RPMFont.FRITZ, 274, 16)

      RPMGui.addButton(L["edit"],150,iBox,function()
        if chapter._type == RPManager.CHAPTER_TYPE_NORMAL then
          RPM_openChapterManFrm(questID, chapterNr)
        elseif chapter._type == RPManager.CHAPTER_TYPE_ITEM then
          RPM_openItemManFrm(questID, chapterNr)
        elseif chapter._type == RPManager.CHAPTER_TYPE_SCENE then
          RPM_openSceneManFrm(questID, chapterNr)
        elseif chapter._type == RPManager.CHAPTER_TYPE_COMBAT then
          RPM_openCombatManFrm(questID, chapterNr)
        end
      end, L["editChapterDesc"])
      RPMGui.addButton(L["delete"],150,iBox,function()
        RPM_deleteChapter(questID, chapterNr)
      end, L["deleteChapterDesc"])

      RPMGui.addSpacer(iBox, 5)
      RPMGui.addIconButton("interface/addons/RPManager/img/down", 23, iBox, function()
        moveChapterDown(questID, chapterNr)
      end , L["downDesc"], 0, 23/32, 0, 23/32)
    end
  end
  scroll:DoLayout()
end

function RPM_addChapter(_type, questID)
  if _type == RPManager.CHAPTER_TYPE_NORMAL then
    RPMTemplate.setNewChapter(questID)
  elseif _type == RPManager.CHAPTER_TYPE_SCENE then
    RPMTemplate.setNewScene(questID)
  elseif _type == RPManager.CHAPTER_TYPE_ITEM then
    RPMTemplate.setNewItemChapter(questID)
  elseif _type == RPManager.CHAPTER_TYPE_COMBAT then
    RPMTemplate.setNewCombat(questID)
  end
  RPM_updateQuestManFrm(questID)
end

function RPM_deleteChapter(questID, chapterNr)
  RPMDialog.showYesNoDialog(L["deleteChapterQry"], true, function(self)
    local quest = RPMAccountDB.quests[questID]
    table.remove(quest.chapters,chapterNr)
    RPM_updateQuestManFrm(questID)
  end)
end

--local function printCondition(cond)
--  RPManager.managerFrame.ausloes:SetText(L["triggerCondition"]..": "..(cond or ""))
--end

local function printCondition(chapter)
  local cond = L[chapter.conditiontype] or ""
  if chapter.conditiontype == RPManager.CONDITION_TYPE_PERSON then
    local name = (string.len(chapter.condition) <= 26
            and chapter.condition)
            or chapter.condition:sub(1, 24).."..."
    cond = string.format("%s (%s)", name, ((chapter.isPlayer and "SC") or "NPC"))
  elseif chapter.conditiontype == RPManager.CONDITION_TYPE_QUESTION then
    cond = L["solution"].." '"..chapter.condition.."'"
  end
  RPManager.managerFrame.ausloes:SetText(L["triggerCondition"]..": "..cond)
end

local function setPosCondition(questID, chapterNr, updFunc)
  local chapter = RPMAccountDB.quests[questID].chapters[chapterNr]
  chapter.conditiontype = RPManager.CONDITION_TYPE_POSITION
  local x1,y1 = UnitPosition("player")
  chapter.condition = string.format("%s;%.2f;%.2f",GetZoneText(),x1,y1)
  chapter.visible = false
  if updFunc ~= nil then
    updFunc(questID, chapterNr)
  end
  printCondition(chapter)
end

local function setPersonCondition(questID, chapterNr, updFunc)
  local target = UnitName("target")
  if target == nil then
    RPMUtil.msg(L["triggerPersonErr"])
    return
  end

  local chapter = RPMAccountDB.quests[questID].chapters[chapterNr]
  chapter.conditiontype = RPManager.CONDITION_TYPE_PERSON
  chapter.condition = target
  chapter.visible = false
  chapter.isPlayer = UnitIsPlayer("target")
  if updFunc ~= nil then
    updFunc(questID, chapterNr)
  end
  printCondition(chapter)
end

local function setQuestionCondition(questID, chapterNr, updFunc)
  RPMDialog.showInputDialog(L["triggerQuestionQry"], "", function(self)
    local chapter = RPMAccountDB.quests[questID].chapters[chapterNr]
    chapter.conditiontype = RPManager.CONDITION_TYPE_QUESTION
    chapter.condition = self.editBox:GetText()
    chapter.visible = false
    printCondition(chapter)
  end)
end

local function setAutoCondition(questID, chapterNr, updFunc)
  local chapter = RPMAccountDB.quests[questID].chapters[chapterNr]
  chapter.conditiontype = RPManager.CONDITION_TYPE_AUTO
  chapter.condition = ""
  chapter.visible = true
  if updFunc ~= nil then
    updFunc(questID, chapterNr)
  end
  printCondition(chapter)
end

local function setManualCondition(questID, chapterNr, updFunc)
  local chapter = RPMAccountDB.quests[questID].chapters[chapterNr]
  chapter.conditiontype = RPManager.CONDITION_TYPE_MANUAL
  chapter.condition = ""
  chapter.visible = false
  if updFunc ~= nil then
    updFunc(questID, chapterNr)
  end
  printCondition(chapter)
end

local function addTriggerBlock(questID, chapterNr, parent, updFunc)
  local quest = RPMAccountDB.quests[questID]

  local chapter = quest.chapters[chapterNr]
  local grp = RPMGui.addInlineGroup("", "Flow", parent)

  RPMGui.addButton(L["triggerLocation"], 150, grp, function()
    setPosCondition(questID, chapterNr, updFunc)
  end, L["triggerLocationDesc"])
  RPMGui.addButton(L["triggerPerson"], 150, grp, function()
    setPersonCondition(questID, chapterNr, updFunc)
  end, L["triggerPersonDesc"])
  RPMGui.addButton(L["triggerQuestion"], 150, grp, function()
    setQuestionCondition(questID, chapterNr, updFunc)
  end, L["triggerQuestionDesc"])
  RPMGui.addButton(L["triggerManual"], 150, grp, function()
    setManualCondition(questID, chapterNr, updFunc)
  end, L["triggerManualDesc"])

  parent.ausloes = RPMGui.addShortLabel("", grp, RPMFont.FRITZ, 450, 16)
  printCondition(chapter)

  RPMGui.addButton(L["deleteTrigger"], 150, grp, function()
    setAutoCondition(questID, chapterNr, updFunc)
  end, L["deleteTriggerDesc"])
end

-- Manager Chapter Frame

function RPM_openChapterManFrm(questID, chapterNr)
  if RPManager.managerFrame == nil then
    RPManager.managerFrame = RPMForm.drawBaseFrame("RPManager", "manager", RPM_closeManagerFrame)
  else
    RPManager.managerFrame:ReleaseChildren()
  end
  
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  
  local f = RPManager.managerFrame

  local grp1 = RPMGui.addSimpleGroup("Flow", f)
  f.icon = RPMGui.addIcon(chapter.path,32,grp1,function()
    RPM_setIcon(questID, chapterNr)
  end)
  f.icon:SetWidth(35)
  f.title = RPMGui.addEditBox("", chapter.title, 300, 100, grp1, function(self)
    chapter.title = self:GetText()
  end)
   
  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["setSound"], 150, grp2, function()
    RPM_setSound(questID, chapterNr)
  end, L["setSoundDesc"])
  RPMGui.addButton(L["newPara"], 150, grp2, function()
    RPM_addParagraph(questID, chapterNr)
  end, L["newParaDesc"])
  RPMGui.addButton(L["publish"], 150, grp2, function()
    RPMPublish.publish(questID)
  end, L["publishDesc"])
  
  f.scroll = RPMGui.addScrollBox(f, 243, "List")

  addTriggerBlock(questID, chapterNr, f, RPM_updateChapterManFrm)

  RPMGui.addBackButton(f, function() RPM_openQuestManFrm(questID) end)
    
  RPM_updateChapterManFrm(questID, chapterNr)
  RPMUtil.playSound(chapter.soundFileId)
end

local function manageRadioButtons(widget, p)
  for i=1,#p.radio do
    if p.radio[i] ~= widget then
      p.radio[i]:SetValue(false)
    end
  end
end

function RPM_updateChapterManFrm(questID, chapterNr)
  local scroll = RPManager.managerFrame.scroll
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  scroll:ReleaseChildren()

  if chapter.para == nil then
    return
  end

  for i = 1, #chapter.para do
    local _type = chapter.para[i].type
    local _text = chapter.para[i].text
    local iBox = RPMGui.addSimpleGroup("Flow", scroll)
    local txt = RPMGui.addTextArea(5, 1000, _text, iBox, function(widget, event)
      chapter.para[i].text = widget:GetText()
    end)

    RPMGui.addRadioButton(L["text"], 150, (_type == "TEXT"),iBox,iBox,function(widget)
      if widget:GetValue() then
        chapter.para[i].type = "TEXT"
      else
        widget:SetValue(true)
      end
      manageRadioButtons(widget, iBox)
    end,L["textDesc"])
    RPMGui.addRadioButton(L["say"], 150, (_type == "SAY"),iBox,iBox,function(widget)
      if widget:GetValue() then
        chapter.para[i].type = "SAY"
      else
        widget:SetValue(true)
      end
      manageRadioButtons(widget, iBox)
    end,L["sayDesc"])
    RPMGui.addRadioButton(L["emote"], 150, (_type == "EMOTE"),iBox,iBox,function(widget)
      if widget:GetValue() then
        chapter.para[i].type = "EMOTE"
      else
        widget:SetValue(true)
      end
      manageRadioButtons(widget, iBox)
    end,L["emoteDesc"])
    RPMGui.addRadioButton(L["yell"], 150, (_type == "YELL"),iBox,iBox,function(widget)
      if widget:GetValue() then
        chapter.para[i].type = "YELL"
      else
        widget:SetValue(true)
      end
      manageRadioButtons(widget, iBox)
    end,L["yellDesc"])
  end
  scroll:DoLayout()  
end

function RPM_addParagraph(questID, chapterNr)
  local chapter = RPMAccountDB.quests[questID].chapters[chapterNr]
  chapter.para[#chapter.para+1] = { text="", type="EMOTE" }
  RPM_updateChapterManFrm(questID, chapterNr)
end

function RPM_setSound(questID, chapterNr)
  if RPManager:isSoundFileIdsLoaded() then
    RPM_drawSoundPicker(RPMAccountDB.quests[questID].chapters[chapterNr].sound, function(path)
      RPMAccountDB.quests[questID].chapters[chapterNr].sound = path
      RPMAccountDB.quests[questID].chapters[chapterNr].soundFileId = RPManager:getFileId(path:lower())
      RPMUtil.stopSound()
      RPM_updateChapterManFrm(questID, chapterNr)
      RPMUtil.playSound(path)
    end)
  else
    RPMForm.createInputDialog(L["soundFileId"], L["soundFileIdDesc"], RPMAccountDB.quests[questID].chapters[chapterNr].sound, function(self)
      local id = tonumber(self:GetText())
      if (id ~= nil) then
        RPMAccountDB.quests[questID].chapters[chapterNr].soundFileId = id
      end
    end)
  end
end
 
function RPM_setIcon(questID, chapterNr)
  if RPManager.iconPickerDialog == nil then
    RPManager.iconPickerDialog = RPMForm.createIconWindow()
  end
  RPManager.iconPickerDialog.obj = RPMAccountDB.quests[questID].chapters[chapterNr]
  RPManager.iconPickerDialog.parent = RPManager.managerFrame
  RPManager.iconPickerDialog:Show()
end


-- Manager Scene Frame

function RPM_openSceneManFrm(questID, chapterNr)
  if RPManager.managerFrame == nil then
    RPManager.managerFrame = RPMForm.drawBaseFrame("RPManager", "manager", RPM_closeManagerFrame)
  else
    RPManager.managerFrame:ReleaseChildren()
  end
  
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]

  local f = RPManager.managerFrame
  
  local grp1 = RPMGui.addSimpleGroup("Flow", f)
  f.icon = RPMGui.addIcon(chapter.path,32,grp1,function()
    RPM_setIcon(questID, chapterNr)
  end)
  f.icon:SetWidth(35)
  f.title = RPMGui.addEditBox("",chapter.title,300,100,grp1,function(self)
    chapter.title = self:GetText()
  end)
  
  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["publish"],150,grp2,function()
    RPMPublish.publish(questID)
  end, L["publishDesc"])
  
  local grp3 = RPMGui.addInlineGroup("", "Flow", f)
  local txt = RPMGui.addTextArea(11, 1000, chapter.scene, grp3,function(widget, event)
    chapter.scene = widget:GetText()
  end)

  RPMGui.addButton(L["checkScene"],150,grp3,function()
    RPM_checkOrTestScene(questID, chapterNr, true)
  end, L["checkSceneDesc"])
  RPMGui.addButton(L["testScene"],150,grp3,function()
    RPM_checkOrTestScene(questID, chapterNr, false)
  end, L["testSceneDesc"])
  
  addTriggerBlock(questID, chapterNr, f)

  RPMGui.addBackButton(f, function() RPM_openQuestManFrm(questID) end)
end

function RPM_checkOrTestScene(questID, chapterNr, checkOnly)
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  
  local isOk = RPMMovie.checkMovie(chapter.scene)
  if isOk and not checkOnly then
    RPMMovie.startMovie(chapter.scene, true, nil)
  end
end


-- Manager Combat Frame

function RPM_openCombatManFrm(questID, chapterNr)
  if RPManager.managerFrame == nil then
    RPManager.managerFrame = RPMForm.drawBaseFrame("RPManager", "manager", RPM_closeManagerFrame)
  else
    RPManager.managerFrame:ReleaseChildren()
  end

  if RPManager.combatManagerFrame == nil then
     RPM_drawCombatManagerFrame(questID, chapterNr)
  end

  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  
  local f = RPManager.managerFrame
  
  f:SetCallback("OnClose", function()
    chapter.start = RPM_mobList2String(RPManager.managerFrame.mobList)
    RPM_closeCombatManagerFrame()
    RPM_closeManagerFrame()
  end)
  
  local grp1 = RPMGui.addSimpleGroup("Flow", f)
  f.icon = RPMGui.addIcon(chapter.path,32,grp1,function()
    RPM_setIcon(questID, chapterNr)
  end)
  f.icon:SetWidth(35)
  f.title = RPMGui.addEditBox("",chapter.title,300,100,grp1,function(self)
    chapter.title = self:GetText()
  end)
  
  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["addOpponent"],150,grp2,function()
    RPM_addMob(questID, chapterNr)
  end, L["addOpponentDesc"])

  RPMGui.addDropdown(chapter.map,150,RPM_textureSet,RPM_textureOrder,grp2,function(_,_,key)
    RPM_setMapTexture(questID, chapterNr, key)
  end)
  RPMGui.addButton(L["showMap"],150,grp2,function()
    if RPManager.combatManagerFrame == nil then
      RPM_drawCombatManagerFrame(questID, chapterNr)
      RPM_updateCombatManFrm(questID, chapterNr)
    end
  end, L["showMapDesc"])
  RPMGui.addButton(L["publish"],150,grp2,function()
    RPMPublish.publish(questID)
  end, L["publishDesc"])
  
  f.scroll = RPMGui.addScrollBox(f, 243, "List")

  addTriggerBlock(questID, chapterNr, f, RPM_updateCombatManFrm)

  RPMGui.addBackButton(f, function()
    chapter.start = RPM_mobList2String(RPManager.managerFrame.mobList)
    RPM_closeCombatManagerFrame()
    RPM_openQuestManFrm(questID)
    RPManager.managerFrame:SetCallback("OnClose", RPM_closeManagerFrame)
  end)
  
  f.mobList = RPM_mobString2List(chapter.start)
  RPM_updateCombatManFrm(questID, chapterNr)
  -- RPMUtil.playSound(chapter.sound)
end

function RPM_closeCombatManagerFrame()
  if RPManager.combatManagerFrame ~= nil then
    for mobNr, mob in ipairs(RPManager.managerFrame.mobList) do
      RPM_removeToken(mob)
    end

    RPManager.combatManagerFrame.frame:SetScript("OnUpdate", nil)
    RPManager.combatManagerFrame:Hide()
    RPManager.combatManagerFrame = nil
  end
end

function RPM_drawCombatManagerFrame(questID, chapterNr)
  local f = RPMForm.drawBaseFrame("RPCombat", "combat", RPM_closeCombatManagerFrame)
  RPManager.combatManagerFrame = f
  f:SetLayout("Fill")
  f:SetWidth(RPMCharacterDB.profile["combat"]["w"] or 700)
  f:SetHeight(RPMCharacterDB.profile["combat"]["h"] or 500)
  
  local grp = RPMGui.addSimpleGroup("Flow", f)
  local t = grp.frame:CreateTexture(nil, "BACKGROUND")
  f.map = grp.frame
  f.tex = t
  f.owner = UnitName("player")
  t:SetAllPoints(grp.frame)
  t:SetHorizTile(true) -- note: SetTexture must also have
  t:SetVertTile(true)  -- both tilings set to true

  f.frame:SetScript("OnUpdate", RPM_onUpdateCombatManagerFrame)
  
  RPM_setMapTexture(questID, chapterNr)
end

function RPM_onUpdateCombatManagerFrame()
  if RPManager.managerFrame ~= nil then
    RPM_checkTokenVisibility(RPManager.managerFrame.mobList, RPManager.combatManagerFrame)
  end
end

function RPM_setMapTexture(questID, chapterNr, tex)
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]

  if tex == nil then
    RPManager.combatManagerFrame.tex:SetTexture(RPM_TEXTURE_PATH..chapter.map, true, true)
  else
    if RPManager.combatManagerFrame ~= nil then
      RPManager.combatManagerFrame.tex:SetTexture(RPM_TEXTURE_PATH..tex, true, true)
    end
    chapter.map = tex
  end
end

function RPM_updateCombatManFrm(questID, chapterNr)
  local scroll = RPManager.managerFrame.scroll
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  
  scroll:ReleaseChildren()
  if #RPManager.managerFrame.mobList == 0 or RPManager.managerFrame.mobList[1] == "" then
    RPMGui.addLabel(L["noOpponents"],scroll,RPMFont.ARIAL,20)
  else
    for mobNr, mob in ipairs(RPManager.managerFrame.mobList) do
      local iBox = RPMGui.addInlineGroup("", "Flow", scroll)

      RPMGui.addShortLabel(mobNr..")",iBox, RPMFont.FRITZ, 30, 16)

      RPMGui.addSpacer(iBox, 10)

      local i = RPMGui.addIcon("interface/icons/"..mob.icon,32,iBox,function(self)
        RPM_setToken(questID, chapterNr, mob, self)
      end)
      i:SetWidth(35)

      RPMGui.addSpacer(iBox, 10)

      RPMGui.addEditBox("", mob.name, 200, 30, iBox, function(self)
        mob.name = self:GetText()
      end)

      RPMGui.addSpacer(iBox, 10)

      RPMGui.addShortLabel(L["scaling"], iBox, RPMFont.FRITZ, 100, 16)
      RPMGui.addSlider(" ", 1, 3, .5, mob.scale, iBox, function(self,_,val)
        RPM_scaleMob(questID, chapterNr, mobNr, val)
      end, L["scalingDesc"])

      RPMGui.addSpacer(iBox, 40)

      local c = RPMGui.addCheckbox("", mob.visible ,iBox ,function(self)
        RPM_toggleVisibility(mobNr, self:GetValue())
      end, L["visibleDesc"])
      c:SetWidth(30)
      RPMGui.addShortLabel(L["visible"], iBox, RPMFont.FRITZ, 90, 16)

      RPMGui.addSpacer(iBox, 10)

      RPMGui.addRadioButton("", 20, mob.anchor, iBox, scroll, function(self)
        if self:GetValue() then
          for _, m in ipairs(RPManager.managerFrame.mobList) do
            m.anchor = false
          end
          mob.anchor = true
        else
          self:SetValue(true)
        end
        manageRadioButtons(self, scroll)
      end,L["anchorPointDesc"])
      RPMGui.addShortLabel(L["anchorPoint"], iBox, RPMFont.FRITZ, 120, 16)

      RPMGui.addSpacer(iBox, 90)

      RPMGui.addButton(L["duplicate"],100,iBox,function()
        RPM_addMob(questID, chapterNr, mob.name, mob.icon, mob.scale)
      end, L["duplicateDesc"])
      RPMGui.addButton(L["delete"],100,iBox,function()
        RPM_deleteMob(questID, chapterNr, mobNr)
      end, L["deleteOpponentDesc"])
      if mob.token == nil then
        RPM_putToken(mob, RPManager.combatManagerFrame, true)
      end
    end
  end
  scroll:DoLayout()
end

function RPM_addMob(questID, chapterNr, name, icon, scale)
  local mob = {}
  mob.name = name or L["newOpponent"]
  RPManager.managerFrame.mobList[#RPManager.managerFrame.mobList+1] = mob
  mob.mobNr = #RPManager.managerFrame.mobList
  mob.x = (mob.mobNr-1)*32
  mob.y = 0
  mob.icon = icon or "inv_misc_questionmark"
  mob.scale = scale or 1.5
  mob.anchor = false
  mob.visible = true
  RPM_updateCombatManFrm(questID, chapterNr)
end

function RPM_deleteMob(questID, chapterNr, mobNr)
  local mob = RPManager.managerFrame.mobList[mobNr]
  RPM_removeToken(mob)
  table.remove(RPManager.managerFrame.mobList,mobNr)
  for mobNr, mob in ipairs(RPManager.managerFrame.mobList) do
    RPM_removeToken(mob)
    mob.mobNr = mobNr
    RPM_putToken(mob, RPManager.combatManagerFrame, true)
  end
  RPM_updateCombatManFrm(questID, chapterNr)
end

function RPM_scaleMob(questID, chapterNr, mobNr, val)
  local mob = RPManager.managerFrame.mobList[mobNr]
  mob.scale = val
  RPM_removeToken(mob)
  RPM_putToken(mob, RPManager.combatManagerFrame, true)
end

function RPM_toggleVisibility(mobNr, visible)
  local mob = RPManager.managerFrame.mobList[mobNr]
  mob.visible = visible
  local a = (visible and 1) or .5
  mob.token:SetAlpha(a)
end

function RPM_setToken(questID, chapterNr, mob, tokenBtn)
  local iconWin = libIco:CreateIconSelectorWindow("MyTokenWindow",UIParent,{})
  iconWin:SetPoint("CENTER")
  iconWin:SetFrameStrata("FULLSCREEN_DIALOG")
  iconWin:SetScript("OnOkayClicked", function(self) 
    local id = self.iconsFrame:GetSelectedIcon()
    local _,_,ico = self.iconsFrame:GetIconInfo(id)
    mob.icon = ico
    if mob.token ~= nil then
      mob.token.tex:SetTexture("interface/icons/"..ico)
    end
    tokenBtn:SetImage("interface/icons/"..ico)
    iconWin:Hide()
    iconWin = nil
  end)
  iconWin:Show()
end

function RPM_setMobIcon(questID, chapterNr, mobNr, tex)
  local mobList = RPM_mobString2List(str)
  mobList[mobNr].icon = tex
  
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  chapter.start = RPM_mobList2String(mobList)
end


-- Item

function RPM_openItemManFrm(questID, chapterNr)
  if RPManager.managerFrame == nil then
    RPManager.managerFrame = RPMForm.drawBaseFrame("RPManager", "manager", RPM_closeManagerFrame)
  else
    RPManager.managerFrame:ReleaseChildren()
  end
  
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]

  local f = RPManager.managerFrame
  
  local grp1 = RPMGui.addSimpleGroup("Flow", f)
  f.icon = RPMGui.addIcon(chapter.path,32,grp1,function()
    RPM_setIcon(questID, chapterNr)
  end)
  f.icon:SetWidth(35)
--  f.title = RPMGui.addEditBox("",item.name,200,100,grp1,function(self)
--    item.name = self:GetText()
--  end)
  
  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["publish"],150,grp2,function()
    RPMPublish.publish(questID)
  end, L["publishDesc"])
  
  local grp3 = RPMGui.addInlineGroup("", "Flow", f)
  local txt = RPMGui.addTextArea(11, 50000, chapter.script, grp3, function(widget, event)
    chapter.script = widget:GetText()
  end)

  RPMGui.addButton(L["testScript"],150,grp3,function()
    RPM_runScript(questID, chapterNr)
  end, L["testScriptDesc"])
  
  addTriggerBlock(questID, chapterNr, f)

  RPMGui.addBackButton(f, function() RPM_openQuestManFrm(questID) end)
end

function RPM_runScript(questID, chapterNr)
  local quest = RPMAccountDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  RunScript(chapter.script)
end
