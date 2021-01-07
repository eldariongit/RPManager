if RPMBag ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local RPM_ITEM_SIZE = 36

local drawItemFrame
local selectableItems = {
  { text = L["chooseItemType"], isTitle = true},
  { text = L["simple"], func = function() drawItemFrame(nil, RPManager.ITEM_TYPE_SIMPLE) end },
  { text = L["book"], func = function() drawItemFrame(nil, RPManager.ITEM_TYPE_BOOK) end },
  { text = L["map"], func = function() drawItemFrame(nil, RPManager.ITEM_TYPE_MAP) end },
  { text = L["emote"], func = function() drawItemFrame(nil, RPManager.ITEM_TYPE_EMOTE) end },
}

local function createSpecialItemsEntries()
  local specialEntries = { text = L["special"], hasArrow = true, menuList = {} }
  for _, func in pairs(RPManagerItems:getItems()) do
    local data = func()
    table.insert(specialEntries.menuList,
      { text = data.name, func = function() drawItemFrame(nil, RPManager.ITEM_TYPE_SPECIAL, data) end })
  end
  return specialEntries
end

local function getCurrentDB()
  if RPMCharacterDB.profile.activeBag == RPManager.BAG_TYPE_ACCOUNT then
    return RPMAccountDB
  elseif RPMCharacterDB.profile.activeBag == RPManager.BAG_TYPE_CHAR then
    return RPMCharacterDB
  end
end

local function getOtherDB()
  if RPMCharacterDB.profile.activeBag == RPManager.BAG_TYPE_ACCOUNT then
    return RPMCharacterDB
  elseif RPMCharacterDB.profile.activeBag == RPManager.BAG_TYPE_CHAR then
    return RPMAccountDB
  end
end

local function isInAccountDB()
  return RPMCharacterDB.profile.activeBag == RPManager.BAG_TYPE_ACCOUNT
end

local function getCurrentBagNumAndSlot(itemID)
  for i, slot in ipairs(getCurrentDB().bag) do
    if slot.item == itemID then
      return math.ceil(i / 16), i
    end
  end
end

local function move2Bag(chapter, slot)
  RPMAccountDB.bag[slot].item = chapter.id
  RPMAccountDB.items[chapter.id] = {}
  RPMAccountDB.items[chapter.id].version = chapter.version
  RPMAccountDB.items[chapter.id].script = chapter.script
  RPMBag.updateBag()
end

local function copy2OtherDB(itemID)
  local item = getCurrentDB().items[itemID]
  local otherBag = getOtherDB()

  local isNewItem = (otherBag.items[itemID] == nil)
  if isNewItem then
    local slot = RPMBag.getFirstEmptySlot(otherBag)
    if slot == 0 then
      RPMUtil.msg(L["noMoreSlots"])
      return
    end
    otherBag.bag[slot].item = itemID
  end
  otherBag.items[itemID] = RPMUtil.deepCopy(item)
  if isInAccountDB() then
    RPMUtil.msg(string.format(L["copiedToBagChar"], item.name))
  else
    RPMUtil.msg(string.format(L["copiedToBagAccount"], item.name))
  end
end

local function copyItem(itemID)
  local db = getCurrentDB()
  local item = db.items[itemID]
  local slot = RPMBag.getFirstEmptySlot()
  if slot > 0 then
    local newItem = RPMUtil.deepCopy(item)
    newItem.name = string.format(L["copyOf"], item.name)

    local id = RPMUtil.createID()
    db.items[id] = newItem
    db.bag[slot].item = id
    RPMBag.updateBag()
  end
end

local function deleteItem(slot, itemID, db)
  db.bag[slot].item = nil
  db.items[itemID] = nil
  RPMBag.updateBag()
end

local function deleteItemQuery(slot, itemID)
  local db = getCurrentDB()
  local item = db.items[itemID]
  RPMDialog.showYesNoDialog(string.format(L["deleteQry"], item.name), true, function(self)
    deleteItem(slot, itemID, db)
  end)
end

local function createItemMacro(itemID)
  local item = getCurrentDB().items[itemID]
  local name = item.name:sub(1, 16)

  local c = 2
  while GetMacroIndexByName(name) > 0 do
    name = item.name:sub(1, 13).."~"..tostring(c)
    c = c+1
  end

  local icon = item.path:gsub("interface/icons/", "")
  local macroId = CreateMacro(name, icon, "/script RPM_runItemScript('"..itemID.."')", 1)
  ShowMacroFrame()
  MacroFrame_SetCharacterMacros()
  PanelTemplates_SetTab(MacroFrame, 2)
  local index = GetMacroIndexByName(name)
  MacroFrame_SelectMacro(index)
  MacroFrame_Update()
end

local function setStatusText(p, txt)
  p.status:SetText(txt or "")
end

local function switchStatusBagText(bag)
  if isInAccountDB() then
    setStatusText(bag, L["switchBagChar"])
  else
    setStatusText(bag, L["switchBagAccount"])
  end
end

local function drawCmdButton(x, y, w, h, l, p, txt, func, ttip)
  local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  b:SetText(txt)
  b:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", x, y)
  b:SetSize(w, h)
  b:SetFrameLevel(l)
  b:SetScript("OnClick", func)
  b:SetScript("OnEnter", function() setStatusText(p, ttip) end)
  b:SetScript("OnLeave", function() setStatusText(p) end)
  return b
end

local function closeAdditionalBags()
  for i = #RPManager.bagFrame, 2, -1 do
    RPManager.bagFrame[i]:Hide()
    RPManager.bagFrame[i] = nil
  end
end

local function drawAdditionalBag(num)
  local f = RPMForm.drawBaseBag()
  table.insert(RPManager.bagFrame, f)
  RPMForm.registerFrame(f, "bag"..num)
  RPMGui.addCloseButton(f, 4, -1, function() RPManager.bagFrame[num]:Hide() end)
  return f
end

local function drawAdditionalBags()
  closeAdditionalBags()
  if not isInAccountDB() then
    local numBags = RPMCharacterDB.profile.numBags or 1
    for i = 2, numBags do
      drawAdditionalBag(i)
    end
  end
end

local function drawButton(x, y, p, icon, onClick, onEnter, onLeave)
  local f = CreateFrame("Frame", nil, p)
  f:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", x, y)
  f:SetSize(27, 27)
  f:SetFrameLevel(14)
  local t = f:CreateTexture(nil, "BACKGROUND")
  t:SetAllPoints()
  t:SetTexture("Interface/BUTTONS/UI-Quickslot2")
  t:SetTexCoord(12/64, 51/64, 12/64, 52/64)

  local b = CreateFrame("Button", nil, f)
  b:SetPoint("CENTER", f, "CENTER", 0, 0)
  b:SetSize(24, 24)
  b:SetFrameLevel(15)
  b:SetScript("OnClick", onClick)
  b:SetScript("OnEnter", onEnter)
  b:SetScript("OnLeave", onLeave)

  local t = b:CreateTexture(nil, "BACKGROUND")
  t:SetAllPoints()
  t:SetTexture("Interface/icons/"..icon)

  return b, t
end

local function drawScriptStopButton(p)
  local btn = drawButton(123, 187, p, "inv_misc_enggizmos_27", function()
      RPManager:initScriptExecutionMonitor()
      p.cancelButton:Hide()
    end,
    function() setStatusText(p, L["stopScriptsEmotes"]) end,
    function() setStatusText(p) end)

  p.cancelButton = btn
  if RPManager:isScriptExecuting() then
    p.cancelButton:Show()
  else
    p.cancelButton:Hide()
  end
end

local function drawSwitchButton(p)
  local _, tex = drawButton(153, 187, p, "", function()
      if RPMCharacterDB.profile.activeBag == RPManager.BAG_TYPE_CHAR then
        RPMCharacterDB.profile.activeBag = RPManager.BAG_TYPE_ACCOUNT
      else
        RPMCharacterDB.profile.activeBag = RPManager.BAG_TYPE_CHAR
      end
      drawAdditionalBags()
      RPMBag.updateBag()
      switchStatusBagText(p)
    end,
    function() switchStatusBagText(p) end,
    function() setStatusText(p) end)

  p.switchButtonTex = tex
end

local function getCreator(itemID)
  return itemID:gsub("[%d]", "")
end

-- Source: https://wowwiki.fandom.com/wiki/USERAPI_StringHash
-- License: CC-BY-SA https://creativecommons.org/licenses/by-sa/3.0/
local function getScriptHash(script)
  local counter = 1
  local len = string.len(script)
  for i = 1, len, 3 do
    counter = math.fmod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
            (string.byte(script, i)*16776193) +
            ((string.byte(script, i+1) or (len-i+256))*8372226) +
            ((string.byte(script, i+2) or (len-i+256))*3932164)
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

local function createPopup(slot, itemID)
  local list = {}
  local tar = UnitName("target")
  local player = UnitName("player")

  local item = getCurrentDB().items[itemID]
  table.insert(list, { text = item.name, isTitle = true})

  if tar ~= nil and UnitIsPlayer("target") and tar ~= UnitName("player") then
    local db = getCurrentDB()
    if db == RPMAccountDB then
      table.insert(list, { text = string.format(L["copyTo"], tar), func = function() RPMSynch.sendItem(itemID, tar, db, false) end })
    else
      table.insert(list, { text = string.format(L["tradeTo"], tar), func = function()
        RPMSynch.sendItem(itemID, tar, db, true, slot)
      end })
    end
  end
  if isInAccountDB() then
    if itemID:sub(1, #player) == player then
      table.insert(list, { text = L["edit"], func = function() drawItemFrame(itemID) end})
      table.insert(list, { text = L["copy"], func = function() copyItem(itemID) end })
    end
  end
  if item.type == RPManager.ITEM_TYPE_SCRIPT then
    table.insert(list, { text = L["createMacro"], func = function() createItemMacro(itemID) end})
  end
  table.insert(list, { text = L["delete"], func = function() deleteItemQuery(slot, itemID) end})
  table.insert(list, { text = L["creator"]..": "..getCreator(itemID), isTitle = true})

  if item.type == RPManager.ITEM_TYPE_SCRIPT then
    local hash = getScriptHash(item.script)
    local color = ((RPMWhitelist.isWhitelisted(hash) and "|CFF00FF00") or "|CFFFF0000")
    table.insert(list, { text = L["hash"]..": "..color..hash.."|R", isTitle = true})
  end

  local menuFrame = CreateFrame("Frame", ""..time(), UIParent, "UIDropDownMenuTemplate")
  EasyMenu(list, menuFrame, "cursor", 0 , 0, "MENU", 20)
end

local function putToFront(itemID)
  local num = getCurrentBagNumAndSlot(itemID)
  for _, item in ipairs(RPManager.bagFrame[1].items) do
    if itemID == item.itemID then
      item:SetFrameLevel(101)
    else
      item:SetFrameLevel(100)
    end
  end
end

local function getDroppedBag()
  local offset = 1
  for bagNum, bag in ipairs(RPManager.bagFrame) do
    if bag:IsMouseOver() then
      return bag, bagNum, offset
    end
    offset = offset + RPManager.BAG_SIZE
  end
  return nil, 0, 0
end

local function drawItem(c, r, itemID, p)
  local item = getCurrentDB().items[itemID]
  local slot = r*4 + c + 1
  r = r % 4 -- normalize to rows of current bag
  local i = CreateFrame("Button", nil, p)
  i:SetMovable(true)
  i:EnableMouse(true)
  i:RegisterForDrag("LeftButton")
  i:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 15+c*43, 148-r*41)
  i:SetSize(RPM_ITEM_SIZE, RPM_ITEM_SIZE)

  i:SetScript("OnDragStart", function()
    putToFront(itemID)
    i:StartMoving()
    i.origX = i:GetLeft()
    i.origY = i:GetBottom()
  end)
  i:SetScript("OnDragStop", function()
    i:StopMovingOrSizing()

    local droppedBag, bagNum, firstSlot = getDroppedBag()
    if droppedBag == nil then
      droppedBag = p
    end

    local x, y = i:GetCenter()
    local btm, left = droppedBag:GetBottom(), droppedBag:GetLeft()
    x = math.ceil(x - RPM_ITEM_SIZE/2) - left
    y = math.ceil(y - RPM_ITEM_SIZE/2) - btm
    local c2, r2 = math.floor((x-15)/43+.5), math.floor((148-y)/41+.5)
    if r2 == -1 and c2 == 3 and bagNum == 1 then
      copy2OtherDB(itemID) -- between account and char bag
    elseif c2 < 0 or c2 > 3 or r2 < 0 or r2 > 3 then
      x, y = 15+c*43, 148-r*41
      deleteItemQuery(slot, itemID)
    else
      x, y = 15+c2*43, 148-r2*41
      local db = getCurrentDB()
      local newSlot = firstSlot + r2*4 + c2
      db.bag[slot], db.bag[newSlot] = db.bag[newSlot], db.bag[slot]
    end
    i:ClearAllPoints()
    i:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", x, y)
    RPMBag.updateBag()
  end)
  i:SetScript("OnMouseUp",function(_,btn)
    if btn == "LeftButton" then
      if RPManager.bagFrame[1].editMode then
        local player = UnitName("player")
        if itemID:sub(1, #player) == player then
          drawItemFrame(itemID)
        else
          RPMUtil.msg(string.format(L["notYourItem"], item.name))
        end
      elseif RPManager.bagFrame[1].copyMode then
        copyItem(itemID)
      elseif RPManager.bagFrame[1].delMode then
        deleteItemQuery(slot, itemID)
      else
        if item.type == RPManager.ITEM_TYPE_SCRIPT then
          RPM_runItemScript(itemID)
        elseif item.type == RPManager.ITEM_TYPE_MAP then
          RPM_openMap(itemID)
        elseif item.type == RPManager.ITEM_TYPE_BOOK then
          RPMBook.drawBook(itemID, false)
        elseif item.type == RPManager.ITEM_TYPE_EMOTE then
          RPMEmote.playEmotes(itemID)
        end
      end
    elseif btn == "RightButton" then
      createPopup(slot, itemID)
    end
    RPManager.bagFrame[1].copyMode = false
    RPManager.bagFrame[1].editMode = false
    RPManager.bagFrame[1].delMode = false
    SetCursor(nil)
  end)
  i:SetScript("OnEnter",function()
    local num = getCurrentBagNumAndSlot(itemID)
    setStatusText(RPManager.bagFrame[num], item.name)
    if item.tooltip ~= nil then
      RPMGui.showItemTooltip(i, item)
    end
  end)
  i:SetScript("OnLeave",function()
    local num = getCurrentBagNumAndSlot(itemID)
    setStatusText(RPManager.bagFrame[num])
    RPMGui.hideTooltip()
  end)

  local t = i:CreateTexture(nil, "ARTWORK")
  t:SetTexture(item.path)
  t:SetAllPoints()

  i.itemID = itemID
  return i
end

local function clearItemIcons()
  for _,itemIcon in ipairs(RPManager.bagFrame[1].items) do
    itemIcon:Hide()
    itemIcon = nil
  end
end


RPMBag = {
  getFirstEmptySlot = function(bag)
    local db = bag or getCurrentDB()
    for i = 1, RPManager.BAG_SIZE do
      if db.bag[i].item == nil then
        return i
      end
    end
    return 0
  end,

  -- Copy function for item linked to chapter
  -- Needs more testing!
  copy2Bag = function(questID, chapterNr)
    local quest = RPMAccountDB.quests[questID]
    local item = quest.chapters[chapterNr]

    if item.id == nil or item.id == "" then
      item.id = quest.gm..tostring(time())
    end
    if version == nil or tonumber(item.version) == nil then
      item.version = 1
    end

    local slot = RPMBag.getFirstEmptySlot(RPMCharacterDB)
    if slot == 0 then
      RPMUtil.msg(L["noMoreSlots"])
      return
    end

    move2Bag(item, slot)
  end,

  getItem = function(itemID)
    return getCurrentDB().items[itemID]
  end,

  drawBag = function()
    if RPManager.bagFrame ~= nil and RPManager.bagFrame[1] ~= nil then
      RPMBag.closeBag()
      return
    end

    local f = RPMForm.drawBaseBag(1)
    RPManager.bagFrame = {}
    RPManager.bagFrame[1] = f

    RPMForm.registerFrame(f, "bag")

    RPMGui.addCloseButton(f, 4, -1, RPMBag.closeBag)

    local cmd1 = drawCmdButton(12, 186, 20, 20, 15, f, L["newItemB"], function()
      local menuFrame = CreateFrame("Frame", tostring(GetTime()), UIParent, "UIDropDownMenuTemplate")
      local itemList = RPMUtil.deepCopy(selectableItems)
      if RPMItem.isRPMItemsAvailable() then
        table.insert(itemList, createSpecialItemsEntries())
      end
      EasyMenu(itemList, menuFrame, "cursor", 0 , 0, "MENU")
    end, L["newItemBDesc"])
    local cmd2 = drawCmdButton(32,186,20,20,15,f,L["editItem"],function()
      f.editMode = true
      SetCursor("interface/cursor/interact")
    end, L["editItemDesc"])
    local cmd3 = drawCmdButton(52,186,20,20,15,f,L["copyItem"],function()
      f.copyMode = true
      SetCursor("interface/cursor/interact")
    end,L["copyItemDesc"])
    local cmd4 = drawCmdButton(72,186,20,20,15,f,L["deleteItem"],function()
      f.delMode = true
      SetCursor("interface/buttons/UI-GroupLoot-Pass-Down")
    end,L["deleteItemDesc"])
    RPManager.bagFrame[1].cmdButtons = { cmd1, cmd2, cmd3, cmd4 }

    f:SetScript("OnLeave", function()
      local x,y = GetCursorPosition()
      local b, t, l, r = f:GetBottom(), f:GetTop(), f:GetLeft(), f:GetRight()
      if x < l or x > r or y < b or y > t then
        f.editMode = false
        f.copyMode = false
        f.delMode = false
      end
    end)

    drawScriptStopButton(f)
    drawSwitchButton(f)
    drawAdditionalBags()

    RPManager.bagFrame[1].items = {}
    RPMBag.updateBag()
  end,

  updateBag = function()
    if RPManager.bagFrame == nil or RPManager.bagFrame[1] == nil then
      return
    end

    local isInAccountDB = isInAccountDB()
    for _, cmd in ipairs(RPManager.bagFrame[1].cmdButtons) do
      if isInAccountDB then
        cmd:Show()
      else
        cmd:Hide()
      end
    end

    if RPManager:isScriptExecuting() then
      RPManager.bagFrame[1].cancelButton:Show()
    else
      RPManager.bagFrame[1].cancelButton:Hide()
    end

    local tex2 = (isInAccountDB and "inv_misc_bag_08") or "inv_box_02"
    RPManager.bagFrame[1].switchButtonTex:SetTexture("interface/icons/"..tex2)
    local label = (isInAccountDB and "accountLabel") or "charLabel"
    RPManager.bagFrame[1].label:SetText(L[label])

    clearItemIcons()
    local db = getCurrentDB()
    local maxBags = (isInAccountDB and 1) or 9
    for i = 1, RPManager.BAG_SIZE*maxBags do
      if db.bag[i].item then
        local num = getCurrentBagNumAndSlot(db.bag[i].item)
        local r = math.floor((i-1)/4)
        local c = i - (1+r*4)
        local item = drawItem(c, r, db.bag[i].item, RPManager.bagFrame[num])
        table.insert(RPManager.bagFrame[1].items, item)
      end
    end
  end,

  closeBag = function()
    clearItemIcons()
    for i = #RPManager.bagFrame, 1, -1 do
      RPManager.bagFrame[i]:Hide()
      RPManager.bagFrame[i] = nil
    end
  end,
}


-- Item Editor

local function nextTokenId()
  RPManager.itemFrame.tokenId = RPManager.itemFrame.tokenId+1
  if RPManager.itemFrame.tokenId == 201 then
    RPManager.itemFrame.tokenId = 0
  end
  RPM_udpateMapIcon(RPManager.itemFrame.tokenId)
end

local function prevTokenId()
  RPManager.itemFrame.tokenId = RPManager.itemFrame.tokenId-1
  if RPManager.itemFrame.tokenId == -1 then
    RPManager.itemFrame.tokenId = 200
  end
  RPM_udpateMapIcon(RPManager.itemFrame.tokenId)
end

local function setItemIcon(itemID)
  if RPManager.iconPickerDialog == nil then
    RPManager.iconPickerDialog = RPMForm.createIconWindow()
  end
  RPManager.iconPickerDialog.obj = RPMAccountDB.items[itemID]
  RPManager.iconPickerDialog.parent = RPManager.itemFrame
  RPManager.iconPickerDialog:Show()
end

local function closeItemFrame()
  if RPManager.itemFrame == nil then
    return
  end

  local item = RPMAccountDB.items[RPManager.itemFrame.itemID]
  if RPManager.itemFrame.tokens ~= nil then
    item.tokens = RPM_convTable2String()
  end
  if RPManager.itemFrame.controlPanel then
    RPManager.itemFrame.controlPanel:Hide()
  end
  if RPManager.itemFrame.imageViewer then
    RPManager.itemFrame.imageViewer:Hide()
  end
  RPManager.itemFrame = nil

  if RPManager.tokenFrame ~= nil then
    RPManager.tokenFrame:Hide()
  end
  RPMBook.closeBook()
  RPMBag.updateBag()
end

function drawItemFrame(itemID, _type, data)
  if RPManager.itemFrame == nil then
    RPManager.itemFrame = RPMForm.drawBaseFrame("RPItem", "item", closeItemFrame)
  else
    RPManager.itemFrame:ReleaseChildren()
  end

  local f = RPManager.itemFrame

  local item
  if itemID ~= nil then
    item = RPMAccountDB.items[itemID]
  else
    item, itemID = RPMTemplate.setNewItem(_type, data)
    RPMBag.updateBag()
  end

  RPManager.itemFrame.itemID = itemID

  local grp1 = RPMGui.addSimpleGroup("Flow",f)
  f.icon = RPMGui.addIcon(item.path,32,grp1,function()
    setItemIcon(itemID)
  end)
  f.icon:SetWidth(35)
  f.title = RPMGui.addEditBox("",item.name,150,100,grp1,function(self)
    item.name = self:GetText()
  end)

  RPMGui.addIconButton("interface/addons/RPManager/img/align_center", 23, grp1, function()
    RPMTooltipEditor.drawTooltipEditor(item)
  end, L["tooltipDesc"], 0, 23/32, 0, 23/32)

  if item.type == RPManager.ITEM_TYPE_SCRIPT then
    local grp2 = RPMGui.addSimpleGroup("Flow",f)
    local txt = RPMGui.addTextArea(11, 50000, item.script, grp2, function(self, event)
      -- only view and copy
--      item.script = self:GetText()
    end)
    txt:SetHeight(355)
    RPMGui.addButton(L["testScript"], 150, grp2, function()
      RPM_runItemScript(itemID)
    end, L["testScriptDesc"])
    RPMGui.addSpacer(grp2, 20)
    RPMGui.addShortLabel(L["hash"], grp2, RPMFont.FRITZ, 60, 16)
    RPMGui.addEditBox("", getScriptHash(item.script), 100, 10, grp2, function() end)
  elseif item.type == RPManager.ITEM_TYPE_MAP then
    RPMGui.addButton(L["chooseMap"], 150, grp1, function()
      RPM_setMap(itemID)
    end, L["chooseMapDesc"])

    RPManager.itemFrame.tokens = {}
    RPManager.itemFrame.tokenId = 0
    local i1 = RPMGui.addIcon("interface/icons/misc_arrowleft",20,grp1,prevTokenId)
    i1:SetWidth(30)
    RPM_drawMapIcon(grp1)
    local i2 = RPMGui.addIcon("interface/icons/misc_arrowright",20,grp1,nextTokenId)
    i2:SetWidth(30)

    RPMGui.addButton(L["clearMap"],150,grp1,function()
      RPM_cleanMap(RPManager.itemFrame.tokens)
    end, L["clearMapDesc"])
    RPMGui.addCheckbox(L["chooseAnim"],RPMAccountDB.items[itemID].anim,grp1,function(self)
      RPMAccountDB.items[RPManager.itemFrame.itemID].anim = self:GetValue()
    end,L["chooseAnimDesc"])

    if item.map ~= nil and item.map ~= "" then
      RPM_putMapOnScreen(RPManager.itemFrame, item.map)
    end
    if item.tokens ~= nil and item.tokens ~= "" then
      RPM_convString2Table(item.tokens)
    end
    RPM_drawTokenFrame(itemID)
  elseif item.type == RPManager.ITEM_TYPE_BOOK then
    RPMBook.drawBookFrame(itemID, grp1)
  elseif item.type == RPManager.ITEM_TYPE_EMOTE then
    RPMEmote.drawEmoteFrame(itemID, grp1)
  end
  f:DoLayout()
end

-- Because of calling via macro, don't use getCurrentDB()
function RPM_runItemScript(itemID)
  local item = RPMAccountDB.items[itemID]
  if item == nil then
    item = RPMCharacterDB.items[itemID]
  end
  if item == nil then
    RPMUtil.msg("Item not found")
    return
  end

--  if getCreator(itemID) == UnitName("player") then
--    RunScript(item.script)
--  elseif RPMCharacterDB.profile.scriptPermissions == "blockScript" then
--    RPMUtil.msg("Skriptausführung geblockt.")
--  elseif RPMCharacterDB.profile.scriptPermissions == "queryScript" then
--    local query = ""
--    RPMDialog.showYesNoDialog(query, true, function()
--      RunScript(item.script)
--    end)
--  elseif RPMCharacterDB.profile.scriptPermissions == "whitelistScript" then
    if RPMWhitelist.isWhitelisted(getScriptHash(item.script)) then
      RunScript(item.script)
    end
--  end
end

function RPM_setMap(itemID)
    local filter = RPManager.itemFrame.lastFilter or ""
    RPM_drawMapPicker(filter, function(path, newFilter)
      local item = RPMAccountDB.items[itemID]
      item.map = path
      RPManager.itemFrame.lastFilter = newFilter
      RPM_putMapOnScreen(RPManager.itemFrame, path)
    end)
end

function RPM_calcPos(id)
  local z = math.floor(id/14)
  local s = id-(z*14)
  return s*18/256,(s+1)*18/256,z*18/512,(z+1)*18/512
end

function RPM_drawMapIcon(p)
  local path = "Interface/MINIMAP/POIIcons"
  local x1, x2, y1, y2 = RPM_calcPos(RPManager.itemFrame.tokenId)
  RPManager.itemFrame.token = RPMGui.addImage(path, 20, 20, p, x1, x2, y1, y2)
  RPManager.itemFrame.token:SetWidth(25)
  RPM_udpateMapIcon(RPManager.itemFrame.tokenId)
end

function RPM_udpateMapIcon(id)
  local path, x1, x2, y1, y2 = RPM_getIconById(id)
  RPManager.itemFrame.token:SetImage(path, x1, x2, y1, y2)
end

function RPM_getIconById(id)
  if id == 0 then
    return "Interface/TARGETINGFRAME/UI-SmallTargetingFrame-NoMana", 56/128, 75/128, 7/64, 26/64
  else
    local x1, x2, y1, y2 = RPM_calcPos(id)
    return "Interface/MINIMAP/POIIcons", x1, x2, y1, y2
  end
end

function RPM_openMap(itemID)
  local item = getCurrentDB().items[itemID]
  local t,tokens={},{}
  for v in string.gmatch(item.tokens,"([^|]+)") do
    t[#t+1] = v
  end

  for i=1, #t, 7 do
    local nX, nY = t[i+2], t[i+3]
    if nX == "nil" then
      nX = nil
      nY = nil
    end
    tokens[#tokens+1]={ x=t[i], y=t[i+1], x2=nX, y2=nY, id=t[i+4], num=t[i+5], txt=t[i+6] }
  end

  local tileSet = RPM_getMap(item.map)
  if not tileSet then
    return
  end

  local path = "interface/worldmap/"..item.map..tileSet.delim
  local f = CreateFrame("Frame", nil, UIParent)
  local xTiles, yTiles = 3, 3
  if tileSet.tiles == 4 then
    xTiles = 2
    yTiles = 2
  elseif tileSet.tiles == 12 then
    xTiles = 4
  end

  f.textures = {}
  for id = 1, tileSet.tiles do
    local x = (id-1) % xTiles
    local y = math.floor((id-1) / xTiles)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetTexture(path..id)
    t:SetPoint("TOPLEFT", x*256, -y*256, f)
    f.textures[#f.textures+1] = t
  end

  f:SetSize(256*xTiles+10, 256*yTiles+30)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameLevel(99)

  local pane = CreateFrame("Frame", nil, f)
  pane:SetPoint("CENTER",f,"CENTER",-16,50)
  pane:SetSize(256*xTiles-30, 256*yTiles-80)
  pane:SetFrameLevel(102)
  f.pane = pane

  local cls = RPMGui.addCloseButton(pane, 0, 0, RPM_closeMap)
  cls.parent = f

  local mapX, mapY = 5, 75
  for _,tok in ipairs(tokens) do
    local x, y = tok.x, tok.y
    if tok.x2 == nil then
      tok.ico = RPM_drawIcon(x, y, tok.id, pane, true)
      tok.label = RPM_drawLabel(x+90, y+15, tok.txt, pane)
    else
      local x2, y2 = tok.x2, tok.y2
      tok.ico = RPM_drawLine(x, y, x2, y2, pane)
    end
  end
  f.tokens = tokens

  if item.anim then
    DoEmote("read")
    f.anim = true
  end
end

function RPM_closeMap(self)
  if self.parent.anim then
    DoEmote("read")
  end
  for i = #self.parent.textures, 1, -1 do
    self.parent.textures[i]:Hide()
    self.parent.textures[i] = nil
  end
  for i = #self.parent.tokens, 1, -1 do
    RPM_clearToken(self.parent.tokens[i])
  end
  self.parent.pane:Hide()
  self.parent.pane = nil
end
