---------------------------------------------------------------------------
-- BazWidgets User Guide
---------------------------------------------------------------------------

if not BazCore or not BazCore.RegisterUserGuide then return end

BazCore:RegisterUserGuide("BazWidgets", {
    title = "BazWidgets",
    intro = "A pack of 13 ready-to-dock widgets for BazWidgetDrawers — covering activities, character info, currency, navigation, weekly progress, and utilities.",
    pages = {
        {
            title = "Welcome",
            blocks = {
                { type = "lead", text = "BazWidgets serves two purposes: it provides useful widgets that extend BazWidgetDrawers beyond its core set, and it acts as a reference implementation for third-party addon authors building their own widget packs." },
                { type = "h2", text = "Visual style" },
                { type = "paragraph", text = "Every widget follows a consistent look:" },
                { type = "list", items = {
                    "Leading icon at the top-left",
                    "Gold accent for primary values",
                    "Dim grey for secondary text",
                    "Live status text in the title bar (count, value, summary)",
                    "Dynamic resizing based on content",
                }},
                { type = "note", style = "info", text = "Some widgets are |cffffd700dormant|r — they only appear in the drawer when relevant. Dormant widgets are marked with |cffffd700[D]|r in the Widgets settings list and can be reordered while dormant." },
            },
        },
        {
            title = "Activity & Group",
            blocks = {
                { type = "h2", text = "Dungeon Finder" },
                { type = "lead", text = "Dormant queue status panel — auto-appears when you queue for a dungeon." },
                { type = "list", items = {
                    "Role fill indicators (tank / healer / DPS) with color-coded counts",
                    "Average wait time estimate",
                    "Live queue timer in the title bar",
                    "Dungeon name subtitle",
                    "Leave Queue button",
                    "Title turns green on Group Found",
                }},
                { type = "note", style = "tip", text = "This widget replaces the standalone BazDungeonFinder addon. No slot is consumed when you're not queued." },
            },
        },
        {
            title = "Character & Gear",
            blocks = {
                { type = "h2", text = "Repair" },
                { type = "list", items = {
                    "Three-column durability display: paper-doll / damaged-slot list / durability percent",
                    "Worst-damaged slots first, color-graded green→red",
                    "Average durability in the title bar",
                    "Three paper-doll modes: custom icon grid, native DurabilityFrame, or none",
                    "Optional taint-safe suppression of Blizzard's default durability figure",
                }},
                { type = "h2", text = "Stat Summary" },
                { type = "list", items = {
                    "Item level header with statue icon",
                    "Color-coded secondary stat rows: Crit (gold), Haste (cyan), Mastery (pink), Versatility (green)",
                    "Live updates on equipment and rating changes",
                }},
                { type = "h2", text = "Collection Counter" },
                { type = "list", items = {
                    "Mount and pet collection progress",
                    "Owned / total / % display",
                    "Force-loads Blizzard_Collections so totals are accurate",
                }},
            },
        },
        {
            title = "Currency & Economy",
            blocks = {
                { type = "h2", text = "Gold Tracker" },
                { type = "list", items = {
                    "Coin icon with formatted gold/silver/copper",
                    "Session change tracker (green for gains, red for losses)",
                    "Compact gold value (e.g. 1.2k, 1.5M) in the title bar",
                }},
                { type = "h2", text = "Currency Bar" },
                { type = "list", items = {
                    "Per-widget settings to pick which currencies to display",
                    "Real currency icons next to names",
                    "Quantity / max quantity with progress",
                    "Falls back to backpack tracker if no currencies selected",
                    "Dynamically resizes based on tracked count",
                }},
            },
        },
        {
            title = "Navigation & Movement",
            blocks = {
                { type = "h2", text = "Coordinates" },
                { type = "list", items = {
                    "Map icon, gold X/Y coords (live)",
                    "Zone name displayed below",
                    "Compact coords in the title bar",
                }},
                { type = "h2", text = "Speed Monitor" },
                { type = "list", items = {
                    "Sprint icon, large % display, full-width progress bar",
                    "Color coding: green above 100%, white at 100%, red when slowed",
                    "Bar scales linearly to 200%",
                }},
            },
        },
        {
            title = "Weekly Progress",
            blocks = {
                { type = "h2", text = "Weekly Checklist" },
                { type = "lead", text = "Great Vault progress for Raid, Mythic+, and World rewards." },
                { type = "list", items = {
                    "Color-coded source rows: Raid (red), Mythic+ (blue), World (green)",
                    "Progress display (e.g. 2/3) with green check when slot is filled",
                    "Total slots completed in the title bar (e.g. 5/9)",
                    "Updates on Weekly Rewards events",
                }},
            },
        },
        {
            title = "Utilities",
            blocks = {
                { type = "h2", text = "Note Pad" },
                { type = "list", items = {
                    "Bordered text area with subtle backdrop",
                    "Saved per character via widget settings",
                    "Up to 2000 characters",
                    "Status text shows current character count",
                }},
                { type = "h2", text = "Stopwatch" },
                { type = "list", items = {
                    "Large gold time display (h:mm:ss.s)",
                    "Three buttons: Start/Pause, Reset, -1m",
                    "Live updating status text in title bar",
                }},
                { type = "h2", text = "To-Do List" },
                { type = "list", items = {
                    "Type and Enter to add a task",
                    "Click checkbox to mark complete (greyed out)",
                    "Click X to delete a task",
                    "Status shows open count or 'all done'",
                    "Saves per character",
                }},
                { type = "h2", text = "Calculator" },
                { type = "list", items = {
                    "Bordered display with right-aligned gold value",
                    "5x4 button grid: digits, +/-, decimal, 4 operators, equals, AC, backspace",
                    "Color-coded buttons: gold operators, green equals, dim red function keys",
                    "0 button spans 2 columns (classic calculator layout)",
                    "Handles divide by zero, negation, decimals",
                }},
            },
        },
        {
            title = "For Widget Authors",
            blocks = {
                { type = "lead", text = "Want to create your own widget pack? BazWidgets is your reference. Each widget file demonstrates the full pattern." },
                { type = "h3", text = "Always-on widget" },
                { type = "code", text = "local addon = BazCore:GetAddon(\"BazWidgetDrawers\")\nBazCore:RegisterDockableWidget(\"MyWidget\", {\n    title = \"My Widget\",\n    build = function(parent) ... end,\n    GetDesiredHeight = function() return 80 end,\n    GetStatusText    = function() return \"42\" end,\n    GetOptionsArgs   = function() return { ... } end,\n})" },
                { type = "h3", text = "Dormant widget (event-driven)" },
                { type = "code", text = "LibStub(\"LibBazWidget-1.0\"):RegisterDormantWidget(\"MyContextWidget\", {\n    events    = { \"BAG_UPDATE\", \"PLAYER_REGEN_ENABLED\" },\n    condition = function() return SomeStateIsActive() end,\n    build     = function(parent) ... end,\n})" },
                { type = "note", style = "info", text = "See the LibBazWidget-1.0 README for the full widget contract and lifecycle." },
            },
        },
    },
})
