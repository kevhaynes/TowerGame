extends GutTest

## Pausing in a real level scene: levels open paused, the pause button toggles
## the world, and towers can still be placed while paused.

const RUN_SECONDS: float = 0.3
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0
const TOWER_PATH: String = "res://data/towers/machine_gun.json"

var _level: Node


func before_each() -> void:
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	var scene: PackedScene = load(str(first_level["scene"]))
	_level = add_child_autofree(scene.instantiate())
	_level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)


func _enemies() -> Node:
	return _level.get("enemies_container") as Node


func _first_enemy() -> PathEnemy:
	return _enemies().get_child(0) as PathEnemy


func _pause_button() -> Button:
	return _level.get("pause_button") as Button


func test_level_starts_paused_with_survey_prompt() -> void:
	assert_true(_level.call("is_paused"))
	var banner := _level.get("pause_banner") as Label
	assert_true(banner.visible)
	assert_eq(banner.text, _level.get("PAUSED_AT_START_TEXT"))
	assert_eq(_pause_button().text, _level.get("PLAY_TEXT"))


func test_no_enemies_spawn_until_play() -> void:
	await wait_seconds(RUN_SECONDS)
	assert_eq(_enemies().get_child_count(), 0)
	assert_eq((_level.get("wave_label") as Label).text, "WAVE 1 / 1")


func test_pause_button_toggles_play() -> void:
	_pause_button().pressed.emit()
	assert_false(_level.call("is_paused"))
	assert_eq(_pause_button().text, _level.get("PAUSE_TEXT"))
	assert_false((_level.get("pause_banner") as Label).visible)
	await wait_seconds(RUN_SECONDS)
	assert_gt(_enemies().get_child_count(), 0, "first enemy spawns once playing")
	var enemy := _first_enemy()
	assert_gt(enemy.path_distance, 0.0, "enemies move once playing")

	_pause_button().pressed.emit()
	assert_true(_level.call("is_paused"))
	var banner := _level.get("pause_banner") as Label
	assert_eq(banner.text, _level.get("PAUSED_TEXT"), "no survey prompt after starting")
	var frozen_at: float = enemy.path_distance
	var spawned: int = _enemies().get_child_count()
	await wait_seconds(RUN_SECONDS)
	assert_eq(enemy.path_distance, frozen_at)
	assert_eq(_enemies().get_child_count(), spawned, "no spawns while paused")


func test_towers_can_be_placed_while_paused() -> void:
	var pad := (_level.get("build_pads") as Node).get_child(0)
	_level.call("_on_build_pad_selected", pad)
	_level.call("_on_tower_selected", TOWER_PATH)
	var towers := _level.get("towers_container") as Node
	assert_eq(towers.get_child_count(), 1)
	assert_true(_level.call("is_paused"), "placing a tower does not unpause")


func test_backgrounding_the_app_pauses() -> void:
	_level.call("set_paused", false)
	_level.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(_level.call("is_paused"))
