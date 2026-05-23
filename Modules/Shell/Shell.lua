local S = _G.SableUI

if not S then
    return
end

local Shell = S.Shell or {}
S.Shell = Shell

Shell.areas = {
    {
        key = "Shell",
        label = "Shell",
        defaultSection = "Modules",
        sections = {
            { key = "Modules", label = "Modules" },
            { key = "UnitFrames", label = "Unit Frames" },
            { key = "ActionBars", label = "Action Bars" },
            { key = "NamePlates", label = "Name Plates" },
            { key = "ThreatMeter", label = "Threat Meter" },
            { key = "DamageMeter", label = "Damage Meter" },
            { key = "Chat", label = "Chat" },
            { key = "BotControl", label = "Bot Control" },
        },
    },
    {
        key = "Character",
        label = "Character",
        defaultSection = "Stats",
        sections = {
            { key = "Stats", label = "Overview" },
            { key = "Skills", label = "Skills" },
            { key = "Talents", label = "Talents" },
            { key = "Pets", label = "Pets" },
            { key = "Reputation", label = "Reputation" },
        },
    },
    {
        key = "PartyRaid",
        label = "Party/Raid",
        defaultSection = "Stats",
        usesMembers = true,
        sections = {
            { key = "Stats", label = "Stats" },
            { key = "Gear", label = "Gear" },
            { key = "Inventory", label = "Inventory" },
            { key = "Skills", label = "Skills" },
            { key = "Talents", label = "Talents" },
            { key = "Pets", label = "Pets" },
            { key = "Reputation", label = "Reputation" },
        },
    },
}

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if maxValue and value > maxValue then
        return maxValue
    end

    return value
end

local function SafeCall(object, method, ...)
    if object and object[method] then
        object[method](object, ...)
    end
end

function Shell:OnLoad()
    self.enabled = false
    self.areaMap = {}

    for index = 1, table.getn(self.areas) do
        self.areaMap[self.areas[index].key] = self.areas[index]
    end

    S:RegisterEvent("BAG_UPDATE", function()
        Shell:RefreshCharacterOverviewIfShown()
    end)
    S:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
        Shell:RefreshCharacterOverviewIfShown()
    end)
    S:RegisterEvent("PLAYER_TALENT_UPDATE", function()
        Shell:RefreshCharacterOverviewIfShown()
    end)
    S:RegisterEvent("CHARACTER_POINTS_CHANGED", function()
        Shell:RefreshCharacterOverviewIfShown()
    end)
    S:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", function()
        Shell:RefreshCharacterOverviewIfShown()
    end)
end

function Shell:Enable()
    self.enabled = true
end

function Shell:Disable()
    self.enabled = false

    if self.frame then
        self.frame:Hide()
    end
end

function Shell:Toggle()
    if not self.frame then
        self:CreateFrame()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:ApplyResponsiveSize()
        self:ShowArea(S.charDB.shell.lastArea or "Shell")
        self.frame:Show()
    end
end

function Shell:GetResponsiveSize()
    local settings = S.charDB.shell
    local parentWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1024
    local parentHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 768
    local margin = 32
    local width = math.floor(parentWidth * (settings.widthRatio or 0.88))
    local height = math.floor(parentHeight * (settings.heightRatio or 0.82))
    local maxWidth = math.max(settings.minWidth or 900, parentWidth - margin)
    local maxHeight = math.max(settings.minHeight or 560, parentHeight - margin)

    width = Clamp(width, settings.minWidth or 900, maxWidth)
    height = Clamp(height, settings.minHeight or 560, maxHeight)

    return width, height
end

function Shell:ApplyResponsiveSize()
    if not self.frame then
        return
    end

    local width, height = self:GetResponsiveSize()
    self.frame:SetWidth(width)
    self.frame:SetHeight(height)
end

function Shell:CreateFrame()
    local settings = S.charDB.shell
    local frame = CreateFrame("Frame", "SableUIShellFrame", UIParent)
    frame:SetPoint(settings.point or "CENTER", UIParent, settings.relativePoint or "CENTER", settings.x or 0, settings.y or 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Shell:SavePosition()
    end)
    frame:SetScript("OnShow", function()
        Shell:ApplyResponsiveSize()
        Shell:Refresh()
    end)
    frame:SetFrameStrata("DIALOG")
    SafeCall(frame, "SetClampedToScreen", true)
    frame:Hide()

    self.frame = frame
    self:ApplyResponsiveSize()
    S.Theme:ApplyBackdrop(frame, "bg")

    local title = S.Theme:CreateFontString(frame, "title", 18, "")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
    title:SetText("SableUI")
    self.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

    self.topNav = CreateFrame("Frame", nil, frame)
    self.topNav:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -44)
    self.topNav:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -44)
    self.topNav:SetHeight(30)

    self.body = CreateFrame("Frame", nil, frame)
    self.body:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -78)
    self.body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
    S.Theme:ApplyBackdrop(self.body, "panel")

    self.leftNav = CreateFrame("Frame", nil, self.body)
    self.leftNav:SetPoint("TOPLEFT", self.body, "TOPLEFT", 10, -10)
    self.leftNav:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 10, 10)
    self.leftNav:SetWidth(168)

    self.detail = CreateFrame("Frame", nil, self.body)
    self.detail:SetPoint("TOPLEFT", self.leftNav, "TOPRIGHT", 10, 0)
    self.detail:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -10, 10)
    S.Theme:ApplyBackdrop(self.detail, "panelAlt")

    self.detailContent = CreateFrame("Frame", nil, self.detail)
    self.detailContent:SetPoint("TOPLEFT", self.detail, "TOPLEFT", 14, -14)
    self.detailContent:SetPoint("BOTTOMRIGHT", self.detail, "BOTTOMRIGHT", -14, 14)

    self.memberNav = CreateFrame("Frame", nil, self.detail)
    self.memberNav:SetPoint("BOTTOMLEFT", self.detail, "BOTTOMLEFT", 8, 8)
    self.memberNav:SetPoint("BOTTOMRIGHT", self.detail, "BOTTOMRIGHT", -8, 8)
    self.memberNav:SetHeight(30)
    self.memberNav:Hide()

    self.contentTitle = S.Theme:CreateFontString(self.detailContent, "bold", 18, "")
    self.contentTitle:SetPoint("TOPLEFT", self.detailContent, "TOPLEFT", 0, 0)
    self.contentTitle:SetText("")

    self.contentSubtitle = S.Theme:CreateFontString(self.detailContent, "normal", 12, "")
    self.contentSubtitle:SetPoint("TOPLEFT", self.contentTitle, "BOTTOMLEFT", 0, -8)
    self.contentSubtitle:SetJustifyH("LEFT")
    self.contentSubtitle:SetText("")
    S.Theme:ApplyTextColor(self.contentSubtitle, "textMuted")

    self.dynamicFrames = {}
    self.topTabs = {}
    self.leftTabs = {}
    self.memberTabs = {}

    self:CreateTopTabs()
    self:ShowArea(settings.lastArea or "Shell")
end

function Shell:SavePosition()
    if not self.frame then
        return
    end

    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    local settings = S.charDB.shell
    settings.point = point or "CENTER"
    settings.relativePoint = relativePoint or settings.point
    settings.x = x or 0
    settings.y = y or 0
end

function Shell:CreateTab(parent, label, width, height, onClick)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetWidth(width or 120)
    tab:SetHeight(height or 26)
    tab:SetScript("OnClick", onClick)
    S.Theme:ApplyBackdrop(tab, "panelAlt")

    local text = S.Theme:CreateFontString(tab, "normal", 11, "")
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)
    text:SetText(label)
    tab.text = text

    return tab
end

function Shell:CreateActionButton(parent, label, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width or 140)
    button:SetHeight(height or 24)
    button:SetText(label)
    button:SetScript("OnClick", function()
        local ok, message = onClick()

        if not ok and message then
            S:Print(message)
        elseif message then
            S:Print(message)
        end

        Shell:Refresh()
    end)
    S.Theme:StyleButton(button)
    return button
end

function Shell:SetTabSelected(tab, selected)
    if not tab then
        return
    end

    if selected then
        tab:SetBackdropColor(S.Theme:GetColor("panel"))
        tab:SetBackdropBorderColor(S.Theme:GetColor("accent"))

        if tab.text then
            tab.text:SetTextColor(S.Theme:GetColor("accent"))
        end
    else
        tab:SetBackdropColor(S.Theme:GetColor("panelAlt"))
        tab:SetBackdropBorderColor(S.Theme:GetColor("border"))

        if tab.text then
            tab.text:SetTextColor(S.Theme:GetColor("textMuted"))
        end
    end
end

function Shell:CreateTopTabs()
    local previous

    for index = 1, table.getn(self.areas) do
        local area = self.areas[index]
        local tab = self:CreateTab(self.topNav, area.label, 126, 28, function()
            Shell:ShowArea(area.key)
        end)

        if previous then
            tab:SetPoint("LEFT", previous, "RIGHT", 2, 0)
        else
            tab:SetPoint("LEFT", self.topNav, "LEFT", 0, 0)
        end

        self.topTabs[area.key] = tab
        previous = tab
    end
end

function Shell:CreateOrGetLeftTab(index)
    self.leftTabs[index] = self.leftTabs[index] or self:CreateTab(self.leftNav, "", 156, 28, function() end)
    return self.leftTabs[index]
end

function Shell:BuildLeftTabs(area)
    for index = 1, table.getn(self.leftTabs) do
        self.leftTabs[index]:Hide()
    end

    for index = 1, table.getn(area.sections) do
        local section = area.sections[index]
        local tab = self:CreateOrGetLeftTab(index)
        tab.key = section.key
        tab.text:SetText(section.label)
        tab:SetScript("OnClick", function()
            Shell:ShowSection(section.key)
        end)
        tab:ClearAllPoints()

        if index == 1 then
            tab:SetPoint("TOPLEFT", self.leftNav, "TOPLEFT", 0, 0)
        else
            tab:SetPoint("TOPLEFT", self.leftTabs[index - 1], "BOTTOMLEFT", 0, -4)
        end

        tab:Show()
    end
end

function Shell:ShowArea(areaKey)
    local area = self.areaMap[areaKey] or self.areaMap.Shell
    local settings = S.charDB.shell

    self.currentArea = area.key
    settings.lastArea = area.key
    settings.lastSections = settings.lastSections or {}

    for key, tab in pairs(self.topTabs) do
        self:SetTabSelected(tab, key == area.key)
    end

    self:BuildLeftTabs(area)

    local section = settings.lastSections[area.key] or area.defaultSection
    local sectionFound = false

    for index = 1, table.getn(area.sections) do
        if area.sections[index].key == section then
            sectionFound = true
            break
        end
    end

    if not sectionFound then
        section = area.defaultSection
    end

    if area.usesMembers then
        self:RefreshRoster()
        self:BuildMemberTabs()
    else
        self.memberNav:Hide()
        self.detailContent:ClearAllPoints()
        self.detailContent:SetPoint("TOPLEFT", self.detail, "TOPLEFT", 14, -14)
        self.detailContent:SetPoint("BOTTOMRIGHT", self.detail, "BOTTOMRIGHT", -14, 14)
    end

    self:ShowSection(section)
end

function Shell:ShowSection(sectionKey)
    local area = self.areaMap[self.currentArea] or self.areaMap.Shell
    local settings = S.charDB.shell

    settings.lastSections = settings.lastSections or {}
    settings.lastSections[area.key] = sectionKey
    self.currentSection = sectionKey

    for index = 1, table.getn(self.leftTabs) do
        local tab = self.leftTabs[index]

        if tab:IsShown() then
            self:SetTabSelected(tab, tab.key == sectionKey)
        end
    end

    self:RenderContent()
end

function Shell:GetUnitName(unit)
    if not unit then
        return nil
    end

    if UnitExists and not UnitExists(unit) then
        return nil
    end

    return S.Utils.GetUnitName(unit)
end

function Shell:RefreshRoster()
    if S.Roster then
        S.Roster:Scan()
        self.roster = S.Roster:GetMembers()
    else
        self.roster = {}
    end

    local roster = self.roster

    if table.getn(roster) > 0 then
        local selected = S.charDB.shell.selectedPartyMember
        local found = false

        for index = 1, table.getn(roster) do
            if roster[index].key == selected then
                found = true
                break
            end
        end

        if not found then
            S.charDB.shell.selectedPartyMember = roster[1].key
        end
    else
        S.charDB.shell.selectedPartyMember = ""
    end
end

function Shell:CreateOrGetMemberTab(index)
    self.memberTabs[index] = self.memberTabs[index] or self:CreateTab(self.memberNav, "", 90, 24, function() end)
    return self.memberTabs[index]
end

function Shell:BuildMemberTabs()
    local roster = self.roster or {}
    local count = table.getn(roster)
    local navWidth = self.memberNav:GetWidth() or 780
    local tabWidth = 90

    if count > 0 then
        tabWidth = math.floor((navWidth - ((count - 1) * 3)) / count)
        tabWidth = Clamp(tabWidth, 54, 112)
    end

    for index = 1, table.getn(self.memberTabs) do
        self.memberTabs[index]:Hide()
    end

    for index = 1, count do
        local member = roster[index]
        local tab = self:CreateOrGetMemberTab(index)
        tab.key = member.key
        tab:SetWidth(tabWidth)
        tab.text:SetText(member.name)
        tab:SetScript("OnClick", function()
            S.charDB.shell.selectedPartyMember = member.key
            Shell:BuildMemberTabs()
            Shell:RenderContent()
        end)
        tab:ClearAllPoints()

        if index == 1 then
            tab:SetPoint("LEFT", self.memberNav, "LEFT", 0, 0)
        else
            tab:SetPoint("LEFT", self.memberTabs[index - 1], "RIGHT", 3, 0)
        end

        self:SetTabSelected(tab, member.key == S.charDB.shell.selectedPartyMember)
        tab:Show()
    end

    self.memberNav:Show()
    self.detailContent:ClearAllPoints()
    self.detailContent:SetPoint("TOPLEFT", self.detail, "TOPLEFT", 14, -14)
    self.detailContent:SetPoint("BOTTOMRIGHT", self.memberNav, "TOPRIGHT", -6, 8)
end

function Shell:GetSelectedMember()
    local selected = S.charDB.shell.selectedPartyMember
    local roster = self.roster or {}

    for index = 1, table.getn(roster) do
        if roster[index].key == selected then
            return roster[index]
        end
    end

    return roster[1]
end

function Shell:GetSectionLabel(areaKey, sectionKey)
    local area = self.areaMap[areaKey]

    if not area then
        return sectionKey
    end

    for index = 1, table.getn(area.sections) do
        if area.sections[index].key == sectionKey then
            return area.sections[index].label
        end
    end

    return sectionKey
end

function Shell:HideDynamicContent()
    for index = 1, table.getn(self.dynamicFrames or {}) do
        self.dynamicFrames[index]:Hide()
    end
end

function Shell:AddDynamicFrame(frame)
    self.dynamicFrames = self.dynamicFrames or {}
    table.insert(self.dynamicFrames, frame)
end

function Shell:CreateModuleControls()
    if self.modulePanel then
        return
    end

    local panel = CreateFrame("Frame", nil, self.detailContent)
    panel:SetPoint("TOPLEFT", self.contentSubtitle, "BOTTOMLEFT", 0, -22)
    panel:SetPoint("RIGHT", self.detailContent, "RIGHT", 0, 0)
    panel:SetHeight(360)
    panel:Hide()
    self.modulePanel = panel
    self.moduleRows = {}
    self:AddDynamicFrame(panel)

    local previous

    for index = 1, table.getn(S.Modules.order) do
        local key = S.Modules.order[index]
        local record = S.Modules:Get(key)
        local row = CreateFrame("Frame", nil, panel)
        row:SetHeight(32)
        row:SetPoint("LEFT", panel, "LEFT", 0, 0)
        row:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

        if previous then
            row:SetPoint("TOP", previous, "BOTTOM", 0, -3)
        else
            row:SetPoint("TOP", panel, "TOP", 0, 0)
        end

        local check = CreateFrame("CheckButton", "SableUIShellModuleCheck" .. key, row, "UICheckButtonTemplate")
        check:SetPoint("LEFT", row, "LEFT", 0, 0)
        check.key = key

        local label = _G[check:GetName() .. "Text"]

        if label then
            label:SetText(record.displayName or key)
            label:SetTextColor(S.Theme:GetColor("text"))
        end

        local status = S.Theme:CreateFontString(row, "normal", 11, "")
        status:SetPoint("LEFT", row, "LEFT", 210, 0)
        status:SetText("")
        S.Theme:ApplyTextColor(status, "textMuted")

        check:SetScript("OnClick", function(self)
            if self.locked then
                self:SetChecked(true)
                return
            end

            local enabled = self:GetChecked() and true or false
            local ok, message = S.Modules:SetEnabled(self.key, enabled)

            if not ok then
                S:Print(message)
                self:SetChecked(S.Modules:IsEnabled(self.key))
            elseif message then
                S:Print(message)
            end

            Shell:RefreshModuleControls()
        end)

        self.moduleRows[key] = {
            row = row,
            check = check,
            label = label,
            status = status,
        }

        previous = row
    end
end

function Shell:RefreshModuleControls()
    if not self.modulePanel then
        return
    end

    for index = 1, table.getn(S.Modules.order) do
        local key = S.Modules.order[index]
        local record = S.Modules:Get(key)
        local row = self.moduleRows[key]

        if row then
            local installed = S.Modules:IsInstalled(key)
            local loaded = S.Modules:IsLoaded(key)
            local enabled = S.Modules:IsEnabled(key)
            local locked = key == "Shell"
            local status = installed and (loaded and "loaded" or "available") or "missing"

            row.check.locked = locked
            row.check:SetChecked(enabled or locked)

            if installed and not locked then
                row.check:Enable()
            else
                row.check:Disable()
            end

            if row.label then
                row.label:SetText((record.displayName or key) .. (locked and " (this window)" or ""))
            end

            row.status:SetText(status)
            row.row:Show()
        end
    end
end

function Shell:ShowModuleControls()
    self:CreateModuleControls()
    self:RefreshModuleControls()
    self.modulePanel:Show()
end

function Shell:CreateMemberStatsPanel()
    if self.memberStatsPanel then
        return
    end

    local panel = CreateFrame("Frame", nil, self.detailContent)
    panel:SetPoint("TOPLEFT", self.contentSubtitle, "BOTTOMLEFT", 0, -22)
    panel:SetPoint("RIGHT", self.detailContent, "RIGHT", 0, 0)
    panel:SetHeight(120)
    panel:Hide()
    self.memberStatsPanel = panel
    self:AddDynamicFrame(panel)

    local kind = S.Theme:CreateFontString(panel, "normal", 12, "")
    kind:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    kind:SetText("")
    self.memberKindText = kind

    local progression = S.Theme:CreateFontString(panel, "normal", 12, "")
    progression:SetPoint("TOPLEFT", kind, "BOTTOMLEFT", 0, -8)
    progression:SetText("")
    S.Theme:ApplyTextColor(progression, "textMuted")
    self.memberProgressionText = progression

    local query = self:CreateActionButton(panel, "Server Helper Pending", 180, 24, function()
        return false, "Progression member queries need a server helper module."
    end)
    query:SetPoint("TOPLEFT", progression, "BOTTOMLEFT", 0, -14)
    query:Disable()
    self.memberProgressionButton = query
end

function Shell:ShowMemberStatsPanel(member)
    self:CreateMemberStatsPanel()
    self.progressionMember = member

    local kind = member and member.kind or "Unknown"
    local source = member and member.kindSource or "pending"
    local progression = member and S.Progression:GetProgression(member.name) or nil
    local progressionText = "Progression: server helper pending"

    if progression then
        progressionText = "Progression: " .. tostring(progression.level) .. " (" .. tostring(progression.source) .. ")"
    end

    self.memberKindText:SetText("Classification: " .. kind .. " (" .. source .. ")")
    self.memberProgressionText:SetText(progressionText)
    self.memberStatsPanel:Show()
end

function Shell:FormatNumber(value)
    value = tonumber(value)

    if not value then
        return "-"
    end

    return tostring(math.floor(value + 0.5))
end

function Shell:FormatPercent(value)
    value = tonumber(value)

    if not value then
        return "-"
    end

    return string.format("%.2f%%", value)
end

function Shell:FormatPair(current, maximum)
    current = tonumber(current)
    maximum = tonumber(maximum)

    if not current or not maximum or maximum <= 0 then
        return "-"
    end

    return self:FormatNumber(current) .. " / " .. self:FormatNumber(maximum)
end

function Shell:GetPowerText(unit)
    local current
    local maximum

    if UnitPower then
        current = UnitPower(unit)
        maximum = UnitPowerMax and UnitPowerMax(unit) or nil
    elseif UnitMana then
        current = UnitMana(unit)
        maximum = UnitManaMax and UnitManaMax(unit) or nil
    end

    return self:FormatPair(current, maximum)
end

Shell.inventorySlotFallbacks = {
    AmmoSlot = 0,
    HeadSlot = 1,
    NeckSlot = 2,
    ShoulderSlot = 3,
    ShirtSlot = 4,
    ChestSlot = 5,
    WaistSlot = 6,
    LegsSlot = 7,
    FeetSlot = 8,
    WristSlot = 9,
    HandsSlot = 10,
    Finger0Slot = 11,
    Finger1Slot = 12,
    Trinket0Slot = 13,
    Trinket1Slot = 14,
    BackSlot = 15,
    MainHandSlot = 16,
    SecondaryHandSlot = 17,
    RangedSlot = 18,
    TabardSlot = 19,
}

Shell.gearSlotColumns = {
    left = {
        { slot = "HeadSlot", label = "Head" },
        { slot = "NeckSlot", label = "Neck" },
        { slot = "ShoulderSlot", label = "Shoulders" },
        { slot = "BackSlot", label = "Back" },
        { slot = "ChestSlot", label = "Chest" },
        { slot = "ShirtSlot", label = "Shirt" },
        { slot = "TabardSlot", label = "Tabard" },
        { slot = "WristSlot", label = "Wrist" },
    },
    right = {
        { slot = "HandsSlot", label = "Hands" },
        { slot = "WaistSlot", label = "Waist" },
        { slot = "LegsSlot", label = "Legs" },
        { slot = "FeetSlot", label = "Feet" },
        { slot = "Finger0Slot", label = "Ring 1" },
        { slot = "Finger1Slot", label = "Ring 2" },
        { slot = "Trinket0Slot", label = "Trinket 1" },
        { slot = "Trinket1Slot", label = "Trinket 2" },
    },
    bottom = {
        { slot = "MainHandSlot", label = "Main Hand" },
        { slot = "SecondaryHandSlot", label = "Off Hand" },
        { slot = "RangedSlot", label = "Ranged" },
        { slot = "AmmoSlot", label = "Ammo" },
    },
}

function Shell:CreateStatGroup(parent, title, rowCount, width, height)
    local group = CreateFrame("Frame", nil, parent)
    group:SetWidth(width or 270)
    group:SetHeight(height or (36 + (rowCount * 18)))
    S.Theme:ApplyBackdrop(group, "panel")

    local heading = S.Theme:CreateFontString(group, "bold", 12, "")
    heading:SetPoint("TOPLEFT", group, "TOPLEFT", 10, -8)
    heading:SetText(title)

    group.values = {}

    for index = 1, rowCount do
        local label = S.Theme:CreateFontString(group, "normal", 11, "")
        label:SetPoint("TOPLEFT", group, "TOPLEFT", 12, -30 - ((index - 1) * 18))
        label:SetText("")
        S.Theme:ApplyTextColor(label, "textMuted")

        local value = S.Theme:CreateFontString(group, "normal", 11, "")
        value:SetPoint("RIGHT", group, "RIGHT", -12, 0)
        value:SetPoint("TOP", label, "TOP", 0, 0)
        value:SetJustifyH("RIGHT")
        value:SetText("")

        group.values[index] = {
            label = label,
            value = value,
        }
    end

    return group
end

function Shell:SetStatRow(group, index, label, value)
    local row = group and group.values and group.values[index]

    if not row then
        return
    end

    row.label:SetText(label or "")
    row.value:SetText(value or "-")
end

function Shell:GetInventorySlotID(slotName)
    if GetInventorySlotInfo then
        local slotID = GetInventorySlotInfo(slotName)

        if slotID then
            return slotID
        end
    end

    return self.inventorySlotFallbacks[slotName]
end

function Shell:GetItemNameFromLink(link)
    if not link then
        return nil
    end

    local name

    if GetItemInfo then
        name = GetItemInfo(link)
    end

    if not name then
        name = string.match(link, "%[(.-)%]")
    end

    return name
end

function Shell:GetItemLevelFromLink(link)
    if not link or not GetItemInfo then
        return nil
    end

    local _, _, _, itemLevel = GetItemInfo(link)
    return tonumber(itemLevel)
end

function Shell:SetQualityColor(fontString, quality)
    if not fontString then
        return
    end

    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]

    if color then
        fontString:SetTextColor(color.r, color.g, color.b)
    else
        S.Theme:ApplyTextColor(fontString, "textMuted")
    end
end

function Shell:HandleItemModifiedClick(link)
    if not link or not IsModifiedClick or not HandleModifiedItemClick then
        return false
    end

    if IsModifiedClick("CHATLINK") or IsModifiedClick("DRESSUP") or IsModifiedClick("COMPAREITEMS") then
        return HandleModifiedItemClick(link) and true or false
    end

    return false
end

function Shell:RefreshOverviewAfterItemAction()
    self:RefreshCharacterOverviewIfShown()
end

function Shell:RefreshCharacterOverviewIfShown()
    if self.frame and self.frame:IsShown() and self.currentArea == "Character" and self.currentSection == "Stats" then
        self:UpdateCharacterOverviewPanel()
    end
end

function Shell:PickupInventorySlot(slotID)
    if not slotID or not PickupInventoryItem then
        return false
    end

    PickupInventoryItem(slotID)
    self:RefreshOverviewAfterItemAction()
    return true
end

function Shell:IsInventorySlotTargeting()
    return (SpellIsTargeting and SpellIsTargeting())
        or (CursorHasSpell and CursorHasSpell())
end

function Shell:UseInventorySlot(slotID)
    if not slotID or not UseInventoryItem then
        return false
    end

    UseInventoryItem(slotID)
    self:RefreshOverviewAfterItemAction()
    return true
end

function Shell:PickupBagSlot(bag, slot)
    if bag == nil or not slot or not PickupContainerItem then
        return false
    end

    PickupContainerItem(bag, slot)
    self:RefreshOverviewAfterItemAction()
    return true
end

function Shell:UseBagSlot(bag, slot)
    if bag == nil or not slot or not UseContainerItem then
        return false
    end

    UseContainerItem(bag, slot)
    self:RefreshOverviewAfterItemAction()
    return true
end

function Shell:CreatePaperDollSlotButton(parent, slotInfo)
    self.equipmentButtonIndex = (self.equipmentButtonIndex or 0) + 1

    local name = "SableUI__" .. slotInfo.slot
    local ok
    local button

    if not _G[name] then
        ok, button = pcall(function()
            return CreateFrame("Button", name, parent, "PaperDollItemSlotButtonTemplate")
        end)
    end

    local isPaperDollButton = ok and button

    if not ok or not button then
        name = "SableUICustomEquipmentSlot" .. tostring(self.equipmentButtonIndex)
        button = CreateFrame("Button", name, parent)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnClick", function(self, mouseButton)
            if self.dragging then
                self.dragging = nil
                return
            end

            local link = GetInventoryItemLink and GetInventoryItemLink("player", self.slotID) or nil

            if Shell:HandleItemModifiedClick(link) then
                return
            end

            if mouseButton == "LeftButton" then
                if Shell:IsInventorySlotTargeting() then
                    Shell:UseInventorySlot(self.slotID)
                    return
                end

                Shell:PickupInventorySlot(self.slotID)
            elseif mouseButton == "RightButton" then
                Shell:UseInventorySlot(self.slotID)
            end
        end)
        button:SetScript("OnDragStart", function(self)
            self.dragging = true
            Shell:PickupInventorySlot(self.slotID)
        end)
        button:SetScript("OnReceiveDrag", function(self)
            Shell:PickupInventorySlot(self.slotID)
        end)
    end

    button:SetWidth(36)
    button:SetHeight(36)
    button:SetPoint("LEFT", parent, "LEFT", 6, 0)
    button:SetID(self:GetInventorySlotID(slotInfo.slot) or 0)
    button.slotName = slotInfo.slot
    button.slotID = self:GetInventorySlotID(slotInfo.slot)

    S.Theme:ApplyBackdrop(button, "panelAlt")
    if isPaperDollButton then
        local normal = _G[name .. "NormalTexture"] or button:CreateTexture(name .. "NormalTexture", "BACKGROUND")

        normal:SetAllPoints(button)
        if not normal:GetTexture() then
            normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        end
        normal:SetAlpha(0)
        button:SetNormalTexture(normal)

        button.ignoreTexture = button.ignoreTexture or _G[name .. "IgnoreTexture"]
        if button.ignoreTexture then
            button.ignoreTexture:SetAlpha(0)
            button.ignoreTexture:Hide()
        end
    else
        if button.SetNormalTexture then
            button:SetNormalTexture(nil)
        end
        if button.SetPushedTexture then
            button:SetPushedTexture(nil)
        end
        if button.SetHighlightTexture then
            button:SetHighlightTexture(nil)
        end
        if button.SetCheckedTexture then
            button:SetCheckedTexture(nil)
        end
    end

    button.texture = _G[name .. "IconTexture"] or button:CreateTexture(nil, "ARTWORK")
    button.texture:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    button.texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button:SetScript("OnEnter", function(self)
        if not self.slotID or not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local hasItem = GameTooltip:SetInventoryItem("player", self.slotID)

        if not hasItem then
            GameTooltip:SetText(slotInfo.label)
            GameTooltip:AddLine("Empty", 0.58, 0.57, 0.53)
        end

        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return button
end

function Shell:CreateEquipmentRow(parent, slotInfo, width)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(width or 252)
    row:SetHeight(46)
    S.Theme:ApplyBackdrop(row, "panel")

    local icon = self:CreatePaperDollSlotButton(row, slotInfo)

    local label = S.Theme:CreateFontString(row, "normal", 10, "")
    label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -5)
    label:SetText(slotInfo.label)
    S.Theme:ApplyTextColor(label, "textMuted")

    local item = S.Theme:CreateFontString(row, "normal", 11, "")
    item:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
    item:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    item:SetJustifyH("LEFT")
    item:SetText("-")

    row.slotInfo = slotInfo
    row.icon = icon
    row.label = label
    row.item = item

    return row
end

function Shell:CreateEquipmentColumn(parent, slotList, width)
    local column = CreateFrame("Frame", nil, parent)
    column:SetWidth(width or 258)
    column:SetHeight((table.getn(slotList) * 46) + ((table.getn(slotList) - 1) * 6))
    column.rows = {}

    local previous

    for index = 1, table.getn(slotList) do
        local row = self:CreateEquipmentRow(column, slotList[index], width or 258)

        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
        else
            row:SetPoint("TOPLEFT", column, "TOPLEFT", 0, 0)
        end

        column.rows[index] = row
        previous = row
    end

    return column
end

function Shell:CreateCharacterGearPanel()
    if self.characterGearPanel then
        return
    end

    local panel = CreateFrame("Frame", nil, self.detailContent)
    panel:SetPoint("TOPLEFT", self.contentSubtitle, "BOTTOMLEFT", 0, -22)
    panel:SetPoint("BOTTOMRIGHT", self.detailContent, "BOTTOMRIGHT", 0, 0)
    panel:Hide()
    self.characterGearPanel = panel
    self:AddDynamicFrame(panel)

    local left = self:CreateEquipmentColumn(panel, self.gearSlotColumns.left, 258)
    left:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)

    local right = self:CreateEquipmentColumn(panel, self.gearSlotColumns.right, 258)
    right:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

    local summary = self:CreateStatGroup(panel, "Equipment Summary", 5, 258, 128)
    summary:SetPoint("TOP", panel, "TOP", 0, 0)

    local visual = CreateFrame("Frame", nil, panel)
    visual:SetWidth(258)
    visual:SetHeight(236)
    visual:SetPoint("TOP", summary, "BOTTOM", 0, -14)
    S.Theme:ApplyBackdrop(visual, "panel")

    local visualTitle = S.Theme:CreateFontString(visual, "bold", 12, "")
    visualTitle:SetPoint("TOPLEFT", visual, "TOPLEFT", 10, -8)
    visualTitle:SetText("Paper Doll")

    local visualText = S.Theme:CreateFontString(visual, "normal", 11, "")
    visualText:SetPoint("CENTER", visual, "CENTER", 0, 0)
    visualText:SetJustifyH("CENTER")
    visualText:SetText("Model preview unavailable")
    S.Theme:ApplyTextColor(visualText, "textMuted")

    local ok, model = pcall(function()
        return CreateFrame("PlayerModel", nil, visual)
    end)

    if ok and model then
        model:SetPoint("TOPLEFT", visual, "TOPLEFT", 8, -28)
        model:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", -8, 8)
        model:SetUnit("player")
        visualText:Hide()
    else
        model = nil
    end

    local bottom = self:CreateEquipmentColumn(panel, self.gearSlotColumns.bottom, 258)
    bottom:SetPoint("TOP", visual, "BOTTOM", 0, -14)

    self.characterGear = {
        left = left,
        right = right,
        bottom = bottom,
        summary = summary,
        model = model,
    }
end

function Shell:UpdateEquipmentRow(row)
    local slotID = row and row.icon and row.icon.slotID

    if not slotID then
        return nil
    end

    local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID) or nil
    local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", slotID) or nil
    local quality = GetInventoryItemQuality and GetInventoryItemQuality("player", slotID) or nil
    local itemName = self:GetItemNameFromLink(link)
    local itemLevel = self:GetItemLevelFromLink(link)

    row.icon.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.item:SetText(itemName or "Empty")
    self:SetQualityColor(row.item, quality)

    if row.icon.ignoreTexture then
        row.icon.ignoreTexture:SetAlpha(0)
        row.icon.ignoreTexture:Hide()
    end

    if link then
        row.icon:SetAlpha(1)
    else
        row.icon:SetAlpha(0.55)
    end

    return {
        link = link,
        quality = quality,
        itemLevel = itemLevel,
    }
end

function Shell:UpdateEquipmentColumn(column, totals)
    if not column or not column.rows then
        return
    end

    for index = 1, table.getn(column.rows) do
        local item = self:UpdateEquipmentRow(column.rows[index])

        totals.slots = totals.slots + 1

        if item and item.link then
            totals.equipped = totals.equipped + 1
        end

        if item and item.itemLevel then
            totals.itemLevel = totals.itemLevel + item.itemLevel
            totals.itemLevelCount = totals.itemLevelCount + 1
        end
    end
end

function Shell:UpdateCharacterGearPanel()
    self:CreateCharacterGearPanel()

    local gear = self.characterGear
    local totals = {
        slots = 0,
        equipped = 0,
        itemLevel = 0,
        itemLevelCount = 0,
    }

    self:UpdateEquipmentColumn(gear.left, totals)
    self:UpdateEquipmentColumn(gear.right, totals)
    self:UpdateEquipmentColumn(gear.bottom, totals)

    local average = "-"

    if totals.itemLevelCount > 0 then
        average = self:FormatNumber(totals.itemLevel / totals.itemLevelCount)
    end

    local armor = "-"

    if UnitArmor then
        local _, effective = UnitArmor("player")
        armor = self:FormatNumber(effective)
    end

    self:SetStatRow(gear.summary, 1, "Equipped", tostring(totals.equipped) .. " / " .. tostring(totals.slots))
    self:SetStatRow(gear.summary, 2, "Avg Item Level", average)
    self:SetStatRow(gear.summary, 3, "Armor", armor)
    self:SetStatRow(gear.summary, 4, "Durability", "Pending")
    self:SetStatRow(gear.summary, 5, "Set Bonuses", "Pending")

    if gear.model and gear.model.SetUnit then
        gear.model:SetUnit("player")
    end

    self.characterGearPanel:Show()
end

function Shell:CreateGearIcon(parent, slotInfo)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(96)
    button:SetHeight(48)
    S.Theme:ApplyBackdrop(button, "panel")
    button.slotInfo = slotInfo
    button.slotID = self:GetInventorySlotID(slotInfo.slot)

    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetWidth(32)
    button.texture:SetHeight(32)
    button.texture:SetPoint("LEFT", button, "LEFT", 7, 0)
    button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.label = S.Theme:CreateFontString(button, "normal", 10, "")
    button.label:SetPoint("TOPLEFT", button.texture, "TOPRIGHT", 7, -1)
    button.label:SetText(slotInfo.label)
    S.Theme:ApplyTextColor(button.label, "textMuted")

    button.item = S.Theme:CreateFontString(button, "normal", 10, "")
    button.item:SetPoint("TOPLEFT", button.label, "BOTTOMLEFT", 0, -5)
    button.item:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    button.item:SetJustifyH("LEFT")
    button.item:SetText("-")

    button:SetScript("OnEnter", function(self)
        if not self.slotID or not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local hasItem = GameTooltip:SetInventoryItem("player", self.slotID)

        if not hasItem then
            GameTooltip:SetText(slotInfo.label)
            GameTooltip:AddLine("Empty", 0.58, 0.57, 0.53)
        end

        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return button
end

function Shell:UpdateGearIcon(button)
    local slotID = button and button.slotID

    if not slotID then
        return nil
    end

    local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID) or nil
    local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", slotID) or nil
    local quality = GetInventoryItemQuality and GetInventoryItemQuality("player", slotID) or nil
    local itemName = self:GetItemNameFromLink(link)
    local itemLevel = self:GetItemLevelFromLink(link)

    button.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.item:SetText(itemName or "Empty")
    self:SetQualityColor(button.item, quality)
    button:SetAlpha(link and 1 or 0.58)

    return {
        link = link,
        itemLevel = itemLevel,
    }
end

function Shell:CreateBagButton(parent)
    self.bagButtonIndex = (self.bagButtonIndex or 0) + 1

    local name = "SableUIBagSlot" .. tostring(self.bagButtonIndex)
    local button = CreateFrame("CheckButton", name, parent, "ContainerFrameItemButtonTemplate")
    button:SetWidth(30)
    button:SetHeight(30)
    S.Theme:ApplyBackdrop(button, "panelAlt")

    button:SetNormalTexture(nil)
    button:SetCheckedTexture(nil)
    button.texture = _G[name .. "IconTexture"] or button:CreateTexture(nil, "ARTWORK")
    button.texture:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    button.texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.count = _G[name .. "Count"] or S.Theme:CreateFontString(button, "normal", 9, "OUTLINE")
    button.count:ClearAllPoints()
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 1)

    return button
end

function Shell:GetTalentLink(tab, talentIndex)
    if GetTalentLink then
        local ok, link = pcall(GetTalentLink, tab, talentIndex)

        if ok and link then
            return link
        end
    end

    return nil
end

function Shell:SetTalentTooltip(button)
    if not button or not GameTooltip then
        return
    end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

    local shown

    if GameTooltip.SetTalent then
        local activeGroup = GetActiveTalentGroup and GetActiveTalentGroup() or 1
        local ok = pcall(function()
            GameTooltip:SetTalent(button.tab, button.talentIndex, false, false, activeGroup)
        end)

        shown = ok
    end

    if not shown then
        GameTooltip:SetText(button.talentName or "-")
        GameTooltip:AddLine(button.rankText or "", 0.58, 0.57, 0.53)
    end

    GameTooltip:Show()
end

function Shell:LearnOverviewTalent(tab, talentIndex)
    if not tab or not talentIndex or not LearnTalent then
        return
    end

    LearnTalent(tab, talentIndex, false)
    self:RefreshOverviewAfterItemAction()
end

function Shell:CreateTalentButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(26)
    button:SetHeight(26)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    S.Theme:ApplyBackdrop(button, "panelAlt")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.rank = S.Theme:CreateFontString(button, "normal", 9, "OUTLINE")
    button.rank:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)
    button.rank:SetJustifyH("RIGHT")

    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

    button:SetScript("OnEnter", function(self)
        Shell:SetTalentTooltip(self)
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if IsModifiedClick and IsModifiedClick("CHATLINK") then
            local link = Shell:GetTalentLink(self.tab, self.talentIndex)

            if link and ChatEdit_InsertLink then
                ChatEdit_InsertLink(link)
            end

            return
        end

        if mouseButton == "LeftButton" then
            Shell:LearnOverviewTalent(self.tab, self.talentIndex)
        end
    end)

    return button
end

function Shell:CreateTalentTreePanel(parent, index)
    local tree = CreateFrame("Frame", nil, parent)
    S.Theme:ApplyBackdrop(tree, "panelAlt")

    local background = CreateFrame("Frame", nil, tree)
    background:SetPoint("TOPLEFT", tree, "TOPLEFT", 8, -38)
    background:SetPoint("BOTTOMRIGHT", tree, "BOTTOMRIGHT", -8, 8)
    background:SetFrameLevel(tree:GetFrameLevel() + 1)

    local topLeft = background:CreateTexture(nil, "BACKGROUND")
    topLeft:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    topLeft:SetPoint("BOTTOMRIGHT", background, "CENTER", 0, 0)

    local topRight = background:CreateTexture(nil, "BACKGROUND")
    topRight:SetPoint("TOPLEFT", background, "TOP", 0, 0)
    topRight:SetPoint("BOTTOMRIGHT", background, "RIGHT", 0, 0)

    local bottomLeft = background:CreateTexture(nil, "BACKGROUND")
    bottomLeft:SetPoint("TOPLEFT", background, "LEFT", 0, 0)
    bottomLeft:SetPoint("BOTTOMRIGHT", background, "BOTTOM", 0, 0)

    local bottomRight = background:CreateTexture(nil, "BACKGROUND")
    bottomRight:SetPoint("TOPLEFT", background, "CENTER", 0, 0)
    bottomRight:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 0, 0)

    local connectors = CreateFrame("Frame", nil, tree)
    connectors:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    connectors:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 0, 0)
    connectors:SetFrameLevel(tree:GetFrameLevel() + 2)

    local title = S.Theme:CreateFontString(tree, "bold", 11, "")
    title:SetPoint("TOPLEFT", tree, "TOPLEFT", 8, -7)
    title:SetPoint("RIGHT", tree, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT")
    title:SetText("-")

    local points = S.Theme:CreateFontString(tree, "normal", 10, "")
    points:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    points:SetPoint("RIGHT", tree, "RIGHT", -8, 0)
    points:SetJustifyH("LEFT")
    points:SetText("0")
    S.Theme:ApplyTextColor(points, "textMuted")

    local grid = CreateFrame("Frame", nil, tree)
    grid:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    grid:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 0, 0)
    grid:SetFrameLevel(tree:GetFrameLevel() + 3)

    tree.index = index
    tree.background = background
    tree.backgroundTextures = {
        topLeft = topLeft,
        topRight = topRight,
        bottomLeft = bottomLeft,
        bottomRight = bottomRight,
    }
    tree.connectors = connectors
    tree.connectorTextures = {}
    tree.title = title
    tree.points = points
    tree.grid = grid
    tree.buttons = {}

    return tree
end

function Shell:CreateTalentTreeTab(parent, index)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetHeight(22)
    S.Theme:ApplyBackdrop(tab, "panelAlt")

    local text = S.Theme:CreateFontString(tab, "normal", 10, "")
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetText("-")
    tab.text = text
    tab.index = index

    tab:SetScript("OnClick", function(self)
        Shell.overviewTalentTab = self.index
        Shell:RefreshCharacterOverviewIfShown()
    end)

    return tab
end

Shell.talentConnectorCoords = {
    branch = {
        top = { left = 0.12890625, width = 0.125, bottom = 0.96875 },
        left = { left = 0.2578125, width = 0.125 },
        topright = { left = 0.515625, width = 0.125 },
        topleft = { left = 0.640625, width = -0.125 },
    },
    arrow = {
        top = { left = 0, width = 0.5 },
        left = { left = 0.5, width = 0.5 },
        right = { left = 1.0, width = -0.5 },
    },
}

function Shell:SetTalentConnectorCoords(texture, textureType, subtype)
    local coords = self.talentConnectorCoords[textureType] and self.talentConnectorCoords[textureType][subtype]

    if not coords then
        texture:SetTexCoord(0, 1, 0, 1)
        return
    end

    local left = coords.left
    texture:SetTexCoord(left, left + coords.width, 0, coords.bottom or 1)
end

function Shell:GetTalentConnectorTexture(tree, textureType, subtype)
    tree.connectorIndex = (tree.connectorIndex or 0) + 1

    local texture = tree.connectorTextures[tree.connectorIndex]

    if not texture then
        texture = tree.connectors:CreateTexture(nil, "OVERLAY")
        tree.connectorTextures[tree.connectorIndex] = texture
    end

    texture:ClearAllPoints()
    texture:SetWidth(32)
    texture:SetHeight(32)
    texture:SetTexture(textureType == "arrow" and "Interface\\Addons\\Talented\\Textures\\arrows-normal" or "Interface\\Addons\\Talented\\Textures\\branches-normal")
    texture:SetVertexColor(0.9, 0.72, 0.42)
    texture:SetAlpha(0.85)
    self:SetTalentConnectorCoords(texture, textureType, subtype)
    texture:Show()

    return texture
end

function Shell:HideUnusedTalentConnectors(tree)
    local startIndex = (tree.connectorIndex or 0) + 1

    for index = startIndex, table.getn(tree.connectorTextures) do
        tree.connectorTextures[index]:Hide()
    end
end

function Shell:GetTalentGridPoint(row, column, buttonSize, xStep, yStep)
    local x = (column - 1) * xStep
    local y = -((row - 1) * yStep)

    return x, y
end

function Shell:DrawTalentConnectorSegment(tree, textureType, subtype, x, y, width, height)
    local texture = self:GetTalentConnectorTexture(tree, textureType, subtype)

    texture:SetWidth(width or 32)
    texture:SetHeight(height or 32)
    texture:SetPoint("TOPLEFT", tree.connectors, "TOPLEFT", x, y)

    return texture
end

function Shell:DrawOverviewTalentConnector(tree, fromTalent, toTalent, buttonSize, xStep, yStep)
    if not fromTalent or not toTalent then
        return
    end

    local fromX, fromY = self:GetTalentGridPoint(fromTalent.row, fromTalent.column, buttonSize, xStep, yStep)
    local toX, toY = self:GetTalentGridPoint(toTalent.row, toTalent.column, buttonSize, xStep, yStep)
    local centerOffset = math.floor(buttonSize / 2) - 16

    if fromTalent.column == toTalent.column then
        for row = fromTalent.row + 1, toTalent.row - 1 do
            local x, y = self:GetTalentGridPoint(row, fromTalent.column, buttonSize, xStep, yStep)
            self:DrawTalentConnectorSegment(tree, "branch", "top", x + centerOffset, y + 8, 32, math.max(32, yStep))
        end

        self:DrawTalentConnectorSegment(tree, "arrow", "top", toX + centerOffset, toY + buttonSize - 10, 32, 32)
        return
    end

    if fromTalent.row == toTalent.row then
        local leftColumn = math.min(fromTalent.column, toTalent.column)
        local rightColumn = math.max(fromTalent.column, toTalent.column)

        for column = leftColumn + 1, rightColumn - 1 do
            local x, y = self:GetTalentGridPoint(fromTalent.row, column, buttonSize, xStep, yStep)
            self:DrawTalentConnectorSegment(tree, "branch", "left", x - 8, y + centerOffset, math.max(32, xStep), 32)
        end

        if fromTalent.column < toTalent.column then
            self:DrawTalentConnectorSegment(tree, "arrow", "right", toX - buttonSize, toY + centerOffset, 32, 32)
        else
            self:DrawTalentConnectorSegment(tree, "arrow", "left", toX + buttonSize - 8, toY + centerOffset, 32, 32)
        end
        return
    end

    self:DrawTalentConnectorSegment(tree, "branch", "top", fromX + centerOffset, fromY + buttonSize - 4, 32, math.max(32, yStep))
    self:DrawTalentConnectorSegment(tree, "branch", fromTalent.column < toTalent.column and "topleft" or "topright", toX + centerOffset, fromY + yStep - 4, 32, 32)
    self:DrawTalentConnectorSegment(tree, "arrow", "top", toX + centerOffset, toY + buttonSize - 10, 32, 32)
end

function Shell:GetBagRange()
    local lastBag = NUM_BAG_SLOTS or 4
    return 0, lastBag
end

function Shell:CreateCharacterOverviewPanel()
    if self.characterOverviewPanel then
        return
    end

    local panel = CreateFrame("Frame", nil, self.detailContent)
    panel:SetPoint("TOPLEFT", self.contentSubtitle, "BOTTOMLEFT", 0, -22)
    panel:SetPoint("BOTTOMRIGHT", self.detailContent, "BOTTOMRIGHT", 0, 0)
    panel:Hide()
    self.characterOverviewPanel = panel
    self:AddDynamicFrame(panel)

    local gear = CreateFrame("Frame", nil, panel)
    gear:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    gear:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 196)
    gear:SetWidth(620)
    S.Theme:ApplyBackdrop(gear, "panel")

    local gearTitle = S.Theme:CreateFontString(gear, "bold", 12, "")
    gearTitle:SetPoint("TOPLEFT", gear, "TOPLEFT", 10, -8)
    gearTitle:SetText("Equipment")

    local leftRows = {}

    for index = 1, table.getn(self.gearSlotColumns.left) do
        leftRows[index] = self:CreateEquipmentRow(gear, self.gearSlotColumns.left[index], 170)
    end

    local rightRows = {}

    for index = 1, table.getn(self.gearSlotColumns.right) do
        rightRows[index] = self:CreateEquipmentRow(gear, self.gearSlotColumns.right[index], 170)
    end

    local weaponRows = {}

    for index = 1, table.getn(self.gearSlotColumns.bottom) do
        weaponRows[index] = self:CreateEquipmentRow(gear, self.gearSlotColumns.bottom[index], 170)
    end

    local modelPanel = CreateFrame("Frame", nil, gear)
    modelPanel:SetWidth(220)
    modelPanel:SetHeight(312)
    S.Theme:ApplyBackdrop(modelPanel, "panelAlt")

    local modelText = S.Theme:CreateFontString(modelPanel, "normal", 11, "")
    modelText:SetPoint("CENTER", modelPanel, "CENTER", 0, 0)
    modelText:SetJustifyH("CENTER")
    modelText:SetText("Model preview unavailable")
    S.Theme:ApplyTextColor(modelText, "textMuted")

    local ok, model = pcall(function()
        return CreateFrame("PlayerModel", nil, modelPanel)
    end)

    if ok and model then
        model:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 6, -6)
        model:SetPoint("BOTTOMRIGHT", modelPanel, "BOTTOMRIGHT", -6, 6)
        model:SetUnit("player")
        modelText:Hide()
    else
        model = nil
    end

    local inventory = CreateFrame("Frame", nil, panel)
    inventory:SetPoint("TOPLEFT", gear, "TOPRIGHT", 12, 0)
    inventory:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    inventory:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 196)
    S.Theme:ApplyBackdrop(inventory, "panel")

    local inventoryTitle = S.Theme:CreateFontString(inventory, "bold", 12, "")
    inventoryTitle:SetPoint("TOPLEFT", inventory, "TOPLEFT", 10, -8)
    inventoryTitle:SetText("Inventory")

    local inventorySummary = S.Theme:CreateFontString(inventory, "normal", 11, "")
    inventorySummary:SetPoint("TOPRIGHT", inventory, "TOPRIGHT", -10, -9)
    inventorySummary:SetText("")
    S.Theme:ApplyTextColor(inventorySummary, "textMuted")

    local bagParents = {}
    local firstBag, lastBag = self:GetBagRange()

    for bag = firstBag, lastBag do
        local bagFrame = CreateFrame("Frame", nil, inventory)
        bagFrame:SetID(bag)
        bagFrame:SetAllPoints(inventory)
        bagParents[bag] = bagFrame
    end

    local bagButtons = {}

    for index = 1, 120 do
        local button = self:CreateBagButton(inventory)
        bagButtons[index] = button
        button:Hide()
    end

    local talents = CreateFrame("Frame", nil, panel)
    talents:SetPoint("TOPLEFT", inventory, "TOPRIGHT", 12, 0)
    talents:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    talents:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 196)
    S.Theme:ApplyBackdrop(talents, "panel")

    local talentsTitle = S.Theme:CreateFontString(talents, "bold", 12, "")
    talentsTitle:SetPoint("TOPLEFT", talents, "TOPLEFT", 10, -8)
    talentsTitle:SetText("Talents")

    local talentTabs = {}

    for index = 1, 3 do
        talentTabs[index] = self:CreateTalentTreeTab(talents, index)
    end

    local talentTrees = {}

    for index = 1, 3 do
        talentTrees[index] = self:CreateTalentTreePanel(talents, index)
    end

    local summary = self:CreateStatGroup(panel, "Summary", 6, 150, 182)
    summary:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)

    local attributes = self:CreateStatGroup(panel, "Attributes", 5, 150, 182)
    attributes:SetPoint("LEFT", summary, "RIGHT", 8, 0)

    local combat = self:CreateStatGroup(panel, "Combat", 8, 150, 182)
    combat:SetPoint("LEFT", attributes, "RIGHT", 8, 0)

    local defense = self:CreateStatGroup(panel, "Defense", 6, 150, 182)
    defense:SetPoint("LEFT", combat, "RIGHT", 8, 0)

    local resistances = self:CreateStatGroup(panel, "Resistances", 5, 150, 182)
    resistances:SetPoint("LEFT", defense, "RIGHT", 8, 0)

    local progression = self:CreateStatGroup(panel, "Progression", 4, 150, 182)
    progression:SetPoint("LEFT", resistances, "RIGHT", 8, 0)

    local challenges = self:CreateStatGroup(panel, "Challenge Modes", 4, 150, 182)
    challenges:SetPoint("LEFT", progression, "RIGHT", 8, 0)

    self.characterOverview = {
        gear = gear,
        inventory = inventory,
        talents = talents,
        bagParents = bagParents,
        leftRows = leftRows,
        rightRows = rightRows,
        weaponRows = weaponRows,
        modelPanel = modelPanel,
        model = model,
        bagButtons = bagButtons,
        talentTabs = talentTabs,
        talentTrees = talentTrees,
        inventorySummary = inventorySummary,
        summary = summary,
        attributes = attributes,
        combat = combat,
        defense = defense,
        resistances = resistances,
        progression = progression,
        challenges = challenges,
        statGroups = {
            summary,
            attributes,
            combat,
            defense,
            resistances,
            progression,
            challenges,
        },
    }
end

function Shell:LayoutOverviewEquipmentRows(rows, anchorFrame, point, relativePoint, xOffset, rowWidth)
    local previous

    for index = 1, table.getn(rows) do
        local row = rows[index]
        row:SetWidth(rowWidth)
        row:ClearAllPoints()

        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
        else
            row:SetPoint(point, anchorFrame, relativePoint, xOffset, -30)
        end

        previous = row
    end
end

function Shell:LayoutCharacterOverviewPanel()
    local overview = self.characterOverview

    if not overview then
        return
    end

    local panelWidth = self.characterOverviewPanel:GetWidth() or 1180
    local topBottomOffset = 206
    local cardGap = 8
    local cardWidth = math.floor((panelWidth - (cardGap * 6)) / 7)

    cardWidth = math.max(128, cardWidth)

    local gearWidth = (cardWidth * 3) + (cardGap * 2)
    local inventoryWidth = cardWidth
    local talentsWidth = (cardWidth * 3) + (cardGap * 2)

    overview.gear:SetWidth(gearWidth)
    overview.gear:ClearAllPoints()
    overview.gear:SetPoint("TOPLEFT", self.characterOverviewPanel, "TOPLEFT", 0, 0)
    overview.gear:SetPoint("BOTTOMLEFT", self.characterOverviewPanel, "BOTTOMLEFT", 0, topBottomOffset)
    overview.gear:Show()

    overview.inventory:ClearAllPoints()
    overview.inventory:SetWidth(inventoryWidth)
    overview.inventory:SetPoint("TOPLEFT", overview.gear, "TOPRIGHT", cardGap, 0)
    overview.inventory:SetPoint("BOTTOMLEFT", self.characterOverviewPanel, "BOTTOMLEFT", gearWidth + cardGap, topBottomOffset)
    overview.inventory:Show()

    overview.talents:SetWidth(talentsWidth)
    overview.talents:ClearAllPoints()
    overview.talents:SetPoint("TOPLEFT", overview.inventory, "TOPRIGHT", cardGap, 0)
    overview.talents:SetPoint("BOTTOMRIGHT", self.characterOverviewPanel, "BOTTOMRIGHT", 0, topBottomOffset)
    overview.talents:Show()

    for index = 1, table.getn(overview.talentTabs) do
        local tab = overview.talentTabs[index]
        tab:ClearAllPoints()
        tab:SetWidth(math.floor((talentsWidth - 36) / 3))

        if index == 1 then
            tab:SetPoint("TOPLEFT", overview.talents, "TOPLEFT", 10, -28)
        else
            tab:SetPoint("LEFT", overview.talentTabs[index - 1], "RIGHT", 8, 0)
        end
    end

    for index = 1, table.getn(overview.talentTrees) do
        local tree = overview.talentTrees[index]
        tree:ClearAllPoints()
        tree:SetPoint("TOPLEFT", overview.talents, "TOPLEFT", 10, -58)
        tree:SetPoint("RIGHT", overview.talents, "RIGHT", -10, 0)
        tree:SetPoint("BOTTOM", overview.talents, "BOTTOM", 0, 8)
    end

    local rowWidth = Clamp(math.floor((gearWidth - 278) / 2), 150, 190)
    local modelWidth = math.max(180, gearWidth - (rowWidth * 2) - 44)

    self:LayoutOverviewEquipmentRows(overview.leftRows, overview.gear, "TOPLEFT", "TOPLEFT", 10, rowWidth)
    self:LayoutOverviewEquipmentRows(overview.rightRows, overview.gear, "TOPRIGHT", "TOPRIGHT", -10, rowWidth)

    overview.modelPanel:SetWidth(modelWidth)
    overview.modelPanel:ClearAllPoints()
    overview.modelPanel:SetPoint("TOP", overview.gear, "TOP", 0, -30)
    overview.modelPanel:SetPoint("BOTTOM", overview.gear, "BOTTOM", 0, 70)
    overview.modelPanel:Show()

    for index = 1, table.getn(overview.weaponRows) do
        local row = overview.weaponRows[index]
        row:SetWidth(math.max(126, math.floor((gearWidth - 44) / table.getn(overview.weaponRows))))
        row:ClearAllPoints()

        if index == 1 then
            row:SetPoint("BOTTOMLEFT", overview.gear, "BOTTOMLEFT", 10, 12)
        else
            row:SetPoint("LEFT", overview.weaponRows[index - 1], "RIGHT", 8, 0)
        end
    end

    for index = 1, table.getn(overview.statGroups) do
        local group = overview.statGroups[index]
        group:SetWidth(cardWidth)
        group:ClearAllPoints()

        if index == 1 then
            group:SetPoint("BOTTOMLEFT", self.characterOverviewPanel, "BOTTOMLEFT", 0, 0)
        else
            group:SetPoint("LEFT", overview.statGroups[index - 1], "RIGHT", cardGap, 0)
        end
    end
end

function Shell:UpdateCharacterOverviewBags()
    local overview = self.characterOverview
    local buttons = overview.bagButtons
    local firstBag, lastBag = self:GetBagRange()
    local buttonIndex = 1
    local freeSlots = 0
    local totalSlots = 0
    local inventoryWidth = overview.inventory:GetWidth() or 340
    local columns = math.floor((inventoryWidth - 20) / 34)

    columns = Clamp(columns, 1, 18)

    for index = 1, table.getn(buttons) do
        buttons[index].bag = nil
        buttons[index].slot = nil
        buttons[index].link = nil

        buttons[index]:Hide()
    end

    for bag = firstBag, lastBag do
        local slots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0

        for slot = 1, slots do
            local button = buttons[buttonIndex]
            local link = GetContainerItemLink and GetContainerItemLink(bag, slot) or nil

            if button then
                local texture
                local count

                if GetContainerItemInfo then
                    texture, count = GetContainerItemInfo(bag, slot)
                end

                local column = (buttonIndex - 1) % columns
                local row = math.floor((buttonIndex - 1) / columns)

                button.bag = bag
                button.slot = slot
                button.link = link
                button:SetParent(overview.bagParents[bag] or overview.inventory)
                button:SetID(slot)

                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", overview.inventory, "TOPLEFT", 10 + (column * 34), -30 - (row * 34))
                button.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                button.count:SetText(count and count > 1 and tostring(count) or "")
                button:SetAlpha(link and 1 or 0.35)
                button:Show()

                buttonIndex = buttonIndex + 1
            end

            totalSlots = totalSlots + 1

            if not link then
                freeSlots = freeSlots + 1
            end
        end
    end

    overview.inventorySummary:SetText(tostring(freeSlots) .. " free / " .. tostring(totalSlots))
end

function Shell:UpdateCharacterOverviewTalents()
    local overview = self.characterOverview

    if not overview or not overview.talentTrees then
        return
    end

    local activeGroup = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    local unspent = GetUnspentTalentPoints and GetUnspentTalentPoints(nil, false, activeGroup) or nil
    local selectedTab = self.overviewTalentTab
    local selectedPoints = -1

    for tab = 1, table.getn(overview.talentTrees) do
        local name
        local points

        if GetTalentTabInfo then
            name, _, points = GetTalentTabInfo(tab, false, false, activeGroup)
        end

        points = tonumber(points) or 0

        if overview.talentTabs and overview.talentTabs[tab] then
            overview.talentTabs[tab].text:SetText((name or ("Tree " .. tostring(tab))) .. " (" .. tostring(points) .. ")")
        end

        if not selectedTab and points > selectedPoints then
            selectedPoints = points
            selectedTab = tab
        end
    end

    selectedTab = selectedTab or 1
    self.overviewTalentTab = selectedTab

    for tab = 1, table.getn(overview.talentTabs or {}) do
        local tabButton = overview.talentTabs[tab]

        if tab == selectedTab then
            tabButton:SetBackdropBorderColor(S.Theme:GetColor("accent"))
            tabButton.text:SetTextColor(S.Theme:GetColor("accent"))
        else
            tabButton:SetBackdropBorderColor(S.Theme:GetColor("border"))
            S.Theme:ApplyTextColor(tabButton.text, "textMuted")
        end
    end

    for tab = 1, table.getn(overview.talentTrees) do
        local tree = overview.talentTrees[tab]
        local name
        local points
        local backgroundName

        if GetTalentTabInfo then
            name, _, points, backgroundName = GetTalentTabInfo(tab, false, false, activeGroup)
        end

        tree.title:SetText(name or ("Tree " .. tostring(tab)))
        tree.connectorIndex = 0

        if backgroundName then
            tree.backgroundTextures.topLeft:SetTexture("Interface\\TalentFrame\\" .. backgroundName .. "-TopLeft")
            tree.backgroundTextures.topRight:SetTexture("Interface\\TalentFrame\\" .. backgroundName .. "-TopRight")
            tree.backgroundTextures.bottomLeft:SetTexture("Interface\\TalentFrame\\" .. backgroundName .. "-BottomLeft")
            tree.backgroundTextures.bottomRight:SetTexture("Interface\\TalentFrame\\" .. backgroundName .. "-BottomRight")
            tree.background:SetAlpha(0.42)
        end

        if unspent then
            tree.points:SetText(tostring(points or 0) .. " spent, " .. tostring(unspent) .. " free")
        else
            tree.points:SetText(tostring(points or 0) .. " spent")
        end

        if tab ~= selectedTab then
            tree:Hide()
            self:HideUnusedTalentConnectors(tree)
            for index = 1, table.getn(tree.buttons) do
                tree.buttons[index]:Hide()
            end
        else
            tree:Show()
        end

        if tab == selectedTab then
        local numTalents = GetNumTalents and GetNumTalents(tab, false, false) or 0
        local gridWidth = tree.grid:GetWidth() or 120
        local gridHeight = tree.grid:GetHeight() or 260
        local buttonSize = math.floor(math.min((gridWidth - 18) / 4, (gridHeight - 30) / 11))

        buttonSize = Clamp(buttonSize, 24, 37)

        local xStep = math.floor((gridWidth - buttonSize) / 3)
        local yStep = math.floor((gridHeight - buttonSize) / 10)
        local talentPositions = {}

        for index = 1, numTalents do
            local button = tree.buttons[index]

            if not button then
                button = self:CreateTalentButton(tree.grid)
                tree.buttons[index] = button
            end

            local talentName, icon, row, column, currentRank, maxRank, _, meetsPrereq, previewRank = GetTalentInfo(tab, index, false, false, activeGroup)
            local displayRank = tonumber(previewRank) or tonumber(currentRank) or 0

            row = tonumber(row) or 1
            column = tonumber(column) or 1
            maxRank = tonumber(maxRank) or 0
            talentPositions[index] = {
                row = row,
                column = column,
            }

            button:SetWidth(buttonSize)
            button:SetHeight(buttonSize)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", tree.grid, "TOPLEFT", (column - 1) * xStep, -((row - 1) * yStep))
            button.tab = tab
            button.talentIndex = index
            button.talentName = talentName
            button.rankText = tostring(displayRank) .. "/" .. tostring(maxRank)
            button.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            button.rank:SetText(button.rankText)

            if displayRank and displayRank > 0 then
                button:SetAlpha(1)
                if button.icon.SetDesaturated then
                    button.icon:SetDesaturated(false)
                end
                button.rank:SetTextColor(0.1, 1, 0.1)
            elseif meetsPrereq == false or (unspent and unspent <= 0) then
                button:SetAlpha(0.42)
                if button.icon.SetDesaturated then
                    button.icon:SetDesaturated(true)
                end
                button.rank:SetTextColor(0.7, 0.7, 0.7)
            else
                button:SetAlpha(0.75)
                if button.icon.SetDesaturated then
                    button.icon:SetDesaturated(false)
                end
                button.rank:SetTextColor(1, 0.82, 0)
            end

            button:Show()
        end

        if GetTalentPrereqs then
            for index = 1, numTalents do
                local requiredRow, requiredColumn = GetTalentPrereqs(tab, index, false, false, activeGroup)

                if requiredRow and requiredColumn then
                    local requiredTalent

                    for searchIndex = 1, numTalents do
                        local position = talentPositions[searchIndex]

                        if position and position.row == requiredRow and position.column == requiredColumn then
                            requiredTalent = position
                            break
                        end
                    end

                    self:DrawOverviewTalentConnector(tree, requiredTalent, talentPositions[index], buttonSize, xStep, yStep)
                end
            end
        end

        self:HideUnusedTalentConnectors(tree)

        for index = numTalents + 1, table.getn(tree.buttons) do
            tree.buttons[index]:Hide()
        end
        end
    end
end

function Shell:UpdateOverviewEquipmentRows(rows, totals)
    for index = 1, table.getn(rows) do
        local item = self:UpdateEquipmentRow(rows[index])
        totals.slots = totals.slots + 1

        if item and item.link then
            totals.equipped = totals.equipped + 1
        end

        if item and item.itemLevel then
            totals.itemLevel = totals.itemLevel + item.itemLevel
            totals.itemLevelCount = totals.itemLevelCount + 1
        end
    end
end

function Shell:UpdateCharacterOverviewPanel()
    self:CreateCharacterOverviewPanel()

    local overview = self.characterOverview
    self:LayoutCharacterOverviewPanel()

    local totals = {
        slots = 0,
        equipped = 0,
        itemLevel = 0,
        itemLevelCount = 0,
    }

    self:UpdateOverviewEquipmentRows(overview.leftRows, totals)
    self:UpdateOverviewEquipmentRows(overview.rightRows, totals)
    self:UpdateOverviewEquipmentRows(overview.weaponRows, totals)

    if overview.model and overview.model.SetUnit then
        overview.model:SetUnit("player")
    end

    self:UpdateCharacterOverviewBags()
    self:UpdateCharacterOverviewTalents()

    local name = S.Utils.GetUnitName("player") or "-"
    local level = UnitLevel and UnitLevel("player") or nil
    local class = UnitClass and UnitClass("player") or "-"
    local race = UnitRace and UnitRace("player") or "-"
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "-"
    local health = self:FormatPair(UnitHealth and UnitHealth("player") or nil, UnitHealthMax and UnitHealthMax("player") or nil)
    local average = "-"
    local armor = "-"

    if totals.itemLevelCount > 0 then
        average = self:FormatNumber(totals.itemLevel / totals.itemLevelCount)
    end

    if UnitArmor then
        local _, effective = UnitArmor("player")
        armor = self:FormatNumber(effective)
    end

    self:SetStatRow(overview.summary, 1, "Name", name)
    self:SetStatRow(overview.summary, 2, "Level", self:FormatNumber(level))
    self:SetStatRow(overview.summary, 3, "Race", race)
    self:SetStatRow(overview.summary, 4, "Class", class)
    self:SetStatRow(overview.summary, 5, "Faction", faction)
    self:SetStatRow(overview.summary, 6, "Health", health)

    self:SetStatRow(overview.attributes, 1, "Strength", self:GetEffectiveStat(1))
    self:SetStatRow(overview.attributes, 2, "Agility", self:GetEffectiveStat(2))
    self:SetStatRow(overview.attributes, 3, "Stamina", self:GetEffectiveStat(3))
    self:SetStatRow(overview.attributes, 4, "Intellect", self:GetEffectiveStat(4))
    self:SetStatRow(overview.attributes, 5, "Spirit", self:GetEffectiveStat(5))

    self:SetStatRow(overview.combat, 1, "Power", self:GetPowerText("player"))
    self:SetStatRow(overview.combat, 2, "Attack Power", self:GetAttackPower())
    self:SetStatRow(overview.combat, 3, "Melee Crit", GetCritChance and self:FormatPercent(GetCritChance()) or "-")
    self:SetStatRow(overview.combat, 4, "Melee Hit", self:GetCombatRatingBonus("CR_HIT_MELEE"))
    self:SetStatRow(overview.combat, 5, "Melee Haste", GetMeleeHaste and self:FormatPercent(GetMeleeHaste()) or "-")
    self:SetStatRow(overview.combat, 6, "Spell Power", self:GetSpellPower())
    self:SetStatRow(overview.combat, 7, "Healing", GetSpellBonusHealing and self:FormatNumber(GetSpellBonusHealing()) or "-")
    self:SetStatRow(overview.combat, 8, "Spell Hit", self:GetCombatRatingBonus("CR_HIT_SPELL"))

    self:SetStatRow(overview.defense, 1, "Equipped", tostring(totals.equipped) .. " / " .. tostring(totals.slots))
    self:SetStatRow(overview.defense, 2, "Avg Item Level", average)
    self:SetStatRow(overview.defense, 3, "Armor", armor)
    self:SetStatRow(overview.defense, 4, "Dodge", GetDodgeChance and self:FormatPercent(GetDodgeChance()) or "-")
    self:SetStatRow(overview.defense, 5, "Parry", GetParryChance and self:FormatPercent(GetParryChance()) or "-")
    self:SetStatRow(overview.defense, 6, "Block", GetBlockChance and self:FormatPercent(GetBlockChance()) or "-")

    self:SetStatRow(overview.resistances, 1, "Fire", self:GetResistance(2))
    self:SetStatRow(overview.resistances, 2, "Nature", self:GetResistance(3))
    self:SetStatRow(overview.resistances, 3, "Frost", self:GetResistance(4))
    self:SetStatRow(overview.resistances, 4, "Shadow", self:GetResistance(5))
    self:SetStatRow(overview.resistances, 5, "Arcane", self:GetResistance(6))

    local progression = S.Progression and S.Progression:GetDisplayData(name) or nil
    local tierText = progression and progression.tier or "Unknown"

    if progression and progression.level ~= nil then
        tierText = tierText .. " (" .. tostring(progression.level) .. ")"
    end

    self:SetStatRow(overview.progression, 1, "Current Tier", tierText)
    self:SetStatRow(overview.progression, 2, "Next Objective", progression and progression.objective or "Helper pending")
    self:SetStatRow(overview.progression, 3, "Source", progression and progression.source or "pending")
    self:SetStatRow(overview.progression, 4, "Updated", progression and self:GetRelativeTimeText(progression.updated) or "-")

    self:SetStatRow(overview.challenges, 1, "Status", "Server module pending")
    self:SetStatRow(overview.challenges, 2, "Active Mode", "None")
    self:SetStatRow(overview.challenges, 3, "Best Run", "-")
    self:SetStatRow(overview.challenges, 4, "Next Reward", "-")

    self.characterOverviewPanel:Show()
end

function Shell:CreateCharacterStatsPanel()
    if self.characterStatsPanel then
        return
    end

    local panel = CreateFrame("Frame", nil, self.detailContent)
    panel:SetPoint("TOPLEFT", self.contentSubtitle, "BOTTOMLEFT", 0, -22)
    panel:SetPoint("BOTTOMRIGHT", self.detailContent, "BOTTOMRIGHT", 0, 0)
    panel:Hide()
    self.characterStatsPanel = panel
    self:AddDynamicFrame(panel)

    local summary = self:CreateStatGroup(panel, "Summary", 6, 276, 146)
    summary:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)

    local attributes = self:CreateStatGroup(panel, "Attributes", 5, 276, 128)
    attributes:SetPoint("TOPLEFT", summary, "TOPRIGHT", 14, 0)

    local combat = self:CreateStatGroup(panel, "Combat", 8, 276, 182)
    combat:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -14)

    local defense = self:CreateStatGroup(panel, "Defense", 6, 276, 146)
    defense:SetPoint("TOPLEFT", combat, "TOPRIGHT", 14, 0)

    local resistances = self:CreateStatGroup(panel, "Resistances", 5, 276, 128)
    resistances:SetPoint("TOPLEFT", combat, "BOTTOMLEFT", 0, -14)

    local progression = self:CreateStatGroup(panel, "Individual Progression", 4, 276, 110)
    progression:SetPoint("TOPLEFT", resistances, "TOPRIGHT", 14, 0)

    local challenges = self:CreateStatGroup(panel, "Challenge Modes", 4, 276, 110)
    challenges:SetPoint("TOPLEFT", progression, "BOTTOMLEFT", 0, -14)

    self.characterStatGroups = {
        summary = summary,
        attributes = attributes,
        combat = combat,
        defense = defense,
        resistances = resistances,
        progression = progression,
        challenges = challenges,
    }
end

function Shell:GetEffectiveStat(index)
    if not UnitStat then
        return "-"
    end

    local _, effective, positive, negative = UnitStat("player", index)
    local text = self:FormatNumber(effective)
    positive = tonumber(positive) or 0
    negative = tonumber(negative) or 0

    if positive ~= 0 or negative ~= 0 then
        text = text .. " (" .. self:FormatNumber(positive + negative) .. ")"
    end

    return text
end

function Shell:GetAttackPower()
    if not UnitAttackPower then
        return "-"
    end

    local base, positive, negative = UnitAttackPower("player")
    return self:FormatNumber((base or 0) + (positive or 0) + (negative or 0))
end

function Shell:GetSpellPower()
    if not GetSpellBonusDamage then
        return "-"
    end

    local highest = 0

    for school = 2, 7 do
        local value = GetSpellBonusDamage(school) or 0

        if value > highest then
            highest = value
        end
    end

    return self:FormatNumber(highest)
end

function Shell:GetCombatRatingBonus(name)
    if not GetCombatRatingBonus or not _G[name] then
        return "-"
    end

    return self:FormatPercent(GetCombatRatingBonus(_G[name]))
end

function Shell:GetDefenseValue()
    if not UnitDefense then
        return "-"
    end

    local base, modifier = UnitDefense("player")
    return self:FormatNumber((base or 0) + (modifier or 0))
end

function Shell:GetResistance(index)
    if not UnitResistance then
        return "-"
    end

    local _, resistance = UnitResistance("player", index)
    return self:FormatNumber(resistance)
end

function Shell:GetRelativeTimeText(timestamp)
    timestamp = tonumber(timestamp)

    if not timestamp or timestamp <= 0 or not time then
        return "-"
    end

    local elapsed = time() - timestamp

    if elapsed < 0 then
        elapsed = 0
    end

    if elapsed < 60 then
        return "just now"
    end

    if elapsed < 3600 then
        return self:FormatNumber(elapsed / 60) .. " min ago"
    end

    if elapsed < 86400 then
        return self:FormatNumber(elapsed / 3600) .. " hr ago"
    end

    return self:FormatNumber(elapsed / 86400) .. " days ago"
end

function Shell:UpdateCharacterStatsPanel()
    self:CreateCharacterStatsPanel()

    local groups = self.characterStatGroups
    local name = S.Utils.GetUnitName("player") or "-"
    local race = UnitRace and UnitRace("player") or "-"
    local class = UnitClass and UnitClass("player") or "-"
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "-"
    local level = UnitLevel and UnitLevel("player") or nil
    local health = self:FormatPair(UnitHealth and UnitHealth("player") or nil, UnitHealthMax and UnitHealthMax("player") or nil)
    local armor = "-"

    if UnitArmor then
        local _, effective = UnitArmor("player")
        armor = self:FormatNumber(effective)
    end

    self:SetStatRow(groups.summary, 1, "Name", name)
    self:SetStatRow(groups.summary, 2, "Level", self:FormatNumber(level))
    self:SetStatRow(groups.summary, 3, "Race", race)
    self:SetStatRow(groups.summary, 4, "Class", class)
    self:SetStatRow(groups.summary, 5, "Faction", faction)
    self:SetStatRow(groups.summary, 6, "Health", health)

    self:SetStatRow(groups.attributes, 1, "Strength", self:GetEffectiveStat(1))
    self:SetStatRow(groups.attributes, 2, "Agility", self:GetEffectiveStat(2))
    self:SetStatRow(groups.attributes, 3, "Stamina", self:GetEffectiveStat(3))
    self:SetStatRow(groups.attributes, 4, "Intellect", self:GetEffectiveStat(4))
    self:SetStatRow(groups.attributes, 5, "Spirit", self:GetEffectiveStat(5))

    self:SetStatRow(groups.combat, 1, "Power", self:GetPowerText("player"))
    self:SetStatRow(groups.combat, 2, "Attack Power", self:GetAttackPower())
    self:SetStatRow(groups.combat, 3, "Melee Crit", GetCritChance and self:FormatPercent(GetCritChance()) or "-")
    self:SetStatRow(groups.combat, 4, "Melee Hit", self:GetCombatRatingBonus("CR_HIT_MELEE"))
    self:SetStatRow(groups.combat, 5, "Melee Haste", GetMeleeHaste and self:FormatPercent(GetMeleeHaste()) or "-")
    self:SetStatRow(groups.combat, 6, "Spell Power", self:GetSpellPower())
    self:SetStatRow(groups.combat, 7, "Healing", GetSpellBonusHealing and self:FormatNumber(GetSpellBonusHealing()) or "-")
    self:SetStatRow(groups.combat, 8, "Spell Hit", self:GetCombatRatingBonus("CR_HIT_SPELL"))

    self:SetStatRow(groups.defense, 1, "Armor", armor)
    self:SetStatRow(groups.defense, 2, "Defense", self:GetDefenseValue())
    self:SetStatRow(groups.defense, 3, "Dodge", GetDodgeChance and self:FormatPercent(GetDodgeChance()) or "-")
    self:SetStatRow(groups.defense, 4, "Parry", GetParryChance and self:FormatPercent(GetParryChance()) or "-")
    self:SetStatRow(groups.defense, 5, "Block", GetBlockChance and self:FormatPercent(GetBlockChance()) or "-")
    self:SetStatRow(groups.defense, 6, "Resilience", GetCombatRating and _G.CR_CRIT_TAKEN_MELEE and self:FormatNumber(GetCombatRating(_G.CR_CRIT_TAKEN_MELEE)) or "-")

    self:SetStatRow(groups.resistances, 1, "Fire", self:GetResistance(2))
    self:SetStatRow(groups.resistances, 2, "Nature", self:GetResistance(3))
    self:SetStatRow(groups.resistances, 3, "Frost", self:GetResistance(4))
    self:SetStatRow(groups.resistances, 4, "Shadow", self:GetResistance(5))
    self:SetStatRow(groups.resistances, 5, "Arcane", self:GetResistance(6))

    local progression = S.Progression and S.Progression:GetDisplayData(name) or nil
    local tierText = progression and progression.tier or "Unknown"

    if progression and progression.level ~= nil then
        tierText = tierText .. " (" .. tostring(progression.level) .. ")"
    end

    self:SetStatRow(groups.progression, 1, "Current Tier", tierText)
    self:SetStatRow(groups.progression, 2, "Next Objective", progression and progression.objective or "Helper pending")
    self:SetStatRow(groups.progression, 3, "Source", progression and progression.source or "pending")
    self:SetStatRow(groups.progression, 4, "Updated", progression and self:GetRelativeTimeText(progression.updated) or "-")

    self:SetStatRow(groups.challenges, 1, "Status", "Server module pending")
    self:SetStatRow(groups.challenges, 2, "Active Mode", "None")
    self:SetStatRow(groups.challenges, 3, "Best Run", "-")
    self:SetStatRow(groups.challenges, 4, "Next Reward", "-")

    self.characterStatsPanel:Show()
end

function Shell:RenderContent()
    local area = self.areaMap[self.currentArea] or self.areaMap.Shell
    local section = self.currentSection or area.defaultSection
    local sectionLabel = self:GetSectionLabel(area.key, section)

    self:HideDynamicContent()
    self.contentTitle:SetText(sectionLabel)

    if area.key == "PartyRaid" then
        local member = self:GetSelectedMember()

        if member then
            local details = member.kind

            if member.className ~= "" then
                details = details .. " - " .. member.className
            end

            if member.level and member.level > 0 then
                details = details .. " - Level " .. member.level
            end

            self.contentSubtitle:SetText(member.name .. "\n" .. details)

            if section == "Stats" then
                self:ShowMemberStatsPanel(member)
            end
        else
            self.contentSubtitle:SetText("No party or raid members found.")
        end
    elseif area.key == "Character" then
        local name = S.Utils.GetUnitName("player") or "Character"
        self.contentSubtitle:SetText(name)

        if section == "Stats" or section == "Gear" or section == "Inventory" then
            self:UpdateCharacterOverviewPanel()
        end
    else
        self.contentSubtitle:SetText("")

        if area.key == "Shell" and section == "Modules" then
            self:ShowModuleControls()
        end
    end
end

function Shell:Refresh()
    if self.currentArea == "PartyRaid" then
        self:RefreshRoster()
        self:BuildMemberTabs()
    end

    self:RenderContent()
end

S:RegisterModule("Shell", Shell)
