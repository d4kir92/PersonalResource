local _, PersonalResource = ...
local oldPowerType = nil
local oldShapeshift = nil
local DISPLAY_MODE = GetCVar("statusText") or "BOTH"
local frame = CreateFrame("Frame", "PersonalResourceFrame", UIParent)
frame:SetSize(200, 100)
frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then self:StartMoving() end end)
frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        if xOfs < 15 and xOfs > -15 then xOfs = 0 end
        if yOfs < 15 and yOfs > -15 then yOfs = 0 end
        if not PersonalResourceG then PersonalResourceG = {} end
        if not PersonalResourceG["mainFrame"] then PersonalResourceG["mainFrame"] = {} end
        PersonalResourceG["mainFrame"]["position"] = {point, relativePoint, xOfs, yOfs}
        frame:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
    end
end)

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
function PersonalResource:UpdateHealth()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local hp = UnitHealth(unit)
        local maxHP = UnitHealthMax(unit)
        hpBar:SetMinMaxValues(0, maxHP)
        hpBar:SetValue(hp)
        local percent = math.floor((hp / maxHP) * 100)
        local classColor = {
            r = 0.2,
            g = 1,
            b = 0.2
        }

        if UnitExists("player") then
            local _, class = UnitClass("player")
            if class then
                local r, g, b = GetClassColor(class)
                if r and g and b then
                    classColor = {
                        r = r,
                        g = g,
                        b = b
                    }
                end
            end
        end

        hpBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1.0)
        if DISPLAY_MODE == "NUMERIC" then
            hpLeftText:SetText("")
            hpCenterText:SetText(string.format("%d", hp))
            hpRightText:SetText("")
        elseif DISPLAY_MODE == "PERCENT" then
            hpLeftText:SetText("")
            hpCenterText:SetText(string.format("%d%%", percent))
            hpRightText:SetText("")
        elseif DISPLAY_MODE == "BOTH" then
            hpLeftText:SetText(string.format("%d%%", percent))
            hpCenterText:SetText("")
            hpRightText:SetText(string.format("%d", hp))
        else
            hpLeftText:SetText(string.format("%d%%", percent))
            hpCenterText:SetText("")
            hpRightText:SetText(string.format("%d", hp))
        end
    end
end

function PersonalResource:UpdatePower()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        powerBar:SetMinMaxValues(0, maxPower)
        powerBar:SetValue(power)
        local percent = math.floor((power / maxPower) * 100)
        if DISPLAY_MODE == "NUMERIC" then
            powerLeftText:SetText("")
            powerCenterText:SetText(string.format("%d", power))
            powerRightText:SetText("")
        elseif DISPLAY_MODE == "PERCENT" then
            powerLeftText:SetText("")
            powerCenterText:SetText(string.format("%d%%", percent))
            powerRightText:SetText("")
        elseif DISPLAY_MODE == "BOTH" then
            powerLeftText:SetText(string.format("%d%%", percent))
            powerCenterText:SetText("")
            powerRightText:SetText(string.format("%d", power))
        else
            powerLeftText:SetText(string.format("%d%%", percent))
            powerCenterText:SetText("")
            powerRightText:SetText(string.format("%d", power))
        end
    end
end

function PersonalResource:UpdatePowerType()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local powerType = UnitPowerType(unit)
        if PowerBarColor and PowerBarColor[powerType] then
            local color = PowerBarColor[powerType]
            powerBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1.0)
        else
            local classColor = {
                r = 0.8,
                g = 0.8,
                b = 0.8
            }

            if UnitExists("player") then
                local _, class = UnitClass("player")
                if class then
                    local r, g, b = GetClassColor(class)
                    if r and g and b then
                        classColor = {
                            r = r,
                            g = g,
                            b = b
                        }
                    else
                        classColor = {
                            r = 0.0,
                            g = 0.3,
                            b = 1.0
                        }
                    end
                end
            end

            powerBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1.0)
        end
    end
end

function PersonalResource:OnDisplayModeChanged()
    DISPLAY_MODE = GetCVar("statusText") or "BOTH"
    PersonalResource:UpdateHealth()
    PersonalResource:UpdatePower()
    PersonalResource:UpdatePowerType()
end

local cvarFrame = CreateFrame("Frame")
cvarFrame:SetScript("OnEvent", function(self, event, ...) if event == "CVAR_UPDATE" and arg1 == "statusText" then PersonalResource:OnDisplayModeChanged() end end)
PersonalResource:RegisterEvent(cvarFrame, "CVAR_UPDATE")
local healthFrame = CreateFrame("Frame")
healthFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdateHealth() end)
PersonalResource:RegisterEvent(healthFrame, "UNIT_HEALTH", "player")
PersonalResource:RegisterEvent(healthFrame, "UNIT_MAXHEALTH", "player")
local powerFrame = CreateFrame("Frame")
powerFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdatePower() end)
PersonalResource:RegisterEvent(powerFrame, "UNIT_POWER_UPDATE", "player")
PersonalResource:RegisterEvent(powerFrame, "UNIT_MAXPOWER", "player")
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
        C_Timer.After(0.2, function() PersonalResource:UpdatePowerType() end)
    end
end)

PersonalResource:RegisterEvent(shapeshiftFrame, "UPDATE_SHAPESHIFT_FORM")
local initFrame = CreateFrame("Frame")
initFrame:SetScript("OnEvent", function(self, event, ...)
    PersonalResource:SetAddonOutput("PersonalResource", 136075)
    PersonalResource:SetVersion(136075, "0.1.5")
    PersonalResource:OnDisplayModeChanged()
    if PersonalResourceG and PersonalResourceG["mainFrame"] and PersonalResourceG["mainFrame"]["position"] then
        local point, relativePoint, xOfs, yOfs = unpack(PersonalResourceG["mainFrame"]["position"])
        if xOfs < 15 and xOfs > -15 then xOfs = 0 end
        if yOfs < 15 and yOfs > -15 then yOfs = 0 end
        frame:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
    end
end)

PersonalResource:RegisterEvent(initFrame, "PLAYER_LOGIN")
