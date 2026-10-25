---
name: creating-towers
description: Use when adding a new tower or turret type to the TowersGame Godot project, changing how an existing tower behaves, adding a status effect a tower needs, or when a tower JSON in data/towers fails validation or does nothing when placed.
---

# Creating Towers

## Overview

A tower is **data first**: a JSON definition in `data/towers/` holds every stat, its sprites and the path of its behaviour script. `level.gd` loads that script onto a `Sprite2D`, so **no core code changes are needed** for a new tower. Behaviours extend `BaseTower` (`scripts/combat/base_tower.gd`); pure maths lives in plain classes. Read `data/towers/README.md`, `base_tower.gd` and a similar existing tower in `scripts/combat/towers/` before starting.

## Step 1: Pin down the design (ask, don't invent)

1. Find the tower in `CLAUDE.md` (roster table and "Tower Types" list).
2. List every number it needs (cost, damage, fire rate, range, mechanic values).
3. **If the user hasn't given them, ask.** CLAUDE.md: "ask rather than invent balance numbers". Offer provisional values relative to existing towers (`data/towers/*.json`) for them to confirm. Same for traits.
4. Use only the enums in CLAUDE.md (damage types, traits, status effects). A new enum value is a design change: ask first. If the design doesn't work in the game as it stands (e.g. it buffs towers against attacks that don't exist), raise it and propose an alternative.

## Step 2: Files to add

| File | Notes |
|---|---|
| `data/towers/<id>.json` | Fields documented in `data/towers/README.md`; `id` equals the filename stem |
| `assets/sprites/placeholder_<id>.svg` | 96x96 top-down, weapon facing +x, same base as existing placeholders |
| `assets/sprites/placeholder_<projectile>.svg` | Only if it fires projectiles or drones; reuse an existing one if it fits |
| `scripts/combat/towers/<id>_tower.gd` | `extends BaseTower`, `class_name <Pascal>Tower`. Reuse an existing behaviour instead if the tower only differs in stats (Plasma Cannon and Flak Battery share `splash_shell_tower.gd`; Mass Driver extends `MachineGunTower`) |
| Plain logic class / `CombatMath` function | For any new formula, so it is unit-testable |
| `tests/unit/test_<id>_tower.gd` | Step 5 |
| `CLAUDE.md` roster table | Only if it is a new design |

Do **not** hand-write `.import` or `.uid` files.

## Step 3: Behaviour script

```gdscript
extends BaseTower
class_name ExampleTower

var _damage: float = 0.0
var _fire_rate: float = 0.0


func _read_stats(stats: StatReader) -> void:  # read EVERY numeric stat here
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")


func _process(delta: float) -> void:
	var can_fire: bool = tick_cooldown(delta)  # honours Overcharge fire-rate buffs
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		deal_damage(target, _damage)  # applies traits + Overcharge damage buff
		start_cooldown(_fire_rate)
```

- `range`, traits and `projectile_sprite` are read by `BaseTower`. Use `StatReader` (`positive`, `non_negative`, `fraction`, `at_least`, `whole_number`) for everything else: one `push_error` lists every bad stat.
- Use the `BaseTower` helpers rather than hand-rolling: `enemies_within`, `deal_splash`, `launch_projectile` (lands instantly when there's no container, which tests rely on), `spawn_blast`, `get_enemies`. Use `TowerTargeting` for the line, cone, chain or ordered target lists.
- Continuous or area-tick damage passes `is_direct_hit = false` to `deal_damage` so it doesn't consume BRITTLE.
- Status effects: `enemy.apply_status(StatusEffect.slow(...))` and the other `StatusEffect` constructors. Stacking rules live in `StatusEffects`; don't reimplement them. Movement effects use `enemy.push_along_path()`, which applies boss resistance and stasis.
- Expose small public methods for the mechanic (e.g. `spray(point)`, `pulse()`, `detonate(target, point)`) so tests can call them without timing.
- No stat literals; visual constants are named `const`s. Typed GDScript throughout.

## Step 4: JSON

Copy a similar tower's file and change it. Every numeric stat in `stats` (except `cost`) must be read by the behaviour: `test_tower_definitions.gd` deletes each one and expects `configure()` to fail. Leave `upgrade_branches` as `[]` unless the user supplied the tree.

## Step 5: Tests (required)

`tests/unit/test_<id>_tower.gd` using `CombatFixture` (`tests/helpers/combat_fixture.gd`). It builds the tower from its shipped JSON on a straight path (an enemy at path distance d sits at (d, 0)), and `cleanup()` goes in `after_each`. Copy the shape of an existing tower test. Cover the target choice, exact damage numbers, trait affinity if notable, the mechanic and its edge cases (out of range, bosses, expiry). The data-wide checks in `test_tower_definitions.gd` and the level smoke test in `tests/integration/test_tower_placement.gd` pick the new tower up automatically.

GUT fails a test on any `push_error` it doesn't assert: use `assert_push_error(...)` in rejection tests.

## Step 6: Verify before claiming done

```bash
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
gdformat --check scripts/ scenes/ tests/
gdlint scripts/ scenes/ tests/
```

If a tool isn't on PATH, look for an install before giving up, then say exactly which checks did not run. Never report "tests pass" without the output.

## Known gaps vs CLAUDE.md

No `EventBus`, no pooling (projectiles are created and freed), no tower `.tscn` scenes (a behaviour script on a `Sprite2D`). Follow the existing pattern and **mention the gap** rather than restructuring unprompted.

## Common mistakes

| Mistake | Fix |
|---|---|
| Inventing balance numbers | Ask (Step 1) |
| Stat in JSON that the script never reads | Read it in `_read_stats`, or remove it; the definitions test fails otherwise |
| Calling `enemy.apply_damage` directly | Use `deal_damage` so trait affinity and Overcharge apply |
| Beam or tick damage consuming BRITTLE | Pass `is_direct_hit = false` |
| Setting `path_distance` directly for knockback or pull | `push_along_path` (boss factor, stasis) or `set_path_distance` |
| Comparing a possibly freed enemy with `!= null` | Use `is_instance_valid()` first |
| Mechanic maths inside `_process` only | Put it in a plain class or `CombatMath` and test it |
