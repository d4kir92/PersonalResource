-- By D4KiR
local _, PersonalResource = ...
local prset = nil
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 400
function PersonalResource:ToggleSettings()
    if prset == nil then return end
    prset:Toggle()
end

local function GetCollapsed(key)
    if key == nil then return nil end
    if type(PersonalResourceG) ~= "table" then return nil end
    if type(PersonalResourceG["COLLAPSED"]) ~= "table" then return nil end
    return PersonalResourceG["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
    if key == nil then return end
    if type(PersonalResourceG) ~= "table" then return end
    if type(PersonalResourceG["COLLAPSED"]) ~= "table" then PersonalResourceG["COLLAPSED"] = {} end
    if collapsed then
        PersonalResourceG["COLLAPSED"][key] = true
    else
        PersonalResourceG["COLLAPSED"][key] = nil
    end
end

local function AddCategory(key, level)
    prset:AddCategory({
        ["label"] = "LID_" .. key,
        ["key"] = key,
        ["search"] = key,
        ["level"] = level
    })
end

local function AddCheckbox(key, dbkey, default, func)
    prset:AddCheckbox({
        ["label"] = "LID_" .. key,
        ["search"] = key,
        ["value"] = PersonalResource:GV(PersonalResourceG, dbkey, default),
        ["func"] = function(value)
            PersonalResource:SV(PersonalResourceG, dbkey, value)
            if func then func(value) end
        end
    })
end

local function AddSlider(key, dbkey, default, vmin, vmax, step, decimals, func)
    prset:AddSlider({
        ["label"] = "LID_" .. key,
        ["search"] = key,
        ["value"] = PersonalResource:GV(PersonalResourceG, dbkey, default),
        ["min"] = vmin,
        ["max"] = vmax,
        ["step"] = step,
        ["decimals"] = decimals,
        ["func"] = function(value)
            PersonalResource:SV(PersonalResourceG, dbkey, value)
            if func then func(value) end
        end
    })
end

function PersonalResource:InitSettings()
    PersonalResourceG = PersonalResourceG or {}
    prset = PersonalResource:CreateUIWindow({
        ["name"] = "PersonalResourceSettings",
        ["pTab"] = {"CENTER"},
        ["width"] = PersonalResource:GV(PersonalResourceG, "WINDOWWIDTH", DEFAULT_WIDTH),
        ["height"] = PersonalResource:GV(PersonalResourceG, "WINDOWHEIGHT", DEFAULT_HEIGHT),
        ["minWidth"] = 360,
        ["minHeight"] = 240,
        ["onResize"] = function(width, height)
            PersonalResource:SV(PersonalResourceG, "WINDOWWIDTH", width)
            PersonalResource:SV(PersonalResourceG, "WINDOWHEIGHT", height)
        end,
        ["getCollapsed"] = function(key) return GetCollapsed(key) end,
        ["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
        ["title"] = format("|T136075:16:16:0:0|t PersonalResource v%s", PersonalResource:GetVersion())
    })

    prset:SuspendLayout()
    prset:AddSearch()
    AddCategory("GENERAL")
    AddCheckbox("MMBTN", "MMBTN", PersonalResource:GetWoWBuild() ~= "RETAIL", function(value)
        if value then
            PersonalResource:ShowMMBtn("PersonalResource")
        else
            PersonalResource:HideMMBtn("PersonalResource")
        end
    end)

    AddCheckbox("LOCKED", "LOCKED", false, function() PersonalResource:UpdateFrames() end)
    AddCategory("BARS")
    AddSlider("WIDTH", "BARWIDTH", 200, 40, 800, 1, 0, function() PersonalResource:UpdateFrames() end)
    AddSlider("HEIGHT", "BARHEIGHT", 19, 4, 100, 1, 0, function() PersonalResource:UpdateFrames() end)
    AddSlider("SPACING", "BARSPACING", 5, 0, 100, 1, 0, function() PersonalResource:UpdateFrames() end)
    prset:ResumeLayout()
    PersonalResource:CreateMinimapButton({
        ["name"] = "PersonalResource",
        ["icon"] = 136075,
        ["dbtab"] = PersonalResourceG,
        ["vTT"] = {{"|T136075:16:16:0:0|t PersonalResource", "v" .. PersonalResource:GetVersion()}, {PersonalResource:Trans("LID_LEFTCLICK"), PersonalResource:Trans("LID_OPENSETTINGS")}, {PersonalResource:Trans("LID_SHIFTRIGHTCLICK"), PersonalResource:Trans("LID_HIDEMINIMAPBUTTON")}},
        ["funcL"] = function() PersonalResource:ToggleSettings() end,
        ["funcSR"] = function()
            PersonalResource:SV(PersonalResourceG, "MMBTN", false)
            PersonalResource:MSG("Minimap Button is now hidden.")
            PersonalResource:HideMMBtn("PersonalResource")
        end,
        ["dbkey"] = "MMBTN"
    })

    PersonalResource:AddSlash("pr", PersonalResource.ToggleSettings)
    PersonalResource:AddSlash("PersonalResource", PersonalResource.ToggleSettings)
end
