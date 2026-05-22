local S = _G.SableUI

S.Roster = S.Roster or {}

local Roster = S.Roster

function Roster:Initialize()
    self.members = {}
    self.order = {}

    S:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        Roster:Scan()
    end)

    S:RegisterEvent("PARTY_MEMBERS_CHANGED", function()
        Roster:Scan()
    end)

    S:RegisterEvent("RAID_ROSTER_UPDATE", function()
        Roster:Scan()
    end)

    self:Scan()
end

function Roster:GetClassificationStore()
    S.charDB.roster = S.charDB.roster or {}
    S.charDB.roster.classifications = S.charDB.roster.classifications or {}
    return S.charDB.roster.classifications
end

function Roster:SetClassification(name, kind, source)
    name = S.Utils.Trim(name)
    kind = S.Utils.Trim(kind)

    if name == "" or kind == "" then
        return false
    end

    local store = self:GetClassificationStore()
    store[name] = {
        kind = kind,
        source = source or "manual",
        updated = time and time() or 0,
    }

    self:Scan()
    return true
end

function Roster:GetStoredClassification(name)
    local store = self:GetClassificationStore()
    return store and store[name]
end

function Roster:ClassifyUnit(unit, name)
    if unit == "player" or (UnitIsUnit and UnitIsUnit(unit, "player")) then
        return "Player", "unit"
    end

    local stored = self:GetStoredClassification(name)

    if stored and stored.kind then
        return stored.kind, stored.source or "stored"
    end

    return "Unknown", "pending"
end

function Roster:GetUnitName(unit)
    if not unit then
        return nil
    end

    if UnitExists and not UnitExists(unit) then
        return nil
    end

    return S.Utils.GetUnitName(unit)
end

function Roster:AddUnit(unit)
    local name = self:GetUnitName(unit)

    if not name then
        return
    end

    local className, classFile

    if UnitClass then
        className, classFile = UnitClass(unit)
    end

    local kind, kindSource = self:ClassifyUnit(unit, name)
    local guid = UnitGUID and UnitGUID(unit) or name
    local level = UnitLevel and UnitLevel(unit) or nil
    local member = {
        key = guid or name,
        unit = unit,
        guid = guid,
        name = name,
        className = className or "",
        classFile = classFile or "",
        level = level,
        kind = kind,
        kindSource = kindSource,
    }

    self.members[name] = member
    table.insert(self.order, name)
end

function Roster:Scan()
    self.members = {}
    self.order = {}

    local raidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0
    local partyMembers = GetNumPartyMembers and GetNumPartyMembers() or 0

    if raidMembers > 0 then
        for index = 1, raidMembers do
            self:AddUnit("raid" .. index)
        end
    else
        self:AddUnit("player")

        for index = 1, partyMembers do
            self:AddUnit("party" .. index)
        end
    end
end

function Roster:GetMembers()
    if not self.order then
        self:Scan()
    end

    local result = {}

    for index = 1, table.getn(self.order) do
        table.insert(result, self.members[self.order[index]])
    end

    return result
end

function Roster:GetByName(name)
    return self.members and self.members[name]
end
