RPManager = LibStub("AceAddon-3.0"):NewAddon("RPManager",
    "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local minimapBtn = LibStub("LibDBIcon-1.0")

local UPDATE_INTERVAL = .5

local timer = 0
local soundFileIdsLoaded = false
local openWhitelist

local interfaceOptions = {
  name = "RPManager",
  handler = RPManager,
  type = "group",
  args = {
    -- command line arguments
    man = {
      type = "input",
      name = L["manager"],
      hidden = true,
      get = false,
      set = function() RPManager:openManager() end,
    },
    jou = {
      type = "input",
      name = L["journal"],
      hidden = true,
      get = false,
      set = function() RPManager:openJournal() end,
    },

    -- entries in interface options
    h1 = {
      type = "group",
      name = L["visibility"],
      inline = true,
      order = 1,
      args = {
        toggleMinimap = {
          type = "toggle",
          order = 2,
          name = L["toggleMinimap"],
          width = 3,
          desc = L["toggleMinimapDesc"],
          get = function() return RPManager.isMiniMapButtonVisible() end,
          set = function(_, val) RPManager:toggleMinimapButton(val) end,
        },
        toggleToolbar = {
          type = "toggle",
          order = 3,
          name = L["toggleTBar"],
          width = 3,
          desc = L["toggleTBarDesc"],
          get = function() return RPManager.isToolbarVisible() end,
          set = function(_, val) RPManager:toggleToolbar(val) end,
        },
      }
    },

    h2 = {
      type = "group",
      name = L["reset"],
      inline = true,
      order = 11,
      args = {
        centerToolbar = {
          type = "execute",
          order = 11,
          name = L["centerTBar"],
          desc = L["centerTBarDesc"],
          func = function() RPMForm.centerFrame(RPManager.toolBar, "toolbar") end,
        },
        centerManager = {
          type = "execute",
          order = 12,
          name = L["centerManager"],
          desc = L["centerManagerDesc"],
          func = function() RPMForm.centerFrame(RPManager.managerFrame, "manager") end,
        },
        centerJournal = {
          type = "execute",
          order = 13,
          name = L["centerJournal"],
          desc = L["centerJournalDesc"],
          func = function() RPMForm.centerFrame(RPManager.journalFrame, "journal") end,
        },
        centerItemEditor = {
          type = "execute",
          order = 14,
          name = L["centerItemEditor"],
          desc = L["centerItemEditorDesc"],
          func = function() RPMForm.centerFrame(RPManager.itemFrame, "item") end,
        },
        centerBag = {
          type = "execute",
          order = 15,
          name = L["centerBag"],
          desc = L["centerBagDesc"],
          func = function()
            for i = 1, 9 do
              if RPMCharacterDB.profile["bag"..i] ~= nil then
                RPMForm.centerFrame(RPManager.bagFrame, "bag"..i)
              end
            end
          end,
        },
        dq = {
          type = "execute",
          order = 16,
          name = L["resetDefault"],
          func = function() RPManager:resetDefaultQuest() end,
        },
      }
    },

    h3 = {
      type = "group",
      name = L["bag"],
      inline = true,
      order = 21,
      args = {
--        script = {
--          type = "group",
--          name = "",
--          inline = true,
--          order = 22,
--          args = {
--            scriptPermissionDesc = {
--              type = "description",
--              order = 23,
--              name = "|CFFFF0000"..L["scriptPermissionDesc"],
--              fontSize = "medium",
--              width = "full",
--            },
--            scriptPermission = {
--              type = "select",
--              order = 24,
--              name = L["scriptPermission"],
--              width = 1,
--              values = {
--                ["blockScript"] = L["blockScript"],
--                ["queryScript"] = L["queryScript"],
--                ["whitelistScript"] = L["whitelistScript"],
--              },
--              --          sorting = {"blockScript", "queryScript" },
--              style = "radio",
--              get = function() return RPMCharacterDB.profile.scriptPermissions end,
--              set = function(_, val) RPMCharacterDB.profile.scriptPermissions = val end,
--            },
--            whitelist = {
--              type = "execute",
--              order = 25,
--              name = L["whitelist"],
--              func = function() openWhitelist() end,
--            },
--          }
--        },
        numBags = {
          type = "range",
          order = 26,
          name = L["numBags"],
          min = 1,
          max = 9,
          step = 1,
          width = 1,
          desc = L["numBagsDesc"],
          validate = false,
          get = function() return RPMCharacterDB.profile.numBags end,
          set = function(_, val) RPMCharacterDB.profile.numBags = val end,
        },
        numBagsDesc = {
          type = "description",
          order = 27,
          name = L["numBagsDescLong"],
          fontSize = "medium",
          width = 2,
        },
      },
    },

    h4 = {
      type = "group",
      name = L["credits"],
      inline = true,
      order = 31,
      args = {
        credits = {
          type = "execute",
          order = 32,
          name = L["credits"],
          func = function() RPManager:showCredits() end,
        },
      }
    },
  },
}

local libDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("RPManager", {
  type = "data source",
  text = "RPManager",
  icon = "Interface/Icons/ability_priest_angelicfeather",

  OnClick = function(_, btn)
    if btn == "RightButton" then
      RPM_openManager()
    elseif btn == "LeftButton" then
      RPM_openJournal()
    elseif btn == "MiddleButton" then
      RPManager:toggleToolbar(true)
    end
  end,

  OnTooltipShow = function(ttip) 
    ttip:AddLine("RPManager", 1, 1, 1)
    ttip:AddLine(L["leftClick"], 1, .8, .2)
    ttip:AddLine(L["rightClick"], 1, .8, .2)
    ttip:AddLine(L["middleClick"], 1, .8, .2)
    ttip:AddLine(L["dragDrop"], 1, .8, .2)
  end,
})

RPManager.toolBar = nil
RPManager.managerFrame = nil
RPManager.combatManagerFrame = nil
RPManager.journalFrame = nil
RPManager.combatJournalFrame = nil
RPManager.creditFrame = nil
RPManager.bagFrame = nil
RPManager.itemFrame = nil
RPManager.bookFrame = nil
RPManager.tokenFrame = nil
RPManager.diceTrackerFrame = nil
RPManager.soundPickerDialog = nil
RPManager.mapPickerDialog = nil
RPManager.iconPickerDialog = nil

--
-- Init
--

local function greet()
  for i = 1, 4 do
    RPMUtil.msg(L["greet"..i])
  end
end

function RPManager:OnInitialize()
  if not self.mainUpdater then
    self.mainUpdater = CreateFrame("Frame")
    self.progressBarUpdater = CreateFrame("Frame")
  end

  self:initAccountDB()
  self:initCharDB()
  self:initTRPCheck()
  self:initRPMItemsCheck()

  RPMIO.registerAddonMessagePrefix()
  minimapBtn:Register("RPManagerDB", libDataBroker, RPMCharacterDB.profile.minimap)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("RPManager", interfaceOptions)
  self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RPManager", "RPManager")
  self:RegisterChatCommand("rpm", "handleChatCommand")

  greet()
end

function RPManager:OnEnable()
  self:RegisterEvent("CHAT_MSG_ADDON")
  self:RegisterEvent("RAID_ROSTER_UPDATE")
  self:RegisterEvent("GROUP_ROSTER_UPDATE")
  self.mainUpdater:SetScript("OnUpdate", RPM_onUpdate)
  self.progressBarUpdater:SetScript("OnUpdate", RPMProgressBar.onUpdate)

  self:fillMapList()
  self:fillMapTileList()
  
  self:startToolBar()
end

function RPManager:OnDisable()
  self:UnregisterEvent("CHAT_MSG_ADDON")
  self:UnregisterEvent("RAID_ROSTER_UPDATE")
  self:UnregisterEvent("GROUP_ROSTER_UPDATE")
  self.mainUpdater:SetScript("OnUpdate", nil)
  self.progressBarUpdater:SetScript("OnUpdate", nil)

  self.toolBar:Hide()
end

function RPManager:handleChatCommand(input)
  if not input or input:trim() == "" then
    RPManager:toggleToolbar(true)
  else
    LibStub("AceConfigCmd-3.0"):HandleCommand("rpm", "RPManager", input)
  end
end

function RPManager:openManager()
  RPM_openManager()
end

function RPManager:openJournal()
  RPM_openJournal()
end

function RPManager:isMiniMapButtonVisible()
  return not RPMCharacterDB.profile.minimap.hide
end

function RPManager:toggleMinimapButton(visible)
  RPMCharacterDB.profile.minimap.hide = not visible
	if RPMCharacterDB.profile.minimap.hide then
		minimapBtn:Hide("RPManagerDB")
	else
		minimapBtn:Show("RPManagerDB")
  end
end

function RPManager:isToolbarVisible()
  return not RPMCharacterDB.profile.toolbar.hide
end

function RPManager:toggleToolbar(visible)
  RPMCharacterDB.profile.toolbar.hide = not visible
	if RPMCharacterDB.profile.toolbar.hide then
		RPManager.toolBar:Hide()
	else
		RPManager.toolBar:Show()
  end
end

function RPManager:isSoundFileIdsLoaded()
  return soundFileIdsLoaded
end

function RPManager:CHAT_MSG_ADDON(_, ident, msg, _, sender)
  sender = RPMUtil.getLocalName(sender)
  if RPMIO.messageFields[ident] == nil or
          sender == UnitName("player") then
    return
  end

  local msgFields = RPMIO.parseMessage(ident, msg, sender)

  if ident == RPMIO.MSG_SEND_QUEST then
    RPMSynch.receiveNewQuest(msgFields)
  elseif ident == RPMIO.MSG_SEND_CHAPTER then
    RPMSynch.receiveNewChapter(msgFields)
  elseif ident == RPMIO.MSG_SHOW_CHAPTER then
    RPMSynch.activateChapter(msgFields.questID, msgFields.chapterNr, false, true)
  elseif ident == RPMIO.MSG_COMBAT_DATA then
    RPM_updateCombat({ strsplit(";", msgFields.data) })
  elseif ident == RPMIO.MSG_SEND_ITEM_REQ then
    RPMSynch.receivedItemSendRequest(msgFields)
  elseif ident == RPMIO.MSG_SEND_ITEM_PERM then
    RPMSynch.receivedItemSendPermission(msgFields)
  elseif ident == RPMIO.MSG_SEND_ITEM then
    RPMSynch.receiveNewItem(msgFields)
  elseif ident == RPMIO.MSG_SEND_ITEM_STAT then
    RPMSynch.receiveItemSendStatusUpdate(msgFields)
  elseif ident == RPMIO.MSG_SYNCH_QRY then
    RPMSynch.sendQuestProgress(msgFields)
  elseif ident == RPMIO.MSG_SYNCH_ANS then
    RPMSynch.receiveQuestProgress(msgFields)
  end
end

local function groupAction()
  if IsInGroup() then
    RPMSynch.queryQuestProgressDelayed()
  else
    for _, q in pairs(RPMCharacterDB.quests) do
      q.active = false
    end
  end
end

function RPManager:GROUP_ROSTER_UPDATE()
  groupAction()
end

function RPManager:RAID_ROSTER_UPDATE()
  groupAction()
end

local function checkCondition(questID, chapterNr)
  local quest = RPMCharacterDB.quests[questID]
  local chapter = quest.chapters[chapterNr]
  if chapter.visible then
    return
  end

  if chapter.conditiontype == RPManager.CONDITION_TYPE_AUTO then
    RPMSynch.activateChapter(questID, chapterNr, false, true)
  elseif chapter.conditiontype == RPManager.CONDITION_TYPE_PERSON and
          chapter.condition == UnitName("target") and
          CheckInteractDistance("target", 3) then
    RPMSynch.activateChapter(questID, chapterNr, true, true)
  elseif chapter.conditiontype == RPManager.CONDITION_TYPE_POSITION then
    local zone, xs, ys = strsplit(";", chapter.condition)
    local x1, y1 = tonumber(xs), tonumber(ys)
    local x2, y2 = UnitPosition("player")
    if zone == GetZoneText() and ((x2 - x1)^2 + (y2 - y1)^2)^0.5 <= 5 then
      RPMSynch.activateChapter(questID, chapterNr, true, true)
    end
  end
end

local function checkChaptersMeetCondition()
  if RPMCharacterDB == nil then
    return
  end

  for questID, quest in pairs(RPMCharacterDB.quests) do
    local isPreviousChapterVisible = true
    for chapterNr = 1, #quest.chapters do
      if not isPreviousChapterVisible then
        return
      end
      checkCondition(questID, chapterNr)
      isPreviousChapterVisible = quest.chapters[chapterNr].visible
    end
  end
end

function RPM_onUpdate(_, elapsed)
  timer = timer + elapsed
  if timer < UPDATE_INTERVAL then
    return
  end
  timer = 0

  if not soundFileIdsLoaded and IsAddOnLoaded("SoundFileIds") then
    soundFileIdsLoaded = true
    RPManager:fillSoundList()
  end

  checkChaptersMeetCondition()
end
