local PAGE_INC = 50

local aceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local mapPaths = {}
local filteredMapPaths = {}

local labelClickTimer, currPath -- Klick-Handling auf Soundpfad-Labels


function RPManager:fillMapList()
  initMapTextureList()
end

function RPManager:filterMapFromPaths(head, list, filter)
  for k, path in ipairs(list) do
    if string.find(path:lower(), filter:lower()) then
      mapPaths[#mapPaths+1] = path
    end
  end
end

function RPManager:filterMapFromList(o, filter)
  for _,path in ipairs(o) do
    if string.find(path:lower(), filter:lower()) then
      mapPaths[#mapPaths+1] = path
    end
  end
end

function RPManager:filterMaplist(filter)
  if filter:len() < 4 then
    return {}
  elseif filteredMapPaths[filter] ~= nil then
    mapPaths = filteredMapPaths[filter]
    return
  end

  mapPaths = {}
  local filterM1 = filter:sub(1, -2)
  if filteredMapPaths[filterM1] ~= nil then
    self:filterMapFromList(filteredMapPaths[filterM1], filter)
  else
    self:filterMapFromPaths("", RPM_getMapList(), filter)
  end
  filteredMapPaths[filter] = mapPaths
end

local function drawPath(path, p)
  local l = aceGUI:Create("InteractiveLabel")
  l:SetText(path)
  l:SetColor(1,1,1)
  l.width = "fill"
  l:SetHeight(30)
  l:SetFont(RPMFont.ARIAL, 20, nil)
  l:SetCallback("OnEnter", function(self)
    self.label:SetVertexColor(1,.8,.1)
    RPManager.mapPickerDialog:SetStatusText(L["selectDoubleClick"])
  end)
  l:SetCallback("OnLeave", function(self)
    self.label:SetVertexColor(1,1,1)
    RPManager.mapPickerDialog:SetStatusText("")
  end)
  l:SetCallback("OnClick", function()
    if labelClickTimer == nil then
      labelClickTimer = RPManager:ScheduleTimer(function() labelClickTimer = nil end, .25)
      currPath = path
    else
      RPManager:CancelTimer(labelClickTimer)
      labelClickTimer = nil
      RPManager.mapPickerDialog.callback(path, RPManager.mapPickerDialog.filter)
      RPManager.mapPickerDialog:Hide()
    end
  end)
  p:AddChild(l)
  return l
end

local function updateMapPicker(filter)
  RPManager.mapPickerDialog.filter = filter
  local scroll = RPManager.mapPickerDialog.scroll
  scroll:ReleaseChildren()

  if filter ~= nil then
    RPManager:filterMaplist(filter)
    RPManager.mapPickerDialog.currIndex = 1
  end

  if filter ~= nil and filter:len() < 4 then
    RPMGui.addLabel(L["filterTooShort"],scroll,RPMFont.ARIAL,20)
    RPManager.mapPickerDialog.currIndexLabel:SetText("")
  elseif #mapPaths == 0 then
    RPMGui.addLabel(L["noMatch"],scroll,RPMFont.ARIAL,20)
    RPManager.mapPickerDialog.currIndexLabel:SetText("")
  else
    local _max = math.min(RPManager.mapPickerDialog.currIndex+PAGE_INC-1, #mapPaths)
    for i = RPManager.mapPickerDialog.currIndex, _max do
      local iBox = RPMGui.addSimpleGroup("Flow", scroll)
      drawPath(mapPaths[i], iBox)
    end
    RPManager.mapPickerDialog.currIndexLabel:SetText(""..RPManager.mapPickerDialog.currIndex.." - ".._max.." "..L["of"].." "..#mapPaths)
  end
  scroll:DoLayout()
end

local function prevPage()
  if RPManager.mapPickerDialog.currIndex-PAGE_INC < 1 then
    return
  end
  RPManager.mapPickerDialog.currIndex = RPManager.mapPickerDialog.currIndex-PAGE_INC
  updateMapPicker()
end

local function nextPage()
  if RPManager.mapPickerDialog.currIndex+PAGE_INC > #mapPaths then
    return
  end
  RPManager.mapPickerDialog.currIndex = RPManager.mapPickerDialog.currIndex+PAGE_INC
  updateMapPicker()
end

function RPM_drawMapPicker(filter, callback)
  if RPManager.mapPickerDialog ~= nil then
    return
  end

  RPManager.mapPickerDialog = RPMForm.drawBaseFrame("MapPicker", "mappicker", RPM_closeMapPicker)
  local f = RPManager.mapPickerDialog

  f.scroll = RPMGui.addScrollBox(f, 380, "List")
  f.callback = callback
  f.currIndex = 1

  local iBox = RPMGui.addSimpleGroup("Flow", f)
  local input = RPMGui.addEditBox("", filter, 200,30, iBox, nil)
  input:SetCallback("OnTextChanged", function(self, event, text)
    updateMapPicker(text)
  end)
  local i1 = RPMGui.addIcon("interface/icons/misc_arrowleft",20,iBox,prevPage)
  i1:SetWidth(40)
  local i2 = RPMGui.addIcon("interface/icons/misc_arrowright",20,iBox,nextPage)
  i2: SetWidth(40)
  f.currIndexLabel = RPMGui.addLabel("", iBox, RPMFont.ARIAL,20)
  f.currIndexLabel:SetRelativeWidth(.25)
  f:SetHeight(520)
  f:SetWidth(850)
  f:DoLayout()

  updateMapPicker(filter)
end

function RPM_closeMapPicker()
  RPManager.mapPickerDialog:Release()
  RPManager.mapPickerDialog = nil
end

local function formatTime(secs)
  local m = floor(secs / 60)
  local s = mod(secs, 60)
  if s < 10 then
    s = "0"..s
  else
    s = tostring(s)
  end
  return string.format(" (%i:%s)", m, s)
end
