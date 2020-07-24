local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local NORMALIZE_CONST = 22
local playerName = UnitName("player")

RPM_TEXTURE_PATH = "interface/addons/RPManager/textures/"
RPM_textureSet = {
  ["grass"]        = L["texGrass"],
  ["dry_grass"]    = L["texGrassDry"],
  ["sand"]         = L["texSand"],

  ["stone_tiles"]  = L["texTiles"],
  ["cobblestone"]  = L["texCobble"],
  ["stone_plates"] = L["texPlates"],

  ["snow"]         = L["texSnow"],
  ["water"]        = L["texWater"],
  ["sky"]          = L["texSky"],

  ["gravel"]       = L["texGravel"],
  ["rock"]         = L["texRock"],
  ["lava"]         = L["texLava"],

  ["wood"]         = L["texPlanks"],
  ["marble_white"] = L["texMarbleWhite"],
  ["carpet"]       = L["texCarpetRed"],
}
RPM_textureOrder = {
  "grass",
  "dry_grass",
  "sand",

  "gravel",
  "rock",
  "lava",

  "snow",
  "water",
  "sky",
  
  "stone_tiles",
  "cobblestone",
  "stone_plates",
  
  "wood",
  "marble_white",
  "carpet",
}

function RPM_mobString2List(str)
  local mobList = {}
  local mobStrings = RPMUtil.split(str, ";")

  for mobNr, mobString in ipairs(mobStrings) do
    local name, x, y, icon, scale, anchor, visible = strsplit(",", mobString)
    if name ~= nil and name ~= "" then
      local mob = {}
      mob.name = name
      mob.x = tonumber(x)
      mob.y = tonumber(y)
      mob.icon = icon
      mob.scale = tonumber(scale)
      mob.anchor = (anchor == "true")
      mob.visible = (visible == "true")
      mobList[#mobList+1] = mob
      mob.mobNr = #mobList
    end
  end
  return mobList
end

function RPM_mobList2String(list)
  local mobString = ""
  for mobNr, mob in ipairs(list) do
    mobString = mobString..mob.name..","..mob.x..","..mob.y..","..mob.icon..","..mob.scale..","..tostring(mob.anchor)..","..tostring(mob.visible)..";"
  end
  return mobString
end

local function saveSnapshot()
  local quest = RPMCharacterDB.quests[RPManager.combatJournalFrame.questID]
  local chapter = quest.chapters[RPManager.combatJournalFrame.chapterNr]
  chapter.save = RPM_mobList2String(RPManager.combatJournalFrame.mobList)
end

function RPM_putToken(mob, parent)
  if parent == nil then
    return
  end
  
  local size = 32*mob.scale
  local f = CreateFrame("Button", nil, parent.map)
  mob.token = f
  mob.owner = parent.owner
  
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetPoint("TOPLEFT", parent.map, "TOPLEFT", mob.x, mob.y)
  f:SetSize(size, size)

  f:SetScript("OnEnter", function()
    RPMGui.showTooltip(f, mob.mobNr..") "..mob.name)
  end)
  f:SetScript("OnLeave", RPMGui.hideTooltip)
  
  if mob.owner then
    f:SetScript("OnClick", function(_,_)
      mob.visible = not mob.visible
      f:SetAlpha((mob.visible and 1) or .5)
      RPMSynch.synchCombat("visible", f.mob.mobNr,  mob.mobNr, mob.visible)
      saveSnapshot()
    end)
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() RPM_stopMovingToken(f) end)
    f:SetAlpha((mob.visible and 1) or .5)
  else
    if not mob.visible then
      f:Hide()
    end
  end
  
  local t=f:CreateTexture(nil,"ARTWORK")
  t:SetTexture("interface/icons/"..mob.icon)
  t:SetAllPoints()

  f.tokenSize = size
  f.mob = mob
  f.map = parent.map
  f.tex = t
end

function RPM_removeToken(mob)
  if mob.token ~= nil then
    mob.token:Hide()
    mob.token = nil
  end
end

function RPM_stopMovingToken(f)
  f:StopMovingOrSizing()
  local x,y = f:GetCenter()
  local top, left = f.map:GetTop(), f.map:GetLeft()
  x = math.ceil(x-f.tokenSize/2) - left
  y = math.ceil(y+f.tokenSize/2) - top
  
  local w, h = f.map:GetWidth(), f.map:GetHeight()
  if x < 0 then
    x = 0
  elseif x+f.tokenSize > w then
    x = w - f.tokenSize
  end
  if y > 0 then
    y = 0
  elseif y-f.tokenSize < -h then
    y = -h + f.tokenSize
  end
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT",f.map,"TOPLEFT",x,y)
  f.mob.x = x
  f.mob.y = y
  RPMSynch.synchCombat("pos", f.mob.mobNr, x, y)
  if RPManager.combatJournalFrame ~= nil then
    saveSnapshot()
  end
end

function RPM_checkTokenVisibility(mobList, f)
  if f ~= nil then
    local x,y = f.map:GetWidth(), f.map:GetHeight()
    for _, mob in pairs(mobList) do
      local size = 32*mob.scale
      -- mob.token:SetAlpha((mob.visible and 1) or .5)
      if mob.x+size > x or mob.y-size < -y then
        mob.token:Hide()
      elseif not mob.visible and not mob.owner then
        mob.token:Hide()
      else
        mob.token:Show()
      end
    end
  end
end

function RPM_normalizeCoords(x, y)
  local f = RPManager.combatJournalFrame
  x, y = x - f.anchor.wx, f.anchor.wy - y
  x, y = x*NORMALIZE_CONST, y*NORMALIZE_CONST
  return f.anchor.sx - x, f.anchor.sy - y
end

local function drawPlayer(name, x, y)
  local f = CreateFrame("Frame", nil, RPManager.combatJournalFrame.map)
  f:SetSize(48,48)
  f:SetPoint("TOPLEFT", RPManager.combatJournalFrame.map,"TOPLEFT",x,y)
  local trpName = RPMTRP.getTRPName(name)
  local label = ((trpName ~= name) and (trpName.." ("..name..")")) or name
  f:SetScript("OnEnter", function()
    RPMGui.showTooltip(f, label)
  end)

  local t2 = f:CreateTexture(nil, "OVERLAY")
  t2:SetAllPoints()
  SetPortraitTexture(t2, name)
  f.tex = t2
  return f
end

local function updatePlayer(name, x, y)
  local player = RPManager.combatJournalFrame.players[name]
  player:SetPoint("TOPLEFT",RPManager.combatJournalFrame.map,"TOPLEFT",x,y)
  if x < 0 or x+48 > RPManager.combatJournalFrame.map:GetWidth() or
      y > 0 or y-48 < -RPManager.combatJournalFrame.map:GetHeight() then
    player:Hide()
  else
    player:Show()
  end
end

function RPM_deletePlayer(name)
  RPManager.combatJournalFrame.players[name]:Hide()
  RPManager.combatJournalFrame.players[name] = nil
end

function RPM_drawCompass(x, y)
  local a = CreateFrame("Frame", nil, RPManager.combatJournalFrame.map)
  a:SetSize(6, 32)
  a:SetPoint("CENTER", RPManager.combatJournalFrame.map, "CENTER", x+24, y-24)
  local t = a:CreateTexture(nil, "ARTWORK")
  t:SetTexture("Interface/Vehicles/UI-Vehicles-Endcap")
  t:SetAllPoints()
  t:SetVertexColor(1, .3, .3)
  t:SetTexCoord(121/256, 127/256, 92/256, 140/256)
  a.tex = t  
  
  local ag = a:CreateAnimationGroup()
  local r = ag:CreateAnimation("Rotation")
  r:SetRadians(0)
  r:SetDuration(0)
  r:SetEndDelay(20)
  r:SetOrigin("BOTTOM", 0, 0)
  a.rad = ag
  
  return a
end

function RPM_drawSelf(x, y)
  if RPManager.combatJournalFrame.players[playerName] == nil then
    RPManager.combatJournalFrame.players[playerName] = drawPlayer(playerName, x, y)
    RPManager.combatJournalFrame.players[playerName.."Compass"] = RPM_drawCompass(x, y)
  end
  RPManager.combatJournalFrame.frame:SetScript("OnUpdate", RPM_onUpdateCombatJournalFrame)
end

local function updateCompass(x, y)
  local name = playerName.."Compass"
  updatePlayer(name, x, y)
  local a = RPManager.combatJournalFrame.players[name]
  a:SetPoint("TOPLEFT",RPManager.combatJournalFrame.map, "TOPLEFT", x+22, y+8)
  local anim = a.rad:GetAnimations()
  anim:SetRadians(GetPlayerFacing())
  a.rad:Play()
end

function RPM_updateSelf(x, y)
  updatePlayer(playerName, x, y)
  updateCompass(x, y)
  RPMSynch.synchCombat("pos", playerName, x, y)
end

local function setAnchor(wx, wy, sx, sy)
  local anchor = {}
  anchor.wx = tonumber(wx)
  anchor.wy = tonumber(wy)
  anchor.sx = tonumber(sx)
  anchor.sy = tonumber(sy)
  return anchor
end

local function setPlayerPos(name, x, y)
  if RPManager.combatJournalFrame.players[name] == nil then
    RPManager.combatJournalFrame.players[name] = drawPlayer(name, x, y)
  end
  updatePlayer(name, x, y)
end

local function setMobPos(nr, x, y)
  local mob = RPManager.combatJournalFrame.mobList[nr]
  mob.token:ClearAllPoints()
  mob.token:SetPoint("TOPLEFT",RPManager.combatJournalFrame.map,"TOPLEFT",x,y)
  mob.x = x
  mob.y = y
  saveSnapshot()
end

local function setVisible(nr, visible)
  local mob = RPManager.combatJournalFrame.mobList[nr]
  mob.visible = visible
  if mob.visible then
    mob.token:Show()
  else
    mob.token:Hide()
  end
  saveSnapshot()
end

function RPM_updateCombat(list)
  local i = 1
  while i <= #list do
    if list[i] == "anchor" then
      local questID, chapterNr = list[i+1], tonumber(list[i+2])
      local anchor = setAnchor(list[i+3], list[i+4], list[i+5], list[i+6])
      if RPManager.combatJournalFrame ~= nil then
        RPManager.combatJournalFrame.anchor = anchor
        RPM_drawSelf(anchor.sx, anchor.sy)
      else
        RPM_openCombatJrnFrm(questID, chapterNr, anchor)
      end
      i = i+7
    end
    if RPManager.combatJournalFrame == nil then
      i = i+1
    elseif list[i] == "pos" then
      if tonumber(list[i+1]) == nil then
        setPlayerPos(list[i+1], tonumber(list[i+2]), tonumber(list[i+3]))      
      else
        setMobPos(tonumber(list[i+1]), tonumber(list[i+2]), tonumber(list[i+3]))
      end
      i = i+4
    elseif list[i] == "visible" then
      setVisible(tonumber(list[i+1]), list[i+2] == "true")
      i = i+3
    elseif list[i] == "end" then
      RPM_closeCombatJournalFrame()
      i = i+1
    elseif list[i] == "joined" then
      if RPMUtil.isMyQuest(RPManager.combatJournalFrame.questID) then
        RPM_sendAnchor()
        RPM_sendMobs()
      end
      i = i+1
    elseif list[i] == "left" then
      RPM_deletePlayer(list[i+1])
      i = i+2
    end
  end
end

function RPM_sendAnchor()
  local f = RPManager.combatJournalFrame
--  RPMIO.sendAddonMessage(RPMIO.MSG_COMBAT_DATA, string.format("anchor;%d;%d;%f;%f;%f;%f",
--    f.questID, f.chapterNr, f.anchor.wx, f.anchor.wy, f.anchor.sx, f.anchor.sy))
  RPMSynch.synchCombat("anchor", f.questID, f.chapterNr, f.anchor.wx, f.anchor.wy, f.anchor.sx, f.anchor.sy)
end

function RPM_sendMobs()
  for _, mob in ipairs(RPManager.combatJournalFrame.mobList) do
--    RPMIO.sendAddonMessage(RPMIO.MSG_COMBAT_DATA, string.format("pos;%d;%f;%f;visible;%d;%s",
--      mob.mobNr, mob.x, mob.y, mob.mobNr, tostring(mob.visible)))
    RPMSynch.synchCombat("pos", mob.mobNr, mob.x, mob.y,
        "visible", mob.mobNr, mob.visible)
  end
end
