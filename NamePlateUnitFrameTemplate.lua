local _, PersonalResource = ...
function PersonalResource:CreateBlizzardStyleUnitFrame(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    frame:SetScale(1)
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetSize(width, height)
    statusBar:SetPoint("CENTER", frame, "CENTER")
    statusBar:SetStatusBarTexture("UI-HUD-CoolDownManager-Bar")
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAtlas("UI-HUD-CoolDownManager-Bar-BG")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 3)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -7)
    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 1)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -1)
    border:SetAtlas("ui-hud-nameplates-deselected-overlay")
    local textFrame = CreateFrame("Frame", nil, frame)
    textFrame:SetSize(width, height)
    textFrame:SetPoint("CENTER", frame, "CENTER")
    local leftText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftText:SetPoint("LEFT", textFrame, "LEFT", 4, 0)
    leftText:SetJustifyH("LEFT")
    local centerText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    centerText:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    local rightText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightText:SetPoint("RIGHT", textFrame, "RIGHT", -4, 0)
    rightText:SetJustifyH("RIGHT")
    return {
        frame = frame,
        statusBar = statusBar,
        textFrame = textFrame,
        leftText = leftText,
        centerText = centerText,
        rightText = rightText
    }
end

function PersonalResource:SetUnitFrameSize(template, width, height)
    if template == nil then return end
    template.frame:SetSize(width, height)
    template.statusBar:SetSize(width, height)
    template.textFrame:SetSize(width, height)
end

function PersonalResource:UpdateNamePlateTemplate(template, unit)
end
