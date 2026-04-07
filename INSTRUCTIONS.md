# DU Starmap Navigator v2.0 — Setup & User Guide

## Overview

The Navigator is a set of Programming Boards (PBs) for Dual Universe that let you save, share, and navigate to waypoints and routes. There are five PBs:

| File | Purpose |
|------|---------|
| Navigator_Ship_Screen | Ship PB with a clickable screen UI |
| Navigator_Ship_NoScreen | Ship PB with an AR HUD (no screen needed) |
| Navigator_Base | Personal base PB — stores your private waypoints |
| Navigator_OrgBase_Admin | Org base admin PB — manages org-shared waypoints |
| Navigator_OrgBase_Sync | Org base sync PB — serves waypoints to ships on request |

Most players will use one ship PB and Navigator_Base. If you are part of an org, the org admin sets up the two OrgBase PBs at the org's base — you just need your ship PB.

---

## Hardware You Need

### Ship (Screen version)
- 1x Programming Board
- 1x Screen Unit (any size)
- 1x Databank
- 1x Receiver
- 1x Emitter

### Ship (No Screen version)
- 1x Programming Board
- 1x Databank
- 1x Receiver
- 1x Emitter
- 1x Screen Unit *(optional — only needed for the Theme Editor)*

### Personal Base
- 1x Programming Board
- 1x Screen Unit
- 1x Databank
- 1x Receiver
- 1x Emitter

### Org Base (if running an org)
You need TWO programming boards at the base:
- **Admin PB**: Screen + Databank + Receiver + Emitter
- **Sync PB**: Screen + Databank (shared with Admin) + Receiver + Emitter

---

## Slot Connections

Connect slots **in exactly this order** (right-click PB → Configure → drag elements to slots).

### Navigator_Ship_Screen
| Slot | Element |
|------|---------|
| 0 | Screen Unit |
| 1 | Databank |
| 2 | Receiver |
| 3 | Emitter |

### Navigator_Ship_NoScreen
| Slot | Element |
|------|---------|
| 0 | Databank |
| 1 | Receiver |
| 2 | Emitter |
| 3 | Screen Unit *(optional — for Theme Editor only)* |

### Navigator_Base
| Slot | Element |
|------|---------|
| 0 | Screen Unit |
| 1 | Databank |
| 2 | Receiver |
| 3 | Emitter |

### Navigator_OrgBase_Admin
| Slot | Element |
|------|---------|
| 0 | Screen Unit |
| 1 | Databank (same databank as Sync PB) |
| 2 | Receiver |
| 3 | Emitter |

### Navigator_OrgBase_Sync
| Slot | Element |
|------|---------|
| 0 | Screen Unit |
| 1 | Databank (same databank as Admin PB) |
| 2 | Receiver |
| 3 | Emitter |

> **Important:** The Admin and Sync PBs must share the **same physical databank**. The Admin writes data, the Sync reads and serves it to ships.

---

## Export Parameters (Right-click PB → Edit LUA Parameters)

### Ship PBs (Screen and NoScreen)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `CustomAtlas` | `atlas` | Atlas file to load. Leave as default unless you have a custom atlas in `autoconf/custom/`. |
| `BaseChannel` | `NavBase` | Channel name for your personal base. Must match your base PB's channel. |
| `AutopilotCmd` | *(blank)* | *(Work in progress)* Autopilot command prefix. Set to `/goto` for Saga HUD or `/` for Arch HUD. Leave blank to disable. |
| `CalcSpeed` | `30000` | Your max speed in space in km/h for travel time calculations. |
| `CalcThrust` | `0` | Your ship's total thrust in kN — read this directly from your ship's stats screen. Acceleration is calculated automatically using your ship's current mass. Leave at `0` to use `CalcAccel` instead. |
| `CalcBrake` | `0` | Your ship's total brake force in kN from your ship's stats screen. When set, the script decelerates using brakes rather than a flip-and-burn. Leave at `0` to let the script read brake force automatically from the construct; if that also fails it falls back to using thrust for deceleration. |
| `CalcAccel` | `5` | Fallback acceleration in m/s² — only used if `CalcThrust` is `0`. |
| `AccentR/G/B` | `0 / 200 / 255` | Starting accent color (RGB 0–255). The in-game Theme Editor overrides this once you save a theme. |

#### No Screen version only
| Parameter | Default | Description |
|-----------|---------|-------------|
| `HudX` | `13` | HUD left position as a percentage from the screen edge. This always takes effect — change it here to move the HUD without needing to sit in the seat. |
| `HudY` | `15` | HUD top position as a percentage from the screen edge. Same as above. |

### Navigator_Base

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BaseChannel` | `NavBase` | Channel ships use to reach this base. Must match the ships' `BaseChannel`. |

### Navigator_OrgBase_Admin

| Parameter | Default | Description |
|-----------|---------|-------------|
| `OrgChannel` | `NavOrg` | Channel for this org. Ships use this when doing their first org sync. |
| `OrgName` | `MyOrg` | Display name shown on the screen and sent to ships during sync. |

### Navigator_OrgBase_Sync

No export parameters. It reads its channel and org name from the shared databank written by the Admin PB on first start.

---

## Personal Setup (Most Players)

1. Place Navigator_Base at your base. Connect Screen, Databank, Receiver, Emitter in slot order.
2. Place your ship PB on your ship. Connect elements in slot order.
3. Set `BaseChannel` to the same value on both (the default `NavBase` works if you only have one base).
4. Turn on the base PB — it shows a screen with tabs.
5. Turn on the ship PB — it loads your waypoints from the databank.
6. Type `sync` in Lua chat on the ship to pull waypoints from the base.

---

## Org Setup

### At the Org Base

1. Place both the Admin PB and the Sync PB.
2. Connect them to the **same databank**.
3. Connect each PB to its own Screen, Receiver, and Emitter.
4. Set `OrgChannel` on the Admin PB (e.g. `NavAlliance`).
5. Set `OrgName` on the Admin PB (e.g. `Alliance`).
6. Turn on the Admin PB first — this writes the channel and name to the databank.
7. Turn on the Sync PB — it reads those values automatically. The channel name is shown on its screen.

### On Each Ship (First-time connection to an org)

1. Make sure your ship PB is running and your Receiver is in range of the org's Sync PB.
2. Type `firstsync CHANNEL` in Lua chat — use the channel shown on the org's Sync PB screen.
   - Example: `firstsync NavAlliance`
3. The ship syncs with that org and creates a new tab for it automatically. The org channel is saved — you never need to type it again.
4. After that, use the **ORG SYNC** button or type `orgsync` to refresh org waypoints.

For a second org, just repeat: type `firstsync CHANNEL` with the second org's channel. Each org gets its own tab.

---

## Using the Screen Version

The screen has three panels:

- **Left — Waypoints:** Click a waypoint to select it.
- **Middle — Routes/Stops:** Click a route to select it. Click again to expand stops.
- **Right — Navigation + Buttons:** Shows your current nav target, distance, and travel time.

### Tabs
- **Personal** — your private waypoints
- **[Org name]** — org waypoints (appear after first org sync)
- **ATLAS** — all bodies in the game. Click one to navigate to it.

### Buttons
| Button | What it does |
|--------|-------------|
| MARK WP HERE | Saves your current position as a new waypoint |
| MARK ROUTE STOP | Adds your current position as a stop on the selected route |
| NAVIGATE WP | Sets the selected waypoint as your nav target |
| NAVIGATE ROUTE | Starts the selected route from stop 1 |
| NEXT STOP / PREV STOP | Move between route stops |
| CLEAR NAV | Removes your current nav target |
| SYNC BASE | Pulls waypoints/routes from your personal base |
| PUSH TO BASE | Sends your waypoints/routes to your personal base |
| ORG SYNC | Pulls waypoints from the org on the currently active tab |
| ORG PUSH | Sends waypoints to the org on the currently active tab |
| FIRST ORG SYNC | Shows a hint — type `firstsync CHANNEL` in Lua chat to add a new org |
| THEME | Opens the Theme Editor color picker |

### Chat Commands (screen version)
Type these in Lua chat while the PB is running:

| Command | Description |
|---------|-------------|
| `add NAME ::pos{...}` | Add or update a waypoint |
| `rename NEWNAME` | Rename the selected WP or route |
| `setpos ::pos{...}` | Update coords of the selected WP or stop |
| `del` | Delete the selected WP, route, or stop |
| `newroute NAME` | Create a new route |
| `addstop WPNAME` | Add a saved WP as the next stop on the selected route |
| `addstop ::pos{...}` | Add a position as the next stop |
| `delstop N` | Remove stop number N from the selected route |
| `sync` | Sync from personal base |
| `orgsync` | Sync from the org on the current tab |
| `firstsync CHANNEL` | First-time sync with a new org (e.g. `firstsync NavOrg`) |
| `push` | Push to personal base |
| `orgpush` | Push to the org on the current tab |
| `help` | Show all commands in Lua chat |

---

## Using the No Screen Version

The HUD appears as an AR overlay. Press **Left Shift** to show or hide it.

### Navigation Controls
| Keys | Action |
|------|--------|
| Alt + Up / Down | Move between sections (left panel) or items (right panel) |
| Alt + Right | Enter the right panel / activate selected item |
| Alt + Left | Go back to the left panel |
| Alt + 0 | Open / close the Theme Editor (requires screen in slot 3) |
| Left Shift | Toggle HUD on/off |

### Sections
| Section | Contents |
|---------|---------|
| WP | Your personal waypoints. Select one and press Alt+Right to navigate. |
| ORG | Org waypoints and routes (after syncing). |
| ROUTES | Your personal routes. |
| SETTINGS | Mark WP, Next/Prev Stop, Clear Nav, Sync, Push actions. |
| ATLAS | All game bodies. Select one and press Alt+Right to navigate to it. |
| TIME CALC | Travel time to all your waypoints from current position. |

### Chat Commands (no screen version)
| Command | Description |
|---------|-------------|
| `nav NAME` | Navigate to a waypoint or route by name |
| `nav off` | Clear navigation |
| `next` / `prev` | Next / previous route stop |
| `sync` | Sync from personal base |
| `orgsync` | Sync from the active org |
| `firstsync CHANNEL` | First-time sync with a new org (e.g. `firstsync NavOrg`) |
| `push` | Push to personal base |
| `orgpush` | Push to the active org |
| `org NAME` | Switch active org context |
| `hudpos X Y` | Move the HUD while seated (e.g. `hudpos 5 5`). Same as changing `HudX`/`HudY` but takes effect immediately without reimporting. |
| `search NAME` | Filter atlas by name |
| `status` | Show current nav target and distance |
| `list` | List all waypoints |
| `routes` | List all routes |
| `help` | Show all commands in Lua chat |

---

## Theme Editor

All PBs include a built-in color picker to customize the UI colors.

- **Screen version:** Click the **THEME** button in the navigation panel.
- **No screen version:** Press **Alt+0** (requires a Screen Unit in slot 3).
- **Base and Org PBs:** Click the **THEME** button on the screen.

The picker shows 8 color slots. Select a slot on the left, then drag the sliders to adjust hue, saturation, and brightness. The right panel shows a split preview — the left half shows the saved color, the right half shows your current change live. Click **SAVE** to apply. Click **RESET** to go back to the saved color. Themes are stored in the databank and survive PB restarts.

See [THEME_GUIDE.md](THEME_GUIDE.md) for a full description of what each color slot controls.

---

## Travel Time Calculator

Set two export parameters on your ship PB:

- **CalcSpeed** — your max speed in space in km/h. Check your HUD at top speed. Typical: `20000`–`50000`.
- **CalcThrust** — your ship's total thrust in kN, shown on the ship stats screen. The script divides this by your current mass automatically, so the calculation stays accurate as your cargo changes. Recommended over `CalcAccel`.
- **CalcBrake** — your ship's total brake force in kN, also shown on the ship stats screen. When provided, the deceleration phase uses brakes rather than a flip-and-burn, giving a more accurate time estimate. If left at `0` the script tries to read brake force directly from the construct automatically. If that fails too it falls back to using thrust for deceleration.
- **CalcAccel** — fallback acceleration in m/s². Only used if `CalcThrust` is left at `0`.

The calculator uses real burn physics: acceleration burn at the start, cruise at top speed, then deceleration. If the destination is too close to reach top speed, it calculates a triangle burn profile instead.

Travel time shows:
- **Screen version:** Next to the distance in the Navigation panel (e.g. `257 su  ▸  5h 23m`)
- **No screen version:** In the TIME CALC section, listed for every waypoint

---

## Channel Setup Tips

- Channels are text strings — they must match exactly between sender and receiver.
- Make channel names unique to avoid picking up traffic from other players' navigators nearby.
- The org channel is shown on the Sync PB's screen — that's what you type in `firstsync`.
- Emitters and Receivers must be within range of each other (same construct is always in range).

---

## Troubleshooting

**Sync doesn't work / no waypoints appear**
- Check that `BaseChannel` matches exactly on both the ship and the base PB.
- Make sure the base PB is running before you type `sync`.
- Make sure Receiver and Emitter are linked to the correct PBs.

**First org sync doesn't work**
- Make sure the org's Sync PB is running and you can see its channel on the screen.
- Type `firstsync CHANNEL` exactly as shown — the channel is case-sensitive if you type it manually, but the script will still try to match it against known channels.
- Your ship's Emitter must be in range of the org Sync PB's Receiver.

**Screen clicks don't work**
- Make sure you imported the correct `.txt` file into the PB (not copy-pasted into the screen).
- The screen must be linked to slot 0.

**"No emitter" error**
- The Emitter element isn't linked to the PB, or is linked to the wrong slot.

**Waypoints show [0] on screen**
- The databank may be empty — try typing `sync` first to pull from the base.
- If it's a fresh install with no base yet, type `add NAME ::pos{...}` to create your first waypoint.

**Travel time shows ---**
- You are not inside a construct with a core (no position available).
- Or the waypoint uses planet-relative coords that the atlas can't resolve.

**Theme Editor doesn't open on No Screen version**
- A Screen Unit must be connected to slot 3 of the PB.
- The screen must be activated — it will show "THEME EDITOR" when the PB is running and the picker is closed.
