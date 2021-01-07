if RPMGui ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local aceGUI = LibStub("AceGUI-3.0")

aceGUI:RegisterLayout("backbutton",
  function(content, children)
    if children == nil or children[1] == nil or children[1].frame == nil then
      return
    end
    children[1].frame:SetPoint("BOTTOMLEFT",content,"BOTTOMLEFT", -5, 67)
    children[1].frame:Show()
    -- safecall(content.obj.LayoutFinished, content.obj, nil, 100)
  end
)

RPMGui = {
  addInlineGroup = function(title, layout,p)
    local box = aceGUI:Create("InlineGroup")
    box:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    box:SetLayout(layout)
    box:SetTitle(title)
    box:SetRelativeWidth(1)
    p:AddChild(box)
    box.parent = p.parent or p
    return box
  end,

  addSimpleGroup = function(layout, p)
    local box = aceGUI:Create("SimpleGroup")
    box:SetLayout(layout)
    box:SetRelativeWidth(1)
    p:AddChild(box)
    box.parent = p.parent or p
    return box
  end,

  showTooltip = function(parent, ...)
    local labels = { ... }
    GameTooltip:SetOwner(parent, "ANCHOR_CURSOR")
    -- GameTooltip:SetText(label)
    for _, label in ipairs(labels) do
      GameTooltip:AddLine(label, 1, 1, 1)
    end
    GameTooltip:Show()
  end,

  showItemTooltip = function(parent, item)
    local tooltip = item.tooltip
    GameTooltip:SetOwner(parent, "ANCHOR_CURSOR")
    local q = ITEM_QUALITY_COLORS[tonumber(tooltip.quality)].hex
    GameTooltip:AddLine(q..item.name, 1, 1, 1)
    if tooltip.left:len() > 0 or tooltip.right:len() > 0 then
      GameTooltip:AddDoubleLine(tooltip.left,  tooltip.right, 1, 1, 1, 1, 1, 1)
    end
    for _, line in ipairs(RPMUtil.splitText(tooltip.white, 40)) do
      GameTooltip:AddLine(line, 1, 1, 1)
    end
    for _, line in ipairs(RPMUtil.splitText(tooltip.gold, 40)) do
      GameTooltip:AddLine(line, 1, .835, .066)
    end
    for _, line in ipairs(RPMUtil.splitText(tooltip.usage, 40)) do
      GameTooltip:AddLine(line, 0, 1, 0)
    end
    GameTooltip:Show()
  end,

  hideTooltip = function()
    GameTooltip:Hide()
  end,

  addStatusText = function(widget, label, parent)
    if label == nil or label == "" then
      return
    end

    widget:SetCallback("OnEnter", function() parent.parent:SetStatusText(label) end)
    widget:SetCallback("OnLeave", function() parent.parent:SetStatusText("") end)
  end,

  addSpacer = function(p, width)
    local l = aceGUI:Create("Label")
    l:SetText("")
    l:SetWidth(width)
    l:SetHeight(10)
    p:AddChild(l)
    return l
  end,

  addLabel = function(text, p, font, height, flags)
    local l = aceGUI:Create("Label")
    l:SetText(text)
    l.width = "fill"
    l:SetHeight(height)
    if font ~= nil then
      l:SetFont(font, height, flags)
    end
    p:AddChild(l)
    return l
  end,

  addShortLabel = function(text, p, font, width, height, flags)
    local l = aceGUI:Create("Label")
    l:SetText(text)
    l:SetWidth(width)
    l:SetHeight(height)
    if font ~= nil then
      l:SetFont(font, height, flags)
    end
    p:AddChild(l)
    return l
  end,

  addCenterLabel = function(text,p,font,height,flags)
    local box = RPMGui.addSimpleGroup("List", p)
    local l = RPMGui.addLabel(text,box,font,height,flags)
    l:SetRelativeWidth(1)
    l.label:SetJustifyH("CENTER")
    return l, box
  end,

  addHeader = function(text, p)
    local h = aceGUI:Create("Heading")
    h:SetText(text)
    h:SetRelativeWidth(1)
    p:AddChild(h)
    return h
  end,

  addEditBox = function(label, text, width, _max, p, func)
    local txt = aceGUI:Create("EditBox")
    txt:SetText(text)
    txt:SetLabel(label)
    txt:SetWidth(width)
    txt:DisableButton(true)
    txt:SetMaxLetters(_max)
    txt:SetCallback("OnRelease", function(self)
      self.editbox:SetScript("OnEnterPressed", nil)
      self.editbox:SetScript("OnTabPressed", nil)
      self.editbox:SetScript("OnEscapePressed", nil)
    end)
    txt:SetCallback("OnEnterPressed", function(self)
      func(self)
      aceGUI:ClearFocus()
    end)
    txt.editbox:SetScript("OnTabPressed", function(frame)
      local self = frame.obj
      local value = frame:GetText()
      self:Fire("OnEnterPressed", value)
    end)
    txt.editbox:SetScript("OnEscapePressed", function()
      txt:SetText(text)
      aceGUI:ClearFocus()
    end)
    txt.editbox:SetNumeric(false)
    p:AddChild(txt)
    return txt
  end,

  addNumericBox = function(label, text, width, _max, p, func)
    local num = RPMGui.addEditBox(label, text, width, _max, p, func)
    num.editbox:SetNumeric(true)
    return num
  end,

  addTextArea = function(_lines, letters, text, p, func)
    local b = aceGUI:Create("MultiLineEditBox")
    b.width = "fill"
    b:SetLabel("")
    b:SetNumLines(_lines)
    b:DisableButton(true)
    b:SetMaxLetters(letters)
    b:SetText(text)
    b:SetCallback("OnEnterPressed", function(self)
      func(self)
      aceGUI:ClearFocus()
    end)
    b.editBox:SetScript("OnTabPressed", function(frame)
      local self = frame.obj
      local value = frame:GetText()
      self:Fire("OnEnterPressed", value)
    end)
    b:SetCallback("OnLostFocus", function(frame)
      local self = frame.obj
      local value = frame:GetText()
      self:Fire("OnEnterPressed", value)
    end)
    b.editBox:SetScript("OnEscapePressed", function()
      b:SetText(text)
      aceGUI:ClearFocus()
    end)
    p:AddChild(b)
    return b
  end,

  addImage = function(path, w, h, p, ...)
    local img = aceGUI:Create("Icon")
    img:SetImage(path, ...)
    img:SetImageSize(w, h)
    img:SetWidth(w+1)
    p:AddChild(img)
    return img
  end,

  drawCenterImage = function (path, w, h, parent, ...)
    local l = aceGUI:Create("Label")
    l:SetImage(path, ...)
    l:SetImageSize(w, h)
    l:SetRelativeWidth(1)
    parent:AddChild(l)
    return l
  end,

  addIcon = function(iconName, s, p, func, ...)
    local ico = aceGUI:Create("Icon")
    ico:SetImage(iconName, ...)
    ico:SetImageSize(s, s)
    ico:SetCallback("OnClick", func)
    p:AddChild(ico)
    return ico
  end,

  addIconButton = function(iconName, s, p, func, ttip, ...)
    local btn = RPMGui.addIcon(iconName, s, p, func, ...)
    btn:SetWidth(s+1) -- widget width
    RPMGui.addStatusText(btn, ttip, p)
    return btn
  end,

  addButton = function(label, w, p, func, helpText)
    local btn = aceGUI:Create("Button")
    btn:SetText(label)
    btn:SetWidth(w)
    btn:SetCallback("OnClick", func)
    p:AddChild(btn)
    RPMGui.addStatusText(btn, helpText, p)
    return btn
  end,

  addBackButton = function(p, func)
    local bckGrp = RPMGui.addSimpleGroup("backbutton",p)
    local btn = RPMGui.addImage("interface/buttons/ui-microstream-yellow",32,32,bckGrp,1,1,0,1,1,0,0,0)
    btn:SetLabel("")
    btn:SetCallback("OnClick", function()
      RPMUtil.stopSound()
      func()
    end)
    RPMGui.addStatusText(btn, L["back"], p)
    return btn
  end,

  addCloseButton = function(parent, x, y, func)
    local cls = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    cls:SetPoint("TOPRIGHT", x, y)
    cls:SetScript("OnMouseUp", func)
    return cls
  end,

  addRadioButton = function(label, width, set, p, group, func, helpText)
    local btn = aceGUI:Create("CheckBox")
    btn:SetType("radio")
    btn:SetValue(set)
    btn:SetLabel(label)
    btn:SetCallback("OnValueChanged",func)
    btn:SetWidth(width)
    if group.radio == nil then
      group.radio = {}
    end
    group.radio[#group.radio+1] = btn
    p:AddChild(btn)
    RPMGui.addStatusText(btn, helpText, p)
    return btn
  end,

  addCheckbox = function(label,set,p,func,helpText)
    local chk = aceGUI:Create("CheckBox")
    chk:SetValue(set)
    chk:SetLabel(label)
    chk:SetCallback("OnValueChanged",func)
    chk:SetWidth(100)
    p:AddChild(chk)
    RPMGui.addStatusText(chk, helpText, p)
    return chk
  end,

  addSlider = function(l,_min,_max, step, curr, p, func, helpText)
    local s = aceGUI:Create("Slider")
    s:SetLabel(l)
    s:SetIsPercent(false)
    s:SetSliderValues(_min,_max, step)
    s:SetValue(curr)
    s:SetCallback("OnMouseUp", func)
    s.slider:SetObeyStepOnDrag(true)
    --  s.slider:SetHeight(10)
    --  s.editbox:SetHeight(10)
    --  s.label:SetHeight(0)
    --  s.frame:SetHeight(20)
    --  s:SetHeight(15)
    p:AddChild(s)
    RPMGui.addStatusText(s, helpText, p)
    return s
  end,

  addScrollBox = function(p,h,layout)
    local container = aceGUI:Create("InlineGroup")
    container:SetFullWidth(true)
    container:SetHeight(h)
    container:SetLayout("Fill") -- important!
    p:AddChild(container)

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetLayout(layout)
    scroll.width = "fill"
    scroll.height = "fill"
    container:AddChild(scroll)
    scroll.parent = p.parent or p
    return scroll
  end,

  addDropdown = function(key,width,list,order,p,func)
    local dd = aceGUI:Create("Dropdown")
    dd:SetList(list, order)
    dd:SetValue(key)
    dd:SetWidth(width)
    dd:SetCallback("OnValueChanged", func)
    p:AddChild(dd)
    return dd
  end
}
