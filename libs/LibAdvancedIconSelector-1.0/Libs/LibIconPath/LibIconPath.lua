-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local MAJOR, MINOR = "LibIconPath", 20
if not LibStub then error(MAJOR .. " requires LibStub to operate") end
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.iconDB = {} -- is filled within IconDB.lua

function lib:getName(id)
    local name
    if (type(id) == "number") then
        name = self.iconDB[id]
    else
        name = self.iconDB[tonumber(id)]
    end
    if name then
        --print("found "..name)
        return name
    elseif string.match(tostring(id), "_") then --just to prevent the lookup of "ability_ambush" etc
        --print("found complete string, returning it")
        return id
    end

    --print("couldnt find "..tostring(id))
    return "inv_misc_questionmark"
end

function lib:getPath(id)
    return "Interface\\Icons\\" .. self:getName(id)
end

function lib:getIconBySpellID(id)
    local _, _, icon = GetSpellInfo(id)
    return self:getPath(icon)
end

function lib:getIDByName(name)
    name = string.lower(name)
    for k, v in pairs(self.iconDB) do
        if v == name then
            return k
        end
    end
    return nil
end

function lib:getRevision()
    return MINOR
end
