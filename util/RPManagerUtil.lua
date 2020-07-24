if RPMUtil ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")
local soundHandle

local function bool2String(s)
  if s == true then
    return "true"
  else
    return "false"
  end
end

RPMUtil = {
  msg = function(msg, color)
    local inf = ChatTypeInfo[color or "SYSTEM"]
    DEFAULT_CHAT_FRAME:AddMessage(msg, inf.r, inf.g, inf.b, inf.id)
  end,

  createID = function()
    local millis = string.format("%3d", (GetTime() % 1)*1000):gsub(" ", "0")
    return UnitName("player")..time()..millis
  end,

  isMyQuest = function(questID)
    return (RPMAccountDB.quests[questID] ~= nil)
  end,

  -- String functions

  trim = function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end,

  startsWith = function(s, start)
    return string.sub(s, 1, string.len(start)) == start
  end,

  split = function(s, delim)
    local result = {}
    for match in (s..delim):gmatch("(.-)"..delim) do
      table.insert(result, match)
    end
    return result
  end,

  getLocalName = function(name)
    return strsplit("-", name)
  end,

  splitText = function(str, length)
    local words = RPMUtil.split(str:trim(), " ")
    local lines, line, i = {}, "", 1
    while words[i+1] ~= nil do
      if string.len(line) + string.len(words[i+1]) > length then
        table.insert(lines, line:trim())
        line = ""
      end
      line = line..words[i].." "
      i = i+1
    end
    if words[i] ~= nil and words[i]:len() > 0 then
      line = line..words[i].." "
      table.insert(lines, line:trim())
    end
    return lines
  end,

  -- Table functions

  size = function(list)
    local count = 0
    for _ in pairs(list) do
      count = count + 1
    end
    return count
  end,

  isEmpty = function(list)
    return RPMUtil.size(list) == 0
  end,

  contains = function(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
  end,

  shallowCopy = function(obj)
    if type(obj) ~= "table" then
      return obj
    end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(obj) do
      if type(v) == "table" then
        target[k] = {}
      else
        target[k] = v
      end
    end
    setmetatable(target, meta)
    return target
  end,

  deepCopy = function(obj, seen)
    if type(obj) ~= 'table' then
      return obj
    end
    if seen and seen[obj] then
      return seen[obj]
    end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do
      res[RPMUtil.deepCopy(k, s)] = RPMUtil.deepCopy(v, s)
    end
    return res
  end,

  tableToString = function(t)
    local s = "{";
    for index, value in pairs(t) do
      if value == "!first" then
        index = format("\"%s\"", index)
      end
      if type(index) == "string" then
        index = format("\"%s\"", index)
      end
      if type(value) == "table" then
        s = format("%s[%s]=%s,", s, index, RPMUtil.tableToString(value))
      elseif type(value) == "number" then
        s = format("%s[%s]=%s,", s, index, value)
      elseif type(value) == "nil" then
        s = format("%s[%s]=%s,", s, index, "nil")
      elseif type(value) == "boolean" then
        s = format("%s[%s]=%s,", s, index, bool2String(value))
      elseif type(value) == "string" then
        value = gsub(value, "\\", "\\\\")
        value = gsub(value, "\n", "\\n")
        value = gsub(value, "\r", "\\r")
        value = gsub(value, "\"", "\\\"")
        s = format("%s[%s]=\"%s\",", s, index, value)
      end
    end
    return format("%s}", s)
  end,

  stringToTable = function(s)
    RunScript("RPMUtil_tempTable = nil")
    if s == nil then
      print(L["stringToTable1"])
      return nil
    end

    RunScript("RPMUtil_tempTable = " .. s)
    if RPMUtil_tempTable == nil then
      print(L["stringToTable2"])
      return nil
    end
    local table = RPMUtil.deepCopy(RPMUtil_tempTable)
    return table
  end,

  -- Sound functions

  playSound = function(pathOrId)
    if pathOrId == nil or pathOrId == 0 then
      return
    end
    local id = tonumber(pathOrId)
    if id == nil then
      if pathOrId ~= nil and string.len(RPMUtil.trim(pathOrId)) > 0 then
        id = RPManager:getFileId(pathOrId:lower())
      else
        RPMUtil.msg(string.format(L["invalidSound"], (pathOrId or "nil")))
        return
      end
    end
    local _, handle = PlaySoundFile(id, "Master")
    soundHandle = handle
  end,

  stopSound = function()
    StopSound(soundHandle or 0)
  end,

  -- Social functions

  isFriend = function(name)
    for i = 1, GetNumFriends() do
      if GetFriendInfo(i) == name then
        return true
      end
    end
    return false
  end,

  isIgnored = function (name)
    for i = 1, GetNumIgnores() do
      if GetIgnoreName(i) == name then
        return true
      end
    end
    return false
  end
}
