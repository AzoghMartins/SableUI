local S = _G.SableUI

S.Modules = S.Modules or {}

local Modules = S.Modules

Modules.registry = Modules.registry or {}
Modules.order = Modules.order or {}

Modules.knownModules = {
    {
        key = "Shell",
        path = "Modules\\Shell",
        displayName = "Shell",
        description = "Near-full-screen operations window.",
        autoload = false,
        implemented = true,
        internal = true,
    },
    {
        key = "UnitFrames",
        path = "Modules\\UnitFrames",
        displayName = "Unit Frames",
        description = "Unit frame replacement.",
        autoload = false,
        implemented = false,
        internal = true,
    },
    {
        key = "ActionBars",
        path = "Modules\\ActionBars",
        displayName = "Action Bars",
        description = "Action bar replacement.",
        autoload = false,
        implemented = false,
        internal = true,
    },
    {
        key = "NamePlates",
        path = "Modules\\NamePlates",
        displayName = "Name Plates",
        description = "Nameplate replacement.",
        autoload = false,
        implemented = false,
        internal = true,
    },
    {
        key = "ThreatMeter",
        path = "Modules\\ThreatMeter",
        displayName = "Threat Meter",
        description = "Visual threat bars.",
        autoload = false,
        implemented = false,
        internal = true,
    },
    {
        key = "DamageMeter",
        path = "Modules\\DamageMeter",
        displayName = "Damage Meter",
        description = "Combat stats window.",
        autoload = false,
        implemented = false,
        internal = true,
    },
    {
        key = "Chat",
        path = "Modules\\Chat",
        displayName = "Chat",
        description = "Improved chat window.",
        autoload = false,
        implemented = false,
        internal = true,
    },
    {
        key = "BotControl",
        path = "Modules\\BotControl",
        displayName = "Bot Control",
        description = "Compact bot combat controls.",
        autoload = false,
        implemented = false,
        internal = true,
    },
}

function Modules:Initialize()
    self.registry = self.registry or {}
    self.order = {}

    for index = 1, table.getn(self.knownModules) do
        self:RegisterKnown(self.knownModules[index])
    end
end

function Modules:RegisterKnown(metadata)
    if not metadata or not metadata.key then
        return
    end

    local existing = self.registry[metadata.key] or {}

    for key, value in pairs(metadata) do
        existing[key] = value
    end

    existing.loadOnDemand = false
    self.registry[metadata.key] = existing
    table.insert(self.order, metadata.key)

    local settings = S:GetModuleSettings(metadata.key)

    if settings and settings.enabled == nil then
        settings.enabled = false
    end
end

function Modules:RegisterRuntime(key, instance)
    if not key or type(instance) ~= "table" then
        return
    end

    local record = self.registry[key] or { key = key, displayName = key }
    record.instance = instance
    instance.key = key
    instance.metadata = record
    self.registry[key] = record

    if instance.OnLoad and not instance.loaded then
        instance.loaded = true
        instance:OnLoad()
    end

    if self:IsEnabled(key) and instance.Enable then
        instance:Enable()
    end

    return instance
end

function S:RegisterModule(key, instance)
    return self.Modules:RegisterRuntime(key, instance)
end

function Modules:ResolveKey(input)
    local wanted = S.Utils.Lower(input)

    for key, record in pairs(self.registry) do
        if S.Utils.Lower(key) == wanted or S.Utils.Lower(record.displayName) == wanted or S.Utils.Lower(record.addon) == wanted then
            return key
        end
    end

    return nil
end

function Modules:Get(key)
    return self.registry[key]
end

function Modules:IsInstalled(key)
    local record = self.registry[key]

    if record and record.implemented == false then
        return false
    end

    if record and record.internal then
        return record.instance ~= nil
    end

    if not record or not record.addon or not GetAddOnInfo then
        return false
    end

    local name, _, _, loadable, reason = GetAddOnInfo(record.addon)

    if not name then
        return false
    end

    if loadable == false and reason == "MISSING" then
        return false
    end

    return true
end

function Modules:IsLoaded(key)
    local record = self.registry[key]

    if record and record.internal then
        return record.instance ~= nil
    end

    if not record or not record.addon or not IsAddOnLoaded then
        return false
    end

    return IsAddOnLoaded(record.addon)
end

function Modules:IsEnabled(key)
    local settings = S:GetModuleSettings(key)
    return settings and settings.enabled == true
end

function Modules:SetEnabled(key, enabled)
    local record = self.registry[key]

    if not record then
        return false, "Unknown module."
    end

    local settings = S:GetModuleSettings(key)

    if enabled then
        if not self:IsInstalled(key) then
            settings.enabled = false
            return false, "Module is missing: " .. tostring(record.displayName or key)
        end

        settings.enabled = true

        if EnableAddOn and record.addon then
            EnableAddOn(record.addon)
        end

        local ok, message = self:Load(key)

        if not ok then
            settings.enabled = false
        end

        return ok, message
    end

    settings.enabled = false

    if record.instance and record.instance.Disable then
        record.instance:Disable()
    end

    if DisableAddOn and record.addon then
        DisableAddOn(record.addon)
    end

    if self:IsLoaded(key) and not record.internal then
        return true, "Module disabled for next reload. Runtime behavior has been soft-disabled where possible."
    end

    return true
end

function Modules:Load(key)
    local record = self.registry[key]

    if not record then
        return false, "Unknown module."
    end

    if self:IsLoaded(key) then
        if record.instance and record.instance.Enable and self:IsEnabled(key) then
            record.instance:Enable()
        end

        return true
    end

    if record.internal then
        return false, "Module is missing: " .. tostring(record.displayName or key)
    end

    if not record.addon then
        return false, "Module has no addon binding."
    end

    if not self:IsInstalled(key) then
        return false, "Addon folder is not installed: " .. record.addon
    end

    if EnableAddOn then
        EnableAddOn(record.addon)
    end

    if not LoadAddOn then
        return false, "LoadAddOn is unavailable."
    end

    local loaded, reason = LoadAddOn(record.addon)

    if loaded then
        return true
    end

    return false, _G["ADDON_" .. tostring(reason)] or tostring(reason or "Load failed.")
end

function Modules:OnPlayerLogin()
    for index = 1, table.getn(self.order) do
        local key = self.order[index]
        local record = self.registry[key]

        if record and record.autoload and self:IsEnabled(key) then
            self:Load(key)
        end
    end
end

function Modules:ForEach(callback)
    for index = 1, table.getn(self.order) do
        local key = self.order[index]
        callback(key, self.registry[key])
    end
end

function Modules:GetOrdered()
    local ordered = {}

    for index = 1, table.getn(self.order) do
        table.insert(ordered, self.registry[self.order[index]])
    end

    return ordered
end
