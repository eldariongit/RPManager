local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

if RPMMovie ~= nil then
  return
end

-- Frames
local stdFrm = {}
local gfxFrm = {}
local txtFrm

-- Forward definition
local playMovie

local testMode
local finishFunc
local sceneLines = {}
local script
local currentLine = 1
local txtR, txtG, txtB = 1, 1, 1
local loopFrame
local waitTime
local lastTick


local function createTxtFrame(num)
  for i = 1, num do
    if stdFrm[i] == nil then
      stdFrm[i] = CreateFrame("PlayerModel")
      stdFrm[i]:SetFrameStrata("FULLSCREEN")
      stdFrm[i]:SetPoint("BOTTOMLEFT",UIParent, "BOTTOMLEFT", 0,0)
      stdFrm[i]:SetPoint("TOPRIGHT",UIParent, "TOPRIGHT", 0,0)
      stdFrm[i].bg = stdFrm[i]:CreateTexture(nil,"BACKGROUND")
      stdFrm[i].bg:SetAllPoints()
    end
  end
end

local function createGfxFrame(num)
  for i = 1, num do
    if gfxFrm[i] == nil then
      gfxFrm[i] = CreateFrame("Frame")
      gfxFrm[i]:SetFrameStrata("FULLSCREEN")
      gfxFrm[i].bg = gfxFrm[i]:CreateTexture(nil,"BACKGROUND")
      gfxFrm[i].bg:SetAllPoints()
    end
  end
end

local function iniPlayerFrames()
  createTxtFrame(1)
  createGfxFrame(1)

  txtFrm = CreateFrame("MessageFrame")
  txtFrm:SetWidth(512)
  txtFrm:SetHeight(280)
  txtFrm:SetPoint("TOP", 0, -100, "BOTTOM", 0, 200)
  txtFrm:SetScale(1)
  txtFrm:SetInsertMode("BOTTOM")
  txtFrm:SetFrameStrata("TOOLTIP")
  txtFrm:SetToplevel(true)
  txtFrm:SetFontObject(SystemFont_OutlineThick_Huge2)
end

local function releasePlayerFrames()
  for i = #stdFrm, 1, -1 do
    stdFrm[i]:Hide()
    stdFrm[i].bg = nil
    stdFrm[i] = nil
  end
  for i = #gfxFrm, 1, -1 do
    gfxFrm[i]:Hide()
    gfxFrm[i].bg = nil
    gfxFrm[i] = nil
  end

  txtFrm:Hide()
  txtFrm = nil
end

local function checkWait(t)
  if type(sec) ~= "number" or tonumber(t[2]) < 1 then
    RPMUtil.msg(L["checkSecondErr"])
    return false
  end
  return true
end

local function parseWait(t)
  return tonumber(t[2])
end

local function checkText(line)
  return true
end

local function parseText(line)
  local pos=string.find(line, " ")
  local txt=strsub(line, pos+1)
  txtFrm:AddMessage(txt, txtR, txtG, txtB, 55, dur)
  return true
end

local function checkShake(line)
  local intens, dur = tonumber(t[2]), tonumber(t[3])
  if not intens or intens < 1 or intens > 64 then
    RPMUtil.msg(L["checkShakeErr1"])
    return false
  end
  if not dur or dur < 1 then
    RPMUtil.msg(L["checkShakeErr2"])
    return false
  end
  return true
end

local function parseShake(t)
  local intens, dur=tonumber(t[2]),tonumber(t[3])
  local f = CreateFrame("Frame")
  local wf = WorldFrame
  local wfPoints={}
  -- if intens>64 then intens=64 end
  f:Hide()
  f:SetScript("OnUpdate",function(self, elapsed)
    dur = dur - elapsed
    if dur < 0 then
      dur = 0
      f:Hide()
    end
    local moveBy = math.random(-intens, intens)*dur
    wf:ClearAllPoints()
    for _, v in pairs(wfPoints) do
      wf:SetPoint(v[1], v[2], v[3], v[4]+moveBy, v[5]+moveBy)
    end
  end)

  for i = 1, wf:GetNumPoints() do
    wfPoints[i] = { wf:GetPoint(i) }
  end
  f:Show()
end

local function checkScript(_read)
  return true
end

local function parseScript(_read)
  if not _read then
    GHI_DoScript(script)
  end
  script = ""
end

local function checkTexture(t)
  local frm=tonumber(t[2])
  if not frm or frm < 1 then
    RPMUtil.msg(L["checkFrameErr"])
    return false
  end
  if frm > #stdFrm then
    createTxtFrame(frm)
  end
  return true
end

local function parseTexture(t)
  local frm=tonumber(t[2])
  stdFrm[frm]:SetModel(t[3])
end

local function checkGfx(t)
  local gfx = tonumber(t[2])
  if not gfx or gfx < 1 then
    RPMUtil.msg(L["checkFrameErr"])
    return false
  end
  if gfx > #gfxFrm then
    createGfxFrames(gfx)
  end
  if not t[3] then
    return false
  end
  local x1,y1,x2,y2 = tonumber(t[3]),tonumber(t[4]),tonumber(t[5]),tonumber(t[6])
  if not x1 or not x2 or not y1 or not y2 then
    RPMUtil.msg(L["checkGfxErr"])
    return false
  end
  return true
end

local function parseGfx(t)
  local gfx,x1,y1,x2,y2=tonumber(t[2]),tonumber(t[3]),tonumber(t[4]),tonumber(t[5]),tonumber(t[6])
  if not x1 then
    gfxFrm[gfx]:Hide()
    return true
  end
  gfxFrm[gfx]:SetPoint("BOTTOMLEFT", WorldFrame, "CENTER", x1, y1)
  gfxFrm[gfx]:SetPoint("TOPRIGHT", WorldFrame, "CENTER", x2, y2)
  gfxFrm[gfx]:Show()
  if not t[7] then
    return true
  end
  gfxFrm[gfx].bg:SetTexture(t[7])
  gfxFrm[gfx].bg:SetAllPoints()
  return true
end

local function checkColor(t)
  local frm,r,g,b=tonumber(t[2]),tonumber(t[3]),tonumber(t[4]),tonumber(t[5])
  if not r or not g or not b or r<0 or r>1 or g<0 or g>1 or b<0 or b>1 then
    RPMUtil.msg(L["checkColorErr"])
    return false
  end

  if frm and frm > #stdFrm then
    createTxtFrame(frm)
  end

  if frm and frm > 0 then
    return true
  elseif string.lower(t[2]) == "text" then
    return true
  end
  RPMUtil.msg(L["checkFrameErr"])
  return false
end

local function parseColor(t)
  local frm, r, g, b = tonumber(t[2]), tonumber(t[3]), tonumber(t[4]), tonumber(t[5])
  if frm then
    -- stdFrm[frm].bg:SetTexture(r,g,b)
    stdFrm[frm].bg:SetColorTexture(r, g, b) -- 7.0.3
  elseif string.lower(t[2]) == "text" then
    txtR = r
    txtG = g
    txtB = b
  end
end

local function checkFade(t)
  local frm, sec, from, to = tonumber(t[2]), tonumber(t[3]), tonumber(t[4]), tonumber(t[5])
  if not frm or frm < 1 then
    RPMUtil.msg(L["checkFrameErr"])
    return false
  elseif not sec or sec<1 then
    RPMUtil.msg(L["checkSecondErr"])
    return false
  elseif not from or not to or from < 0 or from > 1 or to < 0 or to > 1 then
    RPMUtil.msg(L["checkFadeErr"])
    return false
  end
  if frm > #stdFrm then
    createTxtFrame(frm)
  end
  return true
end

local function parseFade(t)
  local frm,sec,from,to=tonumber(t[2]),tonumber(t[3]),tonumber(t[4]),tonumber(t[5])
  UIFrameFadeIn(stdFrm[frm], sec, from, to)
end

local function checkPlay(t)
  local id = tonumber(t[2])
  if not id then
    RPMUtil.msg(L["checkFileIdErr"])
    return false
  end
  return true
end

local function parsePlay(t)
  --  f = string.gsub(t[2],"\\+","\\")
  --  PlaySoundFile(f, "Master")
  RPMUtil.playSound(t[2])
end

local function checkEmote(line)
  return true
end

local function parseEmote(line)
  local pos = string.find(line, " ")
  local em = strsub(line, pos+1)
  DoEmote(em, "none")
end

local function checkLine(line)
  local t = { strsplit(" ", line) }
  local cmd = string.lower(t[1])
  if cmd == "play" then return checkPlay(t)
  elseif cmd == "emote" then return checkEmote(line)
  elseif cmd == "fade" then return checkFade(t)
  elseif cmd == "color" then return checkColor(t)
  elseif cmd == "text" then return checkText(line)
  elseif cmd == "shake" then return checkShake(t)
  elseif cmd == "texture" then return checkTexture(t)
  elseif cmd == "gfx" then return checkGfx(t)
  elseif cmd == "script" then return checkScript(true)
  elseif cmd == "endscript" then return checkScript(false)
  else return true end
end

function RPM_parseLine(line)
  local t = {strsplit(" ", line)}
  local cmd = string.lower(t[1])
  if cmd == "play" then parsePlay(t)
  elseif cmd == "emote" then parseEmote(line)
  elseif cmd == "fade" then parseFade(t)
  elseif cmd == "color" then parseColor(t)
  elseif cmd == "text" then parseText(line)
  elseif cmd == "shake" then parseShake(t)
  elseif cmd == "texture" then parseTexture(t)
  elseif cmd == "gfx" then parseGfx(t)
--  elseif cmd == "script" then parseScript(true)
--  elseif cmd == "endscript" then parseScript(false)
--  else script = script.." "..string.gsub(line, "&quot;","\"")
  end
end

local function onUpdateMovie()
  if currentLine > #sceneLines then
    return
  end

  local t = time()
  local diff = t-lastTick
  lastTick = t

  if diff > 0 then
    RPM_ELAPSEDTIME=RPM_ELAPSEDTIME + diff
    if RPM_ELAPSEDTIME >= waitTime then
      loopFrame:SetScript("OnUpdate", nil)
      loopFrame = nil
      playMovie()
    end
  end
end

playMovie = function()
  while currentLine <= #sceneLines do
    local line = string.gsub(sceneLines[currentLine], "^%s*(.-)%s*$","%1")
    currentLine = currentLine + 1
    if not line or string.len(line) == 0 then
      -- do nothing
    elseif string.sub(string.lower(line), 1, 4) == "wait" then
      if testMode then
        RPMUtil.msg(L["playing"].." '"..line.."'")
      end
      local t = { strsplit(" ",line) }
      loopFrame = CreateFrame("Frame")
      loopFrame:SetScript("OnUpdate", onUpdateMovie)
      waitTime = parseWait(t)
      lastTick = time()
      RPM_ELAPSEDTIME = 0
      break
    else
      RPM_parseLine(line)
      if testMode then
        RPMUtil.msg(L["playing"].." '"..line.."'")
      end
    end
  end
  if currentLine > #sceneLines then
    if testMode then
      RPMUtil.msg(L["sceneFinished"])
    end
    releasePlayerFrames()
    if finishFunc then
      finishFunc()
    end
  end
end

RPMMovie = {
  checkMovie = function(script)
    local _lines = {strsplit("\n", script)}
    local isOk = true
    for i = 1,#_lines do
      isOk = isOk and checkLine(_lines[i])
    end
    if isOk then
      RPMUtil.msg(L["sceneNoErrors"])
    end
    return isOk
  end,

  startMovie = function(script, mode, onFinishCallback)
    testMode = mode
    finishFunc = onFinishCallback
    sceneLines = {strsplit("\n", script)}
    currentLine = 1

    iniPlayerFrames()
    playMovie()
  end
}
