extends GutTest

## Level health in a real level scene: the starting health from the level
## JSON, escapes costing each enemy's base_damage, the HUD readout, failure at
## 0 health, and the result panel's stars. No test here completes a level, so
## the player's save is never written.

const SPAWN_WAIT_SECONDS: float = 0.2
## Keeps the level from completing during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const MACHINE_GUN: String = "res://data/towers/machine_gun.json"

var _definition: Dictionary
var _level: Node


func before_each() -> void:
	_definition = LevelCatalog.load_levels()[0]
	var scene: PackedScene = load(str(_definition["scene"]))
	_level = add_child_autofree(scene.instantiate())


func _outcome() -> LevelOutcomeTracker:
	return _level.get("_outcome") as LevelOutcomeTracker


func _health_label() -> Label:
	return _level.get("health_label") as Label


func _spawn_first_enemy() -> PathEnemy:
	_level.call("set_paused", false)
	await wait_seconds(SPAWN_WAIT_SECONDS)
	return (_level.get("enemies_container") as Node).get_child(0) as PathEnemy


func test_level_starts_with_its_health() -> void:
	var health: float = float(_definition["health"])
	assert_eq(_outcome().get_health(), health)
	assert_eq(_outcome().get_max_health(), health)
	assert_eq(_health_label().text, "%d / %d HP" % [health, health])


func test_escaping_enemy_costs_its_base_damage() -> void:
	var max_health: float = float(_definition["health"])
	_outcome().start(NEVER_FINISH_ENEMY_COUNT, max_health)
	var enemy: PathEnemy = await _spawn_first_enemy()
	assert_gt(enemy.base_damage, 0.0)
	enemy.escaped.emit(enemy)
	var expected: float = max_health - enemy.base_damage
	assert_eq(_outcome().get_health(), expected)
	assert_eq(_health_label().text, "%d / %d HP" % [expected, max_health])
	assert_false(_level.get("_is_finished"), "level carries on with health left")


func test_running_out_of_health_fails_the_level() -> void:
	var enemy: PathEnemy = await _spawn_first_enemy()
	_outcome().start(NEVER_FINISH_ENEMY_COUNT, enemy.base_damage)
	enemy.escaped.emit(enemy)
	assert_true(_level.get("_is_finished"))
	var panel := _level.get("_result_panel") as LevelResultPanel
	assert_true(panel.visible)
	assert_eq(panel.get_shown_stars(), 0)
	var enemies := _level.get("enemies_container") as Node
	assert_eq(enemies.process_mode, Node.PROCESS_MODE_DISABLED, "enemies stop")


func test_failing_stops_towers_and_projectiles() -> void:
	var pad: Node = (_level.get("build_pads") as Node).get_child(0)
	_level.call("_on_build_pad_selected", pad)
	_level.call("_on_tower_selected", MACHINE_GUN)
	var enemy: PathEnemy = await _spawn_first_enemy()
	_outcome().start(NEVER_FINISH_ENEMY_COUNT, enemy.base_damage)
	enemy.escaped.emit(enemy)
	assert_true(_level.get("_is_finished"))
	for container_name: String in ["towers_container", "projectile_container"]:
		var container := _level.get(container_name) as Node
		assert_eq(container.process_mode, Node.PROCESS_MODE_DISABLED, container_name)
	var projectiles := _level.get("projectile_container") as Node
	var count: int = projectiles.get_child_count()
	await wait_seconds(SPAWN_WAIT_SECONDS)
	assert_eq(projectiles.get_child_count(), count, "towers stop firing")


func test_result_panel_shows_stars_for_a_completion() -> void:
	var panel := _level.get("_result_panel") as LevelResultPanel
	panel.show_complete(true, 2, 7.0, 10.0)
	assert_true(panel.visible)
	assert_eq(panel.get_shown_stars(), 2)
	panel.show_failed()
	assert_eq(panel.get_shown_stars(), 0)
