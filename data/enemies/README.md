# Enemies

One JSON definition per enemy type, including health, speed, traits, rewards
and its sprite path. `bounty` is the credits the player earns for a kill. `base_damage` is the level health the
player loses when this enemy reaches the exit. `shield` points absorb damage before health
(armour only reduces damage that gets past the shield) and are stripped by EMP. See `scout.json` and `heavy.json` for the first-level
placeholder enemy definitions.

| Enemy | Traits | Role | Countered by (tier 1) |
|---|---|---|---|
| `scout` | Mechanical | Fast, light frontline unit | Machine Gun |
| `heavy` | Mechanical, Armoured | Slow armoured unit | Laser Turret, Mass Driver |
| `wasp` | Flying | Fast airborne unit, comes in flights | Flak Battery |
| `brute` | Organic, Armoured | Slow, tough bio-beast | Flame Thrower, Cryo Projector |
| `aegis` | Shielded, Armoured | Shield soaks damage before its armour | Mass Driver (EMP Pylon strips shields) |
| `skitter` | Organic | Swarm: very fast, very weak, sent in large numbers | Flame Thrower, Flak Battery splash |

`wasp`, `brute`, `aegis` and `skitter` are designed so the starting Machine
Gun is never strong against them; `tests/unit/test_enemy_definitions.gd` checks
each has a tier-1 research counter. Flying enemies currently follow the road
like everything else.

The included combat values are provisional prototype stats.
