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

addon.config.onLoad = function(self)
    BazCore:RegisterOptionsTable(ADDON_NAME, GetLandingPage)
    BazCore:AddToSettings(ADDON_NAME, "BazWidgets")
end
