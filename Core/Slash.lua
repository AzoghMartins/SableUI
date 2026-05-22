local S = _G.SableUI

S.Slash = S.Slash or {}

local Slash = S.Slash

local function ReportResult(ok, message)
    if not ok and message then
        S:Print(message)
    elseif ok and message then
        S:Print(message)
    end
end

function Slash:PrintHelp()
    S:Print("/sable - open the Shell module")
    S:Print("/sable shell - open the Shell module")
    S:Print("/sable modules - list known modules")
    S:Print("/sable module <name> on|off|load|toggle - control a module")
    S:Print("/sable profile list|save <name>|load <name>|delete <name> - manage profiles")
    S:Print("/sable pull|tank|tankclear|automark|sap - send common bot commands")
    S:Print("/sable setup|restock|spec <role>|petspec <role> - send setup commands")
end

function Slash:ListModules()
    S.Modules:ForEach(function(key, record)
        local installed = S.Modules:IsInstalled(key) and "installed" or "missing"
        local loaded = S.Modules:IsLoaded(key) and "loaded" or "not loaded"
        local enabled = S.Modules:IsEnabled(key) and "enabled" or "disabled"
        S:Print(key .. " - " .. enabled .. ", " .. loaded .. ", " .. installed)
    end)
end

function Slash:HandleModule(rest)
    local keyInput, action = S.Utils.SplitCommand(rest)
    local key = S.Modules:ResolveKey(keyInput)

    if not key then
        S:Print("Unknown module: " .. tostring(keyInput))
        return
    end

    action = S.Utils.Lower(action)

    if action == "on" or action == "enable" then
        ReportResult(S.Modules:SetEnabled(key, true))
    elseif action == "off" or action == "disable" then
        ReportResult(S.Modules:SetEnabled(key, false))
    elseif action == "load" then
        ReportResult(S.Modules:Load(key))
    elseif action == "toggle" then
        ReportResult(S.Modules:SetEnabled(key, not S.Modules:IsEnabled(key)))
    else
        S:Print("Use: /sable module " .. key .. " on|off|load|toggle")
    end
end

function Slash:HandleProfile(rest)
    local action, value = S.Utils.SplitCommand(rest)
    action = S.Utils.Lower(action)

    if action == "list" or action == "" then
        local names = S.Profiles:List()
        S:Print("Active profile: " .. S.Profiles:GetActiveName())
        S:Print("Profiles: " .. table.concat(names, ", "))
    elseif action == "save" then
        ReportResult(S.Profiles:SaveAs(value))
    elseif action == "load" then
        ReportResult(S.Profiles:Load(value))
    elseif action == "delete" then
        ReportResult(S.Profiles:Delete(value))
    else
        S:Print("Use: /sable profile list|save <name>|load <name>|delete <name>")
    end
end

function Slash:OpenShell()
    local key = "Shell"
    local ok, message

    if not S.Modules:IsEnabled(key) then
        ok, message = S.Modules:SetEnabled(key, true)
    else
        ok, message = S.Modules:Load(key)
    end

    if not ok then
        S:Print(message)
        return
    end

    if S.Shell and S.Shell.Toggle then
        S.Shell:Toggle()
    else
        S:Print("Shell loaded, but no toggle handler was registered.")
    end
end

function Slash:RunCommand(command, rest)
    local ok, message

    if command == "pull" then
        ok, message = S.Commands:Pull()
    elseif command == "tank" then
        ok, message = S.Commands:TankMark()
    elseif command == "tankclear" or command == "cleartank" then
        ok, message = S.Commands:ClearTankMark()
    elseif command == "automark" then
        ok, message = S.Commands:AutoMark()
    elseif command == "sap" then
        ok, message = S.Commands:Sap()
    elseif command == "setup" then
        ok, message = S.Commands:Setup(rest)
    elseif command == "restock" then
        ok, message = S.Commands:Restock(rest)
    elseif command == "spec" then
        ok, message = S.Commands:Spec("", rest)
    elseif command == "petspec" then
        ok, message = S.Commands:PetSpec("", rest)
    end

    ReportResult(ok, message)
end

function Slash:Handle(message)
    local command, rest = S.Utils.SplitCommand(message)
    command = S.Utils.Lower(command)

    if command == "" then
        self:OpenShell()
    elseif command == "help" then
        self:PrintHelp()
    elseif command == "shell" then
        self:OpenShell()
    elseif command == "modules" then
        self:ListModules()
    elseif command == "module" then
        self:HandleModule(rest)
    elseif command == "profile" then
        self:HandleProfile(rest)
    elseif command == "debug" then
        S.profile.debug = not S.profile.debug
        S:Print("debug " .. (S.profile.debug and "enabled" or "disabled"))
    elseif command == "pull" or command == "tank" or command == "tankclear" or command == "cleartank" or command == "automark" or command == "sap" or command == "setup" or command == "restock" or command == "spec" or command == "petspec" then
        self:RunCommand(command, rest)
    else
        S:Print("Unknown command: " .. command)
        self:PrintHelp()
    end
end

SLASH_SABLEUI1 = "/sable"
SLASH_SABLEUI2 = "/sableui"

SlashCmdList.SABLEUI = function(message)
    S.Slash:Handle(message)
end
