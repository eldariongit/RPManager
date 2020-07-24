if RPMTRP ~= nil then
  return
end

local trpLoaded = false

RPMTRP = {
  setTrpLoaded = function(isLoaded)
    trpLoaded = isLoaded
  end,

  isTrpLoaded = function()
    return trpLoaded
  end,

  getTRPName = function(engineName)
    engineName = strsplit(",", engineName)

    local unitID = engineName.."-"..GetRealmName()
    local trpName = ""
    local chara

    if trpLoaded then
      if engineName == UnitName("player") then
        chara = TRP3_API.profile.getPlayerCurrentProfile().player.characteristics
      elseif TRP3_API.register.isUnitIDKnown(unitID) then
        local profileID = TRP3_API.register.hasProfile(unitID)
        chara = TRP3_API.register.getProfile(profileID).characteristics
      else
        return engineName
      end

      -- if chara.TI ~= nil and chara.TI ~= "" then
      -- trpName = trpName .. chara.TI .. " "
      -- end
      if chara.FN ~= nil and chara.FN ~= "" then
        trpName = trpName .. chara.FN .. " "
      end
      -- if chara.LN ~= nil and chara.LN ~= "" then
      -- trpName = trpName .. chara.LN
      -- end
      trpName = strtrim(trpName)
    end

    if trpName == "" then
      trpName = engineName
    end
    trpName = string.gsub(trpName, "-"..GetRealmName(), "")
    return trpName
  end
}
