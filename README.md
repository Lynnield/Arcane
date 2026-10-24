# Arcane

A 2D pixel-art wizard platformer for Android, built with Godot 4.7 (GL Compatibility renderer).
Single-player campaign with five levels plus a 1v1 duel over local Wi-Fi.

## Running

1. Open Godot 4.7 and import `project.godot`.
2. Press F5. The game starts at the title screen.

Desktop controls (for testing): `A`/`D` or arrow keys to move, `Space`/`W` to jump,
mouse drag on the right side of the screen to aim (the mouse acts as a touch), `Esc` to pause.

## Touch controls

| Control | Where | Notes |
|---|---|---|
| Joystick | Left 38% of the screen | Floating: the base appears where the finger lands |
| Jump | Bottom-right button | This area never starts an aim; releasing an aim over it cancels the shot |
| Aim and fire | Anywhere else on the right | Pull back like a slingshot and release to cast. The orb flies opposite the pull |

Each finger belongs to the control it started on until it lifts. A cancelled touch or the app losing focus cancels an unfinished shot.

## Project layout

```
scenes/            .tscn files (Player, MagicOrb, enemies, HUD, Level1-5, PvPArena, ui/*)
scripts/
  autoload/        Save (save file), Game (scene flow), Sfx (generated sounds), Net (LAN + RPCs)
  enemies/         Enemy base, StationaryEnemy, PatrolEnemy (the Level 5 boss is a PatrolEnemy)
  world/           LevelData (layouts), WorldBuilder, TileDrawer, Checkpoint, ExitPortal, backgrounds
  ui/              Title, main menu, level select, settings, lobby, results, UiKit theme
  tuning.gd        Values to tune during playtesting (concept paper section 18)
  orb_physics.gd   Shared projectile math used by both the orb and the trajectory preview
```

All art is drawn in code and all sounds are generated at startup, so the project has no asset files.

## Design notes

- **Trajectory preview:** `OrbPhysics.simulate` uses the same step function, collision mask and physics tick as `MagicOrb`, so the preview ends where the orb actually hits.
- **Orb rules:** damage is fixed at `Tuning.ORB_DAMAGE` and only applies on a direct hit, with no splash. Pull distance changes speed, clamped between `ORB_MIN_SPEED` and `ORB_MAX_SPEED`. The orb disappears on its first collision.
- **Levels:** layouts are lists of rectangles in `scripts/world/level_data.gd`. Defeat every enemy to open the portal, then reach it. Falling respawns the wizard at the last checkpoint (or the start) with a +5 s time penalty and 1.5 s of protection.
- **Saving:** `user://save.cfg` stores unlocked levels, best times (a time is only replaced by a faster one) and settings. If the file can't be read, it is renamed to `save.corrupt.cfg` and the game starts with defaults.
- **PvP:** uses ENet on port 7777. The host is peer 1. Each phone moves its own wizard and streams its state at 30 Hz. Shots are sent to the host, which checks cooldown, speed, origin and the 3-orb limit. The host then spawns each orb on both phones, decides hits, sets health and ends rounds. Matches are best of three with 100 HP each.
  - **Ties:** if both wizards reach 0 HP in the same frame, the round is a draw. Nobody scores and the round is replayed.

## Android export

1. In Godot, install the export templates (Editor > Manage Export Templates).
2. Set the Android SDK path and the debug keystore (Editor Settings > Export > Android).
3. Project > Export > **Android** (the preset is already in `export_presets.cfg`) > Export Project to `build/Arcane.apk`.

The preset turns on the `INTERNET`, `ACCESS_NETWORK_STATE` and `ACCESS_WIFI_STATE` permissions, which the duel needs. The game uses sensor landscape orientation.

For a duel, both phones must be on the same Wi-Fi network. One phone taps **Host Match** and reads out the IP address shown on screen. The other phone enters that IP and taps **Join**. Some public or campus networks block traffic between devices. A phone hotspot works as a fallback.
