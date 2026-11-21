-- By D4KiR
local _, PersonalResource = ...
local prset = nil
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 400
local BARLABELS = {
    HEALTH = "LID_HEALTH",
    POWER = "LID_POWER",
    MANA = "LID_MANA",
    ENERGY = "LID_ALWAYSSHOWDRUIDENERGY",
    RAGE = "LID_ALWAYSSHOWDRUIDRAGE",
    COMBO = "LID_COMBOPOINTS"
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
    return prset:AddCheckbox({
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

local hoverCheckboxes = {}
local function UpdateHoverCheckbox(prefix)
    local cb = hoverCheckboxes[prefix]
    if cb == nil then return end
    local enabled = PersonalResource:GV(PersonalResourceG, prefix .. "HIDEWHENFULLHP", false) == true or PersonalResource:GV(PersonalResourceG, prefix .. "HIDEWHENFULLPOWER", false) == true
    cb:SetEnabled(enabled)
    if enabled then
        cb.Label:SetTextColor(1, 0.82, 0, 1)
    else
        cb.Label:SetTextColor(0.5, 0.5, 0.5, 1)
    end
end

local function AddVisibilityOptions(prefix)
    hoverCheckboxes[prefix] = AddCheckbox(prefix .. "SHOWONHOVER", prefix .. "SHOWONHOVER", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox(prefix .. "HIDEWHENFULLHP", prefix .. "HIDEWHENFULLHP", false, function()
        UpdateHoverCheckbox(prefix)
        PersonalResource:UpdateAll()
    end)

    AddCheckbox(prefix .. "HIDEWHENFULLPOWER", prefix .. "HIDEWHENFULLPOWER", false, function()
        UpdateHoverCheckbox(prefix)
        PersonalResource:UpdateAll()
    end)

    AddCheckbox(prefix .. "SHOWINCOMBAT", prefix .. "SHOWINCOMBAT", false, function() PersonalResource:UpdateAll() end)
end

local function AddBarOrder(prefix, category, order)
    local items = {}
    local native = PersonalResource:UsesNativeDisplay()
    for _, key in ipairs(order) do
        local label = BARLABELS[key]
        if prefix == "DRUIDBARSLOT" and key == "POWER" then
            label = "LID_ALTERNATEPOWER"
        elseif prefix == "DRUIDBARSLOT" and key == "MANA" then
            label = "LID_POWER"
        elseif native and prefix == "BARSLOT" then
            if key == "MANA" then label = "LID_ALTERNATEPOWER" end
            if key == "COMBO" then label = "LID_CLASSRESOURCE" end
        end
        items[#items + 1] = {key = key, label = label, checkable = false}
    end
    prset:AddOrderList({
        label = "LID_" .. category,
        search = category,
        items = items,
        func = function(orderedItems)
            for index, item in ipairs(orderedItems) do
                PersonalResource:SV(PersonalResourceG, prefix .. index, item.key)
            end
            PersonalResource:UpdateAll()
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
        ["title"] = format("|T%s:16:16:0:0|t PersonalResource v%s", PersonalResource:GetAddonIcon(), PersonalResource:GetVersion())
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

    if not PersonalResource:UsesNativeDisplay() then
        AddCheckbox("LOCKED", "LOCKED", false, function() PersonalResource:UpdateAll() end)
    end
    AddCategory("BARS")
    AddSlider("WIDTH", "BARWIDTH", 200, 40, 400, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("HEIGHT", "BARHEIGHT", 19, 4, 64, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("SPACING", "BARSPACING", 0, 0, 32, 1, 0, function() PersonalResource:UpdateAll() end)
    AddCategory("VISIBILITY", 2)
    AddVisibilityOptions("")
    if PersonalResource:IsDruid() then
        local function UpdateDruidBars()
            PersonalResource:UpdateDruidPowerVisibility()
            PersonalResource:UpdateAll()
        end
        AddCheckbox("ALWAYSSHOWDRUIDENERGY", "ALWAYSSHOWDRUIDENERGY", PersonalResource:AlwaysShowDruidResource("ENERGY"), UpdateDruidBars)
        AddCheckbox("ALWAYSSHOWDRUIDRAGE", "ALWAYSSHOWDRUIDRAGE", PersonalResource:AlwaysShowDruidResource("RAGE"), UpdateDruidBars)
    end
    AddCategory("COMBOPOINTS", 2)
    AddCheckbox("SHOWCOMBOPOINTS", "SHOWCOMBOPOINTS", true, function() PersonalResource:UpdateAll() end)
    if PersonalResource:IsDruid() then
        AddCheckbox("ALWAYSSHOWDRUIDCOMBO", "ALWAYSSHOWDRUIDCOMBO", false, function()
            PersonalResource:UpdateDruidPowerVisibility()
            PersonalResource:UpdateAll()
        end)
    end
    AddSlider("COMBOSIZE", "COMBOPOINTSIZE", 20, 6, 48, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("COMBOSPACING", "COMBOPOINTSPACING", 4, 0, 32, 1, 0, function() PersonalResource:UpdateAll() end)
    AddCategory("BARORDER", 2)
    AddBarOrder(PersonalResource:GetBarOrderPrefix(), "BARORDER", PersonalResource:GetBarOrder())
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
    if PersonalResource:UsesNativeDisplay() then
        AddCheckbox("LOCKED", "LOCKED", false, function() PersonalResource:UpdateAll() end)
    end
    AddCheckbox("SHOWPETFRAME", "SHOWPETFRAME", true, function() PersonalResource:UpdateAll() end)
    AddSlider("PETWIDTH", "PETBARWIDTH", 150, 40, 400, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("PETHEIGHT", "PETBARHEIGHT", 14, 4, 64, 1, 0, function() PersonalResource:UpdateAll() end)
    AddSlider("PETSPACING", "PETBARSPACING", 0, 0, 32, 1, 0, function() PersonalResource:UpdateAll() end)
    AddCategory("PETVISIBILITY", 2)
    AddVisibilityOptions("PET")
    AddCategory("PETBARORDER", 2)
    AddBarOrder("PETBARSLOT", "PETBARORDER", PersonalResource:GetPetBarOrder())
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
    UpdateHoverCheckbox("")
    UpdateHoverCheckbox("PET")
    PersonalResource:CreateMinimapButton({
        ["name"] = "PersonalResource",
        ["icon"] = PersonalResource:GetAddonIcon(),
        ["dbtab"] = PersonalResourceG,
        ["vTT"] = {{format("|T%s:16:16:0:0|t PersonalResource", PersonalResource:GetAddonIcon()),"v" .. PersonalResource:GetVersion()}, {PersonalResource:Trans("LID_LEFTCLICK"), PersonalResource:Trans("LID_OPENSETTINGS")}, {PersonalResource:Trans("LID_SHIFTRIGHTCLICK"), PersonalResource:Trans("LID_HIDEMINIMAPBUTTON")}},
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
