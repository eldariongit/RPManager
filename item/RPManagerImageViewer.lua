if RPMImageViewer ~= nil then
  return
end

RPMImageViewer = {}

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local IMAGE_TYPE = {
  ["pvp"] = { min = 1, max = 102, path = {
    "Interface/PVPFrame/Icons/PVP-Banner-Emblem-%s" }},
  ["rune"] = { min = 1, max = 20, path = {
    "Interface/SPELLBOOK/UI-Glyph-Rune-%s" }},
  ["guild"] = { min = 1, max = 188, path = {
    414835,    -- - 415005 (170)
    464107 }}, -- - 464295  (18)
  ["dungeon"] = { min = 1, max = 181, path = {
    337488,337491,337493,340648,340649,340650,340651,340652,340653,340654,
    340655,340656,340657,340658,340659,340660,340661,340662,340663,340664,
    340665,340666,340667,340668,340669,340670,340671,340672,340673,340674,
    340675,340676,340677,340678,340679,340680,340681,340682,340683,340684,
    340685,340686,340687,340688,340689,340690,340691,340692,340693,340694,
    340695,340696,340697,340698,340699,340700,340701,340702,340703,340704,
    340705,368566,368567,368568,368569,460614,460615,460616,460618,460619,
    460620,460906,460907,460908,460909,466904,575267,575268,575269,575270,
    575271,615222,649954,649955,649960,649961,649962,649964,649965,649967,
    649968,649969,649970,651752,651754,655547,656586,656587,838789,838791,
    838793,838795,851369,876949,904244,904246,904248,904250,1042042,
    1042043,1042044,1042045,1042046,1042047,1042048,1042049,1042050,
    1042148,1042149,1042150,1042151,1042152,1042153,1042154,1060549,
    1060550,1135139,1135140,1135141,1135142,1135144,1397428,1411859,
    1411860,1411861,1411862,1411863,1411864,1450578,1450579,1452723,
    1452724,1452725,1452726,1452727,1452728,1452729,1498163,1498164,
    1498165,1498166,1537285,1616110,1616120,1616121,1616122,1616123,
    1616923,1718218,1718219,1718764,1778894,1778895,2179220,2179221,
    2179222,2179223,2179224,2179225,2179226,2179227,2179231,2179232,
    2179233,2482692,2498196,2564735,3025283,3025284,3076645,3221465 }}
}

local function setImage(type, id)
  local viewer = RPManager.itemFrame.imageViewer
  if type == viewer.type then
    return
  end

  if id == nil then
    id = IMAGE_TYPE[type].min
  end
  viewer.type = type
  viewer.id = id

  for i = #viewer.canvas.fields, 1, -1 do
    viewer.canvas.fields[i]:Hide()
    viewer.canvas.fields[i] = nil
  end

  if type == "guild" then
    for x = -1, 1, 2 do
      local f = CreateFrame("Frame", nil, viewer.canvas.parent)
      f:SetSize(100, 200)
      f:SetPoint("CENTER", viewer.canvas.parent, "CENTER", -x*50, 0)
      local t = f:CreateTexture(nil, "BACKGROUND")
      t:SetAllPoints(f)
      local num = #viewer.canvas.fields+1
      viewer.canvas.fields[num] = f
      viewer.canvas.fields[num].tex = t
    end
  else
    local f = CreateFrame("Frame", nil, viewer.canvas.parent)
    if type == "rune" then
      f:SetSize(128, 128)
    elseif type == "dungeon" then
      f:SetSize(320, 160)
    else -- PVP
      f:SetSize(200, 200)
    end
    f:SetPoint("CENTER", viewer.canvas.parent, "CENTER", -5, 0)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(f)
    viewer.canvas.fields[1] = f
    viewer.canvas.fields[1].tex = t
  end
  RPMImageViewer.updateImageViewer()
end

local function prevImage()
  local viewer = RPManager.itemFrame.imageViewer
  viewer.id = viewer.id - 1
  if viewer.id < IMAGE_TYPE[viewer.type].min then
    viewer.id = IMAGE_TYPE[viewer.type].max
  end
  RPMImageViewer.updateImageViewer()
end

local function nextImage()
  local viewer = RPManager.itemFrame.imageViewer
  viewer.id = viewer.id + 1
  if viewer.id > IMAGE_TYPE[viewer.type].max then
    viewer.id = IMAGE_TYPE[viewer.type].min
  end
  RPMImageViewer.updateImageViewer()
end

function RPMImageViewer.drawImageViewer(field, inputField)
  if RPManager.itemFrame.imageViewer ~= nil then
    RPManager.itemFrame.imageViewer:Show()
    return
  end

  local size = 365
  local viewer = RPMForm.drawBaseWindow(L["imageViewer"], "imageviewer",
    size, size+80)
  RPManager.itemFrame.imageViewer = viewer

  RPMGui.addButton(L["pvp"], 85, viewer, function() setImage("pvp") end, "")
  RPMGui.addButton(L["guild"], 85, viewer, function() setImage("guild") end, "")
  RPMGui.addButton(L["runes"], 85, viewer, function() setImage("rune") end, "")
  RPMGui.addButton(L["dungeon"], 85, viewer, function() setImage("dungeon") end, "")

  local iBox = RPMGui.addSimpleGroup("Fill", viewer)
  iBox:SetHeight(size-14)

  RPMGui.addIconButton("interface/addons/RPManager/img/left", 23, viewer, function()
    prevImage()
  end, "", 0, 23/32, 0, 23/32)

  viewer.editBox = RPMGui.addNumericBox("", "", 32, 3, viewer, function(self)
    local num = tonumber(self:GetText())
    if num < IMAGE_TYPE[viewer.type].min then
      num = IMAGE_TYPE[viewer.type].min
    elseif num > IMAGE_TYPE[viewer.type].max then
      num = IMAGE_TYPE[viewer.type].max
    end
    viewer.id = num
    RPMImageViewer.updateImageViewer()
  end)

  RPMGui.addIconButton("interface/addons/RPManager/img/right", 23, viewer, function()
    nextImage()
  end, "", 0, 23/32, 0, 23/32)

  RPMGui.addSpacer(viewer, 22)

  RPMGui.addButton(ACCEPT, 100, viewer, function()
    local path
    if viewer.type == "pvp" or viewer.type == "rune" then
      path = string.format(IMAGE_TYPE[viewer.type].path[1], viewer.id)
    elseif viewer.type == "dungeon" then
      path = IMAGE_TYPE[viewer.type].path[viewer.id]
    else
      local pid = math.floor(viewer.id / 171) + 1
      path = IMAGE_TYPE[viewer.type].path[pid] + viewer.id
      RPMUtil.msg(L["guildNote"])
    end
    viewer.parent:SetText(path)
    viewer.field.path = path
    RPMBook.updateField(viewer.field)
    RPManager.itemFrame.imageViewer:Hide()
  end, "")

  RPMGui.addButton(CANCEL, 100, viewer, function()
    RPManager.itemFrame.imageViewer:Hide()
  end, "")

  viewer.parent = inputField
  viewer.field = field
  viewer.canvas = { parent = iBox.frame, fields = {} }

  setImage("pvp")
  RPMImageViewer.updateImageViewer()
end

function RPMImageViewer.updateImageViewer()
  local viewer = RPManager.itemFrame.imageViewer

  viewer.editBox:SetText(viewer.id)

  if viewer.type == "pvp" or viewer.type == "rune" then
    local path = string.format(IMAGE_TYPE[viewer.type].path[1], viewer.id)
    viewer.canvas.fields[1].tex:SetTexture(path)
  elseif viewer.type == "dungeon" then
    local fileId = IMAGE_TYPE[viewer.type].path[viewer.id]
    viewer.canvas.fields[1].tex:SetTexture(fileId)
  elseif viewer.type == "guild" then
    local pid = math.floor(viewer.id / 171) + 1
    local fileId = IMAGE_TYPE[viewer.type].path[pid] + viewer.id
    for i = 1, 2 do
      viewer.canvas.fields[i].tex:SetTexture(fileId)
    end
    viewer.canvas.fields[2].tex:SetTexCoord(1, 0, 0, 1)
  end
end
