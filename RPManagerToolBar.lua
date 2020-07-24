local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local aceGUI = LibStub("AceGUI-3.0")


local function addButton(iconName, func, ttip)
  local btn = RPMGui.addIcon("interface/icons/"..iconName, 32, RPManager.toolBar, func)
  btn:SetWidth(33) -- Breite des Widgets
  btn.frame:SetScript("OnEnter", function()
    RPMGui.showTooltip(btn.frame, ttip)
  end)
  btn.frame:SetScript("OnLeave", RPMGui.hideTooltip)
end

local function closeBar()
  RPMCharacterDB.profile.toolbar.hide = true
end

function RPManager:startToolBar()
  if RPManager.toolBar ~= nil then
    return
  end

  local buttonList =  {
    { icon = "inv_misc_book_09", func = RPM_openJournal, label = "journal" },
    { icon = "inv_icon_feather01a", func = RPM_openManager, label = "manager" },
    { icon = "inv_misc_dice_02", func = RPM_openDiceTracker, label = "diceTracker" },
    --  { icon = "trade_archaeology_delicatemusicbox", func = nil, label = "musicbox" },
    { icon = "inv_misc_bag_08", func = RPMBag.drawBag, label = "bag" },
    { icon = "inv_misc_screwdriver_01", func = function()
      -- Twice because of a bug in WoW
      InterfaceOptionsFrame_OpenToCategory(RPManager.optionsFrame)
      InterfaceOptionsFrame_OpenToCategory(RPManager.optionsFrame)
    end, label = "settings" },
  }

  local width = 26 + (#buttonList * 33)
  RPManager.toolBar =
      RPMForm.drawBaseWindow("RPManager", "toolbar", width, 75, closeBar)
  for i, btn in ipairs(buttonList) do
    addButton(btn.icon, btn.func, L[btn.label])
  end

  if RPMCharacterDB.profile.toolbar.hide then
    RPManager.toolBar:Hide()
  else
    RPManager.toolBar:Show()
  end
end
