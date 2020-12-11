if RPMWhitelist ~= nil then
  return
end

-- Add any exception here at your own risk!
local whitelist = {
  "3963504668", -- Manaflow (enUS)
  "3277221330", -- Manaflow (deDE)
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