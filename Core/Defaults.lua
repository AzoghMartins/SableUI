local S = _G.SableUI

S.defaultTheme = {
    fonts = {
        normal = "Fonts\\FRIZQT__.TTF",
        bold = "Fonts\\ARIALN.TTF",
        title = "Fonts\\MORPHEUS.TTF",
        mono = "Fonts\\ARIALN.TTF",
    },
    textures = {
        statusbar = "Interface\\TargetingFrame\\UI-StatusBar",
        background = "Interface\\DialogFrame\\UI-DialogBox-Background",
        border = "Interface\\Tooltips\\UI-Tooltip-Border",
    },
    colors = {
        bg = { 0.035, 0.037, 0.04, 0.92 },
        panel = { 0.075, 0.078, 0.085, 0.94 },
        panelAlt = { 0.105, 0.105, 0.11, 0.94 },
        border = { 0.38, 0.32, 0.22, 1 },
        text = { 0.88, 0.86, 0.79, 1 },
        textMuted = { 0.58, 0.57, 0.53, 1 },
        accent = { 0.79, 0.58, 0.29, 1 },
        good = { 0.28, 0.72, 0.42, 1 },
        warn = { 0.88, 0.68, 0.25, 1 },
        bad = { 0.85, 0.24, 0.20, 1 },
        health = { 0.20, 0.72, 0.30, 1 },
        mana = { 0.22, 0.45, 0.88, 1 },
        rage = { 0.82, 0.18, 0.15, 1 },
        energy = { 0.86, 0.78, 0.25, 1 },
        runic = { 0.00, 0.82, 1.00, 1 },
    },
    sizes = {
        border = 1,
        padding = 8,
        rowHeight = 24,
    },
}

S.defaultModules = {
    Shell = { enabled = true },
    UnitFrames = { enabled = false },
    ActionBars = { enabled = false },
    NamePlates = { enabled = false },
    ThreatMeter = { enabled = false },
    DamageMeter = { enabled = false },
    Chat = { enabled = false },
    BotControl = { enabled = false },
}

S.defaults = {
    global = {
        version = 1,
        profile = "Default",
        profiles = {
            Default = {
                debug = false,
                theme = S.defaultTheme,
                commands = {
                    echo = false,
                    logSize = 80,
                },
            },
        },
    },
    char = {
        version = 1,
        profile = "Default",
        shell = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
            widthRatio = 0.88,
            heightRatio = 0.82,
            minWidth = 900,
            minHeight = 560,
            lastArea = "Shell",
            lastSections = {
                Shell = "Modules",
                Character = "Stats",
                PartyRaid = "Stats",
            },
            selectedPartyMember = "",
        },
        modules = S.defaultModules,
        roster = {
            classifications = {},
        },
        progression = {
            cache = {},
        },
    },
}

local function CopyDefaults(destination, defaults)
    if type(destination) ~= "table" or type(defaults) ~= "table" then
        return
    end

    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(destination[key]) ~= "table" then
                destination[key] = {}
            end

            CopyDefaults(destination[key], value)
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
end

function S:CopyDefaults(destination, defaults)
    CopyDefaults(destination, defaults)
end

function S:InitDB()
    SableUIDB = SableUIDB or {}
    SableUICharDB = SableUICharDB or {}

    CopyDefaults(SableUIDB, self.defaults.global)
    CopyDefaults(SableUICharDB, self.defaults.char)

    local profileName = SableUICharDB.profile or SableUIDB.profile or "Default"

    if not SableUIDB.profiles[profileName] then
        profileName = "Default"
    end

    SableUICharDB.profile = profileName
    SableUIDB.profile = SableUIDB.profile or "Default"

    self.db = SableUIDB
    self.charDB = SableUICharDB
    self.profile = SableUIDB.profiles[profileName]

    CopyDefaults(self.profile.theme, self.defaultTheme)
    CopyDefaults(SableUICharDB.modules, self.defaultModules)
end

function S:GetModuleSettings(key)
    if not self.charDB then
        return nil
    end

    self.charDB.modules = self.charDB.modules or {}
    self.charDB.modules[key] = self.charDB.modules[key] or {}
    return self.charDB.modules[key]
end
