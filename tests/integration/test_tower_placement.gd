extends GutTest

## Places every shipped tower in a real level through the build-pad flow and
## lets the level run, so draw/process code runs against live enemies. GUT
## fails the test on any engine or script error raised meanwhile.

const TOWERS_DIRECTORY: String = "res://data/towers"
const RUN_SECONDS: float = 1.5
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0
## Enough credits to place a full batch of the most expensive towers.
const EVERY_TOWER_BUDGET: int = 1000000


func _tower_paths() -> Array[String]:
	var paths: Array[String] = []
	for file_name: String in DirAccess.get_files_at(TOWERS_DIRECTORY):
		if file_name.ends_with(".json"):
			paths.append("%s/%s" % [TOWERS_DIRECTORY, file_name])
	paths.sort()
	return paths


func test_every_tower_places_and_runs_in_a_level() -> void:
	var save_state := SaveStateFixture.new()
	save_state.unlock_all_towers()
	var paths: Array[String] = _tower_paths()
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	var level_scene: PackedScene = load(str(first_level["scene"]))
	var placed: int = 0
	while placed < paths.size():
		var level: Node = add_child_autofree(level_scene.instantiate())
		level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
		(level.get("_wallet") as Wallet).earn(EVERY_TOWER_BUDGET)
		var pads: Array[Node] = (level.get("build_pads") as Node).get_children()
		var towers := level.get("towers_container") as Node
		var batch: int = mini(pads.size(), paths.size() - placed)
		for index: int in batch:
			level.call("_on_build_pad_selected", pads[index])
			level.call("_on_tower_selected", paths[placed + index])
		var batch_paths: Array[String] = paths.slice(placed, placed + batch)
		assert_eq(towers.get_child_count(), batch, "placed %s" % [batch_paths])
		level.call("set_paused", false)
		await wait_seconds(RUN_SECONDS)
		placed += batch
		level.queue_free()
		await wait_process_frames(2)
	assert_eq(placed, paths.size())
	save_state.restore()
