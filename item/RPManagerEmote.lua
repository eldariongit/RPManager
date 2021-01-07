if RPMEmote ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local deleteEmote


local function updateEmoteFrame(itemID)
  local scroll = RPManager.itemFrame.scroll
  scroll:ReleaseChildren()

  local emotes = RPMAccountDB.items[itemID].emotes
  if #emotes == 0 then
    return
  end

  for id, emote in ipairs(emotes) do
    local iBox = RPMGui.addInlineGroup("", "Flow", scroll)

    RPMGui.addShortLabel(L["emoteName"], iBox, RPMFont.FRITZ, 80, 12, "")
    local name = RPMGui.addEditBox("", "", 150, 10, iBox, function(self)
      emote.emote = self:GetText()
    end)

    RPMGui.addSpacer(iBox, 15)

    RPMGui.addShortLabel(L["delay"], iBox, RPMFont.FRITZ, 150, 12, "")
    local delay = RPMGui.addNumericBox("", "", 40, 3, iBox, function(self)
      emote.delay = tonumber(self:GetText())
    end)

    name:SetText(emote.emote)  -- fixes a bug that sometimes keeps
    delay:SetText(emote.delay) -- the fields empty

    RPMGui.addSpacer(iBox, 60)

    RPMGui.addButton(L["delete"],100,iBox,function()
      deleteEmote(itemID, id)
    end, L["deleteFieldDesc"])

  end
  scroll:DoLayout()
end

function deleteEmote(itemID, id)
  local emotes = RPMAccountDB.items[itemID].emotes
  table.remove(emotes, id)
  updateEmoteFrame(itemID)
end

local function addEmote(itemID)
  local emotes = RPMAccountDB.items[itemID].emotes
  emotes[#emotes+1] = { emote = "", delay = 0 }
  updateEmoteFrame(itemID)
end


RPMEmote = {
  drawEmoteFrame = function(itemID, group)
    local item = RPMAccountDB.items[itemID]

    RPMGui.addSpacer(group, 5)

    RPMGui.addButton(L["addEmote"],150,group,function()
      addEmote(itemID)
    end, L["addEmoteDesc"])

    RPMGui.addSpacer(group, 5)

    RPMGui.addCheckbox(L["forceStand"], item.forceStand, group, function(self)
      item.forceStand = self:GetValue()
    end, L["forceStandDesc"])

    RPManager.itemFrame.scroll = RPMGui.addScrollBox(RPManager.itemFrame, 343, "List")
    updateEmoteFrame(itemID)
  end,

  playEmotes = function(itemID)
    if not RPManager:initScriptExecutionMonitor("EMOTE") then
      print("wait")
      return
    end

    RPMBag.updateBag()

    local item = RPMBag.getItem(itemID)
    local emotes = RPMUtil.deepCopy(RPMAccountDB.items[itemID].emotes)
    if item.forceStand then
      for _, emote in ipairs(emotes) do
        emote.delay = emote.delay + 4
      end
      table.insert(emotes, 1, { emote = "stand", delay = 0 })
    end
    for i = 1, #emotes do
      if emotes[i].delay == 0 then
        DoEmote(emotes[i].emote)
      else
        if i == #emotes then
          local id = RPManager:ScheduleTimer(function()
            DoEmote(emotes[i].emote)
            RPManager:initScriptExecutionMonitor()
            RPMBag.updateBag()
          end, emotes[i].delay)
          RPManager:addScriptExecution(id)
        else
          local id = RPManager:ScheduleTimer(function()
            DoEmote(emotes[i].emote)
          end, emotes[i].delay)
          RPManager:addScriptExecution(id)
        end
      end
    end
  end
}
