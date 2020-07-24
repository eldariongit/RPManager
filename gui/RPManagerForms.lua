if RPMForm ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local aceGUI = LibStub("AceGUI-3.0")
local libIco = LibStub("LibAdvancedIconSelector-1.0")
local libWin = LibStub("LibWindow-1.1")

local function drawText(x, y, w, h, just, p, txt)
  local l=p:CreateFontString()
  l:SetFont(RPMFont.FRITZ, 13, nil)
  l:SetTextColor(1, 213/255, 0, 1)
  l:SetSize(w, h)
  l:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", x, y)
  l:SetText(txt)
  l:SetJustifyH(just)
  return l
end

RPMForm = {
  registerFrame = function(frame, profileName)
    if RPMCharacterDB.profile[profileName] == nil then
      RPMCharacterDB.profile[profileName] = {}
    end
    libWin.RegisterConfig(frame, RPMCharacterDB.profile[profileName])
    libWin.RestorePosition(frame)  -- restores scale also
  end,

  centerFrame = function(parent, profileName)
    if RPMCharacterDB.profile[profileName] == nil then
      RPMCharacterDB.profile[profileName] = {}
    end
    RPMCharacterDB.profile[profileName]["x"] = 0
    RPMCharacterDB.profile[profileName]["y"] = 0
    RPMCharacterDB.profile[profileName]["point"] = "CENTER"
    if parent ~= nil then
      libWin.RestorePosition(parent.frame)
    end
  end,

  startDrag = function(frame)
    libWin.windowData[frame].isDragging = true
  end,

  stopDrag = function(frame)
    libWin.SavePosition(frame)
    libWin.windowData[frame].isDragging = false
  end,

  drawBaseFrame = function(title, profile, closeFunc, status)
    local base = aceGUI:Create("Frame")
    base:SetTitle(title)
    base:SetStatusText(status or "")
    base:SetCallback("OnClose", closeFunc)
    base:SetLayout("List")
    base.profile = profile

    local frame = base.frame
    RPMForm.registerFrame(frame, profile)
    if frame.StartMovingOrig == nil then
      frame.StartMovingOrig = frame.StartMoving
      frame.StartMoving = function()
        frame:StartMovingOrig()
        RPMForm.startDrag(frame)
      end
    end
    if frame.StopMovingOrSizingOrig == nil then
      frame.StopMovingOrSizingOrig = frame.StopMovingOrSizing
      frame.StopMovingOrSizing = function()
        frame:StopMovingOrSizingOrig()
        RPMForm.stopDrag(frame)
        if base == RPManager.combatManagerFrame or base == RPManager.combatJournalFrame then
          RPMCharacterDB.profile["combat"]["w"] = frame:GetWidth()
          RPMCharacterDB.profile["combat"]["h"] = frame:GetHeight()
        end
      end
    end
    base.parent = base
    return base
  end,

  drawBaseWindow = function(title, profile, width, height, closeFunc)
    local f = aceGUI:Create("Window")
    local frame = f.frame
    f:SetTitle(title)
    f:SetCallback("OnClose", closeFunc)

    f:SetWidth(width)
    f:SetHeight(height)
    f:SetLayout("Flow")
    f.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -22)
    f.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    f.sizer_se:Hide()
    f.sizer_e:Hide()
    f.sizer_s:Hide()

    frame:SetMinResize(0, 0)
    frame:SetResizable(false)

    RPMForm.registerFrame(frame, profile)

    if frame.StartMovingOrig == nil then
      frame.StartMovingOrig = frame.StartMoving
      frame.StartMoving = function()
        frame:StartMovingOrig()
        RPMForm.startDrag(frame)
      end
    end
    if frame.StopMovingOrSizingOrig == nil then
      frame.StopMovingOrSizingOrig = frame.StopMovingOrSizing
      frame.StopMovingOrSizing = function()
        frame:StopMovingOrSizingOrig()
        RPMForm.stopDrag(frame)
      end
    end
    return f
  end,

  drawBaseBag = function(num)
    local f = CreateFrame("Frame")
    f.frame = f

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetSize(190, 250)

    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface/ContainerFrame/UI-BackpackBackground")
    t:SetTexCoord(67/256, 252/256, 0, 250/256)
    t:SetAllPoints()

    f.label = drawText(50, 223, 110, 20, "LEFT", f, "RPBag")
    f.status = drawText(20, 3, 150, 20, "LEFT", f, "")

    f:SetScript("OnDragStart",function()
      f:StartMoving()
      RPMForm.startDrag(f)
    end)
    f:SetScript("OnDragStop",function()
      f:StopMovingOrSizing()
      RPMForm.stopDrag(f)
    end)
    f:SetScript("OnKeyDown", function(self,key)
      if key == "ESCAPE" then
        self:SetPropagateKeyboardInput(false)
        RPMBag.closeBag()
      else
        self:SetPropagateKeyboardInput(true)
      end
    end)
    return f
  end,

  createIconWindow = function(func)
    local options = {}
    local iconWin = libIco:CreateIconSelectorWindow("MyIconWindow", UIParent, options)
    iconWin:SetPoint("CENTER")
    iconWin:SetFrameStrata("FULLSCREEN_DIALOG")
    iconWin:SetScript("OnOkayClicked", function(self)
      local id = self.iconsFrame:GetSelectedIcon()
      local _,_,tex = self.iconsFrame:GetIconInfo(id)
      self.obj.path = "interface/icons/"..tex
      self.parent.icon:SetImage("interface/icons/"..tex)
      iconWin:Hide()
      if func ~= nil then
        func(self.obj, true)
      end
    end)
    iconWin:Hide()
    return iconWin
  end,

  createInputDialog = function(title, label, default, func)
    local f = aceGUI:Create("Window")
    f:SetTitle(title)
    f:SetStatusText("")
    f:SetLayout("List")
    f:SetWidth(350)
    f:SetHeight(150)

    f.sizer_se:Hide()
    f.sizer_e:Hide()
    f.sizer_s:Hide()

    f.frame:SetResizable(false)
    f.frame:SetFrameStrata("TOOLTIP")

    local grp1 = RPMGui.addSimpleGroup("Flow", f)
    local label = RPMGui.addLabel(label, grp1, RPMFont.ARIAL,20);
    label:SetWidth(290)
    local txt = RPMGui.addEditBox("", default, 290, 100, grp1, nil)
    txt:SetCallback("OnEnterPressed", function()
      aceGUI:ClearFocus()
    end)
    txt.editbox:SetScript("OnTabPressed", function(frame)
      local self = frame.obj
      local value = frame:GetText()
      self:Fire("OnEnterPressed", value)
    end)
    txt.editbox:SetScript("OnEscapePressed", function()
      txt:SetText(default)
      aceGUI:ClearFocus()
    end)

    RPMGui.addButton(L["ok"], 100, grp1, function()
      func(txt)
      f:Hide()
    end, L["okInputDesc"])
    RPMGui.addButton(L["cancel"], 100, grp1, function()
      f:Hide()
    end, L["cancelInputDesc"])

    f:SetHeight(label.frame.height+100)
  end,

  createColorPicker = function(r, g, b, a, callback)
    ColorPickerFrame.func = callback
    ColorPickerFrame.opacityFunc = callback
    ColorPickerFrame.cancelFunc = callback

    ColorPickerFrame.hasOpacity = (a ~= nil)
    ColorPickerFrame.opacity = a
    ColorPickerFrame.previousValues = {r,g,b,a}

    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:SetPoint("CENTER")
    ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    ColorPickerFrame:Hide() -- Need to run the OnShow handler.
    ColorPickerFrame:Show()
  end
}
