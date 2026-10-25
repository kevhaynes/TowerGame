# TowersGame

A 2D top-down tower defence game for Android, built in Godot 4 with
statically typed GDScript. You hold a fixed enemy route with futuristic
military turrets placed on build pads beside the road. Each turret has
its own mechanic, from chain lightning and orbital strikes to time stasis
and gravity wells.

## Features

- **22 towers**, each with a JSON definition, a behaviour script and unit
  tests: Machine Gun, Laser Turret, Tesla Coil, Plasma Cannon, Mass Driver,
  Boson Bomb, Flak Battery, Railgun Emplacement, Cryo Projector, EMP Pylon,
  Swarm Missile Pod, Graviton Well, Nanite Hive, Orbital Uplink, Antimatter
  Mortar, Drone Bay, Sonic Lance, Chrono Stasis Field, Phase Disruptor,
  Shield Projector, Overcharge Relay and Flame Thrower.
- **6 enemy types**: Scout, Skitter, Wasp, Heavy, Brute and Aegis Walker.
  Each one has traits (armoured, shielded, mechanical, organic, flying, boss)
  that changes how much damage it takes from each damage type.
- **5 levels**, drawn in the Godot editor, with enemy waves defined in JSON.
- **Damage model**: six damage types (kinetic, energy, explosive, thermal,
  cryo, EMP) and stackable status effects (slow, stun, brittle, armour shred,
  damage over time, phased, stasis, mass increase).
- **Meta-progression**: you earn 1 to 3 stars per level based on the health
  you have left, and spend them in a research tree to unlock towers. Only the
  Machine Gun is available at the start.
- **Local saves** with versioning and migration between save versions.

## Requirements

- **Godot 4.7** (developed against 4.7.2 stable). Godot doesn't have to be on
  `PATH`; you can call the executable by its full path.
- **gdtoolkit** for linting and formatting: `pip install gdtoolkit`.
- **Android export templates** and the Android SDK, if you want to build an
  APK.

## Getting started

1. Clone the repository.
2. Open `project.godot` in the Godot editor.
3. Press **F5** to run. The game starts at the main menu
   (`scenes/ui/main_menu.tscn`).

To try a single level, open `scenes/levels/level_NN.tscn` and use
**Run Current Scene** (F6). The level finds its JSON definition by itself.

## Project layout

```
addons/gut/        GUT test framework (vendored, do not edit)
assets/            Sprites, maps, audio and fonts
data/
  towers/          One JSON definition per tower
  enemies/         One JSON definition per enemy
  levels/          Level settings and enemy waves
  progression/     Research tree (research_tree.json)
scenes/
  game/            Base level scene and build pad
  levels/          Playable levels (level_01.tscn ...)
  ui/              Menus
scripts/
  core/            Game state, economy, waves, levels, save/load
  combat/          Damage, targeting, status effects, tower behaviours
  ui/              Menu and HUD scripts
tests/
  unit/            Logic tests that don't need the scene tree
  integration/     Scene-level tests
  helpers/         Shared test fixtures
```

Most folders have their own `README.md` with more detail.

## How it fits together

- **Data-driven.** Tower, enemy, level and research stats live in JSON under
  `data/`. Scripts load these definitions and never hard-code a stat. Adding a
  tower normally means adding a JSON file, a scene and a behaviour script,
  without touching core systems.
- **Logic is separate from presentation.** Combat maths, targeting, status
  effects and the economy are plain GDScript classes (for example
  `scripts/combat/combat_math.gd`, `scripts/core/wallet.gd`), so they can be
  unit-tested without instancing scenes.
- **Tower behaviours are kept shallow.** Each tower script in
  `scripts/combat/towers/` extends `BaseTower` (`scripts/combat/base_tower.gd`)
  and uses shared helpers for targeting, status effects and stat reading.
- **Autoloads are kept to a minimum**: `GameState` and `SaveManager`.

## Making content

### Levels

Each level is a scene `scenes/levels/level_NN.tscn` that inherits
`scenes/game/level.tscn`, plus a matching `data/levels/level_NN.json`.

1. Draw the enemy route on the `Path` node with the editor's Path2D tools.
   It renders as the road, with ENTRY and EXIT markers added at its ends.
2. Add `scenes/game/build_pad.tscn` instances under `BuildPads` and drag them
   into place. The editor rings a pad in red if it breaks a layout rule (too
   close to the road or another pad, off screen, or under the HUD buttons).
3. Optionally, add a backdrop image from `assets/maps/` as a `Sprite2D` below
   the `Path` node.
4. In the JSON file, set `id`, `display_name`, `order`, `scene`,
   `starting_credits`, `health` and `waves`.

The layout rules live in `scripts/core/level_layout.gd`. The runtime, the
editor warnings and `tests/unit/test_level_layout.gd` all use them, and the
test checks every level scene.

### Towers and enemies

1. Read the existing definitions in `data/towers/` or `data/enemies/` and copy
   their field structure.
2. Add the JSON definition, the scene and, if the tower has its own mechanic,
   a behaviour script in `scripts/combat/towers/`.
3. Add a research node for the new tower in
   `data/progression/research_tree.json`.
4. Add tests. The data-validation tests (`test_tower_definitions.gd`,
   `test_enemy_definitions.gd`) check every definition automatically.

Each tower's upgrade tree has two branches with three tiers each. The player
commits to one branch at tier 2.

## Testing

Tests use [GUT](https://github.com/bitwes/Gut). To run the full suite
headless:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

On Windows, if Godot isn't on `PATH`, use the full path to the main editor
executable, for example `"/c/Program Files/Godot/Godot.exe"` from Git Bash.

Changes to combat, economy, targeting, status effects, wave spawning,
save/load or level layout validation need GUT tests.

## Lint and format

```bash
gdformat --check scripts/ scenes/ tests/
gdlint scripts/ scenes/ tests/
```

To fix formatting, run `gdformat` without `--check`. Don't lint or format
`addons/gut/`.

## Building for Android

The game targets Android in landscape orientation with touch input. Export a
debug APK for testing, or a signed AAB for release, through
**Project > Export** in the editor.

Never commit a keystore or put signing credentials in `export_presets.cfg`.
The planned CI pipeline (see `.github/workflows/README.md`) takes them from
GitHub secrets.

## Contributing

`CLAUDE.md` holds the full design reference and coding conventions: the tower
roster, damage model, static typing rules, naming, and mobile performance
targets. Read it before making larger changes.
