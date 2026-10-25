---
name: creating-levels
description: Use when adding a new level or map to the TowersGame Godot project, editing a level's path, build pads, enemy waves or spawns, or when a level fails to load, is missing from the level select menu, or its build pads overlap the road.
---

# Creating Levels

## Overview

A level is **a scene plus a small JSON file**. The scene (`scenes/levels/level_NN.tscn`) inherits `scenes/game/level.tscn` and holds the layout: the route drawn on its `Path` node (a `LevelPath`) and `BuildPad` instances under `BuildPads`. The JSON (`data/levels/level_NN.json`) holds `id`, `display_name`, `order`, `scene`, `starting_credits`, `health` and `waves`. Read "Level authoring" in CLAUDE.md, `data/levels/README.md`, `scripts/core/level_layout.gd` and an existing level scene and JSON before starting.

The layout is meant to be drawn by the user in the Godot editor. When asked to create a level, produce a sensible first layout they can then reshape.

## Step 1: Pin down the design (ask, don't invent)

Ask for anything not given:
- **Starting credits, health, waves, enemy line-up and timing.** This is balance; CLAUDE.md says ask. You may propose one relative to existing levels for them to confirm.
- Its place in the sequence (default: after the last level) and display name.
- Whether they will draw the path themselves (then create the scene with a placeholder path) or want you to lay one out.

## Step 2: Create the scene

Copy an existing `scenes/levels/level_NN.tscn` and change it. It must keep this shape:

```
[ext_resource type="PackedScene" path="res://scenes/game/level.tscn" id="1_level"]
[ext_resource type="PackedScene" path="res://scenes/game/build_pad.tscn" id="2_build_pad"]
[sub_resource type="Curve2D" id="Curve2D_path"]   # bake_interval = 4.0, points
[node name="LevelNN" instance=ExtResource("1_level")]
[node name="Path" parent="." index="6"]            # curve = SubResource("Curve2D_path")
[node name="BuildPad1" parent="BuildPads" instance=ExtResource("2_build_pad")]
```

- Curve `points` are triples of (in handle, out handle, position) per point; zero handles give straight segments.
- Coordinates run from the top-left of the level. Its size is `level_size` on the root node (default one screen, the viewport in `project.godot`; maximum `LevelLayout.MAX_LEVEL_SIZE`, 3840x2160). Ask whether the level should be larger than one screen; if so set it on the root node, e.g. `level_size = Vector2i(2880, 1620)` under `[node name="LevelNN" ...]`. The player drags to scroll; the camera starts on the path's ENTRY.
- The road is 123px wide. Keep parallel runs at least ~255px apart (centre to centre) so pads fit between them. Round corners with handles or several close points.
- Put pads inside bends and between parallel runs, where tower range (180-675px) covers a lot of road.
- ENTRY/EXIT markers are drawn automatically ~36px beyond the path ends, so start and end the path a little inside the level edge (or just beyond it, so enemies walk in from off the map).
- Never hand-write `.uid` or `.import` files.

## Step 3: Create the JSON

`data/levels/level_NN.json` with `schema_version` 6, a unique `id` (`level_NN`; **never rename a shipped id**, since save data uses it), a unique `order` (normally highest + 1; inserting mid-sequence changes existing players' unlocks, so ask first), `scene` pointing at the new scene, `starting_credits` (whole number; credits never carry over between levels), `health` (whole number, at least 1), and `waves` (each `{ "spawns": [group, ...] }`, a group being `{ "enemy", "count", "spawn_delay", "spawn_interval" }`). Each wave starts when the previous one is cleared (wave 1 when PLAY is pressed). A group is `count` enemies (default 1) `spawn_interval` seconds apart (required when `count` > 1). Its `spawn_delay` is seconds **after the previous group's last enemy**; for a wave's first group it counts from the wave's start; omitted means 0. Write "5 scouts then 6 heavies" as two groups, not eleven entries. Each escaping enemy costs its `base_damage` (enemy JSON) in level health and the level fails at 0; stars come from the health left (3 at full, 1 below 50%, 2 otherwise), so size `health` against the waves' total `base_damage`.

## Step 4: Verify

```bash
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
godot --headless --quit-after 240 res://scenes/levels/level_NN.tscn   # runs the level directly
```

`test_level_layout.gd` loads every level scene and applies the `LevelLayout` rules (level_size between one screen and the maximum, pad clearance 112.5px, pad spacing 114px, inside the level, clear of the HUD buttons), and `test_level_catalog.gd` checks the JSON. Quote any layout problem it reports and fix the scene. If `godot` isn't on PATH, look for an install before saying tests could not run. Tell the user they can open the scene to reshape the path (select `Path`, use the Path2D toolbar) and drag pads; pads breaking a rule show a red ring.

## Common mistakes

| Mistake | Fix |
|---|---|
| Inventing the enemy line-up | Ask (Step 1) |
| Treating `spawn_delay` as time since level start | It's seconds after the previous group's last enemy in the same wave |
| One entry per enemy | Use a group with `count` and `spawn_interval` |
| Scene doesn't inherit `level.tscn` | No HUD, containers or script: copy an existing level scene |
| JSON `scene` path doesn't match the file | Level missing from the menu; "No level definition ... uses the scene" error when run directly |
| Pads added somewhere other than under `BuildPads` | They are not tappable and are not validated |
| Moving or scaling the `Path` node | Allowed (handled by `LevelLayout.world_curve`), but keep `Enemies` and `Towers` at the origin |
| Assuming a level is one screen | Read the root's `level_size` (default 1920x1080, up to `LevelLayout.MAX_LEVEL_SIZE`) |
| Pads near the top-left of a large level | The HUD buttons cover the level's top-left corner whatever the scroll; keep pads clear of it |
| Duplicate `order` | Unique, normally highest + 1 |
