local S = _G.SableUI

S.Utils = S.Utils or {}

function S.Utils.Trim(value)
    if not value then
        return ""
    end

    return string.gsub(tostring(value), "^%s*(.-)%s*$", "%1")
end

function S.Utils.SplitCommand(value)
    value = S.Utils.Trim(value)

    if value == "" then
        return "", ""
    end

    local command, rest = string.match(value, "^(%S+)%s*(.-)$")
    return command or "", rest or ""
end

function S.Utils.Lower(value)
    if not value then
        return ""
    end

    return string.lower(tostring(value))
end

function S.Utils.TableLength(tbl)
    local count = 0

    if type(tbl) ~= "table" then
        return count
    end

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

function S.Utils.GetGroupChannel()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return "RAID"
    end

    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        return "PARTY"
    end

    return nil
end

function S.Utils.GetUnitName(unit)
    if not unit or not UnitName then
        return nil
    end

    local name = UnitName(unit)

    if name and name ~= "" and name ~= "Unknown Entity" then
        return name
    end

    return nil
end

function S.Utils.ColorToHex(color)
    if type(color) ~= "table" then
        return "ffffffff"
    end

    local r = math.floor((color[1] or color.r or 1) * 255)
    local g = math.floor((color[2] or color.g or 1) * 255)
    local b = math.floor((color[3] or color.b or 1) * 255)
    local a = math.floor((color[4] or color.a or 1) * 255)

    return string.format("%02x%02x%02x%02x", a, r, g, b)
end

function S.Utils.DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[S.Utils.DeepCopy(key, seen)] = S.Utils.DeepCopy(item, seen)
    end

    return copy
end
