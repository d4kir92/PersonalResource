-- By D4KiR
local _, PersonalResource = ...
local prset = nil
local DEFAULT_WIDTH = 600
local DEFAULT_HEIGHT = 400
local ADDED = "2026-11-21"
local LANGUAGES = {{"English", "enUS"}, {"Deutsch", "deDE"}, {"Español (España)", "esES"}, {"Español (México)", "esMX"}, {"Français", "frFR"}, {"Italiano", "itIT"}, {"한국어", "koKR"}, {"Português (Brasil)", "ptBR"}, {"Русский", "ruRU"}, {"简体中文", "zhCN"}, {"繁體中文", "zhTW"}}
local languageNames = {}
for _, info in ipairs(LANGUAGES) do
    languageNames[info[2]] = info[1]
end

function PersonalResource:GetLanguage()
    local lang = type(PersonalResourceG) == "table" and PersonalResourceG["LANGUAGE"] or nil
    if lang ~= nil and languageNames[lang] ~= nil then return lang end
    if languageNames[GetLocale()] ~= nil then return GetLocale() end
    return "enUS"
end

PersonalResource.LibTrans = PersonalResource.Trans
function PersonalResource:Trans(key, lang, ...)
    return PersonalResource.LibTrans(self, key, lang or PersonalResource:GetLanguage(), ...)
end

function PersonalResource:SetLanguage(lang)
    if languageNames[lang] == nil or lang == PersonalResource:GetLanguage() then return end
    PersonalResourceG = PersonalResourceG or {}
    if lang == GetLocale() then
        PersonalResourceG["LANGUAGE"] = nil
    else
        PersonalResourceG["LANGUAGE"] = lang
    end

    if prset ~= nil then
        prset:RefreshLanguage()
        if prset.prRefreshLanguageButton then prset.prRefreshLanguageButton() end
    end

    if PersonalResource.WhatsNew then PersonalResource.WhatsNew:RefreshLanguage() end
end

local function LanguageMenu(_, root)
    root:CreateTitle(PersonalResource:Trans("LID_LANGUAGE"))
    for _, info in ipairs(LANGUAGES) do
        local lang = info[2]
        root:CreateRadio(format("%s (%s)", info[1], lang), function() return PersonalResource:GetLanguage() == lang end, function() PersonalResource:SetLanguage(lang) end)
    end
end

function PersonalResource:AddLanguageButton(win)
    local parent = win.titleBar or win
    local button
    if PersonalResource:GetWoWBuild() == "RETAIL" and PersonalResource:CheckTemplates("WowStyle1DropdownTemplate") then
        button = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        button:SetScale(0.8)
        button:SetSize(162.5, 25)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -1.25)
        button:SetSelectionText(function() return languageNames[PersonalResource:GetLanguage()] end)
        button:SetTooltip(function(tooltip) tooltip:SetText(PersonalResource:Trans("LID_LANGUAGE")) end)
        button:SetupMenu(LanguageMenu)
    else
        button = PersonalResource:CreateButton(nil, parent)
        button:SetSize(130, 20)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, -2)
        button.Arrow = button:CreateTexture(nil, "OVERLAY")
        button.Arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        button.Arrow:SetSize(16, 16)
        button.Arrow:SetPoint("RIGHT", button, "RIGHT", -2, 0)
        button:SetScript("OnClick", function(sel)
            if MenuUtil and MenuUtil.CreateContextMenu then
                MenuUtil.CreateContextMenu(sel, LanguageMenu)
            else
                local current = 1
                for index, info in ipairs(LANGUAGES) do
                    if info[2] == PersonalResource:GetLanguage() then current = index end
                end

                PersonalResource:SetLanguage(LANGUAGES[current % #LANGUAGES + 1][2])
            end
        end)

        button:SetScript("OnEnter", function(sel)
            GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
            GameTooltip:SetText(PersonalResource:Trans("LID_LANGUAGE"))
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local function RefreshButton()
        button:SetText(languageNames[PersonalResource:GetLanguage()])
    end

    RefreshButton()
    win.Language = button
    return RefreshButton
end
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

local function AddCheckbox(key, dbkey, default, func, added, tooltip)
    return prset:AddCheckbox({
        ["label"] = "LID_" .. key,
        ["search"] = key,
        ["added"] = added,
        ["tooltip"] = tooltip,
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
    local enabled = false
    for _, key in ipairs({"HIDEWHENFULLHP", "HIDEWHENFULLPOWER", "HIDEWHENFULLENERGY", "HIDEWHENEMPTYRAGE"}) do
        if PersonalResource:GV(PersonalResourceG, prefix .. key, false) == true then enabled = true end
    end
    cb:SetEnabled(enabled)
    if enabled then
        cb.Label:SetTextColor(1, 0.82, 0, 1)
    else
        cb.Label:SetTextColor(0.5, 0.5, 0.5, 1)
    end
end

local CLASSPOWERS = {
    ENERGY = {DRUID = true, ROGUE = true, MONK = true},
    RAGE = {DRUID = true, WARRIOR = true},
    ONLYSPECIAL = {ROGUE = true, WARRIOR = true}
}

local function ClassHas(kind)
    local _, class = UnitClass("player")
    return CLASSPOWERS[kind][class] == true
end

local function AddVisibilityOptions(prefix)
    local function UpdateHide()
        UpdateHoverCheckbox(prefix)
        PersonalResource:UpdateAll()
    end

    local powerDefault = PersonalResource:GV(PersonalResourceG, prefix .. "HIDEWHENFULLPOWER", false)
    AddCategory(prefix .. "AUTOHIDE", 2)
    AddCheckbox(prefix .. "HIDEWHENFULLHP", prefix .. "HIDEWHENFULLHP", false, UpdateHide)
    if prefix ~= "" or not ClassHas("ONLYSPECIAL") then AddCheckbox(prefix .. "HIDEWHENFULLPOWER", prefix .. "HIDEWHENFULLPOWER", false, UpdateHide) end
    if prefix == "" and ClassHas("ENERGY") then AddCheckbox("HIDEWHENFULLENERGY", "HIDEWHENFULLENERGY", powerDefault, UpdateHide, ADDED) end
    if prefix == "" and ClassHas("RAGE") then AddCheckbox("HIDEWHENEMPTYRAGE", "HIDEWHENEMPTYRAGE", powerDefault, UpdateHide, ADDED) end
    AddCategory(prefix .. "SHOWANYWAY", 2)
    hoverCheckboxes[prefix] = AddCheckbox(prefix .. "SHOWONHOVER", prefix .. "SHOWONHOVER", false, function() PersonalResource:UpdateAll() end)
    AddCheckbox(prefix .. "SHOWINCOMBAT", prefix .. "SHOWINCOMBAT", false, function() PersonalResource:UpdateAll() end, ADDED)
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
        ["minWidth"] = 460,
        ["minHeight"] = 240,
        ["navigation"] = true,
        ["onResize"] = function(width, height)
            PersonalResource:SV(PersonalResourceG, "WINDOWWIDTH", width)
            PersonalResource:SV(PersonalResourceG, "WINDOWHEIGHT", height)
        end,
        ["getCollapsed"] = function(key) return GetCollapsed(key) end,
        ["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
        ["title"] = format("|T%s:16:16:0:0|t PersonalResource v%s", PersonalResource:GetAddonIcon(), PersonalResource:GetVersion())
    })

    prset.prRefreshLanguageButton = PersonalResource:AddLanguageButton(prset)
    PersonalResourceG["WHATSNEW"] = PersonalResourceG["WHATSNEW"] or {}
    PersonalResource.WhatsNew = PersonalResource:CreateUIWhatsNew({
        ["name"] = "PersonalResourceWhatsNew",
        ["title"] = format("|T%s:16:16:0:0|t PersonalResource v%s", PersonalResource:GetAddonIcon(), PersonalResource:GetVersion()),
        ["db"] = PersonalResourceG["WHATSNEW"],
        ["since"] = ADDED,
        ["getSettings"] = function() return prset end,
        ["addLanguageButton"] = function(win) return PersonalResource:AddLanguageButton(win) end
    })

    prset:SuspendLayout()
    prset:AddSearch()
    AddCategory("GENERAL")
    PersonalResource.WhatsNew:AddSettingsCheckbox(prset, ADDED)
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
    AddVisibilityOptions("")
    if PersonalResource:IsDruid() then
        AddCategory("DRUID", 2)
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
    AddCheckbox("SMARTWARNINGCOLORS", "SMARTWARNINGCOLORS", false, function() PersonalResource:UpdateAll() end, nil, "LID_SMARTWARNINGCOLORSTOOLTIP")
    prset:ResumeLayout()
    C_Timer.After(3, function() PersonalResource.WhatsNew:ShowIfNew() end)
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
