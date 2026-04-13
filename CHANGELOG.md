# BazWidgets Changelog

## 001 - Initial Release
- Widget pack addon for BazDrawer — requires BazCore + BazDrawer
- **Dungeon Finder** widget — queue status panel with role fills, wait time, live queue timer, dungeon name, and leave queue button. Auto-shows when queued via LFG, auto-hides when not. Self-contained queue data polling via GetLFGQueueStats. Title switches to green "Group Found!" on proposal. Status text shows live queue timer in the widget title bar.
- **Repair** widget — three-column durability display (paper doll / damaged-slot list / percent) with three paper-doll modes (custom icon grid, native DurabilityFrame, none). Hides Blizzard's auto-popup durability figure via hooksecurefunc (taint-safe). Color-graded green-to-red based on per-slot durability.
