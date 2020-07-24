RPM_BD = {
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
  tile = true,
  tileSize = 6,
  edgeSize = 6,
  insets = { left = 4, right = 4,top = 4,bottom = 4}}

-- https://github.com/Gethe/wow-ui-textures/tree/live/Worldmap/
-- https://github.com/Gethe/wow-ui-textures/tree/live/WorldMap/
-- (notice the big and small m of Worldmap/WorldMap)

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local mapTiles, mapList = {}, {}

function RPM_getMapTiles()
  return mapTiles
end

function RPM_getMap(fullPath)
  return mapTiles[fullPath]
end

local function getMapList()
  return mapList
end

local function split(s, delim)
  local result = {}
  for match in (s..delim):gmatch("(.-)"..delim) do
    table.insert(result, match)
  end
  return result
end

function RPManager:fillMapTileList()
  for i = 1, #mapTextureList do
    local path, tex = string.match(mapTextureList[i], "(.-)([^/]-([^/%.]+))$")

    local numbers = {}
    for num in string.gmatch(tex, "%d+" ) do
      numbers[#numbers+1] = num
    end

    if #numbers > 0 then
      local delim = ""
      local tile = tonumber(numbers[#numbers])

      tex = string.sub(tex, 1, -string.len(tile)-1)
      if string.sub(tex, -1, -1) == "_" then
        delim = "_"
        tex = string.sub(tex, 1, -2)
      end

      local fullPath = path..tex
      if mapTiles[fullPath] == nil then
        mapTiles[fullPath] = { path=path, tex=tex, delim=delim, tiles = tile }
      elseif mapTiles[fullPath].tiles < tile then
        mapTiles[fullPath].tiles = tile
      end
    end
  end

  for k,v in pairs(mapTiles) do
    if v.tiles < 4 then
      mapTiles[k] = nil
    else
      mapList[#mapList+1] = v.path..v.tex
    end
  end
  table.sort(mapList)
end

local function setNewPointOnMap(x, y)
  local i = #RPManager.itemFrame.tokens+1
  if RPManager.itemFrame.tokenId ~= 0 then
    RPManager.itemFrame.tokens[i] = { x=x, y=y, x2=nil, y2=nil, id=RPManager.itemFrame.tokenId, num=0, txt="", ico=nil, label=nil }
    RPM_drawTableEntry(i)
    RPM_updateTokenFrm()
  elseif RPManager.itemFrame.tempX ~= nil then
    RPManager.itemFrame.tokens[i] = { x=RPManager.itemFrame.tempX, y=RPManager.itemFrame.tempY, x2=x, y2=y, id=RPManager.itemFrame.tokenId, num=0, txt="", ico=nil, label=nil }
    RPM_drawTableEntry(i)
    RPM_updateTokenFrm()
    RPManager.itemFrame.tempX = nil
    RPManager.itemFrame.tempY = nil
  else
    RPManager.itemFrame.tempX = x
    RPManager.itemFrame.tempY = y
  end
end

function RPM_putMapOnScreen(frame, key)
  if frame.textures ~= nil then
    for i = #frame.textures, 1, -1 do
      frame.textures[i]:SetTexture(nil)
      frame.textures[i] = nil
    end
  else
    frame.textures = {}
  end
  if frame.pane ~= nil then
    frame.pane:Hide()
    frame.pane = nil
  end

  local tileSet = mapTiles[key]
  local path = "interface/worldmap/"..key..tileSet.delim
  local xTiles, yTiles = 3, 3
  if tileSet.tiles == 4 then
    xTiles = 2
    yTiles = 2
  elseif tileSet.tiles == 12 then
    xTiles = 4
  end

  for id = 1, tileSet.tiles do
    local x = (id-1) % xTiles
    local y = math.floor((id-1) / xTiles)
    local t = frame.frame:CreateTexture(nil, "ARTWORK")
    t:SetTexture(path..id)
    t:SetPoint("TOPLEFT", x*256 + 15, -y*256 - 65, frame.frame)
    frame.textures[#frame.textures+1] = t
  end

  frame:SetWidth(256*xTiles + 10)
  frame:SetHeight(256*yTiles + 30)

  local pane = CreateFrame("Button", nil, frame.frame)
  pane:SetPoint("CENTER",frame.frame,"CENTER",0,-15)
  pane:SetSize(256*xTiles-30, 256*yTiles-80)
  pane:SetBackdrop(RPM_BD)
  pane:SetFrameLevel(101)
  pane:SetScript("OnClick", function()
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    setNewPointOnMap(x/s-frame.pane:GetLeft(), y/s-frame.pane:GetBottom())
  end)
  pane:SetScript("OnEnter",function() frame:SetStatusText(key) end)
  pane:SetScript("OnLeave",function() frame:SetStatusText("") end)

  frame.pane = pane
end

function RPM_drawTableEntry(i)
  RPM_clearTableEntry(i)

  local x, y = RPManager.itemFrame.tokens[i].x, RPManager.itemFrame.tokens[i].y
  if RPManager.itemFrame.tokens[i].x2 == nil then
    RPManager.itemFrame.tokens[i].ico = RPM_drawIcon(x, y, RPManager.itemFrame.tokens[i].id, RPManager.itemFrame.pane, true)
    RPManager.itemFrame.tokens[i].label = RPM_drawLabel(x+90, y+15, RPManager.itemFrame.tokens[i].txt, RPManager.itemFrame.pane)
  else
    local x2, y2 = RPManager.itemFrame.tokens[i].x2, RPManager.itemFrame.tokens[i].y2
    RPManager.itemFrame.tokens[i].ico = RPM_drawLine(x, y, x2, y2, RPManager.itemFrame.pane)
  end
end

function RPM_drawLabel(x, y, txt, parent)
  local l = parent:CreateFontString(nil)
  l:SetFont("Fonts\\FRIZQT__.TTF", 11, nil)
  l:SetJustifyH("LEFT")
  l:SetSize(170, 20)
  l:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
  l:SetText(txt)
  return l
end

function RPM_drawIcon(x, y, id, parent, onMap)
  local f = CreateFrame("Frame", nil, parent)
  local t = f:CreateTexture(nil, "BACKGROUND")
  t:SetTexture("Interface/MINIMAP/POIIcons")
  t:SetAllPoints()
  f:SetSize(24, 24)
  f:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
  f:SetFrameLevel(100)
  f.tex = t

  local x1, x2, y1, y2 = RPM_calcPos(id)
  f.tex:SetTexCoord(x1, x2, y1, y2)
  return f
end

local function drawRouteLine(tex,parent,sx,sy,ex,ey,w)
  local relPoint = "CENTER"
  local linefactor_2 = 32/30/2
  local dx, dy = ex-sx, ey-sy
  local cx, cy = (sx+ex)/2, (sy+ey)/2

  if dx<0 then dx,dy=-dx,-dy end

  local l = sqrt((dx*dx) + (dy*dy))

  if l == 0 then
    tex:SetTexCoord(0,0,0,0,0,0,0,0)
    tex:SetPoint("BOTTOMLEFT", parent, relPoint, cx,cy)
    tex:SetPoint("TOPRIGHT", parent, relPoint, cx,cy)
    return
  end

  local s, c = -dy/l, dx/l
  local sc = s*c

  local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy
  if dy >= 0 then
    Bwid =((l*c) - (w*s))*linefactor_2
    Bhgt =((w*c) - (l*s))*linefactor_2
    BLx, BLy, BRy = (w/l)*sc, s*s, (l/w)*sc
    BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx
    TRy = BRx
  else
    Bwid = ((l*c) + (w*s))*linefactor_2
    Bhgt = ((w*c) + (l*s))*linefactor_2
    BLx, BLy, BRx = s*s, -(l/w)*sc, 1 + (w/l)*sc
    BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy
    TRx = TLy
  end

  tex:ClearAllPoints()
  tex:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
  tex:SetPoint("BOTTOMLEFT", parent, relPoint, cx - Bwid, cy - Bhgt)
  tex:SetPoint("TOPRIGHT", parent, relPoint, cx + Bwid, cy + Bhgt)
end

function RPM_drawLine(sx, sy, ex, ey, parent)
  local f = CreateFrame("Button", nil, parent)
  local t = f:CreateTexture(nil, "BACKGROUND")
  t:SetTexture("Interface/CHATFRAME/UI-ChatInputBorder")
  t:SetAllPoints()
  f:SetSize(parent:GetWidth(), parent:GetHeight())
  f:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
  f:SetFrameLevel(100)
  f.tex = t

  drawRouteLine(t, parent,
    sx-(parent:GetWidth()/2), sy-(parent:GetHeight()/2),
    ex-(parent:GetWidth()/2), ey-(parent:GetHeight()/2), 5)
  return f
end

function RPM_clearTableEntry(i)
  RPM_clearToken(RPManager.itemFrame.tokens[i])
end

function RPM_clearToken(t)
  if t.ico ~= nil then
    t.ico:Hide()
    t.ico = nil
  end
  if t.label ~= nil then
    t.label:Hide()
    t.label = nil
  end
end

function RPM_convTable2String()
   local s = ""
   for i = 1, #RPManager.itemFrame.tokens do
     local t = RPManager.itemFrame.tokens[i]
     local txt = t.txt
     if txt == nil or txt == "" then
       txt = " "
     end
     s = s..t.x.."|"..t.y.."|"..tostring(t.x2).."|"..tostring(t.y2)
             .."|"..t.id.."|"..t.num.."|"..txt.."|"
   end
   return s
end

function RPM_convString2Table(s)
  local t = {}
  for v in string.gmatch(s,"([^|]+)") do
    t[#t+1] = v
  end
  for i=1, #t, 7 do
    local nX, nY = t[i+2], t[i+3]
    if nX == "nil" then
      nX = nil
      nY = nil
    end
    RPManager.itemFrame.tokens[#RPManager.itemFrame.tokens+1]={ x=t[i], y=t[i+1], x2=nX, y2=nY, id=t[i+4], num=t[i+5], txt=t[i+6], frm=nil, ico=nil, label=nil }
    RPM_drawTableEntry(#RPManager.itemFrame.tokens)
  end
end

function RPM_cleanMap(tokenList)
  for i = #tokenList, 1, -1 do
    RPM_clearTableEntry(i)
    table.remove(tokenList, 1)
  end
end

function RPM_drawTokenFrame(itemID)
  if RPManager.tokenFrame == nil then
    RPManager.tokenFrame = RPMForm.drawBaseFrame("Token", "token", RPM_closeTokenFrame)
  else
    RPManager.tokenFrame:ReleaseChildren()
  end

  local f = RPManager.tokenFrame
  f.scroll = RPMGui.addScrollBox(f, 396, "List")
  f:SetWidth(300)
  RPM_updateTokenFrm()
  f.itemID = itemID
end

function RPM_updateTokenFrm()
  local scroll = RPManager.tokenFrame.scroll
  local itemID = RPManager.tokenFrame.itemID
  local item = RPMAccountDB.items[itemID]

  scroll:ReleaseChildren()
  if RPManager.itemFrame.tokens == nil or RPManager.itemFrame.tokens == {} then
    RPMGui.addLabel(L["noTokens"], scroll, RPMFont.ARIAL, 20)
    return
  end
  for i = 1, #RPManager.itemFrame.tokens do
    local token = RPManager.itemFrame.tokens[i]
    local iBox = RPMGui.addInlineGroup("", "Flow", scroll)

    local path, x1, x2, y1, y2 = RPM_getIconById(tonumber(token.id))
    local img = RPMGui.addImage(path, 16, 16, iBox, x1, x2, y1, y2)
    img:SetWidth(20)

    RPMGui.addEditBox("", token.txt, 200, 30, iBox, function(self)
      RPManager.itemFrame.tokens[i].txt = self:GetText()
      RPM_clearTableEntry(i)
      RPM_drawTableEntry(i)
    end)
    RPMGui.addButton(L["delete"],100,iBox,function()
      RPM_clearTableEntry(i)
      table.remove(RPManager.itemFrame.tokens, i)
    end, L["deleteTokenDesc"])
  end
  scroll:DoLayout()
end

function RPM_closeTokenFrame()
  RPManager.tokenFrame:Release()
  RPManager.tokenFrame = nil
  if RPManager.itemFrame ~= nil then
    RPManager.itemFrame:Hide()
  end
end
