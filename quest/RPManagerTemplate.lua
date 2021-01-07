if RPMTemplate ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local function setBaseValues(questID, chapter, chapterNr)
  chapter.id = RPMUtil.createID()
  chapter.sound = ""
  chapter.soundFileId = 0
  chapter.published = false
  chapter.condition = ""
  if chapterNr == 1 then
    chapter.conditiontype = RPManager.CONDITION_TYPE_AUTO
    chapter.visible = true
  else
    chapter.conditiontype = RPManager.CONDITION_TYPE_MANUAL
    chapter.visible = false
  end

  RPMAccountDB.quests[questID].chapters[chapterNr] = chapter
end

RPMTemplate = {
  setNewQuest = function()
    local questID = RPMUtil.createID()
    local quest = {
      quest = questID,
      title = L["noTitle"],
      gm = UnitName("player"),
      active = false, -- only needed in journal
      gfx = "",
      chapters = {}
    }
    RPMAccountDB.quests[questID] = quest
  end,

  setNewChapter = function(questID)
    local i = #(RPMAccountDB.quests[questID].chapters)+1
    local chapter = {}
    setBaseValues(questID, chapter, i)
    chapter._type = RPManager.CHAPTER_TYPE_NORMAL
    chapter.title = L["newChapter"]
    chapter.path = "interface/icons/inv_misc_scrollunrolled01"

    chapter.para = {}
    for j = 1, 3 do
      chapter.para[j] = { text = "", type = "EMOTE" }
    end
  end,

--  setNewItemChapter = function(questID)
--    local i = #(RPMAccountDB.quests[questID].chapters)+1
--    local chapter = {}
--    setBaseValues(questID, chapter, i)
--    chapter._type = RPManager.CHAPTER_TYPE_ITEM
--    chapter.title = L["newItem"]
--    chapter.path = "interface/icons/item_shop_giftbox01"
--
--    chapter.id = ""
--    chapter.itemtype = ""
--    chapter.version = 1
--  end,

  setNewScene = function(questID)
    local i = #(RPMAccountDB.quests[questID].chapters)+1
    local chapter = {}
    setBaseValues(questID, chapter, i)
    chapter._type = RPManager.CHAPTER_TYPE_SCENE
    chapter.title = L["newCutscene"]
    chapter.path = "interface/icons/inv_misc_film_01"

    chapter.scene = ""
  end,

  setNewCombat = function(questID)
    local i = #(RPMAccountDB.quests[questID].chapters)+1
    local chapter = {}
    setBaseValues(questID, chapter, i)
    chapter._type = RPManager.CHAPTER_TYPE_COMBAT
    chapter.title = L["newCombat"]
    chapter.path = "interface/icons/achievement_arena_2v2_4"

    chapter.map = "grass"
    chapter.start = ""
    chapter.save = ""
  end,

  setNewTooltip = function()
    return { quality = "1", left = "", right = "",
      white = "", gold = "", usage = "" }
  end,

  setNewItem = function(itemType, data, targetDB)
    if targetDB == nil then
      targetDB = RPMAccountDB
    end
    local slot = RPMBag.getFirstEmptySlot(targetDB)
    if slot == 0 then
      RPMUtil.msg(L["bagFull2"])
      return nil
    end

    local item = {}
    item.version = 0
    item.type = itemType

    if data ~= nil then
      item.tooltip = { quality = data.quality, left = data.left,
        right = data.right, white = data.desc, gold = data.comment,
        usage = data.usage }
    else
      item.tooltip = RPMTemplate.setNewTooltip()
    end

    if itemType == RPManager.ITEM_TYPE_SIMPLE then
      item.name = L["newSimple"]
      item.path = "interface/icons/inv_misc_enggizmos_swissarmy"
    elseif itemType == RPManager.ITEM_TYPE_SPECIAL then
      item.type = RPManager.ITEM_TYPE_SCRIPT
      item.name = data.name
      item.path = data.icon
      item.customization, item.script = RPManagerItems:getItem(data.id)
    elseif itemType == RPManager.ITEM_TYPE_SCRIPT then
      item.name = L["newScript"]
      item.path = "interface/icons/trade_engineering"
      item.customization = ""
      item.script = ""
    elseif itemType == RPManager.ITEM_TYPE_MAP then
      item.name = L["newMap"]
      item.path = "interface/icons/inv_misc_map08"
      item.map = ""
      item.tokens = ""
      item.anim = false
    elseif itemType == RPManager.ITEM_TYPE_BOOK then
      item.name = L["newBook"]
      item.path = "interface/icons/inv_misc_book_06"
      item.bookType = "journal"
      item.pages = {
        { fields = {} } -- Page 1
      }
      item.currPage = 1
    elseif itemType == RPManager.ITEM_TYPE_EMOTE then
      item.name = L["newEmote"]
      item.path = "interface/icons/wow_token01"
      item.forceStand = false
      item.emotes = {
        { emote = "", delay = 0 } -- 1st emote
      }
    end

    if data ~= nil then
      if data.name ~= nil then
        item.name = data.name
      end
      if data.icon ~= nil then
        item.path = data.icon
      end
    end

    local id = RPMUtil.createID()
    targetDB.items[id] = item
    targetDB.bag[slot].item = id
    return targetDB.items[id], id
  end,
}
