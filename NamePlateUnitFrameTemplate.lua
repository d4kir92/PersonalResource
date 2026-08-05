local _, PersonalResource = ...
function PersonalResource:CreateBlizzardStyleUnitFrame(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetSize(width, height)
    statusBar:SetPoint("CENTER", frame, "CENTER")
    statusBar:SetStatusBarTexture("UI-HUD-CoolDownManager-Bar")
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetAtlas("UI-HUD-CoolDownManager-Bar-BG")
    bg:SetVertexColor(0.25, 0.25, 0.25, 0.75)
    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetSize(width + 4, height + 4)
    border:SetPoint("CENTER", frame, "CENTER")
    border:SetAtlas("ui-hud-nameplates-deselected-overlay")
    border:SetVertexColor(0.8, 0.8, 0.8, 0.5)
    local textFrame = CreateFrame("Frame", nil, frame)
    textFrame:SetSize(width, height)
    textFrame:SetPoint("CENTER", frame, "CENTER")
    local leftText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftText:SetPoint("LEFT", textFrame, "LEFT", 2, 0)
    leftText:SetJustifyH("LEFT")
    local centerText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    centerText:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    local rightText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightText:SetPoint("RIGHT", textFrame, "RIGHT", -2, 0)
    rightText:SetJustifyH("RIGHT")
    return {
        frame = frame,
        statusBar = statusBar,
        leftText = leftText,
        centerText = centerText,
        rightText = rightText
    }
end

function PersonalResource:UpdateNamePlateTemplate(template, unit)
end
