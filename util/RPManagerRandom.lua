if RPMRandom ~= nil then
  return
end

local randomtable = {}
for i = 1, 97 do
  randomtable[i] = math.random()
end

RPMRandom = {
  random = function(arg1, arg2)
    if tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
      local r = RPMRandom.random()
      return math.floor((r * (arg2 - arg1 + 1)) + arg1)
    elseif tonumber(arg1) ~= nil then
      return RPMRandom.random(1, arg1)
    else
      local x = math.random()
      local i = 1 + math.floor(97*x)
      x, randomtable[i] = randomtable[i], x
      return x
    end
  end
}
