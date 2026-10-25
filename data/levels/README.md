# Levels

One JSON definition per level. The layout itself (path and build pads) is
drawn in the level's scene under `scenes/levels/`; see "Level authoring" in
CLAUDE.md.

Levels are listed on the level select menu in ascending `order`. The first level
is always unlocked; each later level unlocks when the one before it is
completed.

| Field | Meaning |
|---|---|
| `id` | Unique level id, also used in save data. Never rename a shipped id |
| `display_name` | Name shown on the menu and level HUD |
| `order` | Position in the level sequence (1 = first), unique |
| `scene` | `res://` path of the level scene holding the path and build pads |
| `starting_credits` | Credits the player starts the level with. Credits come from kills (each enemy's `bounty`), are spent on towers, and do not carry over to other levels |
| `health` | The level's health (whole number, at least 1). Each enemy reaching the exit costs its `base_damage`; the level fails at 0 |
| `waves` | List of `{ "spawns": [group, ...] }`; each group is `{ "enemy": <id in data/enemies>, "count": n, "spawn_delay": seconds, "spawn_interval": seconds }` |

Wave timing (`scripts/core/wave_spawner.gd`):

- Wave 1 starts when the player presses PLAY; each later wave starts once every
  enemy of the previous wave has been killed or has escaped.
- A wave is a sequence of spawn groups. A group is `count` enemies of one
  type (default 1), `spawn_interval` seconds apart (required when `count` is
  more than 1).
- A group's `spawn_delay` is the wait before its first enemy: from the start of
  the wave for the first group, otherwise from the previous group's last enemy.
  Leaving it out (or 0) starts the group at the same moment.

For example, 5 scouts, then 6 heavies 2 seconds later, then 10 scouts:

```json
"spawns": [
  { "enemy": "scout", "count": 5, "spawn_interval": 0.8 },
  { "enemy": "heavy", "count": 6, "spawn_delay": 2.0, "spawn_interval": 1.5 },
  { "enemy": "scout", "count": 10, "spawn_delay": 2.0, "spawn_interval": 0.5 }
]
```

Stars (`scripts/core/level_stars.gd`), awarded on completion from the health
left: 3 at full health, 1 below 50%, 2 otherwise. The best rating per level is
saved and will be spent on tower research.

`tests/unit/test_level_catalog.gd` checks every definition;
`tests/unit/test_level_layout.gd` checks every level scene's layout.
