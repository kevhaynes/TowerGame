# Towers

One JSON definition per tower. This folder is the source of truth for which
towers are implemented. All stat values are provisional prototype numbers.

| Field | Meaning |
|---|---|
| `id` | Matches the filename stem |
| `display_name`, `description` | Shown in the build menu |
| `sprite` | Tower texture (`res://` path, faces +x) |
| `projectile_sprite` | Optional texture for projectiles or drones |
| `behaviour` | Script extending `BaseTower` that implements the tower |
| `strong_against_trait`, `weak_against_trait` | Up to two traits each (x1.2 / x0.8 damage) |
| `stats` | `cost`, `range`, `damage_type`, `targeting_mode` plus the numeric stats the behaviour reads |
| `upgrade_branches` | Empty until upgrade trees are designed (two branches x three tiers) |

`tests/unit/test_tower_definitions.gd` checks every file, including that each
numeric stat is actually required by its behaviour script.
