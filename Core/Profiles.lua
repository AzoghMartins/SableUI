local S = _G.SableUI

S.Profiles = S.Profiles or {}

local Profiles = S.Profiles

function Profiles:Initialize()
    S.db.profiles = S.db.profiles or {}
    S.charDB.profile = S.charDB.profile or "Default"

    if not S.db.profiles[S.charDB.profile] then
        S.charDB.profile = "Default"
    end
end

function Profiles:GetActiveName()
    return S.charDB.profile or "Default"
end

function Profiles:GetActive()
    return S.profile
end

function Profiles:List()
    local names = {}

    for name in pairs(S.db.profiles or {}) do
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

function Profiles:SaveAs(name)
    name = S.Utils.Trim(name)

    if name == "" then
        return false, "Profile name is required."
    end

    S.db.profiles[name] = S.Utils.DeepCopy(S.profile)
    S.charDB.profile = name
    S.profile = S.db.profiles[name]

    if S.Theme and S.Theme.Initialize then
        S.Theme:Initialize()
    end

    return true, "Saved profile: " .. name
end

function Profiles:Load(name)
    name = S.Utils.Trim(name)

    if name == "" then
        return false, "Profile name is required."
    end

    if not S.db.profiles[name] then
        return false, "Unknown profile: " .. name
    end

    S.charDB.profile = name
    S.profile = S.db.profiles[name]
    S:CopyDefaults(S.profile.theme, S.defaultTheme)

    if S.Theme and S.Theme.Initialize then
        S.Theme:Initialize()
    end

    return true, "Loaded profile: " .. name
end

function Profiles:Delete(name)
    name = S.Utils.Trim(name)

    if name == "" or name == "Default" then
        return false, "Default profile cannot be deleted."
    end

    if not S.db.profiles[name] then
        return false, "Unknown profile: " .. name
    end

    S.db.profiles[name] = nil

    if S.charDB.profile == name then
        return self:Load("Default")
    end

    return true, "Deleted profile: " .. name
end
