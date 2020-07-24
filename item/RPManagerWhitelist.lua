if RPMWhitelist ~= nil then
  return
end


local whitelist = {
  "4146470940", -- Manaflow (enUS)
  "598125325", -- Manaflow (deDE)
  "1488823541", -- Airgun (enUS)
  "3498968952", -- Airgun (deDE)
  "1911885282", -- Airgun Target (enUS)
  "2889388785", -- Airgun Target (deDE)
}

RPMWhitelist = {
  isWhitelisted = function(hash)
    return RPMUtil.contains(whitelist, tostring(hash))
  end,
}