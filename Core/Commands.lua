local S = _G.SableUI

S.Commands = S.Commands or {}

local Commands = S.Commands

function Commands:Initialize()
    self.history = self.history or {}
end

function Commands:GetLogSize()
    if S.profile and S.profile.commands and S.profile.commands.logSize then
        return S.profile.commands.logSize
    end

    return 80
end

function Commands:Log(command, channel, target)
    self.history = self.history or {}

    table.insert(self.history, 1, {
        time = date and date("%H:%M:%S") or "",
        command = command,
        channel = channel or "SAY",
        target = target,
    })

    while table.getn(self.history) > self:GetLogSize() do
        table.remove(self.history)
    end
end

function Commands:Send(command, channel, target)
    command = S.Utils.Trim(command)

    if command == "" then
        return false, "Empty command."
    end

    channel = channel or "SAY"

    if channel == "WHISPER" and S.Utils.Trim(target) == "" then
        return false, "Whisper command needs a target."
    end

    if not SendChatMessage then
        return false, "SendChatMessage is unavailable."
    end

    SendChatMessage(command, channel, nil, target)
    self:Log(command, channel, target)

    if S.profile and S.profile.commands and S.profile.commands.echo then
        S:Print("sent [" .. channel .. "] " .. command)
    end

    return true
end

function Commands:SendToGroup(command)
    local channel = S.Utils.GetGroupChannel()

    if not channel then
        return false, "You are not in a party or raid."
    end

    return self:Send(command, channel)
end

function Commands:SendToBotChannel(command)
    local channel = S.Utils.GetGroupChannel() or "SAY"
    return self:Send(command, channel)
end

function Commands:SendToTarget(command)
    local target = S.Utils.GetUnitName("target")

    if not target then
        return false, "No valid target selected."
    end

    return self:Send(command, "WHISPER", target)
end

function Commands:WhisperBot(botName, command)
    botName = S.Utils.Trim(botName)

    if botName == "" then
        return false, "No bot name selected."
    end

    return self:Send(command, "WHISPER", botName)
end

function Commands:SendSelector(selector, command)
    selector = S.Utils.Trim(selector)
    command = S.Utils.Trim(command)

    if selector ~= "" then
        command = selector .. " " .. command
    end

    return self:SendToBotChannel(command)
end

function Commands:Pull()
    return self:SendToGroup("pull")
end

function Commands:TankMark()
    return self:SendToBotChannel("tank")
end

function Commands:ClearTankMark()
    return self:SendToBotChannel("tank clear")
end

function Commands:AutoMark()
    return self:SendToBotChannel("automark")
end

function Commands:Sap()
    return self:SendToGroup("sap")
end

function Commands:Setup(selector)
    return self:SendSelector(selector, "setup")
end

function Commands:Spec(selector, specOrRole)
    specOrRole = S.Utils.Trim(specOrRole)

    if specOrRole == "" then
        return self:SendSelector(selector, "spec")
    end

    return self:SendSelector(selector, "spec " .. specOrRole)
end

function Commands:SpecManual(selector, state)
    return self:SendSelector(selector, "spec manual " .. S.Utils.Trim(state))
end

function Commands:SpecSwitch(selector, slot)
    slot = S.Utils.Trim(slot)

    if slot == "" then
        return self:SendSelector(selector, "spec switch")
    end

    return self:SendSelector(selector, "spec switch " .. slot)
end

function Commands:Restock(selector)
    return self:SendSelector(selector, "restock")
end

function Commands:PetSpec(selector, petRole)
    petRole = S.Utils.Trim(petRole)

    if petRole == "" then
        return false, "Pet spec role is required."
    end

    return self:SendSelector(selector, "petspec " .. petRole)
end

function Commands:RunDotCommand(command)
    command = S.Utils.Trim(command)

    if command == "" then
        return false, "Empty server command."
    end

    return self:Send(command, "SAY")
end
