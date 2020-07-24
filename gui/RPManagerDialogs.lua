local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

if RPMDialog ~= nil then
  return
end

local RPM_DIALOG_YESNO = "RPMYesNoDialog"
local RPM_DIALOG_INPUT = "RPMInputDialog"

RPMDialog = {
  showYesNoDialog = function(msg, alert, callback1, callback2)
    StaticPopupDialogs[RPM_DIALOG_YESNO] = {
      text = msg,
      showAlert = alert,
      button1 = YES,
      button2 = NO,
      timeout = 30,
      whileDead = true,
      hideOnEscape = true,
      enterClicksFirstButton = true,
      hasEditBox = false,
      OnAccept = callback1,
      OnCancel = callback2,
    }

    local dialog=StaticPopup_Show(RPM_DIALOG_YESNO)
    dialog:SetFrameStrata("TOOLTIP")
  end,

  showInputDialog = function(msg, default, callback)
    StaticPopupDialogs[RPM_DIALOG_INPUT] = {
      text = msg,
      showAlert = false,
      button1 = ACCEPT,
      button2 = CANCEL,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      enterClicksFirstButton = true,
      hasEditBox = true,
      OnAccept = callback,
    }

    local dialog = StaticPopup_Show(RPM_DIALOG_INPUT)
    dialog.editBox:SetText(default)
    dialog:SetFrameStrata("TOOLTIP")
  end
}
