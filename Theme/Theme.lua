local S = _G.SableUI

S.Theme = S.Theme or {}

local Theme = S.Theme

function Theme:Initialize()
    self.profile = S.profile and S.profile.theme or S.defaultTheme
    self:TryRegisterSharedMedia()
end

function Theme:TryRegisterSharedMedia()
    if not LibStub then
        return
    end

    local media = LibStub("LibSharedMedia-3.0", true)

    if not media then
        return
    end

    media:Register("font", "Sable Normal", self:GetFont("normal"))
    media:Register("font", "Sable Bold", self:GetFont("bold"))
    media:Register("statusbar", "Sable Status", self:GetTexture("statusbar"))
end

function Theme:GetFont(key)
    local fonts = self.profile and self.profile.fonts or S.defaultTheme.fonts
    return fonts[key] or S.defaultTheme.fonts.normal
end

function Theme:GetTexture(key)
    local textures = self.profile and self.profile.textures or S.defaultTheme.textures
    return textures[key] or S.defaultTheme.textures.statusbar
end

function Theme:GetColorTable(key)
    local colors = self.profile and self.profile.colors or S.defaultTheme.colors
    return colors[key] or S.defaultTheme.colors.text
end

function Theme:GetColor(key)
    local color = self:GetColorTable(key)
    return color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1, color[4] or color.a or 1
end

function Theme:ApplyTextColor(fontString, key)
    if fontString and fontString.SetTextColor then
        fontString:SetTextColor(self:GetColor(key or "text"))
    end
end

function Theme:ApplyBackdrop(frame, variant)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = self:GetTexture("background"),
        edgeFile = self:GetTexture("border"),
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    frame:SetBackdropColor(self:GetColor(variant or "panel"))
    frame:SetBackdropBorderColor(self:GetColor("border"))
end

function Theme:CreateFontString(parent, name, size, style)
    local fontString = parent:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(self:GetFont(name or "normal"), size or 12, style or "")
    fontString:SetTextColor(self:GetColor("text"))
    return fontString
end

function Theme:StyleButton(button)
    if not button then
        return
    end

    if button.SetBackdrop then
        self:ApplyBackdrop(button, "panelAlt")
    end

    local fontString = button:GetFontString()

    if fontString then
        fontString:SetFont(self:GetFont("normal"), 11, "")
        fontString:SetTextColor(self:GetColor("text"))
    end
end
