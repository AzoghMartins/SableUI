local S = _G.SableUI

S.Progression = S.Progression or {}

local Progression = S.Progression

function Progression:Initialize()
    self.pending = self.pending or {}
    self.cache = S.charDB.progression and S.charDB.progression.cache or {}

    S:RegisterEvent("CHAT_MSG_SYSTEM", function(_, _, message)
        Progression:ParseSystemMessage(message)
    end)
end

function Progression:GetCache()
    S.charDB.progression = S.charDB.progression or {}
    S.charDB.progression.cache = S.charDB.progression.cache or {}
    self.cache = S.charDB.progression.cache
    return self.cache
end

function Progression:RequestForTarget()
    local name = S.Utils.GetUnitName("target")

    if not name then
        return false, "Select a character first."
    end

    self.pending[name] = {
        requested = time and time() or 0,
    }

    return S.Commands:RunDotCommand(".ip get")
end

function Progression:TargetUnitForQuery(unit, name)
    if UnitExists and unit and UnitExists(unit) then
        if UnitIsUnit and UnitIsUnit(unit, "target") then
            return true
        end

        if InCombatLockdown and InCombatLockdown() then
            return false, "Cannot change targets in combat."
        end

        if TargetUnit then
            TargetUnit(unit)
            return true
        end
    end

    name = S.Utils.Trim(name)

    if name == "" then
        return false, "No character name available."
    end

    if InCombatLockdown and InCombatLockdown() then
        return false, "Cannot change targets in combat."
    end

    if TargetByName then
        TargetByName(name, true)
        return true
    end

    return false, "Targeting API is unavailable."
end

function Progression:RequestForUnit(unit, name)
    name = S.Utils.Trim(name or S.Utils.GetUnitName(unit))

    if name == "" then
        return false, "No character selected."
    end

    local ok, message = self:TargetUnitForQuery(unit, name)

    if not ok then
        return false, message
    end

    self.pending[name] = {
        requested = time and time() or 0,
        unit = unit,
    }

    return S.Commands:RunDotCommand(".ip get")
end

function Progression:SetProgression(name, level, source)
    name = S.Utils.Trim(name)
    level = tonumber(level)

    if name == "" or not level then
        return false
    end

    local cache = self:GetCache()
    cache[name] = {
        level = level,
        source = source or "manual",
        updated = time and time() or 0,
    }

    self.pending[name] = nil
    return true
end

function Progression:GetProgression(name)
    local cache = self:GetCache()
    return cache[name]
end

function Progression:StripMessage(message)
    message = tostring(message or "")
    message = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
    message = string.gsub(message, "|r", "")
    return message
end

function Progression:ParseSystemMessage(message)
    local clean = self:StripMessage(message)
    local name, level = string.match(clean, "Progression Level for%s+(.+)%s+=%s+(%d+)")

    if not name then
        name, level = string.match(clean, "Updated Progression Level for%s+(.+)%s+=%s+(%d+)")
    end

    if name and level then
        name = S.Utils.Trim(name)
        self:SetProgression(name, tonumber(level), ".ip get")
        return true
    end

    return false
end
