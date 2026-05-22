local S = _G.SableUI

if not S then
    S = {}
    _G.SableUI = S
end

S.name = "SableUI"
S.version = "0.1.0"
S.prefix = "|cffc9a66bSableUI|r"
S.events = S.events or {}
S.frame = S.frame or CreateFrame("Frame", "SableUICoreFrame")

local function DispatchEvent(_, event, ...)
    local handlers = S.events[event]

    if handlers then
        for index = 1, table.getn(handlers) do
            handlers[index](S, event, ...)
        end
    end
end

S.frame:SetScript("OnEvent", DispatchEvent)

function S:RegisterEvent(event, handler)
    if not event or type(handler) ~= "function" then
        return
    end

    if not self.events[event] then
        self.events[event] = {}
        self.frame:RegisterEvent(event)
    end

    table.insert(self.events[event], handler)
end

function S:Print(message)
    local text = self.prefix .. " " .. tostring(message)

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

function S:Debug(message)
    if self.profile and self.profile.debug then
        self:Print("|cff888888debug:|r " .. tostring(message))
    end
end

function S:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true

    if self.InitDB then
        self:InitDB()
    end

    if self.Theme and self.Theme.Initialize then
        self.Theme:Initialize()
    end

    if self.Modules and self.Modules.Initialize then
        self.Modules:Initialize()
    end

    if self.Commands and self.Commands.Initialize then
        self.Commands:Initialize()
    end

    if self.Roster and self.Roster.Initialize then
        self.Roster:Initialize()
    end

    if self.Progression and self.Progression.Initialize then
        self.Progression:Initialize()
    end

    if self.Profiles and self.Profiles.Initialize then
        self.Profiles:Initialize()
    end

    self:Debug("core initialized")
end

S:RegisterEvent("ADDON_LOADED", function(core, _, addonName)
    if addonName == core.name then
        core:Initialize()
    end
end)

S:RegisterEvent("PLAYER_LOGIN", function(core)
    core.playerLoggedIn = true

    if core.Modules and core.Modules.OnPlayerLogin then
        core.Modules:OnPlayerLogin()
    end
end)
