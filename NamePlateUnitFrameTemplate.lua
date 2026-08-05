local _, PersonalResource = ...
function PersonalResource:CreateBlizzardStyleUnitFrame(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetSize(width, height)
    statusBar:SetPoint("CENTER", frame, "CENTER")
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.25, 0.25, 0.25, 0.75)
    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetSize(width + 4, height + 4)
    border:SetPoint("CENTER", frame, "CENTER")
    border:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    border:SetVertexColor(0.8, 0.8, 0.8, 0.5)
    local leftText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftText:SetPoint("LEFT", frame, "LEFT", 2, 0)
    leftText:SetJustifyH("LEFT")
    local centerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    centerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    local rightText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightText:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
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
