if RPMBook ~= nil then
  return
end

RPMBook = {}

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local TYPE_TEXT    = "text"
local TYPE_ICON    = "icon"
local TYPE_TEXTURE = "texture"

local CURRENT_PAGE = "#cur#"
local PAGE_COUNT = "#max#"

local BOOK_TYPES = {
  ["journal"] = {
    path = "Interface/questframe/UI-QuestDetails-",
    parts = {
      {"TopLeft",    0,   0, 235, 179, { 21/256, 1, 77/256, 1 } },
      {"TopRight", 235,   0,  64, 179, { 0, 64/128, 77/256, 1 } },
      {"BotLeft",    0, 179, 235, 155, { 21/256, 1, 0, 155/256 } },
      {"BotRight", 235, 179,  64, 155, { 0, 64/128, 0, 155/256 } },
    },
    area = { 10, 10, -10, -10}, -- TOPLEFT & BOTTOMRIGHT
  },
  ["folio"] = {
    path = "Interface/SPELLBOOK/Spellbook-Page-",
    parts = {
      { "1",   0, 0, 512, 496, {0,     1, 0, 31/32} },
      { "2", 512, 0,  21, 496, {0, 21/32, 0, 31/32} }
    },
    area = { 80, 50, -31, -55}, -- TOPLEFT & BOTTOMRIGHT
  },
  ["parchment"] = {
    path = "Interface/OPTIONSFRAME/UIOptionsFrame-",
    parts = {
      {"TopLeft",       0,   0, 499, 442, { 13/512, 1, 70/512, 1 } },
      {"TopRight",    499,   0, 503, 442, { 0, 503/512, 70/512, 1 } },
      {"BottomLeft",    0, 442, 499, 226, { 13/512, 1, 0, 226/256 } },
      {"BottomRight", 499, 442, 503, 226, { 0, 503/512, 0, 226/256 } },
    },
    area = { 10, 10, -10, -10}, -- TOPLEFT & BOTTOMRIGHT
  },
  ["parchment_small"] = {
    path = "Interface/OPTIONSFRAME/UIOptionsFrame-",
    parts = {
      {"TopLeft",       0,   0, 249, 221, { 13/512, 1, 70/512, 1 } },
      {"TopRight",    249,   0, 251, 221, { 0, 503/512, 70/512, 1 } },
      {"BottomLeft",    0, 221, 249, 113, { 13/512, 1, 0, 226/256 } },
      {"BottomRight", 249, 221, 251, 113, { 0, 503/512, 0, 226/256 } },
    },
    area = { 7, 7, -7, -7}, -- TOPLEFT & BOTTOMRIGHT
  },
}

local bookSet = {
  ["journal"]         = L["journal"],
  ["folio"]           = L["folio"],
  ["parchment"]       = L["parchment"],
  ["parchment_small"] = L["parchment_small"],
}

local themes = { "bronze", "silver", "stone", "marble", "valentine" }
for _, theme in ipairs(themes) do
  BOOK_TYPES["journal_"..theme] = {
    path = "Interface/ItemTextFrame/ItemText-"..theme.."-",
    parts = {
      {"TopLeft",    0,   0, 256, 256 },
      {"TopRight", 256,   0,  64, 256 },
      {"BotLeft",    0, 256, 256, 100, {0, 1, 0, 0.78} },
      {"BotRight", 256, 256,  64, 100, {0, 1, 0, 0.78} },
    },
    area = { 10, 10, -10, -10}, -- TOPLEFT & BOTTOMRIGHT
  }
  bookSet["journal_"..theme] = L["journal_"..theme]
end

local bookOrder = {
  "journal",
  "journal_bronze",
  "journal_silver",
  "journal_stone",
  "journal_marble",
  "journal_valentine",
  "folio",
  "parchment",
  "parchment_small",
}

local iconSelector
local pageClickTimer
local updateBookFrame


local function getItem()
  return RPMAccountDB.items[RPManager.itemFrame.itemID]
end

local function getPage(item)
  return item.pages[item.currPage]
end

local function calcPageDimensions(type)
  local w, h = 0, 0
  for _, part in ipairs(type.parts) do
    w = math.max(w, part[2] + part[4])
    h = math.max(h, part[3] + part[5])
  end
  return w, h
end

local function clearField(id)
  if RPManager.bookFrame.fields[id] ~= nil then
    if RPManager.bookFrame.fields[id].bold ~= nil then
      RPManager.bookFrame.fields[id].bold:Hide()
      RPManager.bookFrame.fields[id].bold = nil
    end
    RPManager.bookFrame.fields[id]:Hide()
    RPManager.bookFrame.fields[id] = nil
  end
end

local function clearPage()
  for id,field in pairs(RPManager.bookFrame.fields) do
    clearField(id)
  end
end

local function modifyText(field)
  local text = string.gsub(field.text, "\n", "<br/>")
  local item = RPMAccountDB.items[field.itemID]
  text = string.gsub(text,"#cur#", ""..item.currPage)
  text = string.gsub(text,"#max#", #item.pages)
  return text
end

local redBorder = {
  edgeFile = RPM_TEXTURE_PATH.."select-border",
  tile = true,
  tileSize = 4,
  edgeSize = 4,
  insets = { left = 1, right = 1,top = 1,bottom = 1} }

local function drawTextField(field, editMode, bolded)
  local f = CreateFrame("SimpleHTML", nil, RPManager.bookFrame)
  if editMode and field.selected then
    f:SetBackdrop(redBorder)
    if RPManager.itemFrame.controlPanel == nil then
      RPMBook.drawControlPanel()
    end
    RPManager.itemFrame.controlPanel.selected = field
  end
  f:SetFrameLevel(field.level)
  if bolded then
    f:SetPoint("TOPLEFT", RPManager.bookFrame, "TOPLEFT", field.coords.x+1, field.coords.y)
  else
    f:SetPoint("TOPLEFT", RPManager.bookFrame, "TOPLEFT", field.coords.x, field.coords.y)
  end
  f:SetSize(field.size.w, field.size.h)
  local flag = ""
  if field.font.outline then
    flag = "OUTLINE"
  end
  f:SetFont('p', field.font.face, field.font.size, flag)
  local r, g, b, a = unpack(field.font.color)
  f:SetTextColor('p', r, g, b, a)
  local text = modifyText(field)
  f:SetText("<html><body><p align=\""..field.font.align.."\">"
          ..text.."</p></body></html>")
  if field.font.bold and not bolded then
    f.bold = drawTextField(field, false, true)
  end

  return f
end

local function drawIconField(field, editMode)
  local f = CreateFrame("Button", nil, RPManager.bookFrame)
  local t = f:CreateTexture(nil, "BACKGROUND")
  t:SetTexture(field.path)
  t:SetTexCoord(
    field.mirror and 1 or 0,
    not field.mirror and 1 or 0,
    field.flip and 1 or 0,
    not field.flip and 1 or 0
  )
  t:SetAllPoints()
  f.tex = t
  if editMode and field.selected then
    f:SetBackdrop(redBorder)
    if RPManager.itemFrame.controlPanel == nil then
      RPMBook.drawControlPanel()
    end
    RPManager.itemFrame.controlPanel.selected = field
  end
  f:SetFrameLevel(field.level)
  f:SetPoint("TOPLEFT", RPManager.bookFrame, "TOPLEFT", field.coords.x, field.coords.y)
  f:SetSize(field.size.w, field.size.h)

--  f:SetMovable(true)
--  f:EnableMouse(true)
--  f:RegisterForDrag("RightButton")
--  f:SetScript("OnDragStart", function() print("bla"); f:StartMoving() end)
--  f:SetScript("OnDragStop", function() stopMovingField(f) end)
  return f
end

--function stopMovingField(parent)
--  parent:StopMovingOrSizing()
--  print(parent:GetCenter())
--end

local function rotateCoordPair(x, y, ox, oy, a, asp)
  y = y / asp
  oy = oy / asp
  return ox + (x - ox) * math.cos(a) - (y - oy) * math.sin(a),
  (oy + (y - oy) * math.cos(a) + (x - ox) * math.sin(a)) * asp
end

local function setTexCoord(tex, left, right, top, bottom, w, h, angle, originx, originy)
  local ratio, angle, originx, originy = w / h, math.rad(angle), originx or 0.5, originy or 1
  local LRx, LRy = rotateCoordPair(left, top, originx, originy, angle, ratio)
  local LLx, LLy = rotateCoordPair(left, bottom, originx, originy, angle, ratio)
  local ULx, ULy = rotateCoordPair(right, top, originx, originy, angle, ratio)
  local URx, URy = rotateCoordPair(right, bottom, originx, originy, angle, ratio)
  tex:SetTexCoord(LRx, LRy, LLx, LLy, ULx, ULy, URx, URy)
end

local function drawTextureField(field, editMode)
  local f = CreateFrame("Frame", nil, RPManager.bookFrame)
  local t = f:CreateTexture(nil, "BACKGROUND")
  t:SetTexture(field.path)
  --  t:SetTexCoord(
  --    field.mirror and 1 or 0,
  --    not field.mirror and 1 or 0,
  --    field.flip and 1 or 0,
  --    not field.flip and 1 or 0
  --  )
  setTexCoord(t, field.mirror and 1 or 0, not field.mirror and 1 or 0,
    field.flip and 1 or 0, not field.flip and 1 or 0,
    field.size.w, field.size.h, field.rotation, 0.5, 0.5)
  t:SetAllPoints()
  f.tex = t
  if field.shadingColor == nil then
    field.shadingColor = {1, 1, 1, 1 }
  end
  local r, g, b, a = unpack(field.shadingColor)
  t:SetVertexColor(r, g, b, a)
  if editMode and field.selected then
    f:SetBackdrop(redBorder)
    if RPManager.itemFrame.controlPanel == nil then
      RPMBook.drawControlPanel()
    end
    RPManager.itemFrame.controlPanel.selected = field
  end
  f:SetFrameLevel(field.level)
  f:SetPoint("TOPLEFT", RPManager.bookFrame, "TOPLEFT", field.coords.x, field.coords.y)
  f:SetSize(field.size.w, field.size.h)
  return f
end

local function updateField(field, editMode)
  clearField(field.id)
  if field.type == TYPE_TEXT then
    RPManager.bookFrame.fields[field.id] = drawTextField(field, editMode, false)
  elseif field.type == TYPE_ICON then
    RPManager.bookFrame.fields[field.id] = drawIconField(field, editMode)
  elseif field.type == TYPE_TEXTURE then
    RPManager.bookFrame.fields[field.id] = drawTextureField(field, editMode)
  end
end

local function addIconButton(icon, parent, status, func)
  RPMGui.addIconButton("interface/addons/RPManager/img/"..icon, 23, parent,
      func, status, 0, 23/32, 0, 23/32)
end

local function drawPage(itemID, editMode)
  local page = getPage(RPMAccountDB.items[itemID])
  if page.fields == nil then
    return
  end
  for _, field in ipairs(page.fields) do
    updateField(field, editMode)
  end
end

local function addPageBefore(itemID)
  local item = RPMAccountDB.items[itemID]
  table.insert(item.pages, item.currPage, {})
  RPMUtil.msg(string.format(L["addPageSuccess"], item.currPage))
end

local function addPageAfter(itemID)
  local item = RPMAccountDB.items[itemID]
  table.insert(item.pages, (item.currPage+1), {})
  RPMUtil.msg(string.format(L["addPageSuccess"], (item.currPage+1)))
end

local function nextPage(itemID, editMode)
  local item = RPMAccountDB.items[itemID]
  if item.currPage == #item.pages then
    return
  end
  PlaySound(856);
  clearPage()
  item.currPage = item.currPage+1
  drawPage(itemID, editMode)
  if editMode then
    updateBookFrame(itemID)
  end
end

local function prevPage(itemID, editMode)
  local item = RPMAccountDB.items[itemID]
  if item.currPage == 1 then
    return
  end
  PlaySound(856);
  clearPage()
  item.currPage = item.currPage-1
  drawPage(itemID, editMode)
  if editMode then
    updateBookFrame(itemID)
  end
end

local function setBookType(itemID, type)
  local item = RPMAccountDB.items[itemID]
  if item.bookType == type then
    return
  end
  item.bookType = type
  RPMBook.drawBook(itemID, true)
end

local function selectField(field)
  local page = getPage(getItem())
  for _, f in ipairs(page.fields) do
    f.selected = false
  end
  field.selected = true
  drawPage(RPManager.itemFrame.itemID, true)
end

local function moveFieldOrder(field, newPos)
  local page = getPage(getItem())
  for i, f in ipairs(page.fields) do
    if f == field then
      table.insert(page.fields, newPos, table.remove(page.fields, i))
      break
    end
  end
  for i, f in ipairs(page.fields) do
    f.level = 100+i
  end
  drawPage(RPManager.itemFrame.itemID, true)
end

local function deletePageField(field)
  clearField(field.id)

  local page = getPage(getItem())
  for i, f in ipairs(page.fields) do
    if f.id == field.id then
      table.remove(page.fields, i)
      break
    end
  end
  updateBookFrame(RPManager.itemFrame.itemID)
end

local function drawFieldPosAndSize(field, iBox)
--  RPMGui.addShortLabel(L["level"]..":", iBox, RPMFont.FRITZ, 40, 12, "")
--  RPMGui.addNumericBox("", field.level, 40, 3, iBox, function(self)
--    field.level = tonumber(self:GetText())
--    updateField(field, true)
--  end)

--  RPMGui.addSpacer(iBox, 20)
--  RPMGui.addShortLabel("x:", iBox, RPMFont.FRITZ, 20, 12, "")
--  RPMGui.addNumericBox("", field.coords.x, 40, 4, iBox, function(self)
--    field.coords.x = tonumber(self:GetText())
--    updateField(field, true)
--  end)

--  RPMGui.addSpacer(iBox, 20)
--  RPMGui.addShortLabel("y:", iBox, RPMFont.FRITZ, 20, 12, "")
--  RPMGui.addNumericBox("", -field.coords.y, 40, 4, iBox, function(self)
--    field.coords.y = -tonumber(self:GetText())
--    updateField(field, true)
--  end)
  RPMGui.addButton(L["select"], 100, iBox, function()
    selectField(field)
  end, L["selectDesc"])

  RPMGui.addSpacer(iBox, 20)

  addIconButton("front", iBox, L["frontDesc"], function()
    local page = getPage(getItem())
    moveFieldOrder(field, #page.fields)
    selectField(field)
  end)

  addIconButton("back", iBox, L["backDesc"], function()
    moveFieldOrder(field, 1)
    selectField(field)
  end)

  RPMGui.addSpacer(iBox, 74)

  RPMGui.addSpacer(iBox, 20)
  RPMGui.addShortLabel(L["width"]..":", iBox, RPMFont.FRITZ, 40, 12, "")
  RPMGui.addNumericBox("", field.size.w, 40, 4, iBox, function(self)
    field.size.w = tonumber(self:GetText())
    updateField(field, true)
    selectField(field)
  end)

  RPMGui.addSpacer(iBox, 20)
  RPMGui.addShortLabel(L["height"]..":", iBox, RPMFont.FRITZ, 40, 12, "")
  RPMGui.addNumericBox("", field.size.h, 40, 4, iBox, function(self)
    field.size.h = tonumber(self:GetText())
    updateField(field, true)
    selectField(field)
  end)

  RPMGui.addSpacer(iBox, 60)

  RPMGui.addButton(L["delete"],100,iBox,function()
    deletePageField(field)
  end, L["deleteFieldDesc"])
end

local function drawTextureTab(field, iBox)
  drawFieldPosAndSize(field, iBox)

  local pathInput = RPMGui.addEditBox("", field.path, 285, 200, iBox, function(self)
    field.path = self:GetText()
    updateField(field, true)
  end)
  addIconButton("image", iBox, L["imageDesc"], function()
    RPMImageViewer.drawImageViewer(field, pathInput)
  end)
  addIconButton("color", iBox, L["bgColorDesc"], function()
    local r, g, b, a = unpack(field.shadingColor)
    RPMForm.createColorPicker(r, g, b, a, function(restore)
      local newA, newR, newG, newB
      if restore then
        newR, newG, newB, newA = unpack(restore)
      else
        newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
      end
      field.shadingColor = { newR, newG, newB, newA }
      updateField(field, true)
    end)
  end)

  RPMGui.addSpacer(iBox, 20)

  addIconButton("mirror", iBox, L["mirrorDesc"], function()
    field.mirror = not field.mirror
    updateField(field, true)
  end)
  addIconButton("flip", iBox, L["flipDesc"], function()
    field.flip = not field.flip
    updateField(field, true)
  end)

  RPMGui.addSlider(" ", 0, 359, 1, field.rotation, iBox, function(self,_,val)
    field.rotation = val
    updateField(field, true)
  end, L["rotationDesc"])
end

local function drawIconTab(field, iBox)
  drawFieldPosAndSize(field, iBox)

  iBox.icon = RPMGui.addIcon(field.path, 32, iBox, function()
    if iconSelector == nil then
      iconSelector = RPMForm.createIconWindow(updateField)
    end
    iconSelector.obj = field
    iconSelector.parent = iBox
    iconSelector:Show()
  end)
  iBox.icon:SetWidth(32)

  RPMGui.addSpacer(iBox, 20)

  addIconButton("mirror", iBox, L["mirrorDesc"], function()
    field.mirror = not field.mirror
    updateField(field, true)
  end)
  addIconButton("flip", iBox, L["flipDesc"], function()
    field.flip = not field.flip
    updateField(field, true)
  end)
end

local function drawTextTab(field, iBox)
  drawFieldPosAndSize(field, iBox)

  RPMGui.addDropdown(field.font.face, 95, RPMFont:getFontMap(), RPMFont:getFontList(),iBox,function(_,_,key)
    field.font.face = key
    updateField(field, true)
  end)

  RPMGui.addNumericBox("", field.font.size, 40, 2, iBox, function(self)
    field.font.size = tonumber(self:GetText())
    updateField(field, true)
  end)

  addIconButton("color", iBox, L["color"], function()
    local r, g, b, a = unpack(field.font.color)
    RPMForm.createColorPicker(r, g, b, a, function(restore)
      local newA, newR, newG, newB
      if restore then
        newR, newG, newB, newA = unpack(restore)
      else
        newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
      end
      field.font.color = { newR, newG, newB, newA }
      updateField(field, true)
    end)
  end)

  RPMGui.addSpacer(iBox, 20)

  addIconButton("style_bold", iBox, L["boldDesc"], function()
    field.font.bold = not field.font.bold
    if field.font.bold then
      field.font.outline = false
    end
    updateField(field, true)
  end)

  addIconButton("style_outline", iBox, L["outlineDesc"], function()
    field.font.outline = not field.font.outline
    if field.font.outline then
      field.font.bold = false
    end
    updateField(field, true)
  end)

  RPMGui.addSpacer(iBox, 20)

  for _, v in ipairs({"left", "center", "right"}) do
    addIconButton("align_"..v, iBox, L["align_"..v], function()
      field.font.align = v
      updateField(field, true)
    end)
  end

  RPMGui.addSpacer(iBox, 20)
  addIconButton("numbers", iBox, L["numbers"], function()
    field.text = field.text..CURRENT_PAGE.."/"..PAGE_COUNT
    updateBookFrame(field.itemID)
    updateField(field, true)
  end)

  RPMGui.addTextArea(5, 1000, field.text, iBox, function(self)
    field.text = self:GetText()
    updateField(field, true)
  end)
end

function updateBookFrame(itemID)
  local scroll = RPManager.itemFrame.scroll
  scroll:ReleaseChildren()

  local currPage = getPage(RPMAccountDB.items[itemID])
  if not currPage.fields then
    return
  end

  for _, field in ipairs(currPage.fields) do
    local iBox = RPMGui.addInlineGroup("", "Flow", scroll)
    if field.type == TYPE_TEXT then
      drawTextTab(field, iBox)
    elseif field.type == TYPE_ICON then
      drawIconTab(field, iBox)
    elseif field.type == TYPE_TEXTURE then
      drawTextureTab(field, iBox)
    end
  end
  scroll:DoLayout()
end

local function deletePage(itemID)
  local item = getItem()
  local page = getPage(item)

  if #item.pages < 1 then
    RPMUtil.msg(L["deleteNotLastPage"])
  end
  if page.field ~= nil and #page.fields > 0 then
    for i = #page.fields, 1, -1 do
      clearField(page.fields[i].id)
      table.remove(page.fields, i)
    end
  end
  table.remove(item.pages, item.currPage)
  if item.currPage > #item.pages then
    item.currPage = #item.pages
  end
  drawPage(itemID, true)
  updateBookFrame(RPManager.itemFrame.itemID)
end

local function addField(itemID, type)
  local page = getPage(RPMAccountDB.items[itemID])
  if not page.fields then
    page.fields = {}
  end

  local id = #page.fields+1
  local level = id+100
  for _,f in ipairs(page.fields) do
    if f.level >= level then
      level = f.level+1
    end
  end
  page.fields[id] = {}
  page.fields[id].type = type
  page.fields[id].id = RPMUtil.createID()
  page.fields[id].level = level
  page.fields[id].itemID = itemID
  return page.fields[id]
end

local function addBookTextField(itemID)
  local item = RPMAccountDB.items[itemID]
  local field = addField(itemID, TYPE_TEXT)

  field.text = ""
  local bookType = BOOK_TYPES[item.bookType]
  local x, y = bookType.area[1], -bookType.area[2]
  field.coords = {
    x = x, y = y
  }
  local w, h = calcPageDimensions(bookType)
  field.size = {
    w = w - x + bookType.area[3], h = h + y + bookType.area[4]
  }
  field.font = {
    face = RPMFont.FRITZ, size = 20, color = { 0, 0, 0, 1},
    align = "left", bold = false
  }

  selectField(field)
  updateBookFrame(itemID)
end

local function addBookIconField(itemID)
  local item = RPMAccountDB.items[itemID]
  local field = addField(itemID, TYPE_ICON)

  field.path = "interface/icons/inv_misc_questionmark"
  local bookType = BOOK_TYPES[item.bookType]
  local x, y = bookType.area[1], -bookType.area[2]
  field.coords = {
    x = x, y = y
  }
  field.size = { w = 64, h = 64 }
  field.mirror = false
  field.flip = false

  selectField(field)
  updateBookFrame(itemID)
end

local function addBookTextureField(itemID)
  local item = RPMAccountDB.items[itemID]
  local field = addField(itemID, TYPE_TEXTURE)

  field.path = "interface/PVPFrame/icons/PVP-Banner-Emblem-"..RPMRandom.random(1, 102)
  local bookType = BOOK_TYPES[item.bookType]
  local x, y = bookType.area[1], -bookType.area[2]
  field.coords = {
    x = x, y = y
  }
  field.size = { w = 256, h = 256 }
  field.mirror = false
  field.flip = false
  field.rotation = 0
  field.shadingColor = { 1, 1, 1, 1 }

  selectField(field)
  updateBookFrame(itemID)
end

local function drawTexture(x, y, w, h, texCoords, tex, p)
  local f = CreateFrame("Frame", nil, p)
  local t = f:CreateTexture(nil, "BACKGROUND")
  t:SetTexture(tex)
  t:SetAllPoints()
  f:SetSize(w, h)
  f:SetPoint("TOPLEFT", p, "TOPLEFT", x, -y)
  if texCoords then
    t:SetTexCoord(unpack(texCoords))
  end
  f:SetFrameLevel(100)
  f.tex = t
  return f
end

local function createFlipArea(x, p, func, itemID)
  local f = CreateFrame("Button", nil, RPManager.bookFrame)
  f:SetPoint("TOPLEFT",RPManager.bookFrame,"TOPLEFT", x, 0)
  f:SetSize(20, RPManager.bookFrame:GetHeight())
  f:SetScript("OnMouseUp", function()
    func(itemID, false)
  end)
  return f
end

function RPMBook.closeBook()
  if RPManager.bookFrame then
    for _, field in pairs(RPManager.bookFrame.fields) do
      field:Hide()
      field = nil
    end
    RPManager.bookFrame:Hide()
    RPManager.bookFrame = nil
  end
end

function RPMBook.drawBook(itemID, editMode)
  local item = RPMAccountDB.items[itemID]
  local type = BOOK_TYPES[item.bookType]
  if type == nil then
    return
  end

  RPMBook.closeBook()

  local f = CreateFrame("Button")
  RPManager.bookFrame = f
  --  f:SetBackdrop(RPM_BD) -- temp

  f:SetPoint("CENTER",UIParent,"CENTER",0,0)
  local w, h = calcPageDimensions(type)
  f:SetSize(w, h)
  f:SetFrameLevel(2000)

  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if not editMode then
    f:SetScript("OnClick", function(self, button)
      if pageClickTimer == nil then
        pageClickTimer = RPManager:ScheduleTimer(function()
          pageClickTimer = nil
        end, .25)
      else
        RPManager:CancelTimer(pageClickTimer)
        pageClickTimer = nil
        RPMBook.closeBook()
      end
    end)
    createFlipArea(0, f, prevPage, itemID)
    createFlipArea(w-20, f, nextPage, itemID)
    RPMUtil.msg(L["bookInstruction"])
  end

  f.fields = {}
  for _, part in ipairs(type.parts) do
    local tex = type.path
    tex = tex..part[1]
    drawTexture(part[2], part[3], part[4], part[5], part[6], tex, f)
  end

  --  if not editMode then
  --    local cls = CreateFrame("Button",nil,f,"UIPanelCloseButton")
  --    cls:SetPoint("TOPRIGHT",0,0)
  --    cls:SetScript("OnMouseUp", RPMBook.closeBook)
  --    cls.parent = f
  --  end
  drawPage(itemID, editMode)
end

function RPMBook.drawBookFrame(itemID, group)
  local item = RPMAccountDB.items[itemID]

  RPMGui.addSpacer(group, 5)

  RPMGui.addDropdown(item.bookType, 140, bookSet, bookOrder, group, function(_,_,key)
    setBookType(itemID, key);
  end)

  RPMGui.addSpacer(group, 5)

  RPMGui.addButton("+",20,group,function()
    addPageBefore(itemID)
  end, L["addPageBeforeDesc"])

  RPMGui.addSpacer(group, 5)

  local i1 = addIconButton("left", group, L["prevPageDesc"], function()
    prevPage(itemID, true)
  end)

  RPMGui.addSpacer(group, 5)

  local i2 = addIconButton("right", group, L["nextPageDesc"], function()
    nextPage(itemID, true)
  end)

  RPMGui.addSpacer(group, 5)

  RPMGui.addButton("+",20,group,function()
    addPageAfter(itemID)
  end, L["addPageAfterDesc"])
  RPMGui.addButton(L["deletePage"],150,group,function()
    deletePage(itemID)
  end, L["deletePageDesc"])

  RPMGui.addButton(L["addTextField"], 150, group, function()
    addBookTextField(itemID)
  end, L["addTextFieldDesc"])
  RPMGui.addSpacer(group, 5)
  RPMGui.addButton(L["addIconField"], 150, group, function()
    addBookIconField(itemID)
  end, L["addIconFieldDesc"])
  RPMGui.addButton(L["addTextureField"], 150, group, function()
    addBookTextureField(itemID)
  end, L["addTextureFieldDesc"])

  RPManager.itemFrame.scroll = RPMGui.addScrollBox(RPManager.itemFrame, 343, "List")

  updateBookFrame(itemID)
  RPMBook.drawBook(itemID, true)
end

local function move(btn, x, y)
--  if btn == "RightButton" then
--    x = x * 10
--    y = y * 10
--  end
  local field = RPManager.itemFrame.controlPanel.selected
  if field then
    field.coords.x = field.coords.x + x
    field.coords.y = field.coords.y + y
    updateField(field, true)
  end
end

local function border(side)
  local field = RPManager.itemFrame.controlPanel.selected
  if not field then
    return
  end
  local item = getItem()
  local bookType = BOOK_TYPES[item.bookType]
  local w, h = calcPageDimensions(bookType)

  if side == "up" then
    field.coords.y = -bookType.area[2]
  elseif side == "down" then
    field.coords.y = -(h + bookType.area[4] - field.size.h)
  elseif side == "left" then
    field.coords.x = bookType.area[1]
  elseif side == "right" then
    field.coords.x = w + bookType.area[3] - field.size.w
  end
  updateField(field, true)
end

local function centerHoriz()
  local field = RPManager.itemFrame.controlPanel.selected
  if field then
    local item = getItem()
    local bookType = BOOK_TYPES[item.bookType]
    local w, _ = calcPageDimensions(bookType)
    field.coords.x = (w + bookType.area[1] + bookType.area[3] - field.size.w)/2
    updateField(field, true)
  end
end

local function centerVert()
  local field = RPManager.itemFrame.controlPanel.selected
  if field then
    local item = getItem()
    local bookType = BOOK_TYPES[item.bookType]
    local _, h = calcPageDimensions(bookType)
    field.coords.y = -(h + bookType.area[2] + bookType.area[4] - field.size.h)/2
    updateField(field, true)
  end
end

function RPMBook.drawControlPanel()
  local width, height = 219, 137
  local panel = RPMForm.drawBaseWindow(L["controlPanel"], "controlpanel", width, height, RPMBook.closePanel)
  RPManager.itemFrame.controlPanel = panel

  -- Line 1

  RPMGui.addSpacer(panel, 29)
  addIconButton("up", panel, "", function(_, _, btn)
    move(btn, 0, 1)
  end)

  RPMGui.addSpacer(panel, 32)

  addIconButton("center_horiz", panel, "", function()
    centerHoriz()
  end)

  RPMGui.addSpacer(panel, 32)

  addIconButton("up_full", panel, "", function()
    border("up")
  end)

  RPMGui.addSpacer(panel, width - 190)

  -- Line 2

  addIconButton("left", panel, "", function(_, _, btn)
    move(btn, -1, 0)
  end)

  RPMGui.addSpacer(panel, 35)

  addIconButton("right", panel, "", function(_, _, btn)
    move(btn, 1, 0)
  end)

  RPMGui.addSpacer(panel, 29)

  addIconButton("left_full", panel, "", function()
    border("left")
  end)

  RPMGui.addSpacer(panel, 35)

  addIconButton("right_full", panel, "", function()
    border("right")
  end)

  RPMGui.addSpacer(panel, width - 216)

  -- Line 3

  RPMGui.addSpacer(panel, 29)
  addIconButton("down", panel, "", function(_, _, btn)
    move(btn, 0, -1)
  end)

  RPMGui.addSpacer(panel, 32)

  addIconButton("center_vert", panel, "", function()
    centerVert()
  end)

  RPMGui.addSpacer(panel, 32)

  addIconButton("down_full", panel, "", function()
    border("down")
  end)
end

function RPMBook.closePanel()
  if RPManager.itemFrame and RPManager.itemFrame.controlPanel ~= nil then
    RPManager.itemFrame.controlPanel = nil
    RPManager.itemFrame:Hide()
  end
end

function RPMBook.updateField(field)
  updateField(field, true)
end
