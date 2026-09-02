local _, PersonalResource = ...
local BG_LEFT = -2
local BG_TOP = 3
local BG_RIGHT = 6
local BG_BOTTOM = 7
local BORDER_TOP = 1
local BORDER_BOTTOM = 1
local OVERHANG_TOP = 2
local OVERHANG_BOTTOM = 2
function PersonalResource:GetUnitFrameOverhang()
    return OVERHANG_TOP, OVERHANG_BOTTOM
end

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
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", BG_LEFT, BG_TOP)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", BG_RIGHT, -BG_BOTTOM)
    bg:SetVertexColor(1, 1, 1, 1)
    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, BORDER_TOP)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -BORDER_BOTTOM)
    border:SetAtlas("ui-hud-nameplates-deselected-overlay")
    border:SetVertexColor(1, 1, 1, 1)
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
