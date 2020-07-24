local DICE_TRACKER_TYPE_ENTRY     = 0
local DICE_TRACKER_TYPE_SEPARATOR = 1

local ROLL_COLOR_NORMAL   = {1, 1, 1}
local ROLL_COLOR_INVALID  = {.6, .6, .6}
local ROLL_COLOR_HIGHEST  = {0, 1, 0}

if GetLocale() == 'deDE' then -- Umlaut erzeugt einen Fehler beim Parsen
  RANDOM_ROLL_RESULT = "%s w\195\188rfelt. Ergebnis: %d (%d-%d)"
end

local TIME_OFFSET = math.floor(time() - GetTime())

local pattern = RANDOM_ROLL_RESULT
  :gsub("[%(%)-]", "%%%1")
  :gsub("%%s", "(.+)")
  :gsub("%%d", "%(%%d+%)")

local aceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local labelClickTimer

local function roll(lo, hi)
  RandomRoll(lo, hi)
end

function RPM_openDiceTracker()
  if RPManager.diceTrackerFrame ~= nil then
    return
  end
  
  RPManager.diceTrackerFrame = RPMForm.drawBaseFrame("DiceTracker", "dicetracker", RPM_closeDiceTracker)
  local f = RPManager.diceTrackerFrame
  f.frame:SetScript("OnEvent", RPManager.diceTrackerFrame_onEvent)
  f.frame:RegisterEvent("CHAT_MSG_SYSTEM")
  
  f.includeExtraRolls = false
  f.includeInvalidRolls = false
  f.showTRPName = false
  
  local grp1 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["rnd100"],150,grp1,function()
    roll(1, 100)
  end, L["rnd100Desc"])
  RPMGui.addButton(L["rnd20"],150,grp1,function()
    roll(1, 20)
  end, L["rnd20Desc"])
  RPMGui.addButton(L["separator"],150,grp1,function()
    RPM_addSeparator()
  end, L["separatorDesc"])
  RPMGui.addButton(L["delete"],150,grp1,function()
    RPM_delProtocol()
  end, L["deleteDTDesc"])
  
  local grp2 = RPMGui.addSimpleGroup("Flow", f)
  RPMGui.addButton(L["showOrder"],150,grp2,function()
    RPM_showOrder()
  end, L["showOrderDesc"])
  local c = RPMGui.addCheckbox(L["withInvalidRolls"],false,grp2,function(self)
    f.includeInvalidRolls = self:GetValue()
  end, L["withInvalidRollsDesc"])
  c:SetWidth(150)
  RPMGui.addButton(L["sort"],150,grp2,function()
    RPM_sortRolls()
  end, L["sortDesc"])
  c = RPMGui.addCheckbox(L["withExtraRolls"],false,grp2,function(self)
    f.includeExtraRolls = self:GetValue()
  end, L["withExtraRollsDesc"])
  c:SetWidth(150)
  if RPMTRP.isTrpLoaded() then
    local d = RPMGui.addCheckbox(L["showTRP"], false, grp2, function(self)
      f.showTRPName = self:GetValue()
    end, L["showTRPDesc"])
    d:SetWidth(160)
  end
  
--  f.scroll = RPMGui.addScrollBox(f, 356, "List")
  f.scroll = RPMGui.addScrollBox(f, 334, "List")

  RPM_updateDiceTracker()
end

function RPM_closeDiceTracker()
  RPManager.diceTrackerFrame.frame:UnregisterEvent("CHAT_MSG_SYSTEM")
  RPManager.diceTrackerFrame.frame:SetScript("OnEvent", nil)
  RPManager.diceTrackerFrame:Hide()
  RPManager.diceTrackerFrame = nil
end

local function printLine(entry)
  local name = (RPManager.diceTrackerFrame.showTRPName and entry.trpName) or entry.name
  local s = string.format(RANDOM_ROLL_RESULT, name, entry.res, entry.low, entry.hi)
  if entry.roll > 1 then
    s = s.." ("..entry.roll..". "..L["roll"]..")"
  end
  return s
end

local function showTargetRolls(name, id)
  local list = {}

  for _,entry in ipairs(RPMAccountDB.dicetracker) do
    if entry.name == name and entry.id == id then
      table.insert(list, { text = printLine(entry), isTitle = true})
      local menuFrame = CreateFrame("Frame", ""..time(), UIParent, "UIDropDownMenuTemplate")
      EasyMenu(list, menuFrame, "cursor", 0 , 0, "MENU")
    end
  end
end

local function deleteLine(delEntry)
  local roll = delEntry.roll
  local deleted = false
  for i=#RPMAccountDB.dicetracker,1,-1 do
    local entry = RPMAccountDB.dicetracker[i]
    if entry.ts == delEntry.ts and not deleted then
      table.remove(RPMAccountDB.dicetracker, i)
      deleted = true
    elseif entry.name == delEntry.name and entry.id == delEntry.id and entry.roll > delEntry.roll then
      entry.roll = entry.roll-1
    end
  end
  RPM_updateDiceTracker()  
end

local function drawLine(line, p, entry)
  local l = aceGUI:Create("InteractiveLabel")
  l:SetText(line)
  l:SetColor(1,1,1)
  l.width = "fill"
  l:SetHeight(30)
  l:SetFont(RPMFont.FRITZ, 18, nil)
  l:SetCallback("OnEnter", function(self)
    self.label:SetVertexColor(1,.8,.1)
    RPManager.diceTrackerFrame:SetStatusText(L["singleDoubleDesc"])
  end)
  l:SetCallback("OnLeave", function(self)
    self.label:SetVertexColor(entry.color[1], entry.color[2], entry.color[3])
    RPManager.diceTrackerFrame:SetStatusText("")
  end)
  l:SetCallback("OnClick", function(_, _, btn)
    if labelClickTimer ~= nil then
      if btn == "LeftButton" then
        RPManager:CancelTimer(labelClickTimer)
        labelClickTimer = nil
        deleteLine(entry)
      end
    else
      if btn == "RightButton" then
        labelClickTimer = RPManager:ScheduleTimer(function()
          showTargetRolls(entry.name, entry.id)
          labelClickTimer = nil
        end, .25)
      else
        labelClickTimer = RPManager:ScheduleTimer(function()
          labelClickTimer = nil
        end, .25)
      end
    end
  end)
  p:AddChild(l)
  return l
end

function RPM_updateDiceTracker()
  if RPManager.diceTrackerFrame == nil then
    return
  end
  
  local scroll = RPManager.diceTrackerFrame.scroll
  scroll:ReleaseChildren()
  
  for _,v in ipairs(RPMAccountDB.dicetracker) do
    if v.type == DICE_TRACKER_TYPE_SEPARATOR then
      RPMGui.addHeader("", scroll)
    elseif v.type == DICE_TRACKER_TYPE_ENTRY then
      local name = (RPManager.diceTrackerFrame.showTRPName and v.trpName) or v.name
      local l = drawLine(printLine(v), scroll, v)
      if v.color ~= nil then
        l:SetColor(v.color[1], v.color[2], v.color[3])
      else
        l:SetColor(1,1,1)
      end
    end
  end
  scroll:DoLayout()
end

local function addDiceTrackerProtocolLine(_type, name, low, hi, res)
  local ts = TIME_OFFSET+GetTime()
  local protSize = #RPMAccountDB.dicetracker
  local entry
  if _type == DICE_TRACKER_TYPE_SEPARATOR then
    entry = { type = _type, ts = ts, id = math.floor(ts) }
  elseif _type == DICE_TRACKER_TYPE_ENTRY then
    local id, trial, roll = math.floor(ts), 1, 1
    for i = protSize, 1, -1 do
      if RPMAccountDB.dicetracker[i].type == DICE_TRACKER_TYPE_ENTRY and
          RPMAccountDB.dicetracker[i].name == name and
          RPMAccountDB.dicetracker[i].low == low and
          RPMAccountDB.dicetracker[i].hi == hi then
        roll=roll+1
      end
      if RPMAccountDB.dicetracker[i].type == DICE_TRACKER_TYPE_SEPARATOR or i==1 then
        id = RPMAccountDB.dicetracker[i].id
        break
      end
    end
    entry = { type = _type, ts = ts, id = id, name = name,
      trpName = RPMTRP.getTRPName(name), roll = roll, low = low, hi = hi,
      res = res, color = {1, 1, 1} }
  end
  RPMAccountDB.dicetracker[protSize+1] = entry
end

function RPM_addSeparator()
  local list = RPMAccountDB.dicetracker
  if #list == 0 or list[#list].type == DICE_TRACKER_TYPE_ENTRY then
    addDiceTrackerProtocolLine(DICE_TRACKER_TYPE_SEPARATOR)
    RPM_updateDiceTracker()
  end
end

function RPManager.diceTrackerFrame_onEvent(self, event, arg1)
  if event == "CHAT_MSG_SYSTEM" then
    for name, roll, low, high in string.gmatch(arg1, pattern) do
      addDiceTrackerProtocolLine(DICE_TRACKER_TYPE_ENTRY, name, tonumber(low), tonumber(high), tonumber(roll))
      RPM_updateDiceTracker()
    end
  end
end

function RPM_delProtocol()
  RPMAccountDB.dicetracker =  {}
  RPM_updateDiceTracker()
end

local function getCurrentGroup()
  local list = RPMAccountDB.dicetracker
  local endId
  if list[#list].type == DICE_TRACKER_TYPE_ENTRY then
    endId = #list
  else
    endId = #list-1
  end
  local tempList = {}
  
  if endId == 0 then
    return tempList
  end
  
  local startId = endId
  repeat
    table.insert(tempList, 1, list[startId])
    startId = startId-1
  until (startId == 0 or list[startId].type ~= DICE_TRACKER_TYPE_ENTRY)
  startId = startId+1
  return tempList, startId, endId
end

function RPM_showOrder()
  local msg = ""
  local tempList = getCurrentGroup()
  
  for _, entry in ipairs(tempList) do
    if RPManager.diceTrackerFrame.includeInvalidRolls or
        entry.color[1] ~= .6 then
      msg = msg .. entry.name .. " > "
    end
  end
  if msg:len() > 4 then
    msg = msg:sub(1, -4)
  end

  if IsInRaid() then
    RPMIO.sendChatMessage("RAID", msg)
  elseif IsInGroup() then
    RPMIO.sendChatMessage("PARTY", msg)
  else
    RPMUtil.msg(msg)
  end
end


local function contains(t, name)
  for _, entry in ipairs(t) do
    if entry.name == name then
      return true
    end
  end
  return false
end

function RPM_sortRolls()
  local tempList, remList = {}, {}
  local startId

  if not RPManager.diceTrackerFrame.includeExtraRolls then
    tempList, startId = getCurrentGroup()
    for i = #tempList, 1, -1 do
      if tempList[i].roll > 1 then
        local roll = table.remove(tempList, i)
        table.insert(remList, roll)
      end
    end
  else
    remList, startId = getCurrentGroup()
    for i = #remList, 1, -1 do
      local exists = false
      for j = #tempList, 1, -1 do
        if remList[i].name == tempList[j].name then
          if remList[i].res > tempList[j].res then
            local rem = table.remove(tempList, j)
            table.insert(remList, rem)
            local add = table.remove(remList, i)
            table.insert(tempList, add)
          end
          exists = true
        end
      end
      if not exists then
        table.insert(tempList, remList[i])
        table.remove(remList, i)
      end
    end
  end

  table.sort(tempList, function(e1, e2) return e1.res > e2.res end)
  table.sort(remList, function(e1, e2)
    if e1.res == e2.res then
      return e1.roll < e2.roll
    else
      return e1.res > e2.res
    end
  end)

  local valid = #tempList
  for i = 1, #remList do
    table.insert(tempList, remList[i])
  end

  local _max = 0
  for i=1,#tempList do
    if i > valid then
      tempList[i].color = ROLL_COLOR_INVALID
    elseif tempList[i].res >= _max then
      tempList[i].color = ROLL_COLOR_HIGHEST
      _max = tempList[i].res
    else
      tempList[i].color = ROLL_COLOR_NORMAL
    end

    RPMAccountDB.dicetracker[startId+i-1] = tempList[i]
  end
  RPM_updateDiceTracker()
end

--function RPM_sortRollsOld()
--  local tempList, startId, endId = getCurrentGroup()
--
--  table.sort(tempList, function(e1, e2)
--    if not RPManager.diceTrackerFrame.includeExtraRolls then
--      if e1.roll > 1 and e2.roll > 1 then
--        if e1.roll == e2.roll then
--          return e1.res >= e2.res
--        else
--          return e1.roll <= e2.roll
--        end
--      elseif e1.roll > 1 then
--        return false
--      elseif e2.roll > 1 then
--        return true
--      end
--    else
--      if e1.res == e2.res then
--        return e1.roll <= e2.roll
--      else
--        return e1.res > e2.res
--      end
--    end
--  end)
--
--  local rollers = {}
--  local id = 1
--  while id <= #tempList do
--    if not contains(rollers, tempList[id].name) then
--      table.insert(rollers, table.remove(tempList, id))
--    else
--      id = id +1
--    end
--  end
--  for i=1,#rollers do
--    table.insert(tempList, i, rollers[i])
--  end
--
--  local _max=0
--  for i=1,#tempList do
--    if i > #rollers then
--      tempList[i].color = {.6,.6,.6}
--    elseif tempList[i].res >= _max then
--      tempList[i].color = {0,1,0}
--      _max = tempList[i].res
--    else
--      tempList[i].color = {1,1,1}
--    end
--
--    RPMAccountDB.dicetracker[startId+i-1] = tempList[i]
--  end
--
--  RPM_updateDiceTracker()
--end
