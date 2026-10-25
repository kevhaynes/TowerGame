# Game Scenes

Top-level gameplay scenes: the main game scene, level scene and shared world pieces.

`level.tscn` is the generic level scene. Its script reads the level chosen in
`GameState.current_level_id` from `data/levels/` and builds the road, entry and
exit markers, build pads and enemies from it. Enemy and tower stats and sprites
come from `data/enemies/` and `data/towers/`. When every enemy has been
killed, the level is marked complete in `SaveManager` (unlocking the next level)
and a result panel offers Next Level, Retry and Levels. If any enemy reaches the
exit, the level is failed once all enemies are resolved.

`first_level.tscn`/`first_level.gd` are the original hand-built prototype, now
superseded by `level.tscn` + `data/levels/level_01.json`.
