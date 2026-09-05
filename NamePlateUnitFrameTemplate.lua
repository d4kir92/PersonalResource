local _, PersonalResource = ...
local BG_LEFT = -2
local BG_TOP = 3
local BG_RIGHT = 6
local BG_BOTTOM = 7
local BORDER_TOP = 1
local BORDER_BOTTOM = 1
local OVERHANG_TOP = 2
local OVERHANG_BOTTOM = 2
local COMBO_SHADOWOFFSET = 0.2
local COMBO_ATLAS_SHADOW = "uf-roguecp-bg-shadow"
local COMBO_ATLAS_BGACTIVE = "uf-roguecp-bg"
local COMBO_ATLAS_BGINACTIVE = "uf-roguecp-bg-dis"
local COMBO_ATLAS_ICON = "uf-roguecp-icon-red"
local COMBO_FALLBACKTEXTURE = "Interface\\ComboFrame\\ComboPoint"
local COMBO_FALLBACK_BG = {0, 0.375, 0, 1}
local COMBO_FALLBACK_ICON = {0.375, 0.5625, 0, 1}
local function HasAtlas(atlas)
    if C_Texture == nil then return false end
    if C_Texture.GetAtlasInfo == nil then return false end

    return C_Texture.GetAtlasInfo(atlas) ~= nil
end

function PersonalResource:GetUnitFrameOverhang()
    return OVERHANG_TOP, OVERHANG_BOTTOM
end

function PersonalResource:UsesComboPointAtlas()
    if not HasAtlas(COMBO_ATLAS_BGACTIVE) then return false end
    if not HasAtlas(COMBO_ATLAS_BGINACTIVE) then return false end
    if not HasAtlas(COMBO_ATLAS_ICON) then return false end

    return true
end

function PersonalResource:CreateComboPoint(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(20, 20)
    local shadow = frame:CreateTexture(nil, "BACKGROUND")
    local bgInactive = frame:CreateTexture(nil, "BORDER")
    bgInactive:SetAllPoints(frame)
    local bgActive = frame:CreateTexture(nil, "BORDER")
    bgActive:SetAllPoints(frame)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)
    if PersonalResource:UsesComboPointAtlas() then
        if HasAtlas(COMBO_ATLAS_SHADOW) then
            shadow:SetAtlas(COMBO_ATLAS_SHADOW)
        else
            shadow:Hide()
        end

        bgInactive:SetAtlas(COMBO_ATLAS_BGINACTIVE)
        bgActive:SetAtlas(COMBO_ATLAS_BGACTIVE)
        icon:SetAtlas(COMBO_ATLAS_ICON)
    else
        shadow:Hide()
        bgInactive:SetTexture(COMBO_FALLBACKTEXTURE)
        bgInactive:SetTexCoord(unpack(COMBO_FALLBACK_BG))
        bgInactive:SetVertexColor(0.35, 0.35, 0.35, 1)
        bgActive:SetTexture(COMBO_FALLBACKTEXTURE)
        bgActive:SetTexCoord(unpack(COMBO_FALLBACK_BG))
        bgActive:SetVertexColor(1, 1, 1, 1)
        icon:SetTexture(COMBO_FALLBACKTEXTURE)
        icon:SetTexCoord(unpack(COMBO_FALLBACK_ICON))
    end

    bgActive:Hide()
    icon:Hide()

    return {
        frame = frame,
        shadow = shadow,
        bgActive = bgActive,
        bgInactive = bgInactive,
        icon = icon
    }
end

function PersonalResource:SetComboPointSize(point, size)
    if point == nil then return end
    point.frame:SetSize(size, size)
    local offset = size * COMBO_SHADOWOFFSET
    point.shadow:ClearAllPoints()
    point.shadow:SetPoint("TOPLEFT", point.frame, "TOPLEFT", 0, -offset)
    point.shadow:SetPoint("BOTTOMRIGHT", point.frame, "BOTTOMRIGHT", 0, -offset)
end

function PersonalResource:SetComboPointFull(point, full)
    if point == nil then return end
    point.bgActive:SetShown(full)
    point.icon:SetShown(full)
    point.bgInactive:SetShown(not full)
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
