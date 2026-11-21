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
local DRUIDBARKEYS = {"COMBO", "ENERGY", "RAGE", "MANA", "POWER", "HEALTH"}
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

local function DruidComboAlwaysShown()
    return GetCfg("ALWAYSSHOWDRUIDCOMBO", false) and PersonalResource:IsDruid()
end

local function GetDruidPrimaryBarKey(powerType)
    if powerType == ENERGYPOWERTYPE and PersonalResource:AlwaysShowDruidResource("ENERGY") then return "ENERGY" end
    if powerType == RAGEPOWERTYPE and PersonalResource:AlwaysShowDruidResource("RAGE") then return "RAGE" end
    return "POWER"
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
local nativeDruidHeight
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
    comboFrame = CreateFrame("Frame", "PersonalResourceComboFrame", frame)
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
local petBarTemplates = {}
local function EnsurePetBars()
    if petBarTemplates.HEALTH then return end
    for _, key in ipairs(PETBARKEYS) do
        local template = PersonalResource:CreateBlizzardStyleUnitFrame(petFrame, 150, 14, nativeFrame ~= nil, nativeFrame and "TextStatusBarText")
        template.leftText:SetTextColor(1, 1, 1, 1)
        template.rightText:SetTextColor(1, 1, 1, 1)
        petBarTemplates[key] = template
    end
end

local function GetPetHealthColor()
    local color = nativeFrame and PERSONAL_RESOURCE_DISPLAY_DEFAULT_HEALTH_COLOR
    if color and color.GetRGB then return color:GetRGB() end
    return 0.2, 1, 0.2
end

local function GetPetPowerColor(powerType, powerToken)
    local color
    if nativeFrame and powerToken then color = (MANA_BAR_COLOR and MANA_BAR_COLOR[powerToken]) or (PowerBarColor and PowerBarColor[powerToken]) end
    color = color or (PowerBarColor and PowerBarColor[powerType])
    if color then return color.r, color.g, color.b end
    return 0.0, 0.0, 1.0
end

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

local function GetNativeComboPointSetup(classFrame)
    if not classFrame or not classFrame.resourcePointTemplate then return end
    return classFrame.resourcePointSetupFunc or (classFrame.resourcePointMixin and classFrame.resourcePointMixin.Setup)
end

local function EnsureComboPoints(count)
    for i = #comboPoints + 1, count do
        if nativeFrame then
            local classFrame = nativeFrame.classFrame
            local point = CreateFrame("Frame", nil, comboFrame, classFrame.resourcePointTemplate)
            local setup = GetNativeComboPointSetup(classFrame)
            setup(point)
            comboPoints[i] = {frame = point}
        else
            comboPoints[i] = PersonalResource:CreateComboPoint(comboFrame)
        end
    end
end

function PersonalResource:HasComboPoints()
    local unit = "player"
    if not UnitExists(unit) then return false end
    if DruidComboAlwaysShown() then return true end
    if not GetCfg("SHOWCOMBOPOINTS", true) then return false end
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
    return BuildBarOrder("DRUIDBARSLOT", DRUIDBARKEYS)
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
            if nativeFrame then
                point.frame:SetScale(size / point.frame:GetWidth())
            else
                PersonalResource:SetComboPointSize(point, size)
            end
            point.frame:ClearAllPoints()
            point.frame:SetPoint("CENTER", comboFrame, "CENTER", (first + (i - 1) * (size + spacing)) / point.frame:GetScale(), 0)
            point.frame:Show()
        else
            point.frame:Hide()
        end
    end
    return size
end

function PersonalResource:UpdateComboPoints()
    if not comboFrame or not comboFrame:IsShown() or not PersonalResource:HasComboPoints() then return end
    local value = GetCurrentComboPoints()
    local readable = PersonalResource:CanAccessValue(value)
    for i = 1, #comboPoints do
        local point = comboPoints[i]
        local active = readable and i <= (value or 0)
        if nativeFrame then
            point.frame:SetActive(active)
        else
            PersonalResource:SetComboPointFull(point, active)
        end
    end
end

local function NativeHasComboPoints()
    local _, class = UnitClass("player")
    return class == "ROGUE" or class == "DRUID"
end

local function AnimateDruidBar(statusBar, elapsed)
    local current = statusBar:GetValue()
    local target = statusBar.personalResourceTarget
    if not PersonalResource:CanAccessValue(current) then
        statusBar:SetScript("OnUpdate", nil)
        statusBar:SetValue(target)
        return
    end
    local difference = target - current
    local nextValue = current + difference * (1 - math.exp(-elapsed * 18))
    if math.abs(target - nextValue) < 0.02 then
        nextValue = target
        statusBar:SetScript("OnUpdate", nil)
    end
    statusBar:SetValue(nextValue)
end

local function UpdateDruidBarText(bar, powerType)
    local value = UnitPower("player", powerType)
    local maximum = UnitPowerMax("player", powerType)
    if powerType ~= MANAPOWERTYPE and PersonalResource:CanAccessValue(maximum) and maximum <= 0 then maximum = 100 end
    local statusBar = bar.statusBar
    local _, previousMax = statusBar:GetMinMaxValues()
    if not PersonalResource:CanAccessValues(maximum, previousMax) or maximum ~= previousMax then
        statusBar:SetMinMaxValues(0, maximum)
    end
    local interpolation = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
    if interpolation then
        statusBar:SetValue(value, interpolation)
    elseif PersonalResource:CanAccessValues(value, statusBar:GetValue()) then
        statusBar.personalResourceTarget = value
        statusBar:SetScript("OnUpdate", AnimateDruidBar)
    else
        statusBar:SetScript("OnUpdate", nil)
        statusBar:SetValue(value)
    end
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
            bar = PersonalResource:CreateBlizzardStyleUnitFrame(parent, 200, 19, true, nativeFrame and "TextStatusBarText")
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

local function SetHeightKeepingBottom(target, height)
    local oldHeight = target:GetHeight()
    if oldHeight == height then return end
    if oldHeight > 0 and target:GetNumPoints() == 1 then
        local point, relative, relativePoint, x, y = target:GetPoint()
        local vertical = 0.5
        if point:find("BOTTOM", 1, true) then
            vertical = 0
        elseif point:find("TOP", 1, true) then
            vertical = 1
        end
        if vertical ~= 0 then
            target:SetPoint(point, relative, relativePoint, x, y + (height - oldHeight) * vertical)
        end
    end
    target:SetHeight(height)
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
    local druid = PersonalResource:IsDruid()
    local slotHeight = GetCfg("BARHEIGHT", 19)
    if druid then
        local primaryType = UnitPowerType("player")
        local primaryKey = GetDruidPrimaryBarKey(primaryType)
        local alternate = bars.MANA
        local duplicateMana = primaryType == MANAPOWERTYPE
        local hasAlternate = alternate and alternate:IsShown() and not duplicateMana
        if alternate then alternate:SetAlpha(duplicateMana and 0 or 1) end
        if not hasAlternate then bars.MANA = nil end
        if primaryKey ~= "POWER" then
            bars[primaryKey] = bars.POWER
            bars.POWER = nil
        end
        local classFrame = nativeFrame.classFrame
        local nativeComboShown = classFrame and classBar and classBar:IsShown() and classFrame:IsShown()
            and (not nativeFrame.HasClassInfo or nativeFrame:HasClassInfo())
            and classFrame.classResourceButtonTable and #classFrame.classResourceButtonTable > 0
        local useAlwaysCombo = DruidComboAlwaysShown() and GetNativeComboPointSetup(classFrame)
            and (not nativeComboShown or (primaryType == ENERGYPOWERTYPE and PersonalResource:CanAccessValue(GetCurrentComboPoints())))
        if classBar then
            if useAlwaysCombo then
                if classBar.personalResourceComboAlpha == nil then classBar.personalResourceComboAlpha = classBar:GetAlpha() end
                classBar:SetAlpha(0)
            elseif classBar.personalResourceComboAlpha ~= nil then
                classBar:SetAlpha(classBar.personalResourceComboAlpha)
                classBar.personalResourceComboAlpha = nil
            end
        end
        if useAlwaysCombo then
            if not comboFrame then comboFrame = CreateFrame("Frame", "PersonalResourceComboFrame", nativeFrame) end
            PersonalResource:UpdateComboLayout(GetCfg("BARWIDTH", 200))
            comboFrame:SetHeight(slotHeight)
            comboFrame:Show()
            PersonalResource:UpdateComboPoints()
            bars.COMBO = comboFrame
        elseif comboFrame then
            comboFrame:Hide()
        end
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
        local visible = bar and bar:IsShown() and (bar ~= classBar or not nativeFrame.HasClassInfo or nativeFrame:HasClassInfo())
        if visible then
            if hasBar then offset = offset + spacing end
            if bar == classBar and not NativeHasComboPoints() then offset = offset - (bar.yOffset or 0) end
            bar:ClearAllPoints()
            bar:SetPoint("TOP", nativeFrame, "TOP", 0, -offset)
            offset = offset + (druid and slotHeight or bar:GetHeight())
            hasBar = true
        end
    end
    local minimum = nativeFrame.GetMinimumFrameHeight and nativeFrame:GetMinimumFrameHeight() or 1
    local height = math.max(offset, minimum)
    if druid then
        nativeDruidHeight = height
        SetHeightKeepingBottom(nativeFrame, height)
    else
        nativeFrame:SetHeight(height)
    end
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
    if not nativeFrame.hasBeenSetup or nativeFrame:IsShown() or (not AlwaysShowDruidPower() and not DruidComboAlwaysShown()) then return end
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
    if nativeFrame and PersonalResource:IsDruid() and not nativeFrame.isInEditMode then
        if nativeFrame.hasBeenSetup then nativeFrame:UpdateShownState() end
        SyncNativeDruidPowerBar()
        if not InCombatLockdown() or alwaysShow then nativeDruidPowerActive = alwaysShow end
    end
    if nativeFrame then ScheduleNativeOrder() end
    PersonalResource:UpdateVisibility()
end

local function UpdateNativeComboLayout()
    if not NativeHasComboPoints() then return end
    local container = nativeFrame.ClassFrameContainer
    if container and nativeFrame.classFrame then
        local shown = DruidComboAlwaysShown() or GetCfg("SHOWCOMBOPOINTS", true)
        if container:IsShown() ~= shown then container:SetShown(shown) end
    end

    local classFrame = nativeFrame.classFrame
    if not classFrame then return end
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
    if not bar then return end
    local fraction = GetResourceFraction(UnitHealth("player"), UnitHealthMax("player"))
    if GetCfg("SMARTWARNINGCOLORS", false) and fraction and fraction < LOWHEALTHPCT then
        bar:SetStatusBarColor(1, 0.1, 0.1, 1)
    else
        local _, class = UnitClass("player")
        local color = GetCfg("USECLASSCOLOR", true) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        color = color or PERSONAL_RESOURCE_DISPLAY_DEFAULT_HEALTH_COLOR
        if color then bar:SetStatusBarColor(color.r, color.g, color.b) end
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
        for _, part in ipairs({nativeFrame, nativeFrame.HealthBarsContainer, nativeFrame.PowerBar, nativeFrame.AlternatePowerBar, nativeFrame.ClassFrameContainer}) do
            part:SetWidth(width)
        end
        for _, part in ipairs({nativeFrame.HealthBarsContainer, nativeFrame.PowerBar, nativeFrame.AlternatePowerBar}) do
            part:SetHeight(height)
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
    local order = PersonalResource:GetBarOrder()
    if PersonalResource:IsDruid() then
        local powerType = UnitPowerType("player")
        local primaryKey = GetDruidPrimaryBarKey(powerType)
        templates = {HEALTH = hpTemplate, MANA = manaTemplate, COMBO = barTemplates.COMBO}
        templates[primaryKey] = powerTemplate
        UpdateDruidExtraBars(frame, powerType, showMana)
        for key, bar in pairs(druidBars) do
            if bar.frame:IsShown() then templates[key] = bar end
        end
        if not showMana then manaTemplate.frame:Hide() end
        if not showCombo then comboFrame:Hide() end
        local offset = 0
        local gap = spacing + overTop + overBottom
        for _, key in ipairs(order) do
            local template = templates[key]
            local visible = template and (template ~= manaTemplate or showMana) and (template.frame ~= comboFrame or showCombo)
            if visible then
                if template.frame == comboFrame then
                    PersonalResource:UpdateComboLayout(width)
                    comboFrame:SetHeight(height)
                else
                    PersonalResource:SetUnitFrameSize(template, width, height)
                end
                template.frame:ClearAllPoints()
                template.frame:SetPoint("TOP", frame, "TOP", 0, -offset)
                template.frame:Show()
                offset = offset + height + gap
            end
        end
        frame:SetWidth(width)
        SetHeightKeepingBottom(frame, math.max(offset - gap, 1))
        return
    end
    local previous = nil
    local previousBottom = 0
    local total = 0
    for _, key in ipairs(order) do
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
    if not frame and not nativeFrame then return false end
    if not GetCfg("SHOWPETFRAME", true) then return false end
    if not UnitExists(unit) then return false end
    local dead = UnitIsDead(unit)
    if PersonalResource:CanAccessValue(dead) and dead then return false end
    local maxHealth = UnitHealthMax(unit)
    return not PersonalResource:CanAccessValue(maxHealth) or maxHealth > 0
end

function PersonalResource:UpdatePetFrames()
    oldPetState = PersonalResource:HasPet()
    local placeholder = not oldPetState and PersonalResource:IsEditModeFrameActive(petFrame)
    if not oldPetState and not placeholder then
        petFrame:Hide()
        return
    end

    EnsurePetBars()
    if placeholder then
        for _, template in pairs(petBarTemplates) do
            template.statusBar:SetMinMaxValues(0, 1)
            template.statusBar:SetValue(1)
            template.leftText:SetText("")
            template.rightText:SetText("")
        end
        petBarTemplates.HEALTH.statusBar:SetStatusBarColor(GetPetHealthColor())
        petBarTemplates.POWER.statusBar:SetStatusBarColor(GetPetPowerColor(MANAPOWERTYPE, "MANA"))
    end
    local width = GetCfg("PETBARWIDTH", 150)
    local height = GetCfg("PETBARHEIGHT", 14)
    local spacing = GetCfg("PETBARSPACING", 0)
    local overTop, overBottom = PersonalResource:GetUnitFrameOverhang()
    local gap = spacing + overTop + overBottom
    if nativeFrame then gap = spacing end
    local maxPower = UnitPowerMax("pet")
    local showPower = placeholder or not PersonalResource:CanAccessValue(maxPower) or maxPower > 0
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
    EnsurePetBars()
    local unit = "pet"
    local template = petBarTemplates.HEALTH
    local bar = template.statusBar
    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    bar:SetMinMaxValues(0, maxHP)
    bar:SetValue(hp)
    local fraction = GetResourceFraction(hp, maxHP)
    local r, g, b = GetPetHealthColor()
    if GetCfg("SMARTWARNINGCOLORS", false) and fraction and fraction < LOWHEALTHPCT then r, g, b = 1, 0.1, 0.1 end
    bar:SetStatusBarColor(r, g, b, 1.0)
    local showPercent, percent = GetHealthTextPercent(unit, GetCfg("SHOWPETHEALTHPERCENTAGE", true), fraction)
    SetBarTexts(template,showPercent, percent, GetCfg("SHOWPETHEALTHVALUE", true), GetCfg("SHOWPETMAXHEALTHVALUE", false), hp, maxHP)
end

function PersonalResource:UpdatePetPower()
    if not PersonalResource:HasPet() then return end
    EnsurePetBars()
    local unit = "pet"
    local template = petBarTemplates.POWER
    local bar = template.statusBar
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    bar:SetMinMaxValues(0, maxPower)
    bar:SetValue(power)
    local fraction = GetResourceFraction(power, maxPower)
    local powerType, powerToken = UnitPowerType(unit)
    bar:SetStatusBarColor(GetPetPowerColor(powerType, powerToken))
    local showPercent, percent = GetPowerTextPercent(unit, GetCfg("SHOWPETPOWERPERCENTAGE", true), fraction, powerType)
    SetBarTexts(template,showPercent, percent, GetCfg("SHOWPETPOWERVALUE", true), GetCfg("SHOWPETMAXPOWERVALUE", false), power, maxPower)
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
local fullResourceCurve
if C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
    fullResourceCurve = C_CurveUtil.CreateCurve()
    fullResourceCurve:SetType(Enum.LuaCurveType.Step)
    fullResourceCurve:AddPoint(0, 1)
    fullResourceCurve:AddPoint(1, 0)
end

local function IsHovered(target)
    if target.IsMouseOver then return target:IsMouseOver() end
    if MouseIsOver then return MouseIsOver(target) end
    return false
end

local function GetFullResourceAlpha(current, maximum)
    if not PersonalResource:CanAccessValues(current, maximum) then return nil end
    return (maximum <= 0 or current >= maximum) and 0 or 1
end

local function GetBarFullResourceAlpha(bar)
    if not bar then return nil end
    local _, maximum = bar:GetMinMaxValues()
    return GetFullResourceAlpha(bar:GetValue(), maximum)
end

local function GetHealthVisibilityAlpha(unit, bar)
    local barAlpha = GetBarFullResourceAlpha(bar)
    if barAlpha ~= nil then return barAlpha end
    local alpha = GetFullResourceAlpha(UnitHealth(unit), UnitHealthMax(unit))
    if alpha ~= nil then return alpha end
    if fullResourceCurve and UnitHealthPercent then return UnitHealthPercent(unit, true, fullResourceCurve) end
    return 1
end

local function GetPowerVisibilityAlpha(unit, bar)
    local barAlpha = GetBarFullResourceAlpha(bar)
    if barAlpha ~= nil then return barAlpha end
    local powerType = UnitPowerType(unit)
    local alpha = GetFullResourceAlpha(UnitPower(unit, powerType), UnitPowerMax(unit, powerType))
    if alpha ~= nil then return alpha end
    if fullResourceCurve and UnitPowerPercent then return UnitPowerPercent(unit, powerType, false, fullResourceCurve) end
    return 1
end

local function CombineVisibilityAlpha(first, second)
    if PersonalResource:CanAccessValue(first) then
        if first == 0 then return second end
        return 1
    end
    if PersonalResource:CanAccessValue(second) and second == 0 then return first end
    return 1
end

local function GetVisibilityAlpha(target, unit, prefix, bypassFull, healthBar, primaryBar)
    local hideHealth = GetCfg(prefix .. "HIDEWHENFULLHP", false)
    local hidePower = GetCfg(prefix .. "HIDEWHENFULLPOWER", false)
    if bypassFull or (not hideHealth and not hidePower) then return 1 end
    if GetCfg(prefix .. "SHOWONHOVER", false) and IsHovered(target) then return 1 end
    if GetCfg(prefix .. "SHOWINCOMBAT", false) and UnitAffectingCombat("player") then return 1 end
    local health = 0
    if hideHealth then health = GetHealthVisibilityAlpha(unit, healthBar) end
    local power = 0
    if hidePower then power = GetPowerVisibilityAlpha(unit, primaryBar) end
    if hideHealth and hidePower and not PersonalResource:CanAccessValue(health) and not PersonalResource:CanAccessValue(power) then return 1, health, power end
    return CombineVisibilityAlpha(health, power)
end

local function SetPartsAlpha(healthPart, powerPart, healthAlpha, powerAlpha)
    if healthPart then healthPart:SetAlpha(healthAlpha or 1) end
    if powerPart then powerPart:SetAlpha(powerAlpha or 1) end
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
        local healthBar = nativeFrame and nativeFrame.HealthBarsContainer and nativeFrame.HealthBarsContainer.healthBar
        local primaryBar = nativeFrame and nativeFrame.PowerBar
        local alpha, healthAlpha, powerAlpha = GetVisibilityAlpha(playerDisplay, "player", "", playerDisplay.isInEditMode, healthBar, primaryBar)
        playerDisplay:SetAlpha(alpha)
        if nativeFrame then
            SetPartsAlpha(nativeFrame.HealthBarsContainer, nativeFrame.PowerBar, healthAlpha, powerAlpha)
        else
            SetPartsAlpha(hpTemplate and hpTemplate.frame, powerTemplate and powerTemplate.frame, healthAlpha, powerAlpha)
        end
        if frame then frame:EnableMouse(not locked and (not PersonalResource:CanAccessValue(alpha) or alpha > 0)) end
    end
    local petAlpha, petHealthAlpha, petPowerAlpha = GetVisibilityAlpha(petFrame, "pet", "PET", not petFrame:IsShown() or PersonalResource:IsEditModeFrameActive(petFrame))
    petFrame:SetAlpha(petAlpha)
    SetPartsAlpha(petBarTemplates.HEALTH and petBarTemplates.HEALTH.frame, petBarTemplates.POWER and petBarTemplates.POWER.frame, petHealthAlpha, petPowerAlpha)
    petFrame:EnableMouse(not petFrame.Selection and not locked and (not PersonalResource:CanAccessValue(petAlpha) or petAlpha > 0))
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
    if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_COMBO_POINTS" then
        PersonalResource:UpdateComboPoints()
        return
    end
    if event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateDruidBarValues()
        if nativeFrame then PersonalResource:UpdateComboPoints() end
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
        PersonalResource:RegisterEvent(self, "UNIT_POWER_FREQUENT", "player")
        PersonalResource:RegisterEvent(self, "UNIT_MAXPOWER", "player")
        if nativeFrame then
            PersonalResource:RegisterEvent(self, "UNIT_COMBO_POINTS", "player")
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
        end
    end
    if nativeFrame then
        if class == "DRUID" then
            hooksecurefunc(nativeFrame, "UpdateShownState", ShowNativeDruidDisplay)
            if nativeFrame.SetHidePower then hooksecurefunc(nativeFrame, "SetHidePower", SyncNativeDruidPowerBar) end
        end
        if nativeFrame.UpdateFrameHeight then
            hooksecurefunc(nativeFrame, "UpdateFrameHeight", function()
                if nativeDruidHeight and (not InCombatLockdown() or not nativeFrame:IsProtected()) then
                    nativeFrame:SetHeight(nativeDruidHeight)
                end
                ScheduleNativeOrder()
            end)
        end
        if nativeFrame.UpdateHealthColor then hooksecurefunc(nativeFrame, "UpdateHealthColor", UpdateNativeHealthColor) end
        if nativeFrame.UpdateSystem then
            hooksecurefunc(nativeFrame, "UpdateSystem", function()
                C_Timer.After(0, function() PersonalResource:UpdateFrames() end)
            end)
        end
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
    if nativeFrame then
        PersonalResource:RegisterEditModeFrame(petFrame, {
            name = PET or "Pet",
            onEditMode = function() PersonalResource:UpdatePet() end,
            onMoved = function(_, point, relativePoint, x, y)
                PersonalResourceG.petFrame = PersonalResourceG.petFrame or {}
                PersonalResourceG.petFrame.position = {point, relativePoint, x, y}
            end
        })
        PersonalResource:UpdateVisibility()
    end
end)

PersonalResource:RegisterEvent(initFrame, "PLAYER_LOGIN")
