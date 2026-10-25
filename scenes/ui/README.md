# UI Scenes

Menus, HUD, tower build/upgrade panels and other interface scenes. Touch-first: no hover-only UI, minimum ~48dp targets.

The first level creates its tower build menu from available JSON definitions in
`data/towers/` and displays it on the right when an unoccupied build pad is
selected. Each tower option shows its sprite beside its name and cost.
Strengths and weaknesses from its JSON definition appear as green and red
trait tags; matching strong and weak traits apply their damage modifiers
together.

Building takes two taps on the same tower: the first shows it on the pad at
half opacity with a range indicator (`scripts/ui/range_indicator.gd`: its range
circle, any `min_range` blind spot, and the stretches of road it can hit), the
second builds it. Tapping a different tower switches the preview; CLOSE clears
it. Tapping a built tower toggles its range indicator.
- `main_menu.tscn` - startup menu: PLAY, ENEMIES, TOWERS, and (debug builds
  only) RESET STARS and ADD 10 STARS (`scripts/ui/main_menu.gd`).
- `level_select.tscn` - level select menu, opened by PLAY (`scripts/ui/level_select_menu.gd`).
- `enemies_menu.tscn` - the enemy types the player has encountered, from
  `SaveManager.codex` (`scripts/ui/enemies_menu.gd`).
- `towers_menu.tscn` - the unlocked towers, with a RESEARCH button
  (`scripts/ui/towers_menu.gd`).
- `research_menu.tscn` - the research tree from
  `data/progression/research_tree.json`: one band per category, one column per
  tier, links from each requirement. Tapping a tower shows its details and a
  RESEARCH button (`scripts/ui/research_menu.gd`, `scripts/ui/research_tree_view.gd`).
  Also opened from the level result panel's RESEARCH button; BACK returns to
  `GameState.research_return_scene`.

Levels only offer researched (or starting) towers in the build menu.
