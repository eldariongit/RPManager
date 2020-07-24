local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local aceGUI = LibStub("AceGUI-3.0")

local PAGE_INC = 50

local soundPaths = {}
local soundFileIds = {}
local filteredSoundPaths = {}

local labelClickTimer -- Klick-Handling auf Soundpfad-Labels
local currPath

function RPManager:fillSoundList()
  SoundFileIds_InitSoundList()
  self:ScheduleTimer(function()
    self:createSoundPaths("", SoundFileIds_soundList)
  end, 5)
end

function RPManager:createSoundPaths(head, o)
  if type(o) == "table" then
    for k, v in pairs(o) do
      self:createSoundPaths(head..k, v)
    end
  else
    soundFileIds[head:lower()] = o
  end
end

function RPManager:getFileId(path)
  return soundFileIds[path:lower()]
end

function RPManager:filterSoundsFromTree(head, o, filter)
  if type(o) == "table" then
    for k, v in pairs(o) do
      self:filterSoundsFromTree(head..k, v, filter)
    end
  else
    if string.find(head:lower(), filter) then
      soundPaths[#soundPaths+1] = head:lower()
    end
  end
end

function RPManager:filterSoundsFromList(o, filter)
  for _,v in ipairs(o) do
    if string.find(v, filter) then
      soundPaths[#soundPaths+1] = v
    end
  end
end

function RPManager:filterSoundList(filter)
  if filter:len() < 4 then
    return {}
  elseif filteredSoundPaths[filter] ~= nil then
    soundPaths = filteredSoundPaths[filter]
    return
  end
 
  soundPaths = {}
  local filterM1 = filter:sub(1, -2)
  if filteredSoundPaths[filterM1] == nil then
    self:filterSoundsFromTree("", SoundFileIds_soundList, filter)
  else
    self:filterSoundsFromList(filteredSoundPaths[filterM1], filter)
  end
  filteredSoundPaths[filter] = soundPaths
end

local function prevPage()
  if RPManager.soundPickerDialog.currIndex-PAGE_INC < 1 then
    return
  end
  RPManager.soundPickerDialog.currIndex = RPManager.soundPickerDialog.currIndex-PAGE_INC
  RPM_updateSoundPicker()
end

local function nextPage()
  if RPManager.soundPickerDialog.currIndex+PAGE_INC > #soundPaths then
    return
  end
  RPManager.soundPickerDialog.currIndex = RPManager.soundPickerDialog.currIndex+PAGE_INC
  RPM_updateSoundPicker()
end

function RPM_drawSoundPicker(filter, callback)
  if RPManager.soundPickerDialog ~= nil then
    return
  end
  
  RPManager.soundPickerDialog = RPMForm.drawBaseFrame("SoundPicker", "soundpicker", RPM_closeSoundPicker)
  local f = RPManager.soundPickerDialog

  f.scroll = RPMGui.addScrollBox(f, 380, "List")
  f.callback = callback
  f.currIndex = 1
  
  local iBox = RPMGui.addSimpleGroup("Flow", f)
  local input = RPMGui.addEditBox("", filter, 200,30, iBox, nil)
  input:SetCallback("OnTextChanged", function(self, event, text)
    RPM_updateSoundPicker(text)
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

  RPM_updateSoundPicker(filter)
end

function RPM_closeSoundPicker()
  RPMUtil.stopSound()
  RPManager.soundPickerDialog:Release()
  RPManager.soundPickerDialog:Hide()
  RPManager.soundPickerDialog = nil
end

--local function formatTime(secs)
--  local m = floor(secs / 60)
--  local s = mod(secs, 60)
--  if s < 10 then
--    s = "0"..s
--  else
--    s = tostring(s)
--  end
--  return string.format(" (%i:%s)", m, s)
--end

local function drawPath(path, p)
  local l = aceGUI:Create("InteractiveLabel")
  l:SetText(path.."|CFFFF9050"..
          " ("..soundFileIds[path]..")")
  l:SetColor(1,1,1)
  l.width = "fill"
  l:SetHeight(30)
  l:SetFont(RPMFont.ARIAL, 20, nil)
  l:SetCallback("OnEnter", function(self)
    self.label:SetVertexColor(1,.8,.1)
    RPManager.soundPickerDialog:SetStatusText(L["pickerClickHandler"])
  end)
  l:SetCallback("OnLeave", function(self)
    self.label:SetVertexColor(1,1,1)
    RPManager.soundPickerDialog:SetStatusText("")
  end)
  l:SetCallback("OnClick", function()
    if labelClickTimer ~= nil then
      RPManager:CancelTimer(labelClickTimer)
      labelClickTimer = nil
      RPManager.soundPickerDialog.callback(path)
      RPM_closeSoundPicker()
    else
      if currPath == path then
        RPMUtil.stopSound()
        currPath = nil
      else
        labelClickTimer = RPManager:ScheduleTimer(function()
          RPMUtil.stopSound()
          RPMUtil.playSound(path)
          labelClickTimer = nil
        end, .25)
        currPath = path
      end
    end
  end)
  p:AddChild(l)
  return l
end

function RPM_updateSoundPicker(filter)
  local scroll = RPManager.soundPickerDialog.scroll
  scroll:ReleaseChildren()
  
  if filter ~= nil then
    RPManager:filterSoundList(filter)
    RPManager.soundPickerDialog.currIndex = 1
  end
  
  if filter ~= nil and filter:len() < 4 then
    RPMGui.addLabel(L["filterTooShort"],scroll,RPMFont.ARIAL,20)
    RPManager.soundPickerDialog.currIndexLabel:SetText("")
  elseif #soundPaths == 0 then
    RPMGui.addLabel(L["noMatch"], scroll, RPMFont.ARIAL, 20)
    RPManager.soundPickerDialog.currIndexLabel:SetText("")
  else
    local _max = math.min(RPManager.soundPickerDialog.currIndex+PAGE_INC-1, #soundPaths)
    for i = RPManager.soundPickerDialog.currIndex, _max do
      local iBox = RPMGui.addSimpleGroup("Flow", scroll)
      drawPath(soundPaths[i], iBox)
    end
    RPManager.soundPickerDialog.currIndexLabel:SetText(""..RPManager.soundPickerDialog.currIndex.." - ".._max.." von "..#soundPaths)
  end
  scroll:DoLayout()
end
