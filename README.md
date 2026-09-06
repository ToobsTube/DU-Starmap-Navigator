# DU Starmap Navigator v2.2

A waypoint and route navigation system for **Dual Universe** built on Programming Boards. Save locations, build multi-stop routes, share waypoints with your org, and calculate realistic travel times — all from a screen UI or an AR HUD.

---

## Features

- **Waypoints & Routes** — Save any position as a waypoint. Group them into multi-stop routes and step through them one at a time.
- **Screen UI** — Clickable three-panel interface: waypoint list, route list, and navigation panel with distance and travel time.
- **AR HUD (No Screen)** — Full keyboard-driven overlay that works without a screen unit. Shows navigation, waypoints, routes, and a travel time calculator.
- **Personal Base Sync** — Push and pull waypoints between your ship and your base over emitter/receiver.
- **Org Sharing** — Org bases serve waypoints to any ship that syncs. Ships add org connections once with `firstsync` and refresh any time after that.
- **Multi-Org Support** — One ship can be connected to any number of org bases, each with its own tab.
- **Travel Time Calculator** — Uses real burn physics (asymmetric accel/brake profile). Set thrust and brake force in kN from your ship stats — mass is read automatically so estimates stay accurate as cargo changes. Cruise speed is auto-detected from your ship's actual max speed by default; set it manually to plan a slower trip on purpose (e.g. to save fuel).
- **Theme Editor** — Built-in color picker on every PB. Eight color slots control the full UI palette. Themes are saved to the databank and survive restarts. A ship can also `theme push` its theme straight to its base's databank, and any ship that later `sync`s pulls it back down as a loadable profile — no copy/pasting an export string through Lua chat required.
- **Atlas** — All planets, moons, and space stations built in. Navigate to any body directly from the UI.
- **Arch HUD Integration** — Sends waypoints directly to Arch HUD as temporary nav targets via a shared databank. No extra hardware needed.
- **Saga HUD Integration** — Sends waypoints directly to Saga HUD 4.22 as temporary nav targets via the same shared databank. Use `Saga_AP_4.22_Nav.json` from the Saga HUD folder.
- **Auto Fly** — Toggle that auto-advances route stops and auto-engages the connected HUD's autopilot. Screen version has an AUTO FLY button; no-screen version uses `autofly on/off`.
- **Waypoint Lock** — Per-waypoint lock flag (`lock`/`unlock` commands) that prevents locked waypoints from being pushed to base or overwritten by org syncs. Useful for ship-specific landing coords.
- **Slot Auto-Detect** — Link Screen/Databank/Receiver/Emitter to any of a PB's slots, in any order. Every PB probes what's actually linked at startup and tells you what it found — no fixed slot-number tables to follow.

---

## Files

| File | Purpose |
|------|---------|
| Navigator_Ship_Screen_v2.2.txt | Ship PB — clickable screen UI |
| Navigator_Ship_NoScreen_v2.2.txt | Ship PB — AR HUD, no screen required |
| Navigator_Base_v2.2.txt | Personal base PB |
| Navigator_OrgBase_Admin_v2.2.txt | Org base — admin and editing |
| Navigator_OrgBase_Sync_v2.2.txt | Org base — serves waypoints to ships |

All files are in the `dist/` folder. Tools (backup/restore, databank inspector) are in `dist/tools/`.

---

## Quick Start

### Personal use (ship + base)

1. Import `Navigator_Base_v2.2.txt` into a PB at your base. Slots are **auto-detected** — link a Screen Unit, Databank, Receiver, and Emitter to any of the PB's slots, in any order.

2. Import your chosen ship PB. Slots are **auto-detected** here too — link the required elements to any of the PB's slots, in any order:

   **Screen version:** Screen Unit, Databank, Receiver, Emitter — plus an optional 2nd Databank if using Arch/Saga.

   **No-screen version:** Databank, Receiver, Emitter — plus an optional Screen Unit (for the mouse-driven Theme Editor) and an optional 2nd Databank if using Arch/Saga.

   After activating either PB, check the Lua console: it prints a line like `[NAV] slot1=databank  slot2=receiver  slot3=emitter` (base prints `[BASE] ...`) confirming what it detected in each slot. If something looks wrong (e.g. an element shows up as `unrecognized`), that element isn't one of the supported types for this PB — check what's actually linked there.

3. Both PBs default to channel `NavBase` — no parameter changes needed unless you have multiple bases.
4. Activate both PBs. Type `sync` in Lua chat on the ship to pull waypoints from the base.

### Connecting to an org base

1. Make sure the org Sync PB is running. The channel name is shown on its screen.
2. Type `firstsync CHANNEL` in Lua chat (e.g. `firstsync NavOrg`).
3. The ship syncs and creates a new tab for that org automatically. Repeat for additional orgs.

---

## Documentation

- **[INSTRUCTIONS.md](INSTRUCTIONS.md)** — Full setup guide: hardware, slot connections, export parameters, all chat commands, and troubleshooting.
- **[THEME_GUIDE.md](THEME_GUIDE.md)** — How to use the Theme Editor, chat commands, and sharing themes between PBs.

---

## Requirements

- Dual Universe (live server)
- Programming Board x 1-2 per construct
- Databank, Screen Unit, Receiver, Emitter as needed (see INSTRUCTIONS.md)

---

## License

Personal and org use in Dual Universe is welcome. Do not redistribute modified versions as your own work.
