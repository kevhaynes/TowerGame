# Level Scenes

One scene per level, inheriting `scenes/game/level.tscn`. Draw the route on
`Path` and place `build_pad.tscn` instances under `BuildPads`. The matching
`data/levels/*.json` points here through its `scene` field.
