if RPMProgressBar ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local PROGRESSBAR_BORDER_TEXTURE = "Interface/CastingBar/UI-CastingBar-Border"
local PROGRESSBAR_FILL_TEXTURE = "Interface/GLUES/LoadingBar/Loading-BarFill"
local PROGRESSBAR_FLASH_TEXTURE = "Interface/CastingBar/UI-CastingBar-Flash"

local GetTime = GetTime
local bars = {}
local barOrder = {}

RPMProgressBar = {}

function RPMProgressBar.onUpdate(_, elapsed)
  local now = GetTime()
  for _, bar in pairs(bars) do
    if now - bar.lastUpdate > 5 then
      bar:cancelBar()
      break
    elseif bar.flash ~= nil then
      bar.flash.dur = bar.flash.dur + elapsed
--      local a = math.abs(bar.flash.dur - 0.5) * -2 + 1 -- 1 Second
      local a = math.abs(bar.flash.dur - 0.25) * -4 + 1
      bar.flash.tex:SetVertexColor(1, 1, 1, a)
    elseif bar.curr == bar.max then
      bar:flashBar()
    end
    bar:updateBar()
  end
end

function RPMProgressBar.inc(id)
  local bar = bars[id]
  if bar ~= nil then
    bar.curr = bar.curr + 1
    bar.lastUpdate = GetTime()
  end
end

function RPMProgressBar.getPos(id)
  for i, barId in pairs(barOrder) do
    if barId == id then
      return i
    end
  end
  return 99 -- effectively invisible
end

local function drawBar(parent, w, h, lvl, texLevel, texOrRed, g, b, a)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(w, h)
  f:SetFrameLevel(lvl)

  local t = f:CreateTexture(nil, texLevel)
  t:SetAllPoints()
  if g ~= nil then
    t:SetColorTexture(texOrRed, g, b, a)
  else
    t:SetTexture(texOrRed)
  end
  f.tex = t
  return f
end

function RPMProgressBar.addBar(id, max, type, direction)
  local bar = drawBar(UIParent, 512, 128, 1000, "OVERLAY", PROGRESSBAR_BORDER_TEXTURE)
  bar.lastUpdate = GetTime()
  bar.curr = 1
  bar.max = max
  bar.id = id

  bars[id] = bar
  barOrder[#barOrder+1] = id

  local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("CENTER", bar, "CENTER", 0, 0)
  label:SetJustifyH("CENTER")
--  label:SetText(L["receive"].." "..L[type])
  label:SetText(string.format(L[direction], L[type]))
  label:SetSize(360, 36)

  local bg = drawBar(bar, 390, 40, 998, "OVERLAY", 0, 0, 0, 1)
  bg:SetPoint("CENTER", bar, "CENTER", 0, 0)

  local pg = drawBar(bg, 1, 40, 999, "OVERLAY", PROGRESSBAR_FILL_TEXTURE)
  pg:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
  bar.pg = pg

  bar.updateBar = function(self)
    local pos = RPMProgressBar.getPos(self.id)
    self:SetPoint("CENTER", UIParent, "CENTER", 0, -pos * 100)
    self.pg:SetWidth(390 * self.curr / self.max)
  end

  bar.cancelBar = function(self)
    RPMUtil.msg(L["timeoutMsg"])
    RPMItem.cancelItemInTransfer(self.id) -- only needer for sender
    self:closeBar(false)
  end

  bar.flashBar = function(self)
    local flash = CreateFrame("Frame", nil, self)
    flash:SetSize(512, 128)
    flash:SetPoint("CENTER", self, "CENTER", 0, 0)
    flash:SetFrameLevel(1001)
    local t = flash:CreateTexture(nil, "OVERLAY")
    t:SetTexture(PROGRESSBAR_FLASH_TEXTURE)
    t:SetAllPoints()
    t:SetVertexColor(1, 1, 1, 0)

    self.flash = { tex = t, dur = 0 }
    self.flashTimer = RPManager:ScheduleTimer(function()
      self.flashTimer = nil
      self:closeBar()
    end, .5)
  end

  bar.closeBar = function(self)
    barOrder[self.id] = nil
    bars[self.id] = nil
    self:Hide()
    self = nil
  end

  bg:Show()
end
