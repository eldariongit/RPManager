if RPMItem ~= nil then
  return
end

local L = LibStub("AceLocale-3.0"):GetLocale("RPManager")

local rpmiLoaded = false
local itemsInTransfer = {}

RPMItem = {
  -- checks if the set item type corresponds to the
  -- item's structure (e.g. if someone manipulated it to mask
  -- a script)
  getItemType = function(item)
    local setType = item.type
    local checkType = "undef"
    if item.script ~= nil then
      checkType = RPManager.ITEM_TYPE_SCRIPT
    elseif item.map ~= nil then
      checkType = RPManager.ITEM_TYPE_MAP
    elseif item.pages ~= nil then
      checkType = RPManager.ITEM_TYPE_BOOK
    else
      checkType = RPManager.ITEM_TYPE_SIMPLE
    end
    if checkType ~= setType then
      return nil
    end
    return checkType
  end,

  colorItemType = function(itemType)
    local color = (((itemType == RPManager.ITEM_TYPE_SCRIPT) and "|CFFFF0000") or "|CFFFFFFFF")
    return color..L[itemType].."|R"
  end,

  addItemInTransfer = function(itemID, deleteAfterSend, slot)
    local iit = {
      itemID = itemID,
      delete = deleteAfterSend,
      slot = slot,
    }
    itemsInTransfer[itemID] = iit
  end,

  progressItemInTransfer = function(itemID, val)
    if itemsInTransfer[itemID].progress == nil then
      itemsInTransfer[itemID].parts = val+1 -- because of progress bar
      itemsInTransfer[itemID].progress = 1
      RPMProgressBar.addBar(itemID, val, "item", "send")
    else
      local oldVal = itemsInTransfer[itemID].progress
      itemsInTransfer[itemID].progress = val
      for i = oldVal+1, val do
        RPMProgressBar.inc(itemID)
      end
      if itemsInTransfer[itemID].progress >= itemsInTransfer[itemID].parts then
        RPMItem.finishItemInTransfer(itemID)
      end
    end
  end,

  cancelItemInTransfer = function(itemID)
    itemsInTransfer[itemID] = nil
  end,

  finishItemInTransfer = function(itemID)
    if itemsInTransfer[itemID].delete then
      RPMCharacterDB.bag[itemsInTransfer[itemID].slot].item = nil
      RPMCharacterDB.items[itemID] = nil
      RPMBag.updateBag()
    end
    itemsInTransfer[itemID] = nil
  end,

  setRPMItemsAvailable = function(isLoaded)
    rpmiLoaded = isLoaded
  end,

  isRPMItemsAvailable = function()
    return rpmiLoaded
  end,
}
