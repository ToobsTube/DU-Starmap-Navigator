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

You only need the two that fit your situation. Most players will use one ship PB and Navigator_Base.

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

### Personal Base
- 1x Programming Board
- 1x Screen Unit
- 1x Databank
- 1x Receiver
- 1x Emitter

### Org Base (if running an org)
You need TWO programming boards at the base:
- **Admin PB**: Screen + Databank + Emitter
- **Sync PB**: Databank (shared with Admin) + Receiver + Emitter

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
| 2 | Emitter |

### Navigator_OrgBase_Sync
| Slot | Element |
|------|---------|
| 0 | Databank (same databank as Admin PB) |
| 1 | Receiver |
| 2 | Emitter |

> **Important:** The Admin and Sync PBs must share the **same physical databank**. The Admin writes data, the Sync reads and broadcasts it.

---

## Export Parameters (Right-click PB → Edit LUA Parameters)

### Ship PBs (Screen and NoScreen)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `CustomAtlas` | `atlas` | Atlas file to load. Leave as default unless you have a custom atlas in `autoconf/custom/`. |
| `BaseChannel` | `NavBase` | Channel name for your personal base. Must match your base PB's channel. |
| `OrgChannel1–5` | `NavOrg` / blank | Channels for up to 5 org bases. Must match each org's Sync PB channel. |
| `OrgTag1–5` | _(blank)_ | **Prefix for WPs pushed to that org.** OrgTag1 pairs with OrgChannel1, OrgTag2 with OrgChannel2, etc. See OrgTag section below. |
| `AutopilotCmd` | _(blank)_ | Autopilot command prefix. Set to `/goto` for Saga HUD or `/` for Arch HUD. Leave blank to disable. |
| `CalcSpeed` | `30000` | Your cruise speed in km/h for travel time calculations. |
| `CalcAccel` | `5` | Your ship's acceleration in m/s² for travel time calculations. |

### Navigator_Base

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BaseChannel` | `NavBase` | Channel ships use to reach this base. Must match ships' `BaseChannel`. |
| `OrgTabs` | _(blank)_ | Comma-separated org prefixes to create tabs for. e.g. `Alliance,Corp` |

### Navigator_OrgBase_Admin

| Parameter | Default | Description |
|-----------|---------|-------------|
| `OrgChannel` | `NavOrg` | Channel for this org. Must match ships' `OrgChannel1`–`5`. |
| `OrgName` | `MyOrg` | Display name shown on the screen and sent to ships during sync. |

### Navigator_OrgBase_Sync

No export parameters. It reads its channel and org name from the shared databank (written by the Admin PB on first start).

---

## What is OrgTag?

Each `OrgTag` is the prefix stamped onto your waypoint names when you **push** them to that org's base. Each tag is paired with its matching channel — `OrgTag1` goes with `OrgChannel1`, `OrgTag2` with `OrgChannel2`, and so on.

**Example — single org:** You are in the Alliance. You set:
- `OrgChannel1 = NavAlliance`
- `OrgTag1 = Alliance`

You save a waypoint called `Mining Spot`. When you push to org 1, it arrives at the Alliance base as `Alliance-Mining Spot` and appears under the Alliance tab for everyone.

**Example — two orgs:** You are in the Alliance and the Corp. You set:
- `OrgChannel1 = NavAlliance` / `OrgTag1 = Alliance`
- `OrgChannel2 = NavCorp`     / `OrgTag2 = Corp`

Pushing to org 1 stamps `Alliance-` on your WPs. Pushing to org 2 stamps `Corp-`. Each org base only sees its own tagged waypoints sorted correctly.

**If you leave an OrgTag blank:** Pushed waypoints have no prefix and land in the Personal tab at that base. Only do this if the base owner expects untagged entries.

**Rule of thumb:**
- Personal player, no org sharing → leave all OrgTags blank
- Member of one org → fill in OrgChannel1 + OrgTag1
- Member of multiple orgs → fill in one channel+tag pair per org

---

## Personal Setup (Most Players)

1. Place Navigator_Base at your base. Connect Screen, Databank, Receiver, Emitter in order.
2. Place your ship PB on your ship. Connect elements in order.
3. Set `BaseChannel` to the same value on both (default `NavBase` works fine if you only have one base).
4. Place the Receiver and Emitter close enough to each other that they're in range (same construct is fine).
5. Turn on the base PB — it shows a screen with tabs.
6. Turn on the ship PB — it loads your waypoints from the databank.
7. Type `sync` in Lua chat on the ship to pull waypoints from the base.

---

## Org Setup

### At the Org Base

1. Place both the Admin PB and the Sync PB.
2. Connect them to the **same databank**.
3. Connect the Admin PB to a Screen and an Emitter.
4. Connect the Sync PB to a Receiver and an Emitter (different emitter from Admin).
5. Set `OrgChannel` on the Admin PB (e.g. `NavAlliance`).
6. Set `OrgName` on the Admin PB (e.g. `Alliance`).
7. Turn on the Admin PB first — this writes the channel and name to the databank.
8. Turn on the Sync PB — it reads those values automatically.

### On Each Ship

1. Set `OrgChannel1` to match the org's channel (e.g. `NavAlliance`).
2. Set `OrgTag1` to the org's prefix (e.g. `Alliance`).
3. For a second org, fill in `OrgChannel2` + `OrgTag2`, and so on up to 5 orgs.
4. Type `orgsync` in Lua chat to pull org waypoints from org 1.

---

## Using the Screen Version

The screen has three panels:

- **Left — Waypoints:** Click a waypoint to select it (highlights blue).
- **Middle — Routes/Stops:** Click a route to select it. Click again to expand stops.
- **Right — Navigation + Buttons:** Shows your current nav target, distance, and travel time.

### Buttons
| Button | What it does |
|--------|-------------|
| MARK WP HERE | Saves your current position as a new waypoint |
| MARK ROUTE STOP | Adds your current position as a stop on the selected route |
| NAVIGATE WP | Sets the selected waypoint as your nav target |
| NAVIGATE ROUTE | Starts the selected route from stop 1 |
| NEXT STOP / PREV STOP | Move between route stops |
| CLEAR NAV | Removes your current nav target |
| SYNC BASE | Pulls all waypoints/routes from your personal base |
| PUSH TO BASE | Sends your current waypoints/routes to your personal base |

### Tabs
- **Personal** — your private waypoints
- **[Org name]** — org waypoints (appear after syncing from an org base)
- **ATLAS** — all bodies in the game. Click one, then click NAVIGATE TO BODY.

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
| `orgsync` | Sync from org base |
| `push` | Push to personal base |
| `orgpush` | Push to org base |
| `help` | Show all commands |

---

## Using the No Screen Version

The HUD appears as an AR overlay. Press **Left Shift** to show or hide it.

### Navigation Controls
| Keys | Action |
|------|--------|
| Alt + Up / Down | Move between sections (left panel) or items (right panel) |
| Alt + Right | Enter the right panel / activate selected item |
| Alt + Left | Go back to the left panel |
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
Same commands as the screen version, plus:

| Command | Description |
|---------|-------------|
| `nav NAME` | Navigate to a waypoint or route by name |
| `nav off` | Clear navigation |
| `next` | Next route stop |
| `prev` | Previous route stop |
| `org ORGNAME` | Switch active org context for pushing/syncing |
| `status` | Show current nav target and distance |
| `list` | List all waypoints |
| `routes` | List all routes |

---

## Travel Time Calculator

Set two export parameters on your ship PB:

- **CalcSpeed** — your cruise speed in km/h. Check your HUD at top speed in space. Typical: `20000`–`50000`.
- **CalcAccel** — your ship's acceleration in m/s². Check your ship's stats. Typical: `3`–`15`.

The calculator uses real burn physics: it accounts for the acceleration burn at the start, cruise at top speed, and the deceleration burn at the end. If the destination is close enough that you can't reach top speed, it calculates a shorter triangle burn profile instead.

Travel time shows:
- **Screen version:** Next to the distance in the Navigation panel (e.g. `257 su  ▸  5h 23m`)
- **No screen version:** In the TIME CALC section, listed for every waypoint

---

## Channel Setup Tips

- Channels are just text strings — they must match exactly between sender and receiver.
- Make channel names unique to avoid picking up traffic from other players' navigators nearby.
- The Receiver on a construct only listens to channels you configure — it ignores everything else.
- Emitters and Receivers must be within range of each other (same construct is always in range of itself).

---

## Troubleshooting

**Sync doesn't work / no waypoints appear**
- Check that `BaseChannel` matches exactly on both the ship and the base PB.
- Make sure the base PB is running before you type `sync`.
- Make sure Receiver and Emitter are linked to the correct PBs.

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

**OrgTag waypoints not sorting into tabs at base**
- The prefix in `OrgTag` on the ship must exactly match one of the entries in `OrgTabs` on the base (case-sensitive).
- e.g. Ship: `OrgTag = Alliance` / Base: `OrgTabs = Alliance`
