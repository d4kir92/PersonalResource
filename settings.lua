-- By D4KiR
local _, PersonalResource = ...
local prset = nil
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 400
local BARKEYS = {"HEALTH", "POWER", "MANA", "COMBO"}
local BARCHOICES = {
    {
        ["value"] = "HEALTH",
        ["label"] = "LID_HEALTH"
    },
    {
        ["value"] = "POWER",
        ["label"] = "LID_POWER"
    },
    {
        ["value"] = "MANA",
        ["label"] = "LID_MANA"
    },
    {
        ["value"] = "COMBO",
        ["label"] = "LID_COMBOPOINTS"
    }
}

local PETBARKEYS = {"HEALTH", "POWER"}
local PETBARCHOICES = {
    {
        ["value"] = "HEALTH",
        ["label"] = "LID_HEALTH"
    },
    {
        ["value"] = "POWER",
        ["label"] = "LID_POWER"
    }
}

local SLOTKEYS = {
    ["BARSLOT"] = BARKEYS,
    ["PETBARSLOT"] = PETBARKEYS
}

local SLOTCHOICES = {
    ["BARSLOT"] = BARCHOICES,
    ["PETBARSLOT"] = PETBARCHOICES
}

local slotHolders = {
    ["BARSLOT"] = {},
    ["PETBARSLOT"] = {}
}
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

local function GetBarSlot(prefix, index)
    return PersonalResource:GV(PersonalResourceG, prefix .. index, SLOTKEYS[prefix][index])
end

local function SetBarSlot(prefix, index, value)
    local old = GetBarSlot(prefix, index)
    if old == value then return end
    local holders = slotHolders[prefix]
    for i = 1, #SLOTKEYS[prefix] do
        if i ~= index and GetBarSlot(prefix, i) == value then
            PersonalResource:SV(PersonalResourceG, prefix .. i, old)
            if holders[i] then holders[i]:SetValue(old) end
        end
    end

    PersonalResource:SV(PersonalResourceG, prefix .. index, value)
    PersonalResource:UpdateAll()
end

local function AddBarSlot(prefix, index)
    slotHolders[prefix][index] = prset:AddDropdown({
        ["label"] = "LID_" .. prefix .. index,
        ["search"] = prefix .. index,
        ["value"] = GetBarSlot(prefix, index),
        ["choices"] = SLOTCHOICES[prefix],
        ["func"] = function(value) SetBarSlot(prefix, index, value) end
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

    AddCheckbox("LOCKED", "LOCKED", false, function() PersonalResource:UpdateAll() end)
    AddCategory("BARS")
    AddSlider("WIDTH", "BARWIDTH", 200, 40, 400, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("HEIGHT", "BARHEIGHT", 19, 4, 64, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("SPACING", "BARSPACING", 0, 0, 32, 1, 0, function() PersonalResource:UpdateAll() end)
    AddCategory("VISIBILITY", 2)
    AddCheckbox("SHOWONHOVER", "SHOWONHOVER", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("HIDEWHENFULLHP", "HIDEWHENFULLHP", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("HIDEWHENFULLMANA", "HIDEWHENFULLMANA", false, function() PersonalResource:UpdateAll() end)
    AddCategory("COMBOPOINTS", 2)
    AddCheckbox("SHOWCOMBOPOINTS", "SHOWCOMBOPOINTS", true, function() PersonalResource:UpdateAll() end)
    AddSlider("COMBOSIZE", "COMBOPOINTSIZE", 20, 6, 48, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("COMBOSPACING", "COMBOPOINTSPACING", 4, 0, 32, 1, 0, function() PersonalResource:UpdateAll() end)
    AddCategory("BARORDER", 2)
    AddBarSlot("BARSLOT", 1)
    AddBarSlot("BARSLOT", 2)
    AddBarSlot("BARSLOT", 3)
    AddBarSlot("BARSLOT", 4)
    AddCategory("TEXT")
    AddCategory("HEALTH", 2)
    AddCheckbox("SHOWHEALTHVALUE", "SHOWHEALTHVALUE", true, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWMAXHEALTHVALUE", "SHOWMAXHEALTHVALUE", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWHEALTHPERCENTAGE", "SHOWHEALTHPERCENTAGE", true, function() PersonalResource:UpdateAll() end)
    AddCategory("POWER", 2)
    AddCheckbox("SHOWPOWERVALUE", "SHOWPOWERVALUE", true, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWMAXPOWERVALUE", "SHOWMAXPOWERVALUE", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWPOWERPERCENTAGE", "SHOWPOWERPERCENTAGE", true, function() PersonalResource:UpdateAll() end)
    AddCategory("PET")
    AddCheckbox("SHOWPETFRAME", "SHOWPETFRAME", true, function() PersonalResource:UpdateAll() end)
    AddSlider("PETWIDTH", "PETBARWIDTH", 150, 40, 400, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("PETHEIGHT", "PETBARHEIGHT", 14, 4, 64, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("PETSPACING", "PETBARSPACING", 0, 0, 32, 1, 0, function() PersonalResource:UpdateAll() end)
    AddCategory("PETVISIBILITY", 2)
    AddCheckbox("PETSHOWONHOVER", "PETSHOWONHOVER", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("PETHIDEWHENFULLHP", "PETHIDEWHENFULLHP", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("PETHIDEWHENFULLMANA", "PETHIDEWHENFULLMANA", false, function() PersonalResource:UpdateAll() end)
    AddCategory("PETBARORDER", 2)
    AddBarSlot("PETBARSLOT", 1)
    AddBarSlot("PETBARSLOT", 2)
    AddCategory("PETTEXT")
    AddCategory("PETHEALTH", 2)
    AddCheckbox("SHOWPETHEALTHVALUE", "SHOWPETHEALTHVALUE", true, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWPETMAXHEALTHVALUE", "SHOWPETMAXHEALTHVALUE", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWPETHEALTHPERCENTAGE", "SHOWPETHEALTHPERCENTAGE", true, function() PersonalResource:UpdateAll() end)
    AddCategory("PETPOWER", 2)
    AddCheckbox("SHOWPETPOWERVALUE", "SHOWPETPOWERVALUE", true, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWPETMAXPOWERVALUE", "SHOWPETMAXPOWERVALUE", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SHOWPETPOWERPERCENTAGE", "SHOWPETPOWERPERCENTAGE", true, function() PersonalResource:UpdateAll() end)
    AddCategory("COLORS")
    AddCheckbox("USECLASSCOLOR", "USECLASSCOLOR", true, function() PersonalResource:UpdateAll() end)
    AddCheckbox("SMARTWARNINGCOLORS", "SMARTWARNINGCOLORS", false, function() PersonalResource:UpdateAll() end)
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
