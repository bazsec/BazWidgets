> **Warning: Requires [BazCore](https://www.curseforge.com/wow/addons/bazcore) and [BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers).** If you use the CurseForge app, they will be installed automatically. Manual users must install both separately.

# BazWidgets

![WoW](https://img.shields.io/badge/WoW-12.0_Midnight-blue) ![License](https://img.shields.io/badge/License-GPL_v2-green) ![Version](https://img.shields.io/github/v/tag/bazsec/BazWidgets?label=Version&color=orange)

A widget pack addon for BazWidgetDrawers - **26 ready-to-dock widgets** covering activities, character info, currency, navigation, weekly progress, and utilities. Many are dormant, registering themselves only when relevant (queued, in combat, in a delve, hearthstone on cooldown, etc.) so they never waste drawer space.

BazWidgets serves two purposes: it provides useful widgets that extend BazWidgetDrawers beyond its core set, and it acts as a reference implementation for third-party addon authors who want to create their own widget packs using the LibBazWidget-1.0 API.

***

## Features

### Dormant Widgets

Some widgets are **dormant** - they only appear in the drawer when they're relevant. When their trigger condition clears, they unregister entirely: no slot, no title bar, no wasted space. Dormant widgets are marked with **[D]** in the settings list and can still be reordered and configured while dormant.

### Seamless Integration

*   Widgets dock into BazWidgetDrawers with full title bar, collapse, and fade support
*   Per-widget settings accessible via BazWidgetDrawers > Widgets
*   Drag-to-reorder, floating mode, and all host features work automatically
*   Widget order is preserved across sessions

### Polished Aesthetic

Every widget follows a consistent visual style: leading icon, gold accent for primary values, dim grey for secondary text, status text in the title bar (count, value, summary), and dynamic resizing based on content.

***

## Included Widgets

### Activity & Group

#### Dungeon Finder
Queue status panel that auto-appears when you queue for a dungeon via LFG.

*   **Dormant** - only registers when actively queued, disappears when not
*   Role fill indicators (tank / healer / DPS) with color-coded counts
*   Average wait time estimate
*   Live queue timer displayed in the widget title bar
*   Dungeon name subtitle
*   Leave Queue button
*   Title switches to green "Group Found!" on proposal

#### Pull Timer
Combat-duration tracker that auto-shows on combat enter.

*   **Dormant** - registers on `PLAYER_REGEN_DISABLED`, unregisters on `PLAYER_REGEN_ENABLED`
*   Live elapsed-time gold display with title-bar mirror
*   Zero space taken outside combat

#### Active Delve
Scenario panel that auto-shows when you're inside any active scenario (delves are scenarios).

*   **Dormant** - active in delves, inactive elsewhere
*   Scenario name + objectives list with live progress
*   Auto-hides when you leave

#### Delve Timer
Per-delve run timer with personal-best comparison.

*   **Dormant** - active inside delves
*   Tracks elapsed time of the current run
*   Compares against your best for that delve, color-shifts ahead/behind

#### Delve Companion
Companion display that auto-shows in delves.

*   **Dormant** - active inside delves
*   Brann (or the Midnight companion) icon + name
*   Companion-level / specialization at a glance

#### Bountiful Tracker
Currency tracker for delve-related drops.

*   **Dormant** - auto-shows in delve content
*   Restored Coffer Keys (currency 3028)
*   Coffer Key Shards (currency 3310 — 100 shards = 1 key)

### Character & Gear

#### Repair
Three-column durability display showing your gear condition at a glance.

*   Paper doll / damaged-slot list / durability percent layout
*   Worst-damaged slots listed first, color-graded green to red
*   Average durability shown in the widget title bar
*   Three paper-doll modes: custom icon grid, native DurabilityFrame, or none
*   Option to permanently hide Blizzard's default durability figure
*   Taint-safe suppression via hooksecurefunc

#### Stat Summary
Item level header with color-coded secondary stat rows.

*   Item level prominently displayed at the top with statue icon
*   Crit (gold), Haste (cyan), Mastery (pink), Versatility (green)
*   Live updates on equipment and rating changes

#### Collection Counter
Mount and pet collection progress at a glance.

*   Mount and pet icons with owned/total/% display
*   Force-loads Blizzard_Collections so totals are accurate
*   Status text shows mount/pet counts compactly

#### Trinket Tracker
Both equipped trinkets with live cooldown sweep.

*   Side-by-side icons for trinket slots 13 and 14
*   Live cooldown sweep on each
*   Click a trinket to use it (out-of-combat only — combat-safe)
*   Auto-updates when you swap trinkets

#### Free Bag Slots
Empty inventory slots remaining across all your normal bags.

*   Always-on counter
*   Color shifts as you fill up (green → yellow → red)

#### Hearthstone Cooldown
Hearthstone CD timer.

*   **Dormant** - auto-shows while your Hearthstone is on cooldown, hides once ready
*   Live countdown — keeps your drawer tidy when there's nothing to track

### Currency & Economy

#### Gold Tracker
Current gold + session gain/loss.

*   Coin icon with formatted gold/silver/copper
*   Session change tracker (green for gains, red for losses)
*   Compact gold value (e.g. 1.2k, 1.5M) in the title bar

#### Currency Bar
Configurable currency tracker with icon list.

*   Per-widget settings to pick which currencies to display
*   Real currency icons next to names
*   Quantity / max quantity with progress
*   Falls back to backpack tracker if no currencies are selected
*   Dynamically resizes based on the number of tracked currencies

#### Tracked Reputation
A single user-picked faction's standing and progress to next level.

*   Always-on, ideal for grinding a specific reputation
*   Faction name, current standing, progress bar to the next level
*   Settings page picker pulls from every faction you have standing with

### Navigation & Movement

#### Coordinates
Player map coordinates with zone name.

*   Map icon, gold X/Y coords (live updating)
*   Current zone name displayed below
*   Status text shows coords compactly in the title bar

#### Speed Monitor
Movement speed % with color-coded progress bar.

*   Sprint icon, large % display, full-width progress bar
*   Color coding: green (above 100%), white (100%), red (slowed)
*   Bar scales linearly to 200% maximum

### Weekly Progress

#### Weekly Checklist
Great Vault progress for Raid, Mythic+, and World rewards.

*   Color-coded source rows: Raid (red), Mythic+ (blue), World (green)
*   Progress display (e.g. 2/3) with green check when slot is filled
*   Total slots completed shown in the title bar (e.g. 5/9)
*   Updates on Weekly Rewards events

#### Reset Timers
Time until next daily and weekly resets.

*   Always-on countdown
*   Color shifts from green to yellow to red as deadlines approach
*   Compact — fits in a small drawer slot

### Utilities

#### Note Pad
Persistent text editor for personal notes.

*   Bordered text area with subtle backdrop
*   Saved per character via widget settings
*   Up to 2000 characters
*   Status text shows current character count

#### Stopwatch
Simple start/pause/reset stopwatch.

*   Large gold time display (h:mm:ss.s format)
*   Three buttons: Start/Pause, Reset, -1m (subtract a minute)
*   Live updating status text in the title bar

#### To-Do List
Persistent task list with checkboxes.

*   Input box up top - type and press Enter to add a task
*   Click checkbox to mark complete (greyed out)
*   Click X to delete a task
*   Status text shows open count or "all done"
*   Saves per character

#### Calculator
Basic 4-function calculator with display panel.

*   Bordered display with right-aligned gold value
*   5x4 button grid: digits, +/-, decimal, 4 operators, equals, AC, backspace
*   Color-coded buttons: gold operators, green equals, dim red function keys
*   0 button spans 2 columns (classic calculator layout)
*   Handles divide by zero, negation, decimal points

#### Performance
FPS + home-latency + world-latency display.

*   Always-on, color-coded so you can read client health at a glance
*   Compact — fits a small drawer slot

#### Tooltip
A docked slot that anchors the global GameTooltip into the drawer.

*   Hooks `GameTooltip_SetDefaultAnchor` so default-anchored tooltips appear in the drawer instead of at the cursor
*   Defaults to the bottom edge — tooltip's bottom stays planted, content grows upward
*   Slot height tracks the live tooltip height; other bottom-stack widgets shift up as the tooltip grows
*   ~80% coverage (bags, action bars, unit frames, quest log, character pane); some addons hard-code their own anchor and won't be redirected

***

## For Widget Authors

Want to create your own widget pack? BazWidgets is your reference. Each widget file demonstrates the full pattern:

1.  Get the addon handle via `BazCore:GetAddon("BazWidgetDrawers")`
2.  Build your widget frame
3.  Register via `BazCore:RegisterDockableWidget()` for always-on widgets
4.  Or use `LibStub("LibBazWidget-1.0"):RegisterDormantWidget()` for contextual widgets
5.  Implement optional callbacks: `GetDesiredHeight()`, `GetStatusText()`, `GetOptionsArgs()`

See the [LibBazWidget-1.0 README](https://github.com/bazsec/LibBazWidget) for the full widget contract.

***

## Compatibility

*   **WoW Version:** Retail 12.0 (Midnight)
*   **Midnight API Safe:** Uses taint-safe patterns throughout, no combat log dependencies
*   **Combat Safe:** No secure frame reparenting or protected method overrides
*   **Read-only APIs:** Widgets use `C_CurrencyInfo`, `C_Map`, `C_WeeklyRewards`, `C_MountJournal`, `C_PetJournal`, and other read-only game state APIs

***

## Dependencies

**Required:**

*   [BazCore](https://www.curseforge.com/wow/addons/bazcore) - shared framework for Baz Suite addons
*   [BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers) - the widget drawer host

***

## Part of the Baz Suite

BazWidgets is part of the **Baz Suite** of addons, all built on the [BazCore](https://www.curseforge.com/wow/addons/bazcore) framework:

*   **[BazBars](https://www.curseforge.com/wow/addons/bazbars)** - Custom extra action bars
*   **[BazWidgetDrawers](https://www.curseforge.com/wow/addons/bazwidgetdrawers)** - Slide-out widget drawer
*   **[BazWidgets](https://www.curseforge.com/wow/addons/bazwidgets)** - Widget pack for BazWidgetDrawers
*   **[BazNotificationCenter](https://www.curseforge.com/wow/addons/baznotificationcenter)** - Toast notification system
*   **[BazLootNotifier](https://www.curseforge.com/wow/addons/bazlootnotifier)** - Animated loot popups
*   **[BazFlightZoom](https://www.curseforge.com/wow/addons/bazflightzoom)** - Auto zoom on flying mounts
*   **[BazMap](https://www.curseforge.com/wow/addons/bazmap)** - Resizable map and quest log window
*   **[BazMapPortals](https://www.curseforge.com/wow/addons/bazmapportals)** - Mage portal/teleport map pins

***

## License

BazWidgets is licensed under the **GNU General Public License v2** (GPL v2).
