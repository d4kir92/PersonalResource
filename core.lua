local _, PersonalResource = ...
local oldPowerType = nil
local oldShapeshift = nil
local oldPetState = nil
local LOWHEALTHPCT = 0.35
local GRIDSIZE = 5
local VISIBILITYINTERVAL = 0.1
local MANAPOWERTYPE = 0
local RAGEPOWERTYPE = 1
local ENERGYPOWERTYPE = 3
local COMBOPOWERTYPE = 4
local BARKEYS = {"HEALTH", "POWER", "MANA", "COMBO"}
local DRUIDBARKEYS = {"HEALTH", "ENERGY", "MANA", "COMBO", "RAGE"}
local DRUIDPOWERTYPES = {MANA = MANAPOWERTYPE, ENERGY = ENERGYPOWERTYPE, RAGE = RAGEPOWERTYPE}
local druidBars = {}
local PETBARKEYS = {"HEALTH", "POWER"}
local HIDEWHENFULLKEYS = {"HIDEWHENFULLHP", "HIDEWHENFULLPOWER", "PETHIDEWHENFULLHP", "PETHIDEWHENFULLPOWER"}
local function GetCfg(key, default)
    PersonalResourceG = PersonalResourceG or {}
    return PersonalResource:GV(PersonalResourceG, key, default)
end

function PersonalResource:IsDruid()
    local _, class = UnitClass("player")
    return class == "DRUID"
end

function PersonalResource:AlwaysShowDruidResource(key)
    return GetCfg("ALWAYSSHOWDRUID" .. key, GetCfg("ALWAYSSHOWDRUIDPOWER", false))
end

local function AlwaysShowDruidPower()
    return PersonalResource:IsDruid() and (PersonalResource:AlwaysShowDruidResource("ENERGY") or PersonalResource:AlwaysShowDruidResource("RAGE"))
end

local function GetDruidPowerKey(powerType)
    for key, value in pairs(DRUIDPOWERTYPES) do
        if value == powerType then return key end
    end
end

local function GetResourceFraction(cur, max)
    if not PersonalResource:CanAccessValues(cur, max) then return nil end
    if max <= 0 then return 0 end
    return cur / max
end

local function SetBarTexts(template, showPercent, percent, showValue, showMax, cur, max)
    if showPercent then
        template.leftText:SetFormattedText("%d%%", percent)
    else
        template.leftText:SetText("")
    end

    if showValue and showMax then
        template.rightText:SetFormattedText("%d / %d", cur, max)
    elseif showValue then
        template.rightText:SetFormattedText("%d", cur)
    elseif showMax then
        template.rightText:SetFormattedText("%d", max)
    else
        template.rightText:SetText("")
    end
end

local function GetHealthTextPercent(unit, enabled, fraction)
    if not enabled then return false, 0 end
    if fraction then return true, fraction * 100 end
    if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        return true, UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
    end
    return false, 0
end

local function GetPowerTextPercent(unit, enabled, fraction, powerType)
    if not enabled then return false, 0 end
    if fraction then return true, fraction * 100 end
    if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
        return true, UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100)
    end
    return false, 0
end

local gridFrame = nil
local function ShowMoveHelpers(moveOverlay, show)
    if show then
        if gridFrame == nil then
            PersonalResource:SetGridSize(GRIDSIZE)
            gridFrame = PersonalResource:CreateGrid()
        end

        gridFrame:Show()
        moveOverlay:Show()
    else
        if gridFrame then gridFrame:Hide() end
        moveOverlay:Hide()
    end
end

local function CreateMovableFrame(name, dbKey)
    local movable = CreateFrame("Frame", name, UIParent)
    movable:SetSize(200, 100)
    movable:SetMovable(true)
    movable:EnableMouse(true)
    local moveOverlay = CreateFrame("Frame", name .. "MoveOverlay", movable)
    moveOverlay:SetAllPoints(movable)
    moveOverlay:SetFrameLevel(movable:GetFrameLevel() + 10)
    moveOverlay:EnableMouse(false)
    moveOverlay:Hide()
    local crossHor = moveOverlay:CreateTexture(nil, "OVERLAY")
    crossHor:SetColorTexture(1, 1, 1, 1)
    crossHor:SetHeight(1)
    crossHor:SetPoint("LEFT", moveOverlay, "LEFT", 0, 0)
    crossHor:SetPoint("RIGHT", moveOverlay, "RIGHT", 0, 0)
    local crossVer = moveOverlay:CreateTexture(nil, "OVERLAY")
    crossVer:SetColorTexture(1, 1, 1, 1)
    crossVer:SetWidth(1)
    crossVer:SetPoint("TOP", moveOverlay, "TOP", 0, 0)
    crossVer:SetPoint("BOTTOM", moveOverlay, "BOTTOM", 0, 0)
    local moving = false
    local function StopMoving()
        if moving then
            moving = false
            movable:StopMovingOrSizing()
            ShowMoveHelpers(moveOverlay, false)
            local point, _, relativePoint, xOfs, yOfs = movable:GetPoint()
            if not point then return end
            if xOfs < 15 and xOfs > -15 then xOfs = 0 end
            if yOfs < 15 and yOfs > -15 then yOfs = 0 end
            if not PersonalResourceG then PersonalResourceG = {} end
            if not PersonalResourceG[dbKey] then PersonalResourceG[dbKey] = {} end
            PersonalResourceG[dbKey]["position"] = {point, relativePoint, xOfs, yOfs}
            movable:ClearAllPoints()
            movable:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
        end
    end
    movable:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            movable:StartMoving()
            moving = true
            ShowMoveHelpers(moveOverlay, true)
        end
    end)
    movable:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then StopMoving() end
    end)
    movable:SetScript("OnHide", StopMoving)
    return movable
end

local function RestoreFramePosition(movable, dbKey)
    if PersonalResourceG == nil then return end
    if PersonalResourceG[dbKey] == nil then return end
    if PersonalResourceG[dbKey]["position"] == nil then return end
    local point, relativePoint, xOfs, yOfs = unpack(PersonalResourceG[dbKey]["position"])
    if xOfs < 15 and xOfs > -15 then xOfs = 0 end
    if yOfs < 15 and yOfs > -15 then yOfs = 0 end
    movable:ClearAllPoints()
    movable:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
end

local nativeFrame
local nativeLayoutPending = false
local nativeDruidPowerActive = false
local nativeOrderScheduled = false
local nativeComboFrame
local nativeTexts = {}
local frame
local hpTemplate, hpBar
local powerTemplate, powerBar
local manaTemplate, manaBar
local comboFrame
local comboPoints = {}
local barTemplates = {}

function PersonalResource:UsesNativeDisplay()
    return nativeFrame ~= nil
end

local function EnableNativeDisplay()
    if not PersonalResourceDisplayFrame and C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_PersonalResourceDisplay")
    end

    local display = PersonalResourceDisplayFrame
    if not display or not display.UpdateShownState then return end
    local getCVar = C_CVar and C_CVar.GetCVar or GetCVar
    local setCVar = C_CVar and C_CVar.SetCVar or SetCVar
    if getCVar and setCVar and getCVar("nameplateShowSelf") == "0" then
        setCVar("nameplateShowSelf", "1")
    end
    if C_GameRules and C_GameRules.IsPersonalResourceDisplayEnabled and not C_GameRules.IsPersonalResourceDisplayEnabled() then return end
    local visibility = Enum and Enum.PersonalResourceDisplayVisibleSetting
    if visibility and visibility.Never and display.GetVisibleSetting and display.SetVisibleSetting and display:GetVisibleSetting() == visibility.Never then
        display:SetVisibleSetting(visibility.Always)
    else
        display:UpdateShownState()
    end
    return display
end

local function CreatePlayerFrame()
    frame = CreateMovableFrame("PersonalResourceFrame", "mainFrame")
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
    hpTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(frame, 200, 19)
    hpTemplate.frame:SetPoint("TOP", frame, "TOP", 0, 0)
    hpBar = hpTemplate.statusBar
    local hpLeftText = hpTemplate.leftText
    local hpRightText = hpTemplate.rightText
    hpLeftText:SetTextColor(1, 1, 1, 1)
    hpRightText:SetTextColor(1, 1, 1, 1)
    powerTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(frame, 200, 19)
    powerTemplate.frame:SetPoint("TOP", hpTemplate.frame, "BOTTOM", 0, -5)
    powerBar = powerTemplate.statusBar
    local powerLeftText = powerTemplate.leftText
    local powerRightText = powerTemplate.rightText
    powerLeftText:SetTextColor(1, 1, 1, 1)
    powerRightText:SetTextColor(1, 1, 1, 1)
    manaTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(frame, 200, 19)
    manaTemplate.frame:SetPoint("TOP", powerTemplate.frame, "BOTTOM", 0, -5)
    manaTemplate.frame:Hide()
    manaBar = manaTemplate.statusBar
    manaTemplate.leftText:SetTextColor(1, 1, 1, 1)
    manaTemplate.rightText:SetTextColor(1, 1, 1, 1)
    comboFrame = CreateFrame("Frame", nil, frame)
    comboFrame:SetSize(200, 20)
    comboFrame:SetPoint("TOP", manaTemplate.frame, "BOTTOM", 0, -5)
    comboFrame:Hide()
    barTemplates.HEALTH = hpTemplate
    barTemplates.POWER = powerTemplate
    barTemplates.MANA = manaTemplate
    barTemplates.COMBO = {frame = comboFrame}
    RestoreFramePosition(frame, "mainFrame")
end

local petFrame = CreateMovableFrame("PersonalResourcePetFrame", "petFrame")
petFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
petFrame:Hide()
local petHPTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(petFrame, 150, 14)
petHPTemplate.frame:SetPoint("TOP", petFrame, "TOP", 0, 0)
local petHPBar = petHPTemplate.statusBar
petHPTemplate.leftText:SetTextColor(1, 1, 1, 1)
petHPTemplate.rightText:SetTextColor(1, 1, 1, 1)
local petPowerTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(petFrame, 150, 14)
petPowerTemplate.frame:SetPoint("TOP", petHPTemplate.frame, "BOTTOM", 0, -5)
local petPowerBar = petPowerTemplate.statusBar
petPowerTemplate.leftText:SetTextColor(1, 1, 1, 1)
petPowerTemplate.rightText:SetTextColor(1, 1, 1, 1)
local petBarTemplates = {
    ["HEALTH"] = petHPTemplate,
    ["POWER"] = petPowerTemplate
}

function PersonalResource:HasSecondaryMana()
    local unit = "player"
    if not UnitExists(unit) then return false end
    if UnitPowerType(unit) == MANAPOWERTYPE then return false end
    local maxMana = UnitPowerMax(unit, MANAPOWERTYPE)
    return not PersonalResource:CanAccessValue(maxMana) or maxMana > 0
end

local function GetMaxComboPoints()
    local maxPoints = UnitPowerMax("player", COMBOPOWERTYPE)
    if not PersonalResource:CanAccessValue(maxPoints) or not maxPoints or maxPoints <= 0 then maxPoints = MAX_COMBO_POINTS or 5 end
    return maxPoints
end

local function GetCurrentComboPoints()
    if GetComboPoints and not PersonalResource:IsForever() then return GetComboPoints("player", "target") end
    return UnitPower("player", COMBOPOWERTYPE)
end

local function EnsureComboPoints(count)
    for i = #comboPoints + 1, count do
        comboPoints[i] = PersonalResource:CreateComboPoint(comboFrame)
    end
end

function PersonalResource:HasComboPoints()
    local unit = "player"
    if not GetCfg("SHOWCOMBOPOINTS", true) then return false end
    if not UnitExists(unit) then return false end
    local _, class = UnitClass(unit)
    if class == "ROGUE" then return true end
    if class == "DRUID" then return UnitPowerType(unit) == ENERGYPOWERTYPE end
    return false
end

local function BuildBarOrder(prefix, keys)
    local order = {}
    local used = {}
    for index, default in ipairs(keys) do
        local key = GetCfg(prefix .. index, default)
        if tContains(keys, key) and not used[key] then
            used[key] = true
            table.insert(order, key)
        end
    end
    for _, key in ipairs(keys) do
        if not used[key] then table.insert(order, key) end
    end
    return order
end

function PersonalResource:GetBarOrderPrefix()
    return PersonalResource:IsDruid() and "DRUIDBARSLOT" or "BARSLOT"
end

function PersonalResource:GetBarOrder()
    if not PersonalResource:IsDruid() then return BuildBarOrder("BARSLOT", BARKEYS) end
    if PersonalResourceG and PersonalResourceG.DRUIDBARSLOT1 then return BuildBarOrder("DRUIDBARSLOT", DRUIDBARKEYS) end
    local order = BuildBarOrder("BARSLOT", BARKEYS)
    for index, key in ipairs(order) do
        if key == "POWER" then order[index] = "ENERGY" end
    end
    table.insert(order, "RAGE")
    return order
end

function PersonalResource:GetPetBarOrder()
    return BuildBarOrder("PETBARSLOT", PETBARKEYS)
end

function PersonalResource:UpdateComboLayout(width)
    local size = GetCfg("COMBOPOINTSIZE", 20)
    local spacing = GetCfg("COMBOPOINTSPACING", 4)
    local maxPoints = GetMaxComboPoints()
    EnsureComboPoints(maxPoints)
    comboFrame:SetSize(width, size)
    local total = maxPoints * size + math.max(maxPoints - 1, 0) * spacing
    local first = -total / 2 + size / 2
    for i = 1, #comboPoints do
        local point = comboPoints[i]
        if i <= maxPoints then
            PersonalResource:SetComboPointSize(point, size)
            point.frame:ClearAllPoints()
            point.frame:SetPoint("CENTER", comboFrame, "CENTER", first + (i - 1) * (size + spacing), 0)
            point.frame:Show()
        else
            point.frame:Hide()
        end
    end
    return size
end

function PersonalResource:UpdateComboPoints()
    if not PersonalResource:HasComboPoints() then return end
    local value = GetCurrentComboPoints()
    local readable = PersonalResource:CanAccessValue(value)
    for i = 1, #comboPoints do
        PersonalResource:SetComboPointFull(comboPoints[i], readable and i <= (value or 0))
    end
end

local function NativeHasComboPoints()
    local _, class = UnitClass("player")
    return class == "ROGUE" or class == "DRUID"
end

local function UpdateDruidBarText(bar, powerType)
    local value = UnitPower("player", powerType)
    local maximum = UnitPowerMax("player", powerType)
    if powerType ~= MANAPOWERTYPE and PersonalResource:CanAccessValue(maximum) and maximum <= 0 then maximum = 100 end
    bar.statusBar:SetMinMaxValues(0, maximum)
    bar.statusBar:SetValue(value)
    local showPercent, percent = GetPowerTextPercent("player", GetCfg("SHOWPOWERPERCENTAGE", true), GetResourceFraction(value, maximum), powerType)
    SetBarTexts(bar, showPercent, percent, GetCfg("SHOWPOWERVALUE", true), GetCfg("SHOWMAXPOWERVALUE", false), value, maximum)
end

local function UpdateDruidBarValues()
    for key, bar in pairs(druidBars) do
        if bar.frame:IsShown() then UpdateDruidBarText(bar, DRUIDPOWERTYPES[key]) end
    end
end

local function UpdateDruidExtraBars(parent, primaryType, hasMana)
    for key, powerType in pairs(DRUIDPOWERTYPES) do
        local enabled
        if key == "MANA" then
            enabled = nativeFrame and not nativeFrame.hideAltPower and not hasMana and AlwaysShowDruidPower() and PersonalResource:HasSecondaryMana()
        else
            enabled = PersonalResource:AlwaysShowDruidResource(key)
        end
        local shown = enabled and primaryType ~= powerType
        local bar = druidBars[key]
        if shown and not bar then
            bar = PersonalResource:CreateBlizzardStyleUnitFrame(parent, 200, 19)
            druidBars[key] = bar
            bar.frame:EnableMouse(false)
            bar.leftText:SetTextColor(1, 1, 1, 1)
            bar.rightText:SetTextColor(1, 1, 1, 1)
            local color = PowerBarColor and PowerBarColor[powerType]
            if color then bar.statusBar:SetStatusBarColor(color.r, color.g, color.b) end
        end
        if bar then bar.frame:SetShown(not not shown) end
    end
    UpdateDruidBarValues()
end

local function UpdateNativeOrder()
    if InCombatLockdown() and nativeFrame:IsProtected() then
        nativeLayoutPending = true
        return
    end

    local bars = {
        HEALTH = nativeFrame.HealthBarsContainer,
        POWER = nativeFrame.PowerBar,
        MANA = nativeFrame.AlternatePowerBar,
        COMBO = nativeFrame.ClassFrameContainer
    }
    local classBar = bars.COMBO
    if PersonalResource:IsDruid() then
        local primaryType = UnitPowerType("player")
        local primaryKey = GetDruidPowerKey(primaryType) or "COMBO"
        local alternate = bars.MANA
        local duplicateMana = primaryKey == "MANA"
        local hasAlternate = alternate and alternate:IsShown() and not duplicateMana
        if alternate then alternate:SetAlpha(duplicateMana and 0 or 1) end
        if not hasAlternate then bars.MANA = nil end
        bars[primaryKey] = bars.POWER
        UpdateDruidExtraBars(nativeFrame, primaryType, hasAlternate)
        for key, bar in pairs(druidBars) do
            if bar.frame:IsShown() then
                PersonalResource:SetUnitFrameSize(bar, GetCfg("BARWIDTH", 200), GetCfg("BARHEIGHT", 19))
                bars[key] = bar.frame
            end
        end
    end
    local offset = 0
    local spacing = GetCfg("BARSPACING", 0)
    local hasBar = false
    for _, key in ipairs(PersonalResource:GetBarOrder()) do
        local bar = bars[key]
        if bar and bar:IsShown() and (bar ~= classBar or not nativeFrame.HasClassInfo or nativeFrame:HasClassInfo()) then
            if hasBar then offset = offset + spacing end
            if bar == classBar and not NativeHasComboPoints() then offset = offset - (bar.yOffset or 0) end
            bar:ClearAllPoints()
            bar:SetPoint("TOP", nativeFrame, "TOP", 0, -offset)
            offset = offset + bar:GetHeight()
            hasBar = true
        end
    end
    local minimum = nativeFrame.GetMinimumFrameHeight and nativeFrame:GetMinimumFrameHeight() or 1
    nativeFrame:SetHeight(math.max(offset, minimum))
end

local function ScheduleNativeOrder()
    if nativeOrderScheduled then return end
    nativeOrderScheduled = true
    C_Timer.After(0, function()
        nativeOrderScheduled = false
        UpdateNativeOrder()
    end)
end

local function ShowNativeDruidDisplay()
    if not AlwaysShowDruidPower() or nativeFrame:IsShown() then return end
    if C_GameRules and C_GameRules.IsPersonalResourceDisplayEnabled and not C_GameRules.IsPersonalResourceDisplayEnabled() then return end
    if not InCombatLockdown() or not nativeFrame:IsProtected() then nativeFrame:Show() end
end

local function SyncNativeDruidPowerBar()
    local bar = nativeFrame.PowerBar
    if not bar or nativeFrame.isInEditMode then return end
    local alwaysShow = AlwaysShowDruidPower()
    if not alwaysShow and not nativeDruidPowerActive then return end
    local shown = alwaysShow or not nativeFrame.hidePower
    if bar:IsShown() == shown then return end
    if InCombatLockdown() and bar:IsProtected() then return end
    bar:SetShown(shown)
    ScheduleNativeOrder()
end

function PersonalResource:UpdateDruidPowerVisibility()
    local alwaysShow = AlwaysShowDruidPower()
    if nativeFrame and not nativeFrame.isInEditMode and (alwaysShow or nativeDruidPowerActive) then
        nativeFrame:UpdateShownState()
        SyncNativeDruidPowerBar()
        if not InCombatLockdown() or alwaysShow then nativeDruidPowerActive = alwaysShow end
    end
    if nativeFrame then ScheduleNativeOrder() end
    PersonalResource:UpdateVisibility()
end

local function UpdateNativeComboLayout()
    local classFrame = nativeFrame.classFrame
    if not classFrame or not NativeHasComboPoints() then return end
    if nativeFrame.SetHideClassInfo then
        local hide = not GetCfg("SHOWCOMBOPOINTS", true)
        if (not not nativeFrame.hideClassInfo) ~= hide then nativeFrame:SetHideClassInfo(hide) end
    end

    if nativeComboFrame ~= classFrame then
        nativeComboFrame = classFrame
        classFrame:HookScript("OnShow", ScheduleNativeOrder)
        classFrame:HookScript("OnHide", ScheduleNativeOrder)
        if classFrame.UpdateMaxPower then
            hooksecurefunc(classFrame, "UpdateMaxPower", function()
                C_Timer.After(0, function()
                    if InCombatLockdown() then
                        nativeLayoutPending = true
                    else
                        UpdateNativeComboLayout()
                        UpdateNativeOrder()
                    end
                end)
            end)
        end
    end

    local points = classFrame.classResourceButtonTable
    if not points or #points == 0 then return end
    local size = GetCfg("COMBOPOINTSIZE", 20)
    local spacing = GetCfg("COMBOPOINTSPACING", 4)
    local step = size + spacing
    nativeFrame.ClassFrameContainer:SetHeight(GetCfg("BARHEIGHT", 19))
    for index, point in ipairs(points) do
        local width = point:GetWidth() * point:GetScale()
        if width > 0 then point:SetScale(point:GetScale() * size / width) end
        point:ClearAllPoints()
        point:SetPoint("CENTER", nativeFrame.ClassFrameContainer, "CENTER", (index - (#points + 1) / 2) * step / point:GetScale(), 0)
    end
end

local function UpdateNativeHealthColor()
    local bar = nativeFrame.healthbar
    if not bar or not nativeFrame.GetDesiredHealthColor then return end
    local fraction = GetResourceFraction(UnitHealth("player"), UnitHealthMax("player"))
    if GetCfg("SMARTWARNINGCOLORS", false) and fraction and fraction < LOWHEALTHPCT then
        bar:SetStatusBarColor(1, 0.1, 0.1, 1)
    else
        local color = nativeFrame:GetDesiredHealthColor()
        if color then bar:SetStatusBarColor(color:GetRGB()) end
    end
end

local function UpdateNativeText(bar, kind)
    if not bar then return end
    if not nativeTexts[bar] then
        local left = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText", 7)
        local right = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText", 7)
        left:SetPoint("LEFT", bar, "LEFT", 4, 0)
        right:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
        nativeTexts[bar] = {leftText = left, rightText = right}
        if bar.TextString then bar.TextString:SetAlpha(0) end
        if bar.LeftText then bar.LeftText:SetAlpha(0) end
        if bar.RightText then bar.RightText:SetAlpha(0) end
    end

    local _, maximum = bar:GetMinMaxValues()
    local value = bar:GetValue()
    local fraction = GetResourceFraction(value, maximum)
    local resource = kind == "HEALTH" and "HEALTH" or "POWER"
    local percentEnabled = GetCfg("SHOW" .. resource .. "PERCENTAGE", true)
    local showPercent, percent
    if kind == "HEALTH" then
        showPercent, percent = GetHealthTextPercent("player", percentEnabled, fraction)
    elseif kind == "POWER" then
        showPercent, percent = GetPowerTextPercent("player", percentEnabled, fraction, UnitPowerType("player"))
    elseif bar.powerType ~= nil then
        showPercent, percent = GetPowerTextPercent("player", percentEnabled, fraction, bar.powerType)
    else
        showPercent, percent = percentEnabled and fraction ~= nil, (fraction or 0) * 100
    end
    SetBarTexts(nativeTexts[bar], showPercent, percent, GetCfg("SHOW" .. resource .. "VALUE", true), GetCfg("SHOWMAX" .. resource .. "VALUE", false), value, maximum)
end

function PersonalResource:UpdateFrames()
    if nativeFrame then
        if InCombatLockdown() then
            nativeLayoutPending = true
            return
        end

        nativeLayoutPending = false
        local width = GetCfg("BARWIDTH", 200)
        local height = GetCfg("BARHEIGHT", 19)
        if nativeFrame.SetBarWidth and nativeFrame.defaultBarWidth and nativeFrame.defaultBarWidth > 0 then
            nativeFrame:SetBarWidth(width * 100 / nativeFrame.defaultBarWidth)
        end
        if nativeFrame.SetHealthBarHeight then nativeFrame:SetHealthBarHeight(height) end
        if nativeFrame.SetPowerBarHeight then nativeFrame:SetPowerBarHeight(height) end
        if nativeFrame.SetBarPadding then
            local minimumPadding = nativeFrame.GetMinimumBarPadding and nativeFrame:GetMinimumBarPadding() or 0
            nativeFrame:SetBarPadding(GetCfg("BARSPACING", 0) - minimumPadding)
        end
        if nativeFrame.SetShowClassColor and nativeFrame.healthbar then
            nativeFrame:SetShowClassColor(GetCfg("USECLASSCOLOR", true))
        end
        UpdateNativeHealthColor()
        UpdateNativeComboLayout()
        UpdateNativeOrder()
        local health = nativeFrame.HealthBarsContainer
        UpdateNativeText(health and health.healthBar, "HEALTH")
        UpdateNativeText(nativeFrame.PowerBar, "POWER")
        UpdateNativeText(nativeFrame.AlternatePowerBar, "MANA")
        return
    end
    if not frame then return end
    local width = GetCfg("BARWIDTH", 200)
    local height = GetCfg("BARHEIGHT", 19)
    local spacing = GetCfg("BARSPACING", 0)
    local overTop, overBottom = PersonalResource:GetUnitFrameOverhang()
    local showMana = PersonalResource:HasSecondaryMana()
    local showCombo = PersonalResource:HasComboPoints()
    local templates = barTemplates
    if PersonalResource:IsDruid() then
        local powerType = UnitPowerType("player")
        local primaryKey = GetDruidPowerKey(powerType) or "COMBO"
        templates = {HEALTH = hpTemplate, MANA = manaTemplate, COMBO = barTemplates.COMBO}
        templates[primaryKey] = powerTemplate
        UpdateDruidExtraBars(frame, powerType, showMana)
        for key, bar in pairs(druidBars) do
            if bar.frame:IsShown() then templates[key] = bar end
        end
        if not showMana then manaTemplate.frame:Hide() end
        if not showCombo then comboFrame:Hide() end
    end
    local previous = nil
    local previousBottom = 0
    local total = 0
    for _, key in ipairs(PersonalResource:GetBarOrder()) do
        local template = templates[key]
        local visible = template and (template ~= manaTemplate or showMana) and (template.frame ~= comboFrame or showCombo)
        if template and not visible then
            template.frame:Hide()
        elseif visible then
            local barHeight = height
            local barTop, barBottom = overTop, overBottom
            if template.frame == comboFrame then
                barHeight = PersonalResource:UpdateComboLayout(width)
                barTop, barBottom = 0, 0
            else
                PersonalResource:SetUnitFrameSize(template, width, height)
            end

            template.frame:ClearAllPoints()
            if previous == nil then
                template.frame:SetPoint("TOP", frame, "TOP", 0, 0)
            else
                local gap = spacing + previousBottom + barTop
                template.frame:SetPoint("TOP", previous, "BOTTOM", 0, -gap)
                total = total + gap
            end

            template.frame:Show()
            total = total + barHeight
            previous = template.frame
            previousBottom = barBottom
        end
    end

    frame:SetSize(width, math.max(total, 1))
end

function PersonalResource:UpdateHealth()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local hp = UnitHealth(unit)
        local maxHP = UnitHealthMax(unit)
        hpBar:SetMinMaxValues(0, maxHP)
        hpBar:SetValue(hp)
        local fraction = GetResourceFraction(hp, maxHP)
        local r, g, b = 0.2, 1, 0.2
        if GetCfg("USECLASSCOLOR", true) then
            local _, class = UnitClass(unit)
            if class then
                local cr, cg, cb = GetClassColor(class)
                if cr and cg and cb then r, g, b = cr, cg, cb end
            end
        end

        if GetCfg("SMARTWARNINGCOLORS", false) and fraction and fraction < LOWHEALTHPCT then r, g, b = 1, 0.1, 0.1 end
        hpBar:SetStatusBarColor(r, g, b, 1.0)
        local showPercent, percent = GetHealthTextPercent(unit, GetCfg("SHOWHEALTHPERCENTAGE", true), fraction)
        SetBarTexts(hpTemplate, showPercent, percent, GetCfg("SHOWHEALTHVALUE", true), GetCfg("SHOWMAXHEALTHVALUE", false), hp, maxHP)
    end
end

function PersonalResource:UpdatePower()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        powerBar:SetMinMaxValues(0, maxPower)
        powerBar:SetValue(power)
        local fraction = GetResourceFraction(power, maxPower)
        local showPercent, percent = GetPowerTextPercent(unit, GetCfg("SHOWPOWERPERCENTAGE", true), fraction)
        SetBarTexts(powerTemplate, showPercent, percent, GetCfg("SHOWPOWERVALUE", true), GetCfg("SHOWMAXPOWERVALUE", false), power, maxPower)
    end
end

function PersonalResource:UpdateMana()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local mana = UnitPower(unit, MANAPOWERTYPE)
        local maxMana = UnitPowerMax(unit, MANAPOWERTYPE)
        manaBar:SetMinMaxValues(0, maxMana)
        manaBar:SetValue(mana)
        local fraction = GetResourceFraction(mana, maxMana)
        local showPercent, percent = GetPowerTextPercent(unit, GetCfg("SHOWPOWERPERCENTAGE", true), fraction, MANAPOWERTYPE)
        SetBarTexts(manaTemplate, showPercent, percent, GetCfg("SHOWPOWERVALUE", true), GetCfg("SHOWMAXPOWERVALUE", false), mana, maxMana)
    end
end

function PersonalResource:UpdatePowerType()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local powerType = UnitPowerType(unit)
        if PowerBarColor and PowerBarColor[powerType] then
            local color = PowerBarColor[powerType]
            powerBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
        else
            local r, g, b = 0.0, 0.3, 1.0
            if GetCfg("USECLASSCOLOR", true) then
                local _, class = UnitClass(unit)
                if class then
                    local cr, cg, cb = GetClassColor(class)
                    if cr and cg and cb then r, g, b = cr, cg, cb end
                end
            end

            powerBar:SetStatusBarColor(r, g, b, 1.0)
        end

        if PowerBarColor and PowerBarColor[MANAPOWERTYPE] then
            local color = PowerBarColor[MANAPOWERTYPE]
            manaBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
        else
            manaBar:SetStatusBarColor(0.0, 0.0, 1.0, 1.0)
        end
    end
end

function PersonalResource:HasPet()
    local unit = "pet"
    if not GetCfg("SHOWPETFRAME", true) then return false end
    if not UnitExists(unit) then return false end
    local dead = UnitIsDead(unit)
    if PersonalResource:CanAccessValue(dead) and dead then return false end
    local maxHealth = UnitHealthMax(unit)
    return not PersonalResource:CanAccessValue(maxHealth) or maxHealth > 0
end

function PersonalResource:UpdatePetFrames()
    oldPetState = PersonalResource:HasPet()
    if not oldPetState then
        petFrame:Hide()
        return
    end

    local width = GetCfg("PETBARWIDTH", 150)
    local height = GetCfg("PETBARHEIGHT", 14)
    local spacing = GetCfg("PETBARSPACING", 0)
    local overTop, overBottom = PersonalResource:GetUnitFrameOverhang()
    local gap = spacing + overTop + overBottom
    local maxPower = UnitPowerMax("pet")
    local showPower = not PersonalResource:CanAccessValue(maxPower) or maxPower > 0
    local previous = nil
    local total = 0
    for _, key in ipairs(PersonalResource:GetPetBarOrder()) do
        local template = petBarTemplates[key]
        if key == "POWER" and not showPower then
            template.frame:Hide()
        else
            PersonalResource:SetUnitFrameSize(template, width, height)
            template.frame:ClearAllPoints()
            if previous == nil then
                template.frame:SetPoint("TOP", petFrame, "TOP", 0, 0)
            else
                template.frame:SetPoint("TOP", previous, "BOTTOM", 0, -gap)
                total = total + gap
            end

            template.frame:Show()
            total = total + height
            previous = template.frame
        end
    end

    petFrame:SetSize(width, math.max(total, 1))
    petFrame:Show()
end

function PersonalResource:UpdatePetHealth()
    if not PersonalResource:HasPet() then return end
    local unit = "pet"
    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    petHPBar:SetMinMaxValues(0, maxHP)
    petHPBar:SetValue(hp)
    local fraction = GetResourceFraction(hp, maxHP)
    local r, g, b = 0.2, 1, 0.2
    if GetCfg("SMARTWARNINGCOLORS", false) and fraction and fraction < LOWHEALTHPCT then r, g, b = 1, 0.1, 0.1 end
    petHPBar:SetStatusBarColor(r, g, b, 1.0)
    local showPercent, percent = GetHealthTextPercent(unit, GetCfg("SHOWPETHEALTHPERCENTAGE", true), fraction)
    SetBarTexts(petHPTemplate, showPercent, percent, GetCfg("SHOWPETHEALTHVALUE", true), GetCfg("SHOWPETMAXHEALTHVALUE", false), hp, maxHP)
end

function PersonalResource:UpdatePetPower()
    if not PersonalResource:HasPet() then return end
    local unit = "pet"
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    petPowerBar:SetMinMaxValues(0, maxPower)
    petPowerBar:SetValue(power)
    local fraction = GetResourceFraction(power, maxPower)
    local powerType = UnitPowerType(unit)
    if PowerBarColor and PowerBarColor[powerType] then
        local color = PowerBarColor[powerType]
        petPowerBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
    else
        petPowerBar:SetStatusBarColor(0.0, 0.0, 1.0, 1.0)
    end

    local showPercent, percent = GetPowerTextPercent(unit, GetCfg("SHOWPETPOWERPERCENTAGE", true), fraction)
    SetBarTexts(petPowerTemplate, showPercent, percent, GetCfg("SHOWPETPOWERVALUE", true), GetCfg("SHOWPETMAXPOWERVALUE", false), power, maxPower)
end

function PersonalResource:UpdatePet()
    PersonalResource:UpdatePetFrames()
    PersonalResource:UpdatePetHealth()
    PersonalResource:UpdatePetPower()
    PersonalResource:UpdateVisibility()
end

local visibilityFrame = CreateFrame("Frame")
local visibilityElapsed = 0
visibilityFrame:Hide()
local function IsFull(cur, max)
    if not PersonalResource:CanAccessValues(cur, max) then return false end
    if max <= 0 then return true end
    return cur >= max
end

local function IsHovered(target)
    if target.IsMouseOver then return target:IsMouseOver() end
    if MouseIsOver then return MouseIsOver(target) end
    return false
end

local function IsPlayerHealthFull()
    return IsFull(UnitHealth("player"), UnitHealthMax("player"))
end

local function IsPlayerPowerFull()
    if not IsFull(UnitPower("player"), UnitPowerMax("player")) then return false end
    if nativeFrame then
        local alternate = nativeFrame.AlternatePowerBar
        return not alternate or not alternate:IsShown() or IsFull(alternate:GetValue(), select(2, alternate:GetMinMaxValues()))
    end
    if PersonalResource:HasSecondaryMana() then return IsFull(UnitPower("player", MANAPOWERTYPE), UnitPowerMax("player", MANAPOWERTYPE)) end
    return true
end

local function ShouldHideWhenFull(healthKey, powerKey, healthFull, powerFull)
    local hideHealth = GetCfg(healthKey, false)
    local hidePower = GetCfg(powerKey, false)
    if not hideHealth and not hidePower then return false end
    if hideHealth and not healthFull then return false end
    if hidePower and not powerFull then return false end
    return true
end

local function GetVisibilityAlpha(target, showOnHover, hideWhenFull)
    if not hideWhenFull then return 1 end
    if showOnHover and IsHovered(target) then return 1 end
    return 0
end

local function NeedsVisibilityUpdates()
    for i = 1, #HIDEWHENFULLKEYS do
        if GetCfg(HIDEWHENFULLKEYS[i], false) then return true end
    end
    return false
end

function PersonalResource:UpdateVisibility()
    local locked = GetCfg("LOCKED", false)
    local playerDisplay = nativeFrame or frame
    if playerDisplay then
        local hideFull = ShouldHideWhenFull("HIDEWHENFULLHP", "HIDEWHENFULLPOWER", IsPlayerHealthFull(), IsPlayerPowerFull())
        local alpha = GetVisibilityAlpha(playerDisplay, GetCfg("SHOWONHOVER", false), hideFull and not playerDisplay.isInEditMode and not AlwaysShowDruidPower())
        if playerDisplay:GetAlpha() ~= alpha then playerDisplay:SetAlpha(alpha) end
        if frame then frame:EnableMouse(not locked and alpha > 0) end
    end
    local petHideFull = ShouldHideWhenFull("PETHIDEWHENFULLHP", "PETHIDEWHENFULLPOWER", IsFull(UnitHealth("pet"), UnitHealthMax("pet")), IsFull(UnitPower("pet"), UnitPowerMax("pet")))
    local petAlpha = GetVisibilityAlpha(petFrame, GetCfg("PETSHOWONHOVER", false), petHideFull)
    petFrame:SetAlpha(petAlpha)
    petFrame:EnableMouse(not locked and petAlpha > 0)
    if NeedsVisibilityUpdates() then
        visibilityFrame:Show()
    else
        visibilityFrame:Hide()
    end
end

visibilityFrame:SetScript("OnUpdate", function(self, elapsed)
    visibilityElapsed = visibilityElapsed + elapsed
    if visibilityElapsed < VISIBILITYINTERVAL then return end
    visibilityElapsed = 0
    PersonalResource:UpdateVisibility()
end)

function PersonalResource:UpdateAll()
    PersonalResource:UpdateFrames()
    if frame then
        PersonalResource:UpdateHealth()
        PersonalResource:UpdatePower()
        PersonalResource:UpdateMana()
        PersonalResource:UpdatePowerType()
        PersonalResource:UpdateComboPoints()
    end
    PersonalResource:UpdatePet()
end

local function RegisterPlayerEvents()
    local healthFrame = CreateFrame("Frame")
    healthFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdateHealth() end)
    PersonalResource:RegisterEvent(healthFrame, "UNIT_HEALTH", "player")
    PersonalResource:RegisterEvent(healthFrame, "UNIT_MAXHEALTH", "player")
    local powerFrame = CreateFrame("Frame")
    powerFrame:SetScript("OnEvent", function(self, event, ...)
        PersonalResource:UpdatePower()
        PersonalResource:UpdateMana()
        if event == "UNIT_MAXPOWER" then PersonalResource:UpdateFrames() end
    end)

    PersonalResource:RegisterEvent(powerFrame, "UNIT_POWER_UPDATE", "player")
    PersonalResource:RegisterEvent(powerFrame, "UNIT_MAXPOWER", "player")
    local displayPowerFrame = CreateFrame("Frame")
    displayPowerFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdateAll() end)
    PersonalResource:RegisterEvent(displayPowerFrame, "UNIT_DISPLAYPOWER", "player")
    local powerTypFrame = CreateFrame("Frame")
    powerTypFrame:SetScript("OnEvent", function(self, event, a1, a2)
        if PersonalResource:CanAccessValue(a2) and a2 ~= oldPowerType then
            oldPowerType = a2
            PersonalResource:UpdatePowerType()
        end
    end)

    PersonalResource:RegisterEvent(powerTypFrame, "UNIT_POWER_UPDATE", "player")
    local shapeshiftFrame = CreateFrame("Frame")
    shapeshiftFrame:SetScript("OnEvent", function(self, event, ...)
        local form = GetShapeshiftForm()
        if oldShapeshift ~= form then
            oldShapeshift = form
            C_Timer.After(0.2, function() PersonalResource:UpdateAll() end)
        end
    end)

    PersonalResource:RegisterEvent(shapeshiftFrame, "UPDATE_SHAPESHIFT_FORM")
    local comboEventFrame = CreateFrame("Frame")
    comboEventFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdateComboPoints() end)
    PersonalResource:RegisterEvent(comboEventFrame, "UNIT_COMBO_POINTS", "player")
    PersonalResource:RegisterEvent(comboEventFrame, "UNIT_POWER_UPDATE", "player")
    PersonalResource:RegisterEvent(comboEventFrame, "PLAYER_TARGET_CHANGED")
end

local petHealthFrame = CreateFrame("Frame")
petHealthFrame:SetScript("OnEvent", function(self, event, ...)
    if PersonalResource:HasPet() ~= oldPetState then
        PersonalResource:UpdatePet()
    else
        PersonalResource:UpdatePetHealth()
    end
end)

PersonalResource:RegisterEvent(petHealthFrame, "UNIT_HEALTH", "pet")
PersonalResource:RegisterEvent(petHealthFrame, "UNIT_MAXHEALTH", "pet")
local petPowerFrame = CreateFrame("Frame")
petPowerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_POWER_UPDATE" then
        PersonalResource:UpdatePetPower()
    else
        PersonalResource:UpdatePet()
    end
end)

PersonalResource:RegisterEvent(petPowerFrame, "UNIT_POWER_UPDATE", "pet")
PersonalResource:RegisterEvent(petPowerFrame, "UNIT_MAXPOWER", "pet")
PersonalResource:RegisterEvent(petPowerFrame, "UNIT_DISPLAYPOWER", "pet")
local petStateFrame = CreateFrame("Frame")
petStateFrame:SetScript("OnEvent", function(self, event, ...) C_Timer.After(0.1, function() PersonalResource:UpdatePet() end) end)
PersonalResource:RegisterEvent(petStateFrame, "UNIT_PET", "player")
PersonalResource:RegisterEvent(petStateFrame, "PLAYER_ENTERING_WORLD")
local initFrame = CreateFrame("Frame")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event)
        C_Timer.After(0, function()
            PersonalResource:UpdateDruidPowerVisibility()
            PersonalResource:UpdateFrames()
        end)
        return
    end
    if event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        UpdateDruidBarValues()
        return
    end
    if event == "UNIT_DISPLAYPOWER" then
        PersonalResource:UpdateDruidPowerVisibility()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        PersonalResource:UpdateDruidPowerVisibility()
        if nativeLayoutPending then PersonalResource:UpdateFrames() end
        return
    end

    PersonalResource:SetAddonOutput()
    PersonalResource:SetVersion()
    PersonalResourceG = PersonalResourceG or {}
    nativeFrame = EnableNativeDisplay()
    local _, class = UnitClass("player")
    if class == "DRUID" then
        PersonalResource:RegisterEvent(self, "UNIT_DISPLAYPOWER", "player")
        PersonalResource:RegisterEvent(self, "UNIT_POWER_UPDATE", "player")
        PersonalResource:RegisterEvent(self, "UNIT_MAXPOWER", "player")
    end
    if nativeFrame then
        if class == "DRUID" then
            hooksecurefunc(nativeFrame, "UpdateShownState", ShowNativeDruidDisplay)
            if nativeFrame.SetHidePower then hooksecurefunc(nativeFrame, "SetHidePower", SyncNativeDruidPowerBar) end
        end
        if nativeFrame.UpdateFrameHeight then hooksecurefunc(nativeFrame, "UpdateFrameHeight", ScheduleNativeOrder) end
        if nativeFrame.UpdateHealth then
            hooksecurefunc(nativeFrame, "UpdateHealth", function()
                UpdateNativeHealthColor()
                UpdateNativeText(nativeFrame.healthbar, "HEALTH")
            end)
        end
        if nativeFrame.UpdatePower then
            hooksecurefunc(nativeFrame, "UpdatePower", function() UpdateNativeText(nativeFrame.PowerBar, "POWER") end)
        end
        if nativeFrame.AlternatePowerBar then
            nativeFrame.AlternatePowerBar:HookScript("OnValueChanged", function(bar) UpdateNativeText(bar, "MANA") end)
        end
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        nativeFrame:HookScript("OnShow", function()
            C_Timer.After(0, function()
                PersonalResource:UpdateFrames()
                PersonalResource:UpdateVisibility()
            end)
        end)
        if nativeFrame.SetIsInEditMode then
            hooksecurefunc(nativeFrame, "SetIsInEditMode", function(_, editing)
                PersonalResource:UpdateVisibility()
                if not editing then
                    C_Timer.After(0, function()
                        PersonalResource:UpdateDruidPowerVisibility()
                        PersonalResource:UpdateFrames()
                    end)
                end
            end)
        end
    else
        CreatePlayerFrame()
        RegisterPlayerEvents()
    end
    PersonalResource:InitSettings()
    if class == "DRUID" then PersonalResource:UpdateDruidPowerVisibility() end
    PersonalResource:UpdateAll()
    RestoreFramePosition(petFrame, "petFrame")
end)

PersonalResource:RegisterEvent(initFrame, "PLAYER_LOGIN")
