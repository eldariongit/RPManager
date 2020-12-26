if RPMWhitelist ~= nil then
  return
end

-- Add any exception here at your own risk!
local whitelist = {
  "4092367861", "4267839665", -- Manaflow (enUS/deDE)
  "1488823541", "3498968952", -- Airgun (enUS/deDE)
  "1911885282", "2889388785", -- Airgun Target (enUS/deDE)
  "1819029890", "671494025",  -- Gamebox Apexis (enUS/deDE)
}

RPMWhitelist = {
  isWhitelisted = function(hash)
    return RPMUtil.contains(whitelist, tostring(hash))
  end,
}