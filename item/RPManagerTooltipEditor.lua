if RPMTooltipEditor ~= nil then
  return
end

RPMTooltipEditor = {}

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local order = {
  "0", "1", "2", "3", "4", "5", "6", "7"
}

local qualities = {
  ["0"] = ITEM_QUALITY_COLORS[0].hex..ITEM_QUALITY0_DESC, -- !
  ["1"] = ITEM_QUALITY_COLORS[1].hex..ITEM_QUALITY1_DESC,
  ["2"] = ITEM_QUALITY_COLORS[2].hex..ITEM_QUALITY2_DESC,
  ["3"] = ITEM_QUALITY_COLORS[3].hex..ITEM_QUALITY3_DESC,
  ["4"] = ITEM_QUALITY_COLORS[4].hex..ITEM_QUALITY4_DESC,
  ["5"] = ITEM_QUALITY_COLORS[5].hex..ITEM_QUALITY5_DESC,
  ["6"] = ITEM_QUALITY_COLORS[6].hex..ITEM_QUALITY6_DESC,
  ["7"] = ITEM_QUALITY_COLORS[7].hex..ITEM_QUALITY7_DESC,
}


function RPMTooltipEditor.drawTooltipEditor(item)
  if RPManager.itemFrame.tooltipEditor ~= nil then
    RPManager.itemFrame.tooltipEditor:Show()
    return
  end

  local tooltip
  if item.tooltip ~= nil then
    tooltip = RPMUtil.shallowCopy(item.tooltip)
  else
    tooltip = RPMTemplate.setNewTooltip()
  end

  local editor = RPMForm.drawBaseWindow(L["tooltipEditor"],
    "tooltipeditor", 380, 490)

  RPMGui.addShortLabel(L["quality"], editor, RPMFont.FRITZ, 150, 16)
  RPMGui.addDropdown(tooltip.quality, 120, qualities, order, editor, function(_,_,key)
    tooltip.quality = key
  end)

  RPMGui.addShortLabel(L["leftRightText"], editor, RPMFont.FRITZ, 150, 16)
  RPMGui.addEditBox("", tooltip.left, 90, 20, editor, function(self)
    tooltip.left = self:GetText()
  end)
  RPMGui.addSpacer(editor, 17)
  RPMGui.addEditBox("", tooltip.right, 90, 20, editor, function(self)
    tooltip.right = self:GetText()
  end)
  RPMGui.addShortLabel(L["whiteText"], editor, RPMFont.FRITZ, 150, 16)
  local tw = RPMGui.addTextArea(3, 200, tooltip.white, editor, function(self)
    tooltip.white = self:GetText()
  end)
  tw.width = 1

  RPMGui.addShortLabel(L["goldText"], editor, RPMFont.FRITZ, 150, 16)
  local tg = RPMGui.addTextArea(3, 200, tooltip.gold, editor, function(self)
    tooltip.gold = self:GetText()
  end)
  tg.width = 1

  RPMGui.addShortLabel(L["usage"], editor, RPMFont.FRITZ, 150, 16)
  local tu = RPMGui.addTextArea(3, 200, tooltip.usage, editor, function(self)
    tooltip.usage = self:GetText()
  end)
  tu.width = 1

  RPMGui.addSpacer(editor, 350)

  RPMGui.addCenterLabel(L["preview"], editor, RPMFont.FRITZ, 16)
  RPMGui.addSpacer(editor, 169)
  local preview = RPMGui.addImage(item.path, 32, 32, editor)
  preview.frame:SetScript("OnEnter",function()
    local i = { tooltip = tooltip, name = item.name }
    RPMGui.showItemTooltip(preview.frame, i)
  end)
  preview.frame:SetScript("OnLeave",function()
    RPMGui.hideTooltip()
  end)
  RPMGui.addSpacer(editor, 100)

  RPMGui.addSpacer(editor, 150)
  RPMGui.addButton(ACCEPT, 100, editor, function()
    item.tooltip = RPMUtil.shallowCopy(tooltip)
    editor:Hide()
  end, "")

  RPMGui.addButton(CANCEL, 100, editor, function()
    editor:Hide()
  end, "")
end

