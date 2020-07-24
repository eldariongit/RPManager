if RPMFont ~= nil then
  return
end

RPMFont = {
  FRITZ    = "Fonts/FRIZQT__.ttf",
  ARIAL    = "Fonts/ARIALN.ttf",
  SKURRI   = "Fonts/skurri.ttf",
  MORPHEUS = "Fonts/MORPHEUS.ttf",
}

local FONT_MAP = {
  [RPMFont.FRITZ] = "FritzQT",
  [RPMFont.ARIAL] = "Arial",
  [RPMFont.SKURRI] = "Skurri",
  [RPMFont.MORPHEUS] = "Morpheus",
--  ["Fonts/FRIENDS.TTF"] = "Friends",
}

local FONT_LIST = {}
for k,_ in pairs(FONT_MAP) do
  table.insert(FONT_LIST, k)
end

function RPMFont:getFontMap()
  return FONT_MAP
end

function RPMFont:getFontList()
  return FONT_LIST
end

function RPMFont:getFont(id)
  return FONT_MAP[id]
end
