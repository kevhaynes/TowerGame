# Progression

Meta-progression research tree definitions: tower unlocks and global modifiers bought between levels.

The research currency is stars. Stars to spend are the sum of the best star
rating earned on each level (see `data/levels/README.md`), plus any debug bonus
stars, minus the cost of everything researched
(`SaveManager.get_available_stars()`). Spent stars are worked out from the
current costs, so retuning a cost re-prices research the player already has.

## research_tree.json

Every tower in `data/towers/` must appear exactly once; a tower missing from the
tree can never be built. All costs are provisional prototype numbers
(tier N costs N stars).

`categories` (listed top to bottom on the research screen):

| Field | Meaning |
|---|---|
| `id` | Category id referenced by nodes |
| `display_name`, `description` | Shown on the research screen |
| `color` | HTML colour for the category's label, nodes and links |

`nodes` (one per tower):

| Field | Meaning |
|---|---|
| `tower` | Tower id (filename stem in `data/towers/`) |
| `category` | A category `id` |
| `tier` | Column on the research screen (0 = starting towers) |
| `cost` | Stars to research it (0 for starting towers, at least 1 otherwise) |
| `requires` | Towers that must all be unlocked first; each must be in an earlier tier. Cross-category requirements are allowed (e.g. Chrono Stasis Field needs Graviton Well and Phase Disruptor) |
| `starting` | Optional; `true` for towers unlocked from the start (free, no requirements) |

`tests/unit/test_research_tree.gd` validates the file and checks it covers every tower.
