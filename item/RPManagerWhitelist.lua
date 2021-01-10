if RPMWhitelist ~= nil then
  return
end

-- Add any exception here at your own risk!
-- Never add exceptions from people you don't know!
-- You better also DON't add exceptions from people you DO know!
local whitelist = {
  "4092367861", "4267839665", -- Manaflow (enUS/deDE)
  "162588920",  "3338383437", -- Airgun (enUS/deDE)
  "4229529063",               -- Airgun Target
  "1819029890", "671494025",  -- Gamebox Apexis (enUS/deDE)
}

RPMWhitelist = {
  isWhitelisted = function(hash)
    return RPMUtil.contains(whitelist, tostring(hash))
  end,
}