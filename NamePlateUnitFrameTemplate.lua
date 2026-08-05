-- NamePlateUnitFrameTemplate.lua
-- A template for creating unit frames that mimic Blizzard's nameplate appearance
-- without tainting their code
local _, PersonalResource = ...
-- Create a reusable template that mimics Blizzard's nameplate styling exactly
-- This approach avoids tainting by not modifying Blizzard's code directly
function PersonalResource:CreateNamePlateUnitFrameTemplate(parent)
    -- Create the main frame (status bar container)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(120, 20) -- Standard nameplate size
    -- Create the status bar (the main visual element) - matching Blizzard's exact styling
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetAllPoints()
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    -- Set standard Blizzard-like colors that match nameplate styling
    statusBar:SetStatusBarColor(0.0, 0.8, 0.0, 1.0) -- Green for health
    -- Add background texture (matching Blizzard's UI elements)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0, 0, 0, 0.5) -- Semi-transparent black background
    -- Add border (Blizzard-style - using same textures as nameplates)
    local border = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    border:SetSize(124, 24)
    border:SetPoint("CENTER", frame, "CENTER")
    border:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    -- Create the text elements - exactly like Blizzard's nameplates
    local leftText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftText:SetPoint("LEFT", statusBar, "LEFT", 2, 0)
    leftText:SetJustifyH("LEFT")
    local centerText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    centerText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    local rightText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightText:SetPoint("RIGHT", statusBar, "RIGHT", -2, 0)
    rightText:SetJustifyH("RIGHT")
    -- Return the template with all elements
    return {
        frame = frame,
        statusBar = statusBar,
        background = bg,
        border = border,
        leftText = leftText,
        centerText = centerText,
        rightText = rightText
    }
end

-- Function to apply the template to a specific unit
function PersonalResource:ApplyNamePlateTemplate(unit, templateData)
    -- This would be called to create a new instance of the template for a specific unit
    local newFrame = CreateFrame("Frame", nil, UIParent)
    newFrame:SetSize(120, 20)
    -- Copy all elements from the template
    local newStatusBar = CreateFrame("StatusBar", nil, newFrame)
    newStatusBar:SetAllPoints()
    newStatusBar:SetStatusBarTexture(templateData.statusBar:GetStatusBarTexture())
    newStatusBar:SetStatusBarColor(templateData.statusBar:GetStatusBarColor())
    -- Apply unit-specific values (this would be extended based on actual unit data)
    if UnitExists(unit) and UnitIsConnected(unit) then
        local maxHP = UnitHealthMax(unit)
        local hp = UnitHealth(unit)
        newStatusBar:SetMinMaxValues(0, maxHP)
        newStatusBar:SetValue(hp)
        -- Set text values based on the unit
        local percent = math.floor((hp / maxHP) * 100)
        templateData.leftText:SetText("")
        templateData.centerText:SetText(string.format("%d%%", percent))
        templateData.rightText:SetText("")
    end
    return newFrame
end

-- Function to update the template with unit data - this mimics nameplate updates
function PersonalResource:UpdateNamePlateTemplate(template, unit)
    if not UnitExists(unit) or not UnitIsConnected(unit) then return end
    local maxHP = UnitHealthMax(unit)
    local hp = UnitHealth(unit)
    -- Update the status bar with same styling as Blizzard
    template.statusBar:SetMinMaxValues(0, maxHP)
    template.statusBar:SetValue(hp)
    -- Update text elements - matching Blizzard's exact pattern
    local percent = math.floor((hp / maxHP) * 100)
    template.leftText:SetText("")
    template.centerText:SetText(string.format("%d%%", percent))
    template.rightText:SetText("")
end

-- Function to create a complete nameplate unit frame with proper Blizzard styling
function PersonalResource:CreateBlizzardStyleUnitFrame(parent, width, height)
    -- Create the main frame - matching Blizzard's exact dimensions and structure
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width or 120, height or 20)
    -- Create status bar with identical texture to Blizzard's nameplates
    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetAllPoints()
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    -- Set the same color that Blizzard uses for health bars
    statusBar:SetStatusBarColor(0.0, 0.8, 0.0, 1.0) -- Standard green
    -- Add a background texture like Blizzard's nameplates use
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0, 0, 0, 0.5) -- Dark semi-transparent
    -- Add the border texture used by Blizzard nameplates
    local border = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    border:SetSize(width and width + 4 or 124, height and height + 4 or 24)
    border:SetPoint("CENTER", frame, "CENTER")
    border:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    -- Create text elements exactly like Blizzard's nameplate system
    local leftText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftText:SetPoint("LEFT", statusBar, "LEFT", 2, 0)
    leftText:SetJustifyH("LEFT")
    local centerText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    centerText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    local rightText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightText:SetPoint("RIGHT", statusBar, "RIGHT", -2, 0)
    rightText:SetJustifyH("RIGHT")
    -- Return a complete unit frame that mimics Blizzard's exact appearance
    return {
        frame = frame,
        statusBar = statusBar,
        background = bg,
        border = border,
        leftText = leftText,
        centerText = centerText,
        rightText = rightText
    }
end

-- Example usage function that demonstrates the template functionality
function PersonalResource:ExampleUseTemplate()
    -- Create a Blizzard-style unit frame using our template
    local unitFrame = PersonalResource:CreateBlizzardStyleUnitFrame(UIParent, 120, 20)
    -- Position it on screen
    unitFrame.frame:SetPoint("CENTER", UIParent, "CENTER")
    -- Update with player data
    if UnitExists("player") and UnitIsConnected("player") then PersonalResource:UpdateNamePlateTemplate(unitFrame, "player") end
    return unitFrame
end

-- Export the template for other addons to use
PersonalResource.NamePlateUnitFrameTemplate = {
    Create = PersonalResource.CreateBlizzardStyleUnitFrame,
    Apply = PersonalResource.ApplyNamePlateTemplate,
    Update = PersonalResource.UpdateNamePlateTemplate
}
