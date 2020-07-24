local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")


local function addLabel(text)
  RPMGui.addCenterLabel(text, RPManager.creditFrame.scroll, RPMFont.ARIAL, 20)
end

local function addImage(image, parent)
  addLabel(" ")
  RPMGui.drawCenterImage("Interface/QuestionFrame/"..image, 128, 64, parent)
  addLabel(" ")
end

function RPManager:showCredits()
  if RPManager.creditFrame ~= nil then
    self:closeCreditsFrame()  
  end
  
  local f = RPMForm.drawBaseFrame(L["credits"], "credits", function() self:closeCreditsFrame() end)
  RPManager.creditFrame = f
  
  f.scroll = RPMGui.addScrollBox(f, 420, "List")
  RPMGui.drawCenterImage("interface/addons/RPManager/img/rpm", 512, 80, f.scroll, 0, 1, 3/8, 1)
  addLabel(" ")

  RPMGui.addHeader(L["developer"], f.scroll)
  addLabel("\nPris - Die Aldor ("..L["horde"]..")")
  addLabel("Pr\195\173ss - Die Aldor ("..L["alliance"]..")")
  addImage("answer-ChromieScenario-Gold", f.scroll)

  RPMGui.addHeader(L["tester"], f.scroll)
  addLabel("\nEvirell - Die Aldor ("..L["horde"]..")")
  addLabel("Kandera - Die Aldor ("..L["horde"]..")")
  addImage("answer-ChromieScenario-Hourglass", f.scroll)

  RPMGui.addHeader(L["textures"], f.scroll)
  addLabel("\nAlthaj - "..L["texLava"].." (CC-BY 3.0)")
  addLabel("Behrtron - "..L["texMarbleWhite"]..", weiß (CC0)")
  addLabel("borjae - "..L["texCobble"].." (CC-BY-SA 3.0)")
  addLabel("Downdate - "..L["texSky"].." (CC-BY 3.0)")
  addLabel("etory - "..L["texRock"].." (CC-BY 3.0)")
  addLabel("FRPZ team - "..L["texWater"].." (CC-BY 3.0)")
  addLabel("Keith333 - "..L["texCarpetRed"].." (CC-BY 3.0)")
  addLabel("KIIRA - "..L["texGrass"].." & "..L["texSand"].." (CC-BY 3.0)")
  addLabel("Lamoot - "..L["texGrassDry"].." (CC-BY 3.0)")
  addLabel("n4 - "..L["texGravel"].." (CC0)")
  addLabel("PamNawi - "..L["texTiles"].." (CC0), "..L["texPlates"].." (CC-BY 4.0) & "..L["texPlanks"].." (CC-BY 3.0)")
  addLabel("tomek - "..L["texSnow"].." (CC-BY 3.0)")
  addImage("answer-Gorgrond-PrimalForest", f.scroll)

  RPMGui.addHeader(L["images"], f.scroll)
  addLabel("\nhttps://www.kisspng.com - "..L["quill"])
  addImage("answer-zone-BurningCrusade", f.scroll)
  
  f.scroll:DoLayout()  
end

function RPManager:closeCreditsFrame()
  RPManager.creditFrame:Release()
  RPManager.creditFrame = nil
end
