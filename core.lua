local _, PersonalResource = ...
local oldPowerType = nil
local oldShapeshift = nil
local oldPetState = nil
local LOWHEALTHPCT = 0.35
local GRIDSIZE = 5
local MANAPOWERTYPE = 0
local BARKEYS = {"HEALTH", "POWER", "MANA"}
local function GetCfg(key, default)
    PersonalResourceG = PersonalResourceG or {}
    return PersonalResource:GV(PersonalResourceG, key, default)
end

local function BuildValueText(cur, max, showValue, showMax)
    if showValue and showMax then return string.format("%d / %d", cur, max) end
    if showValue then return string.format("%d", cur) end
    if showMax then return string.format("%d", max) end
    return ""
end

local function SetBarTexts(template, percentText, valueText)
    if percentText ~= "" and valueText ~= "" then
        template.leftText:SetText(percentText)
        template.centerText:SetText("")
        template.rightText:SetText(valueText)
    elseif percentText ~= "" then
        template.leftText:SetText("")
        template.centerText:SetText(percentText)
        template.rightText:SetText("")
    else
        template.leftText:SetText("")
        template.centerText:SetText(valueText)
        template.rightText:SetText("")
    end
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
    movable:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
            ShowMoveHelpers(moveOverlay, true)
        end
    end)

    movable:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
            ShowMoveHelpers(moveOverlay, false)
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            if xOfs < 15 and xOfs > -15 then xOfs = 0 end
            if yOfs < 15 and yOfs > -15 then yOfs = 0 end
            if not PersonalResourceG then PersonalResourceG = {} end
            if not PersonalResourceG[dbKey] then PersonalResourceG[dbKey] = {} end
            PersonalResourceG[dbKey]["position"] = {point, relativePoint, xOfs, yOfs}
            self:ClearAllPoints()
            self:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
        end
    end)

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

local frame = CreateMovableFrame("PersonalResourceFrame", "mainFrame")
frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
local petFrame = CreateMovableFrame("PersonalResourcePetFrame", "petFrame")
petFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
petFrame:Hide()

local hpTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(frame, 200, 19)
hpTemplate.frame:SetPoint("TOP", frame, "TOP", 0, 0)
local hpBar = hpTemplate.statusBar
local hpLeftText = hpTemplate.leftText
local hpCenterText = hpTemplate.centerText
local hpRightText = hpTemplate.rightText
hpLeftText:SetTextColor(1, 1, 1, 1)
hpCenterText:SetTextColor(1, 1, 1, 1)
hpRightText:SetTextColor(1, 1, 1, 1)
local powerTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(frame, 200, 19)
powerTemplate.frame:SetPoint("TOP", hpTemplate.frame, "BOTTOM", 0, -5)
local powerBar = powerTemplate.statusBar
local powerLeftText = powerTemplate.leftText
local powerCenterText = powerTemplate.centerText
local powerRightText = powerTemplate.rightText
powerLeftText:SetTextColor(1, 1, 1, 1)
powerCenterText:SetTextColor(1, 1, 1, 1)
powerRightText:SetTextColor(1, 1, 1, 1)
local manaTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(frame, 200, 19)
manaTemplate.frame:SetPoint("TOP", powerTemplate.frame, "BOTTOM", 0, -5)
manaTemplate.frame:Hide()
local manaBar = manaTemplate.statusBar
manaTemplate.leftText:SetTextColor(1, 1, 1, 1)
manaTemplate.centerText:SetTextColor(1, 1, 1, 1)
manaTemplate.rightText:SetTextColor(1, 1, 1, 1)
local barTemplates = {
    ["HEALTH"] = hpTemplate,
    ["POWER"] = powerTemplate,
    ["MANA"] = manaTemplate
}

local petHPTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(petFrame, 150, 14)
petHPTemplate.frame:SetPoint("TOP", petFrame, "TOP", 0, 0)
local petHPBar = petHPTemplate.statusBar
petHPTemplate.leftText:SetTextColor(1, 1, 1, 1)
petHPTemplate.centerText:SetTextColor(1, 1, 1, 1)
petHPTemplate.rightText:SetTextColor(1, 1, 1, 1)
local petPowerTemplate = PersonalResource:CreateBlizzardStyleUnitFrame(petFrame, 150, 14)
petPowerTemplate.frame:SetPoint("TOP", petHPTemplate.frame, "BOTTOM", 0, -5)
local petPowerBar = petPowerTemplate.statusBar
petPowerTemplate.leftText:SetTextColor(1, 1, 1, 1)
petPowerTemplate.centerText:SetTextColor(1, 1, 1, 1)
petPowerTemplate.rightText:SetTextColor(1, 1, 1, 1)

function PersonalResource:HasSecondaryMana()
    local unit = "player"
    if not UnitExists(unit) then return false end
    if UnitPowerType(unit) == MANAPOWERTYPE then return false end
    return UnitPowerMax(unit, MANAPOWERTYPE) > 0
end

function PersonalResource:GetBarOrder()
    local order = {}
    local used = {}
    for i = 1, 3 do
        local key = GetCfg("BARSLOT" .. i, BARKEYS[i])
        if barTemplates[key] and not used[key] then
            used[key] = true
            table.insert(order, key)
        end
    end

    for i = 1, 3 do
        local key = BARKEYS[i]
        if not used[key] then
            used[key] = true
            table.insert(order, key)
        end
    end

    return order
end

function PersonalResource:UpdateFrames()
    local width = GetCfg("BARWIDTH", 200)
    local height = GetCfg("BARHEIGHT", 19)
    local spacing = GetCfg("BARSPACING", 0)
    local locked = GetCfg("LOCKED", false)
    local overTop, overBottom = PersonalResource:GetUnitFrameOverhang()
    local gap = spacing + overTop + overBottom
    local showMana = PersonalResource:HasSecondaryMana()
    local previous = nil
    local shown = 0
    for _, key in ipairs(PersonalResource:GetBarOrder()) do
        local template = barTemplates[key]
        if key == "MANA" and not showMana then
            template.frame:Hide()
        else
            PersonalResource:SetUnitFrameSize(template, width, height)
            template.frame:ClearAllPoints()
            if previous == nil then
                template.frame:SetPoint("TOP", frame, "TOP", 0, 0)
            else
                template.frame:SetPoint("TOP", previous, "BOTTOM", 0, -gap)
            end

            template.frame:Show()
            previous = template.frame
            shown = shown + 1
        end
    end

    frame:SetSize(width, height * shown + gap * (shown - 1))
    frame:EnableMouse(not locked)
end

function PersonalResource:UpdateHealth()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local hp = UnitHealth(unit)
        local maxHP = UnitHealthMax(unit)
        hpBar:SetMinMaxValues(0, maxHP)
        hpBar:SetValue(hp)
        local fraction = 0
        if maxHP > 0 then fraction = hp / maxHP end
        local percent = math.floor(fraction * 100)
        local r, g, b = 0.2, 1, 0.2
        if GetCfg("USECLASSCOLOR", true) then
            local _, class = UnitClass(unit)
            if class then
                local cr, cg, cb = GetClassColor(class)
                if cr and cg and cb then r, g, b = cr, cg, cb end
            end
        end

        if GetCfg("SMARTWARNINGCOLORS", false) and fraction < LOWHEALTHPCT then r, g, b = 1, 0.1, 0.1 end
        hpBar:SetStatusBarColor(r, g, b, 1.0)
        local percentText = ""
        if GetCfg("SHOWHEALTHPERCENTAGE", true) then percentText = string.format("%d%%", percent) end
        SetBarTexts(hpTemplate, percentText, BuildValueText(hp, maxHP, GetCfg("SHOWHEALTHVALUE", true), GetCfg("SHOWMAXHEALTHVALUE", false)))
    end
end

function PersonalResource:UpdatePower()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        powerBar:SetMinMaxValues(0, maxPower)
        powerBar:SetValue(power)
        local percent = 0
        if maxPower > 0 then percent = math.floor((power / maxPower) * 100) end
        local percentText = ""
        if GetCfg("SHOWPOWERPERCENTAGE", true) then percentText = string.format("%d%%", percent) end
        SetBarTexts(powerTemplate, percentText, BuildValueText(power, maxPower, GetCfg("SHOWPOWERVALUE", true), GetCfg("SHOWMAXPOWERVALUE", false)))
    end
end

function PersonalResource:UpdateMana()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local mana = UnitPower(unit, MANAPOWERTYPE)
        local maxMana = UnitPowerMax(unit, MANAPOWERTYPE)
        manaBar:SetMinMaxValues(0, maxMana)
        manaBar:SetValue(mana)
        local percent = 0
        if maxMana > 0 then percent = math.floor((mana / maxMana) * 100) end
        local percentText = ""
        if GetCfg("SHOWPOWERPERCENTAGE", true) then percentText = string.format("%d%%", percent) end
        SetBarTexts(manaTemplate, percentText, BuildValueText(mana, maxMana, GetCfg("SHOWPOWERVALUE", true), GetCfg("SHOWMAXPOWERVALUE", false)))
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
    if UnitIsDead(unit) then return false end
    if UnitHealthMax(unit) <= 0 then return false end

    return true
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
    local locked = GetCfg("LOCKED", false)
    local overTop, overBottom = PersonalResource:GetUnitFrameOverhang()
    local gap = spacing + overTop + overBottom
    local shown = 1
    PersonalResource:SetUnitFrameSize(petHPTemplate, width, height)
    petHPTemplate.frame:ClearAllPoints()
    petHPTemplate.frame:SetPoint("TOP", petFrame, "TOP", 0, 0)
    petHPTemplate.frame:Show()
    if UnitPowerMax("pet") > 0 then
        PersonalResource:SetUnitFrameSize(petPowerTemplate, width, height)
        petPowerTemplate.frame:ClearAllPoints()
        petPowerTemplate.frame:SetPoint("TOP", petHPTemplate.frame, "BOTTOM", 0, -gap)
        petPowerTemplate.frame:Show()
        shown = shown + 1
    else
        petPowerTemplate.frame:Hide()
    end

    petFrame:SetSize(width, height * shown + gap * (shown - 1))
    petFrame:EnableMouse(not locked)
    petFrame:Show()
end

function PersonalResource:UpdatePetHealth()
    if not PersonalResource:HasPet() then return end
    local unit = "pet"
    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    petHPBar:SetMinMaxValues(0, maxHP)
    petHPBar:SetValue(hp)
    local fraction = 0
    if maxHP > 0 then fraction = hp / maxHP end
    local percent = math.floor(fraction * 100)
    local r, g, b = 0.2, 1, 0.2
    if GetCfg("SMARTWARNINGCOLORS", false) and fraction < LOWHEALTHPCT then r, g, b = 1, 0.1, 0.1 end
    petHPBar:SetStatusBarColor(r, g, b, 1.0)
    local percentText = ""
    if GetCfg("SHOWPETHEALTHPERCENTAGE", true) then percentText = string.format("%d%%", percent) end
    SetBarTexts(petHPTemplate, percentText, BuildValueText(hp, maxHP, GetCfg("SHOWPETHEALTHVALUE", true), GetCfg("SHOWPETMAXHEALTHVALUE", false)))
end

function PersonalResource:UpdatePetPower()
    if not PersonalResource:HasPet() then return end
    local unit = "pet"
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    petPowerBar:SetMinMaxValues(0, maxPower)
    petPowerBar:SetValue(power)
    local percent = 0
    if maxPower > 0 then percent = math.floor((power / maxPower) * 100) end
    local powerType = UnitPowerType(unit)
    if PowerBarColor and PowerBarColor[powerType] then
        local color = PowerBarColor[powerType]
        petPowerBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
    else
        petPowerBar:SetStatusBarColor(0.0, 0.0, 1.0, 1.0)
    end

    local percentText = ""
    if GetCfg("SHOWPETPOWERPERCENTAGE", true) then percentText = string.format("%d%%", percent) end
    SetBarTexts(petPowerTemplate, percentText, BuildValueText(power, maxPower, GetCfg("SHOWPETPOWERVALUE", true), GetCfg("SHOWPETMAXPOWERVALUE", false)))
end

function PersonalResource:UpdatePet()
    PersonalResource:UpdatePetFrames()
    PersonalResource:UpdatePetHealth()
    PersonalResource:UpdatePetPower()
end

function PersonalResource:UpdateAll()
    PersonalResource:UpdateFrames()
    PersonalResource:UpdateHealth()
    PersonalResource:UpdatePower()
    PersonalResource:UpdateMana()
    PersonalResource:UpdatePowerType()
    PersonalResource:UpdatePet()
end

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
    if a2 ~= oldPowerType then
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
initFrame:SetScript("OnEvent", function(self, event, ...)
    PersonalResource:SetAddonOutput("PersonalResource", 136075)
    PersonalResource:SetVersion(136075, "0.1.10")
    PersonalResourceG = PersonalResourceG or {}
    PersonalResource:InitSettings()
    PersonalResource:UpdateAll()
    RestoreFramePosition(frame, "mainFrame")
    RestoreFramePosition(petFrame, "petFrame")
end)

PersonalResource:RegisterEvent(initFrame, "PLAYER_LOGIN")
