local _, PersonalResource = ...
local DISPLAY_MODE = GetCVar("statusText") or "BOTH"
local frame = CreateFrame("Frame", "PersonalResourceFrame", UIParent)
frame:SetSize(200, 100)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
local hpBar = CreateFrame("StatusBar", "PersonalResourceHPBar", frame)
hpBar:SetSize(200, 20)
hpBar:SetPoint("TOP", frame, "TOP", 0, 0)
hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
hpBar:SetStatusBarColor(0.0, 0.8, 0.0, 1.0)
local hpLeftText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hpLeftText:SetPoint("LEFT", hpBar, "LEFT", 2, 0)
hpLeftText:SetJustifyH("LEFT")
local hpCenterText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hpCenterText:SetPoint("CENTER", hpBar, "CENTER", 0, 0)
hpCenterText:SetJustifyH("CENTER")
local hpRightText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hpRightText:SetPoint("RIGHT", hpBar, "RIGHT", -2, 0)
hpRightText:SetJustifyH("RIGHT")
local powerBar = CreateFrame("StatusBar", "PersonalResourcePowerBar", frame)
powerBar:SetSize(200, 20)
powerBar:SetPoint("TOP", hpBar, "BOTTOM", 0, -5)
powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
powerBar:SetStatusBarColor(0.0, 0.3, 1.0, 1.0)
local powerLeftText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
powerLeftText:SetPoint("LEFT", powerBar, "LEFT", 2, 0)
powerLeftText:SetJustifyH("LEFT")
local powerCenterText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
powerCenterText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
powerCenterText:SetJustifyH("CENTER")
local powerRightText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
powerRightText:SetPoint("RIGHT", powerBar, "RIGHT", -2, 0)
powerRightText:SetJustifyH("RIGHT")
function PersonalResource:UpdateHealth()
    local unit = "player"
    if UnitExists(unit) and UnitIsConnected(unit) then
        local hp = UnitHealth(unit)
        local maxHP = UnitHealthMax(unit)
        hpBar:SetMinMaxValues(0, maxHP)
        hpBar:SetValue(hp)
        local percent = math.floor((hp / maxHP) * 100)
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

function PersonalResource:OnDisplayModeChanged()
    DISPLAY_MODE = GetCVar("statusText") or "BOTH"
    PersonalResource:UpdateHealth()
    PersonalResource:UpdatePower()
end

local cvarFrame = CreateFrame("Frame")
cvarFrame:SetScript("OnEvent", function(self, event, ...) if event == "CVAR_UPDATE" and arg1 == "statusText" then PersonalResource:OnDisplayModeChanged() end end)
cvarFrame:RegisterEvent("CVAR_UPDATE")
local healthFrame = CreateFrame("Frame")
healthFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdateHealth() end)
healthFrame:RegisterEvent("UNIT_HEALTH")
healthFrame:RegisterEvent("UNIT_MAXHEALTH")
healthFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
local powerFrame = CreateFrame("Frame")
powerFrame:SetScript("OnEvent", function(self, event, ...) PersonalResource:UpdatePower() end)
powerFrame:RegisterEvent("UNIT_POWER_UPDATE")
powerFrame:RegisterEvent("UNIT_MAXPOWER")
powerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
local initFrame = CreateFrame("Frame")
initFrame:SetScript("OnEvent", function(self, event, ...)
    PersonalResource:SetAddonOutput("PersonalResource", 136075)
    PersonalResource:OnDisplayModeChanged()
    PersonalResource:MSG("INIT")
end)

initFrame:RegisterEvent("PLAYER_LOGIN")
