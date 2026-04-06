# Navigator Color Theme System — User Guide

## Overview

All five Navigator programming boards support a full color theming system. You can customize every aspect of the UI appearance using a visual color picker on screen, chat commands, or both. Themes are saved to the databank and persist across restarts. You can create named profiles and share them between scripts.

---

## Quick Start

1. **Open the picker**: Click the `[THEME]` button in the bottom-right corner of any screen-equipped PB.
2. **Select an element**: Click an element name in the left panel (Accent, Background, Text, etc.).
3. **Pick a color**: Click the hue bar to choose a base hue, then click the saturation/brightness grid to fine-tune.
4. **Save**: Click `Save` in the profile bar at the bottom, or type `theme save` in chat.
5. **Close**: Click `[X CLOSE]` to return to the normal navigator UI with your new colors applied.

---

## The 8 Color Elements

Every script uses the same 8 customizable color "slots." All other UI colors (lines, scrollbars, disabled buttons, panel headers, tab bars, footers, etc.) are automatically derived from these 8.

| # | Element | What It Controls |
|---|---------|------------------|
| 1 | **Accent** | Highlight text, active selection text, accent glow, tab highlight |
| 2 | **Background** | Main screen background, footer background (darkened) |
| 3 | **Text** | Normal body text, dim text (derived darker), info labels |
| 4 | **Header** | Title bar text, panel header labels, section titles |
| 5 | **Btn Normal** | Button fill and stroke in their default/idle state |
| 6 | **Btn Hover** | Button fill and stroke when the mouse cursor hovers over them |
| 7 | **Selected** | Waypoint/item selection highlight fill and border |
| 8 | **Route** | Route list text, route selection fill, route scrollbar |

### Auto-Derived Colors

These are computed automatically — you do not need to set them:

- **Lines/Borders**: Derived from Accent (50% saturation, 40% brightness)
- **Disabled Buttons**: Fixed desaturated dark gray
- **Panel Header Background**: Derived from Accent (60% saturation, 12% brightness)
- **Tab Bar Background**: Derived from Accent (60% saturation, 8% brightness)
- **Active Tab Fill**: Derived from Accent (80% saturation, 35% brightness)
- **Inactive Tab Text**: Derived from Text (65% brightness)
- **Scrollbar Track**: Derived from Accent (50% saturation, 30% brightness)
- **Scrollbar Thumb**: Derived from Accent (70% saturation, 70% brightness)
- **Footer Background**: Derived from Background (brightened)
- **Status Messages**: Fixed orange (always visible regardless of theme)
- **Number Indices**: Derived from Text (muted blue-tinted)
- **Info Labels**: Derived from Text (muted)

---

## Visual Color Picker (Screen UI)

### Available On

- **Navigator Ship Screen** — click `[THEME]` in footer
- **Navigator Base** �� click `[THEME]` in footer
- **Navigator OrgBase Admin** — click `[THEME]` in footer
- **Navigator Ship NoScreen** — press `Alt+0` (requires optional screen linked to Slot 3)

### Picker Layout

```
+------------------------------------------------------------------+
| [X CLOSE]         COLOR THEME SETTINGS             Profile: NAME |
+------------------------------------------------------------------+
| ELEMENTS    | HUE  | SATURATION / BRIGHTNESS  | VALUES & PREVIEW |
|             | BAR  | GRID                     |                  |
| > Accent    |      |                          | R: 0    G: 200  |
|   Background|  36  |  16 x 16 cells           | B: 255          |
|   Text      |  hue |  (256 colored boxes)     |                 |
|   Header    |  seg-|                          | H: 195  S: 100% |
|   Btn Normal|  ments                          | V: 100%         |
|   Btn Hover |      |                          |                 |
|   Selected  |      |                          | Hex: #00C8FF    |
|   Route     |      |                          |                 |
|             |      |                          | [COLOR PREVIEW]  |
+------------------------------------------------------------------+
| [Default] [Theme 2]  [+ New] [Save] [Delete] [Reset]            |
+------------------------------------------------------------------+
```

### How to Use

1. **Select Element**: Click an element name on the left. The selected element is highlighted and the hue/SV grid shows its current color.

2. **Hue Bar**: The vertical strip on the left shows all 360 degrees of hue in 36 segments (10 degrees each). Click anywhere on it to change the base hue. A white outline shows the current selection.

3. **SV Grid**: The 16x16 square grid shows every combination of saturation (horizontal, left=0% right=100%) and brightness/value (vertical, top=100% bottom=0%) for the selected hue. Click to choose your exact shade. A crosshair marks the current position.

4. **Values Panel**: Shows the resulting color as:
   - RGB (0-255 per channel)
   - HSV (Hue 0-360 degrees, Saturation 0-100%, Value/Brightness 0-100%)
   - Hex code (#RRGGBB)
   - A large preview swatch with the element name overlaid

5. **Profile Bar** (bottom):
   - Click a profile name button to load it
   - `+ New` — create a new profile (copies current colors)
   - `Save` — save changes to the active profile
   - `Delete` — remove the active profile (must have at least one)
   - `Reset` — restore all 8 elements to the script's factory defaults

6. **Close**: Click `[X CLOSE]` in the top-left corner. Your changes are applied immediately to the main UI.

---

## Chat Commands

All theme commands start with `theme`. Available on all scripts except OrgBase Sync (which inherits the admin's theme automatically).

### Viewing Current Theme

```
theme
```

Prints all 8 element colors with their HSV values, hex codes, and the active profile name.

### Setting Colors by Hex

```
theme accent #00C8FF
theme background #000A14
theme route #22DD66
```

Set any element by its name followed by a 6-digit hex color code. Element names: `accent`, `background`, `text`, `header`, `btnNormal`, `btnHover`, `selected`, `route`.

### Setting Colors by RGB

```
theme accent 0 200 255
theme background 0 10 20
theme text 210 210 210
```

Set any element using three numbers (0-255) for Red, Green, Blue.

### Profile Management

```
theme save              Save changes to the current active profile
theme save MyTheme      Save current colors as a new profile named "MyTheme"
theme load CoolBlue     Load a saved profile by name
theme delete OldTheme   Delete a saved profile
theme rename NewName    Rename the current active profile
theme profiles          List all saved profile names (active profile marked with arrow)
theme reset             Reset all colors to factory defaults for this script type
```

### Cross-Script Profile Sharing (Export/Import)

Since each PB has its own databank, themes created on one PB are not automatically available on another (except OrgBase Admin + Sync which share a databank). Use export/import to transfer themes:

**Export:**
```
theme export
theme export MyTheme
```

Prints a compact string to chat that encodes the full theme:
```
THEME:MyTheme:195.00,1.00,1.00|210.00,0.80,0.04|0.00,0.00,0.82|48.00,1.00,1.00|195.00,1.00,0.40|195.00,0.85,0.65|195.00,1.00,0.86|140.00,0.70,1.00
```

**Import:**

Copy the entire `THEME:...` line and paste it into any other PB's chat:
```
theme import THEME:MyTheme:195.00,1.00,1.00|210.00,0.80,0.04|...
```

The theme is saved to the local databank and applied immediately.

**Typical workflow:**
1. Build a theme visually on the Ship Screen PB (mouse-driven picker)
2. Type `theme export` — copy the output line
3. Switch to the Ship NoScreen PB, type `theme import ` and paste the line
4. Both PBs now use the same theme

---

## Per-Script Details

### Navigator Ship Screen (`ship_screen.lua`)

- **Default theme**: Cyan accent, dark blue background, gold headers
- **Picker access**: Click `[THEME]` in footer
- **Databank keys**: `theme_profile_active`, `theme_profile_names`, `theme_p_NAME`

### Navigator Ship NoScreen (`ship_noscreen.lua`)

- **Default theme**: Same cyan/blue as Ship Screen
- **Picker access**: Link a screen to **Slot 3** (optional), then press `Alt+0` to toggle
- **Chat commands**: Always available regardless of screen
- **Slot connections**: Slot 0 = Databank, Slot 1 = Receiver, Slot 2 = Emitter, Slot 3 = Screen (optional)
- **Databank keys**: Same `theme_` prefix as Ship Screen

### Navigator Base (`base.lua`)

- **Default theme**: Blue accent (slightly different from ship — matches the original base colors)
- **Picker access**: Click `[THEME]` in footer
- **Databank keys**: Same `theme_` prefix

### Navigator OrgBase Admin (`orgbase_admin.lua`)

- **Default theme**: Warm amber/brown accent, dark brown background, orange-gold headers
- **Picker access**: Click `[THEME]` in footer
- **Databank keys**: `orgtheme_profile_active`, `orgtheme_profile_names`, `orgtheme_p_NAME` (uses `orgtheme_` prefix to avoid collision with navigation data on shared databank)

### Navigator OrgBase Sync (`orgbase_sync.lua`)

- **Default theme**: Same warm brown as OrgBase Admin
- **No picker, no chat commands** — this is intentional
- **Inherits theme automatically** from the OrgBase Admin PB via the shared databank
- Any theme changes made on the Admin PB are picked up by the Sync PB on its next heartbeat refresh (~30 seconds)
- **Databank keys**: Reads `orgtheme_` keys (same ones the Admin writes)

---

## Default Color Palettes

### Ship / Base Defaults (Cyan)

| Element | Hex | RGB | HSV |
|---------|-----|-----|-----|
| Accent | #00C8FF | 0, 200, 255 | H:195 S:100% V:100% |
| Background | #000A14 | 0, 10, 20 | H:210 S:80% V:4% |
| Text | #D1D1D1 | 209, 209, 209 | H:0 S:0% V:82% |
| Header | #FFDB00 | 255, 219, 0 | H:48 S:100% V:100% |
| Btn Normal | #003366 | 0, 51, 102 | H:195 S:100% V:40% |
| Btn Hover | #1A6B99 | 26, 107, 153 | H:195 S:85% V:65% |
| Selected | #00ABDB | 0, 171, 219 | H:195 S:100% V:86% |
| Route | #4DFF4D | 77, 255, 77 | H:140 S:70% V:100% |

### OrgBase Defaults (Amber)

| Element | Hex | RGB | HSV |
|---------|-----|-----|-----|
| Accent | #A66A17 | 166, 106, 23 | H:30 S:85% V:65% |
| Background | #050302 | 5, 3, 2 | H:20 S:50% V:2% |
| Text | #D1D1D1 | 209, 209, 209 | H:0 S:0% V:82% |
| Header | #FFA600 | 255, 166, 0 | H:40 S:100% V:100% |
| Btn Normal | #382200 | 56, 34, 0 | H:30 S:100% V:22% |
| Btn Hover | #8C5E14 | 140, 94, 20 | H:30 S:85% V:55% |
| Selected | #8C5E14 | 140, 94, 20 | H:30 S:85% V:55% |
| Route | #4DFF4D | 77, 255, 77 | H:140 S:70% V:100% |

---

## Migration from AccentR/G/B Exports

If you previously customized the `AccentR`, `AccentG`, `AccentB` export parameters on the Ship Screen or Ship NoScreen PBs, your custom accent color is automatically migrated on first load. The system converts your RGB accent to HSV and creates a "Migrated" profile. No action needed — your colors are preserved.

The `AccentR/G/B` export parameters still exist for backwards compatibility but are only used as a fallback if no theme profile is saved in the databank.

---

## Tips

- **Live preview**: Color changes from the picker apply instantly to the preview swatch. Close the picker to see them on the main UI.
- **Fine-tuning**: The SV grid gives you 256 possible shade variations per hue. For exact colors, use chat: `theme accent #1A8CCC`.
- **Sharing across constructs**: Use `theme export` / `theme import` to copy themes between ships, bases, or even between friends.
- **Org consistency**: Set the theme on the OrgBase Admin PB — the Sync PB inherits it automatically. All org members see the same colors when they sync.
- **Safe to experiment**: Use `theme reset` to go back to defaults at any time. Or save your current theme first with `theme save Backup` before experimenting.
- **Profile naming**: Profile names can contain letters, numbers, spaces, underscores, and hyphens. Maximum 20 characters.
