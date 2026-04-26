---------------------------------------------------------------------------
-- BazWidgets — widget pack for BazWidgetDrawers
--
-- Registers with BazCore so the pack appears as its own tab in the
-- BazCore options window. Individual widgets register themselves with
-- the BWD widget host via BazCore:RegisterDockableWidget; this file
-- only handles the addon-level registration (tab, slash, profiles).
---------------------------------------------------------------------------

local ADDON_NAME = "BazWidgets"

local addon
addon = BazCore:RegisterAddon(ADDON_NAME, {
    title         = "BazWidgets",
    savedVariable = "BazWidgetsDB",
    profiles      = true,
    defaults      = {},

    slash = { "/bw", "/bazwidgets" },
    commands = {},

    minimap = {
        label = "BazWidgets",
        icon  = 134395,  -- Interface\Icons\INV_Misc_Gear_01
    },
})

---------------------------------------------------------------------------
-- Options pages
---------------------------------------------------------------------------

local function GetLandingPage()
    return BazCore:CreateLandingPage("BazWidgets", {
        subtitle    = "Widget pack for BazWidgetDrawers",
        description = "A pack of ready-to-dock widgets for " ..
            "BazWidgetDrawers covering activities, character info, " ..
            "currency, navigation, weekly progress, and utilities. " ..
            "Each widget is configured individually inside the " ..
            "BazWidgetDrawers options window.",
        features = "Dungeon Finder, Active Delve, Companion, Bountiful Tracker, " ..
            "Delve Timer, Hearthstone CD, Reset Timers, Free Bag Slots, " ..
            "Performance, Pull Timer, Trinket Tracker, Tracked Reputation, " ..
            "Repair, Gold Tracker, Coordinates, Speed Monitor, Stat Summary, " ..
            "Currency Bar, Note Pad, Stopwatch, Todo List, Weekly Checklist, " ..
            "Collection Counter, Calculator.",
        guide = {
            { "Open BazWidgetDrawers", "All widgets dock inside BWD's drawer" },
            { "Enable widgets",         "BazWidgetDrawers → Widgets → toggle each one" },
            { "Configure each widget",  "Click a widget in the list for its per-widget settings" },
            { "User Manual",            "See the User Manual tab for a tour of every widget" },
        },
    })
end

---------------------------------------------------------------------------
-- Widgets sub-page — enable/disable each pack widget
--
-- Single source of truth is BWD's `widgetEnabled` per-profile setting,
-- so toggling here syncs with BWD's own Widgets page automatically.
-- Disabling here removes the widget from BWD entirely (it's hidden
-- from every drawer and unfloats if it was floating).
---------------------------------------------------------------------------

local function GetWidgetsPage()
    local args = {
        intro = {
            order = 0.1,
            type  = "lead",
            text  = "Enable or disable each BazWidgets pack widget. Toggling here is shared with the BazWidgetDrawers Widgets page — disabled widgets do not appear in any drawer at all.",
        },
        widgetsHeader = {
            order = 1,
            type  = "header",
            name  = "Pack Widgets",
        },
    }

    local bwd = BazCore.GetAddon and BazCore:GetAddon("BazWidgetDrawers")
    if not bwd then
        args.bwdMissing = {
            order = 2,
            type  = "note",
            style = "warning",
            text  = "BazWidgetDrawers is not loaded. Widgets cannot be enabled or disabled until it loads.",
        }
        return { name = "Widgets", type = "group", args = args }
    end

    -- Collect every registered dockable widget owned by this pack
    -- (id prefix `bazwidgets_` is the suite-wide convention).
    local owned = {}
    local all = (BazCore.GetDockableWidgets and BazCore:GetDockableWidgets()) or {}
    for _, w in ipairs(all) do
        if type(w.id) == "string" and w.id:sub(1, 11) == "bazwidgets_" then
            owned[#owned + 1] = w
        end
    end
    table.sort(owned, function(a, b)
        return (a.label or a.id) < (b.label or b.id)
    end)

    if #owned == 0 then
        args.empty = {
            order = 2,
            type  = "note",
            style = "info",
            text  = "No BazWidgets pack widgets registered yet. They register on PLAYER_LOGIN — try /reload if this list looks empty.",
        }
        return { name = "Widgets", type = "group", args = args }
    end

    local order = 10
    for _, w in ipairs(owned) do
        local id = w.id
        local label = w.label or id
        args["widget_" .. id] = {
            order = order,
            type  = "toggle",
            name  = label,
            desc  = "Show " .. label .. " in BazWidgetDrawers. Disabled widgets are hidden from every drawer and any floating window.",
            get   = function() return bwd:IsWidgetEnabled(id) end,
            set   = function(_, val)
                if bwd.WidgetHost and bwd.WidgetHost.SetWidgetEnabled then
                    bwd.WidgetHost:SetWidgetEnabled(id, val)
                else
                    bwd:SetWidgetEnabled(id, val)
                end
            end,
        }
        order = order + 1
    end

    return { name = "Widgets", type = "group", args = args }
end

addon.config.onLoad = function(self)
    BazCore:RegisterOptionsTable(ADDON_NAME, GetLandingPage)
    BazCore:AddToSettings(ADDON_NAME, "BazWidgets")

    BazCore:RegisterOptionsTable(ADDON_NAME .. "-Widgets", GetWidgetsPage)
    BazCore:AddToSettings(ADDON_NAME .. "-Widgets", "Widgets", ADDON_NAME)
end
