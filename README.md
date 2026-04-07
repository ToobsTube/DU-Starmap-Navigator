# DU Starmap Navigator v2.0

A waypoint and route navigation system for **Dual Universe** built on Programming Boards. Save locations, build multi-stop routes, share waypoints with your org, and calculate realistic travel times — all from a screen UI or an AR HUD.

---

## Features

- **Waypoints & Routes** — Save any position as a waypoint. Group them into multi-stop routes and step through them one at a time.
- **Screen UI** — Clickable three-panel interface: waypoint list, route list, and navigation panel with distance and travel time.
- **AR HUD (No Screen)** — Full keyboard-driven overlay that works without a screen unit. Shows navigation, waypoints, routes, and a travel time calculator.
- **Personal Base Sync** — Push and pull waypoints between your ship and your base over emitter/receiver.
- **Org Sharing** — Org bases serve waypoints to any ship that syncs. Ships add org connections once with firstsync and refresh any time after that.
- **Multi-Org Support** — One ship can be connected to any number of org bases, each with its own tab.
- **Travel Time Calculator** — Uses real burn physics (asymmetric accel/brake profile). Set thrust and brake force in kN from your ship stats — mass is read automatically so estimates stay accurate as cargo changes.
- **Theme Editor** — Built-in color picker on every PB. Eight color slots control the full UI palette. Themes are saved to the databank and survive restarts.
- **Atlas** — All planets, moons, and space stations built in. Navigate to any body directly from the UI.
- **Arch HUD Integration** — Sends waypoints directly to Arch HUD as temporary nav targets via a shared databank. No extra hardware needed.
- **Saga HUD Integration** — *(Work in progress)* Command prefix support for Saga HUD.

---

## Files

| File | Purpose |
|------|---------|
| Navigator_Ship_Screen_v2.0.txt | Ship PB — clickable screen UI |
| Navigator_Ship_NoScreen_v2.0.txt | Ship PB — AR HUD, no screen required |
| Navigator_Base_v2.0.txt | Personal base PB |
| Navigator_OrgBase_Admin_v2.0.txt | Org base — admin and editing |
| Navigator_OrgBase_Sync_v2.0.txt | Org base — serves waypoints to ships |

All files are in the dist/ folder. Tools are in dist/tools/.

---

## Quick Start

### Personal use (ship + base)

1. Import Navigator_Base_v2.0.txt into a PB at your base. Connect **Screen -> slot 0, Databank -> slot 1, Receiver -> slot 2, Emitter -> slot 3**.
2. Import your chosen ship PB. Connect elements in the same slot order (NoScreen: Databank -> slot 0, Receiver -> slot 1, Emitter -> slot 2).
3. Both PBs default to channel NavBase — no parameter changes needed unless you have multiple bases.
4. Activate both PBs. Type sync in Lua chat on the ship to pull waypoints from the base.

### Connecting to an org base

1. Make sure the org Sync PB is running. The channel name is shown on its screen.
2. Type firstsync CHANNEL in Lua chat (e.g. firstsync NavOrg).
3. The ship syncs and creates a new tab for that org automatically. Repeat for additional orgs.

---

## Documentation

- **[INSTRUCTIONS.md](INSTRUCTIONS.md)** — Full setup guide: hardware, slot connections, export parameters, all chat commands, and troubleshooting.
- **[THEME_GUIDE.md](THEME_GUIDE.md)** — How to use the Theme Editor and what each color slot controls.

---

## Requirements

- Dual Universe (live server)
- Programming Board x 1-2 per construct
- Databank, Screen Unit, Receiver, Emitter as needed (see INSTRUCTIONS.md)

---

## License

Personal and org use in Dual Universe is welcome. Do not redistribute modified versions as your own work.