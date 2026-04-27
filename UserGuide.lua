---------------------------------------------------------------------------
-- BazWidgets User Guide
---------------------------------------------------------------------------

if not BazCore or not BazCore.RegisterUserGuide then return end

BazCore:RegisterUserGuide("BazWidgets", {
    title = "BazWidgets",
    intro = "A pack of 26 ready-to-dock widgets for BazWidgetDrawers — covering activities, character info, currency, navigation, weekly progress, and utilities. Many are dormant, registering themselves only when a relevant condition is met (queued, in combat, in a delve, hearthstone on cooldown, etc.) so they never waste drawer space.",
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

                { type = "h2", text = "Pull Timer" },
                { type = "lead", text = "Dormant combat-duration tracker — auto-shows when you enter combat, disappears when combat ends." },
                { type = "list", items = {
                    "Live elapsed time, large gold display",
                    "Auto-shows on PLAYER_REGEN_DISABLED, auto-hides on PLAYER_REGEN_ENABLED",
                    "Title-bar status text mirrors the elapsed time so you can read it even when widget body is collapsed",
                }},

                { type = "h2", text = "Active Delve" },
                { type = "lead", text = "Dormant scenario panel — auto-shows when you're inside a delve (any active scenario)." },
                { type = "list", items = {
                    "Scenario name + objectives list",
                    "Live objective progress (counts, percentages)",
                    "Auto-hides when you leave the scenario",
                }},

                { type = "h2", text = "Delve Timer" },
                { type = "lead", text = "Dormant per-delve run timer with personal-best comparison." },
                { type = "list", items = {
                    "Tracks the elapsed time of your current delve run",
                    "Compares against your best time on that delve",
                    "Color shifts based on whether you're ahead of or behind your record",
                }},

                { type = "h2", text = "Delve Companion" },
                { type = "lead", text = "Dormant companion display — auto-shows in delves to surface your active companion." },
                { type = "list", items = {
                    "Brann (or the Midnight companion) icon and name",
                    "Companion-level / specialization at a glance",
                    "Auto-hides outside delves",
                }},

                { type = "h2", text = "Bountiful Tracker" },
                { type = "lead", text = "Dormant currency surface for delve-related drops." },
                { type = "list", items = {
                    "Restored Coffer Keys (currency 3028)",
                    "Coffer Key Shards (currency 3310 — 100 shards = 1 key)",
                    "Auto-shows in delve content",
                }},
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
                { type = "h2", text = "Item Level" },
                { type = "list", items = {
                    "Headline equipped iLevel rounded to one decimal",
                    "Sub-label shows your overall (best-available) average when it differs from equipped",
                    "Headline tints yellow when better gear is sitting in your bags",
                    "Live updates on equipment changes",
                }},
                { type = "h2", text = "Tooltip" },
                { type = "list", items = {
                    "A docked slot that anchors the global GameTooltip — item, unit, spell, and quest hovers appear inside the drawer instead of at the cursor",
                    "Defaults to the drawer's bottom edge: tooltip's bottom stays planted, content grows upward as the tooltip extends",
                    "Slot height tracks the live tooltip height; other bottom-stack widgets shift up as the tooltip grows",
                    "Auto-dismisses when the drawer collapses or the widget is disabled",
                }},
                { type = "note", style = "info", text = "The Tooltip widget only redirects |cffffd700default-anchored|r tooltips. Some addons hardcode their own anchor (e.g. ANCHOR_RIGHT off a button) and will keep it — typical coverage is ~80% (bags, action bars, unit frames, quest log, character pane)." },
                { type = "h2", text = "Collection Counter" },
                { type = "list", items = {
                    "Mount and pet collection progress",
                    "Owned / total / % display",
                    "Force-loads Blizzard_Collections so totals are accurate",
                }},

                { type = "h2", text = "Trinket Tracker" },
                { type = "list", items = {
                    "Both equipped trinkets shown side-by-side with icons",
                    "Live cooldown sweep on each trinket",
                    "Click a trinket to use it (out-of-combat only — combat-safe)",
                    "Auto-updates when you swap trinkets",
                }},

                { type = "h2", text = "Free Bag Slots" },
                { type = "list", items = {
                    "Always-on counter showing empty inventory slots remaining",
                    "Color shifts as you fill up — green when comfortable, red when nearly full",
                    "Counts across every normal bag slot",
                }},

                { type = "h2", text = "Hearthstone Cooldown" },
                { type = "list", items = {
                    "Dormant — auto-shows while your Hearthstone is on cooldown",
                    "Live countdown to ready",
                    "Auto-hides the moment the cooldown clears, keeping your drawer tidy",
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

                { type = "h2", text = "Tracked Reputation" },
                { type = "list", items = {
                    "Always-on display of a single user-picked faction",
                    "Faction name, current standing, and progress to next level",
                    "Ideal for grinding a specific reputation — pick the faction once, then watch progress build",
                    "Settings page lets you pick from any faction you currently have standing with",
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

                { type = "h2", text = "Reset Timers" },
                { type = "list", items = {
                    "Always-on countdown to next daily reset and next weekly reset",
                    "Color shifts from green to yellow to red as the deadline approaches",
                    "Compact format suits a stack of small status widgets",
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

                { type = "h2", text = "Performance" },
                { type = "list", items = {
                    "Always-on FPS + home-latency + world-latency display",
                    "Color-coded so you can see at a glance whether your client is healthy",
                    "Compact format — fits in a small drawer slot",
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
