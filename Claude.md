# CLAUDE.md

Guidance for Claude when working in this repository.

## Project overview

A 2D top-down **tower defence game** with military, futuristic/sci-fi turrets, built in **Godot 4** with **GDScript**, targeting **Android**.

- Enemies follow a **fixed path** per level (no mazing).
- Towers are placed on designated build slots beside the path.
- v1 scope: **tower upgrade trees**, **multiple enemy types**, **meta-progression** between levels.
- Out of scope for v1: monetisation (ads/IAP), iOS, desktop/web builds, multiplayer.

## Tech stack

| Area | Choice |
|---|---|
| Engine | Godot 4 (exact version pinned in `.godot-version`; do not change it without being asked) |
| Language | GDScript only, statically typed |
| Renderer | Compatibility (widest Android device support) |
| Tests | GUT (Godot Unit Test), under `addons/gut` |
| Lint/format | gdtoolkit (`gdlint`, `gdformat`) |
| CI/CD | GitHub Actions |
| Target | Android (APK for testing, AAB for release) |

## Repository layout

```
addons/
  gut/                  # Test framework (vendored, do not edit)
data/
  towers/               # Tower JSON definitions, one per tower
  enemies/              # Enemy JSON definitions
  levels/               # Level JSON definitions (id, order, scene, enemy waves)
  progression/          # Meta-progression unlock tree
assets/
  maps/                 # Level background images (.png/.jpg)
  sprites/  audio/  fonts/
scenes/                 # .tscn files (game, levels, ui, towers, enemies, projectiles)
scripts/
  core/                 # Game state, economy, wave spawning, save/load
  combat/               # Damage, targeting, status effects
  resources/            # Custom Resource class definitions (the data schema)
  ui/
tests/
  unit/                 # Pure logic tests (no scene tree where possible)
  integration/          # Scene-level tests
.github/workflows/
```

## Architecture principles

- **Data-driven first.** Tower, enemy, wave, level and upgrade stats and sprite paths live in JSON files under `data/`. Never hard-code a stat in a script or scene. Adding a new tower should normally mean adding a JSON definition, a scene and (if it has a unique mechanic) a behaviour script; not editing core systems.
- **JSON definitions are the source of truth.** Keep definition fields consistent within each data category and load them where they are used. Sprite references use Godot `res://` paths.
- **Separate logic from presentation.** Combat maths, economy, targeting and status-effect calculations are plain GDScript classes that can be unit-tested without instancing scenes. Nodes call into them.
- **Composition over inheritance** for tower behaviours: a tower scene is assembled from components (targeting, weapon, aura/support, status-applier) rather than a deep class hierarchy.
- **Signals for cross-system communication** (e.g. `enemy_killed`, `wave_started`, `credits_changed`) via an `EventBus` autoload. Keep autoloads minimal: `EventBus`, `GameState`, `SaveManager`.
- **Object pooling** for projectiles, enemies and effects. Avoid `instantiate()`/`queue_free()` in hot paths.

## Game design reference

### Damage and enemy model

Every hit carries a `DamageType` and every enemy has traits. Towers interact with these, so keep them consistent across data files.

- Damage types: `KINETIC`, `ENERGY`, `EXPLOSIVE`, `THERMAL`, `CRYO`, `EMP`
- Enemy traits: `ARMOURED`, `SHIELDED`, `MECHANICAL`, `ORGANIC`, `FLYING`, `BOSS`
- Status effects (stackable rules defined per effect): `SLOW`, `STUN`, `BRITTLE`, `ARMOUR_SHRED`, `DOT`, `PHASED`, `STASIS`, `MASS_INCREASE`
- Flying enemies still follow a level path, but may use a separate flight path defined in the level JSON.

### Tower roster

Each tower has a base definition plus an upgrade tree of **two branches, three tiers each** (the player commits to one branch at tier 2).

| Tower | Role |
|---|---|
| Machine Gun | Cheap single-target kinetic DPS |
| Laser Turret | Continuous energy beam, ramps damage on the same target |
| Tesla Coil | Chain lightning between nearby enemies |
| Plasma Cannon | Thermal splash damage |
| Mass Driver | High single-target kinetic burst |
| Boson Bomb | Increases enemy mass: slow + damage over time |
| Flak Battery | Anti-air / anti-cluster splash |
| Railgun Emplacement | Line-piercing shot |
| Cryo Projector | Slow + brittle (bonus damage taken) |
| EMP Pylon | Stuns mechanical enemies, strips shields |
| Swarm Missile Pod | Multi-target homing missiles |
| Graviton Well | Pulls enemies together (setup for splash) |
| Nanite Hive | Spreading armour shred + DoT |
| Orbital Uplink | Delayed high-damage area strike |
| Antimatter Mortar | Long-range huge splash, minimum-range blind spot |
| Drone Bay | Autonomous patrolling drones |
| Sonic Lance | Knockback along the path |
| Chrono Stasis Field | Freezes enemies; stored damage released on expiry |
| Phase Disruptor | Phased enemies take extra damage but ignore slows |
| Shield Projector | Support: energy barrier across the path that holds enemies until broken, then recharges |
| Overcharge Relay | Support: buffs adjacent towers, overheats |
| Flame Thrower | Close-range thermal cone with burn DoT; strong vs organic, weak vs mechanical |

Not every tower needs to ship in v1. Treat this table as the design pool; `data/towers/` is the source of truth for what is implemented.

### Meta-progression

Between levels the player spends a persistent currency (stars: 1-3 per level from the health left on completion, best run counts) in a research tree (`data/progression/`) that unlocks new towers and grants global modifiers. Save data is local only, versioned, and must migrate cleanly between save versions.

The research tree (`data/progression/research_tree.json`) groups towers into categories (Physical, Explosive, Thermal, Particle, Status, Support) and branches: each tower requires one or more earlier towers, sometimes from another category. Only the Machine Gun is unlocked at the start. When adding a tower, add its node to the tree too.

## Level authoring

Levels are scenes, drawn in the Godot editor. Each level is `scenes/levels/level_NN.tscn`, a scene inheriting `scenes/game/level.tscn`:

- Draw the enemy route on the `Path` node (a `LevelPath`, i.e. a `Path2D`) with the editor's Path2D tools; use point handles for curves. It renders as the road at full width in the editor and in game, with ENTRY/EXIT markers placed automatically at its ends.
- Add `scenes/game/build_pad.tscn` instances as children of `BuildPads` and drag them into place. Pads that break a layout rule (too close to the road or another pad, off screen, under the HUD buttons) are ringed in red in the editor.
- A backdrop image from `assets/maps/` can be added as a `Sprite2D` below the `Path` node.
- `data/levels/level_NN.json` holds the level's `id`, `display_name`, `order`, `scene` path, `starting_credits`, `health` and enemy `waves`; the level finds its JSON by matching `scene`, so a level scene can be run directly with "Run Current Scene".

Layout rules live in `LevelLayout` (`scripts/core/level_layout.gd`) and are shared by the runtime, the editor warnings and `tests/unit/test_level_layout.gd`, which loads every level scene and validates it.

## Mobile considerations

- Landscape orientation, touch-first input. No hover-dependent UI; minimum touch target ~48dp.
- Support tap to place, tap a tower to open its upgrade panel, pinch-zoom and drag-pan on larger maps.
- Handle app pause/resume: auto-pause the game and save state when the app is backgrounded.
- Respect safe areas / display cutouts.
- Performance budget: steady 60 fps on mid-range Android. Profile with large waves; prefer pooling, `Area2D` with sensible collision layers, and batched/simple shaders.
- Interaction cost from UI elements should be kept to a minimum.

## Coding conventions

- Static typing everywhere: typed variables, parameters, return types and typed arrays (for example, `Array[Dictionary]` for parsed JSON records).
- Naming: `snake_case` files, functions and variables; `PascalCase` for `class_name` and nodes; `UPPER_SNAKE` for constants and enum values.
- One `class_name` per script. Use `@export` for anything a designer should tune.
- Prefer `@onready` over `get_node()` in `_process`. Never use string-based node paths in hot loops.
- No magic numbers: put tuning values in data resources or named constants.
- Code must pass `gdformat --check` and `gdlint` before committing.

## Testing

- Every change to combat, economy, targeting, status effects, wave spawning, save/load or level layout validation needs GUT tests.
- Unit tests go in `tests/unit/`, named `test_<subject>.gd`, extending `GutTest`.
- Add a data-validation test that loads every JSON file in `data/` and checks required fields, valid enum values, non-negative costs, and that upgrade trees have the expected shape.
- Run tests headless:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

## Lint and format

```bash
gdformat --check scripts/ scenes/ tests/
gdlint scripts/ scenes/ tests/
```

Run `gdformat` (without `--check`) to fix formatting. Do not lint or format `addons/gut/`.

## CI/CD (GitHub Actions)

Workflows live in `.github/workflows/`:

- **ci.yml** (on pull request and push to `main`): lint, format check, import the project headless, run GUT tests, publish test results.
- **android.yml** (on tag `v*` and manual dispatch): build a debug APK on every run and a signed release AAB on tags; upload as artifacts.

Rules:
- Pin the Godot version and export templates to the value in `.godot-version`.
- Signing keystore and passwords come from GitHub secrets only (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Never commit a keystore or put credentials in `export_presets.cfg`.
- Cache Godot binaries and export templates between runs.
- CI must fail on lint errors, format drift or any failing test.

## Working agreements for Claude

- Read existing JSON definitions in the relevant `data/` category before editing or adding data files.
- When adding a tower or enemy: add the JSON definition, the scene, any behaviour script, and tests; update the roster table above if it is a new design.
- Don't edit vendored addons (`addons/gut`).
- Don't change the pinned Godot version, renderer, or Android export settings unless asked.
- Keep changes small and focused; run lint, format and tests before declaring work done.
- If a design question isn't answered here or in `data/`, ask rather than invent balance numbers.

## Tower Types:

All tower types should be futuristic military style towers.

- Flak Battery: Bursting proximity shells that shred clustered or airborne enemies with area splash.
- Railgun Emplacement: Slow-firing hypervelocity slug that pierces every enemy in a straight line.
- Cryo Projector: Sprays liquid-nitrogen mist that slows enemies and makes them brittle, so the next hit does bonus damage.
- EMP Pylon: Periodic pulse that stuns mechanical enemies and strips shields, but does little to organic targets.
- Swarm Missile Pod: Launches clusters of micro-missiles that home in on separate targets.
- Graviton Well: Creates a singularity that pulls nearby enemies toward its centre, bunching them up for splash towers.
- Nanite Hive: Releases a cloud of nanobots that eat away at armour, lowering defence over time and spreading to nearby enemies.
- Orbital Uplink: Doesn’t fire directly. It paints targets and calls down a kinetic strike from orbit after a short delay, hitting massive damage in an area.
- Flame Thrower: Close range tower, strong against organic target, weak on mechanical.
- Drone Bay: Deploys autonomous combat drones that patrol a zone and engage enemies independently.
- Sonic Lance: Focused acoustic beam that knocks enemies back along the path, buying time.
- Antimatter Mortar: Long-range, slow-reload artillery with a huge blast radius and a minimum range blind spot.
- Chrono Stasis Field: Freezes enemies in time for a few seconds. Damage dealt during stasis is stored and released all at once when it ends.
- Overcharge Relay: Support tower that boosts fire rate and damage of adjacent towers, at the cost of overheating and needing cooldown periods.
