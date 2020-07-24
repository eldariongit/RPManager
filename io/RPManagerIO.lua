if RPMIO ~= nil then
  return
end

local MSG_SPLITTER = "#"
local MSG_HEADER = "RPM1"
local MSG_MAX_LEN = 200


RPMIO = {
  -- addon message prefixes
  MSG_SEND_QUEST     = "RPMQuest",
  MSG_SEND_CHAPTER   = "RPMChapter",
  MSG_SHOW_CHAPTER   = "RPMShow",
  MSG_COMBAT_DATA    = "RPMCombat",
  MSG_SEND_ITEM_REQ  = "RPMItemReq",
  MSG_SEND_ITEM_PERM = "RPMItemPerm",
  MSG_SEND_ITEM_STAT = "RPMItemStat",
  MSG_SEND_ITEM      = "RPMItem",
  MSG_SYNCH_QRY      = "RPMSynchQry",
  MSG_SYNCH_ANS      = "RPMSynchAns",


  registerAddonMessagePrefix = function()
    for key, _ in pairs(RPMIO.messageFields) do
      C_ChatInfo.RegisterAddonMessagePrefix(key)
    end
  end,

  parseMessage = function(type, msg, sender)
    local fields = RPMIO.messageFields[type]
    if fields == nil then
      return
    end

    local msgTokens = {}
    local numFields = #fields.tokens + 1 -- + header
    local tokens = { strsplit(MSG_SPLITTER, msg, numFields) }
    table.remove(tokens, 1) -- remove header
    for i, token in ipairs(tokens) do
      if fields.numeric[i] then
        msgTokens[fields.tokens[i]] = tonumber(token)
      else
        msgTokens[fields.tokens[i]] = token
      end
    end
    msgTokens["sender"] = sender
    return msgTokens
  end,

  splitElement = function(element)
    local str = RPMUtil.tableToString(element)
    local list = {}
    while string.len(str) > MSG_MAX_LEN do
      list[#list+1] = string.sub(str, 1, MSG_MAX_LEN)
      str = string.sub(str, -(string.len(str) - MSG_MAX_LEN))
    end
    if str ~= nil and string.len(str) > 0 then
      list[#list+1] = str
    end
    return list
  end,

  sendAddonMessage = function(msgType, tokenList, receiver)
    local msg = MSG_HEADER
    for _, token in ipairs(tokenList) do
      msg = msg..MSG_SPLITTER..tostring(token)
    end
    local channel = (receiver and "WHISPER") or "RAID"
    ChatThrottleLib:SendAddonMessage("ALERT", msgType, msg, channel, receiver)
  end,

  sendChatMessage = function(channel, msg)
    ChatThrottleLib:SendChatMessage("NORMAL", "RPM", msg:trim(), channel)
  end,
}

RPMIO.messageFields = {
  [RPMIO.MSG_SEND_QUEST] = { tokens = { "questID", "chapterNr", "current", "max", "part"}, numeric = { false, true, true, true, false } },
  [RPMIO.MSG_SEND_CHAPTER] = { tokens = { "questID", "chapterNr", "current", "max", "part"}, numeric = { false, true, true, true, false } },
  [RPMIO.MSG_SHOW_CHAPTER] = { tokens = { "questID", "chapterNr" }, numeric = { false, true } },
  [RPMIO.MSG_COMBAT_DATA] = { tokens = { "data"}, numeric = { false } },
  [RPMIO.MSG_SEND_ITEM_REQ] = { tokens = { "itemID", "itemName", "itemType" }, numeric = { false, false, false } },
  [RPMIO.MSG_SEND_ITEM_PERM] = { tokens = { "permission", "itemID" }, numeric = { false, false } },
  [RPMIO.MSG_SEND_ITEM_STAT] = { tokens = { "itemID", "current" }, numeric = { false, true } },
  [RPMIO.MSG_SEND_ITEM] = { tokens = { "itemID", "current", "max", "part"}, numeric = { false, true, true, false } },
  [RPMIO.MSG_SYNCH_QRY] = { tokens = { "questID", "currentChapter", "lastChapter" }, numeric = { false, true, true } },
  [RPMIO.MSG_SYNCH_ANS] = { tokens = { "questID", "currentChapter", "lastChapter" }, numeric = { false, true, true } },
}
