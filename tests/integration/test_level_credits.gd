extends GutTest

## Credits in a real level scene: the starting amount, buying towers, the
## build menu's affordability, kill bounties, and no carry-over between levels.

const MACHINE_GUN: String = "res://data/towers/machine_gun.json"
const LASER_TURRET: String = "res://data/towers/laser_turret.json"
const SPAWN_WAIT_SECONDS: float = 0.2
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0

var _definition: Dictionary
var _save_state: SaveStateFixture
var _level: Node


func before_each() -> void:
	_save_state = SaveStateFixture.new()
	_save_state.unlock_all_towers()
	_definition = LevelCatalog.load_levels()[0]
	_level = _load_level()


func after_each() -> void:
	_save_state.restore()


func _load_level() -> Node:
	var scene: PackedScene = load(str(_definition["scene"]))
	var level: Node = add_child_autofree(scene.instantiate())
	level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
	return level


func _credits(level: Node = _level) -> int:
	return int(level.call("get_credits"))


func _cost(path: String) -> int:
	return int(LevelCatalog.read_json_object(path)["stats"]["cost"])


func _buy(pad_index: int, tower_path: String) -> void:
	var pad: Node = (_level.get("build_pads") as Node).get_child(pad_index)
	_level.call("_on_build_pad_selected", pad)
	_level.call("_on_tower_selected", tower_path)


func _towers() -> Node:
	return _level.get("towers_container") as Node


func test_level_starts_with_its_starting_credits() -> void:
	assert_eq(_credits(), int(_definition["starting_credits"]))
	var label := _level.get("credits_label") as Label
	assert_eq(label.text, "%d CR" % _definition["starting_credits"])


func test_buying_a_tower_spends_its_cost() -> void:
	var start: int = _credits()
	_buy(0, MACHINE_GUN)
	assert_eq(_towers().get_child_count(), 1)
	assert_eq(_credits(), start - _cost(MACHINE_GUN))


func test_cannot_buy_an_unaffordable_tower() -> void:
	var pads: int = (_level.get("build_pads") as Node).get_child_count()
	var bought: int = 0
	while _credits() >= _cost(LASER_TURRET) and bought < pads - 1:
		_buy(bought, LASER_TURRET)
		bought += 1
	assert_lt(_credits(), _cost(LASER_TURRET), "test needs the player short of a laser")
	var before: int = _credits()
	_buy(bought, LASER_TURRET)
	assert_push_warning("Not enough credits")
	assert_eq(_towers().get_child_count(), bought, "no tower placed")
	assert_eq(_credits(), before, "no credits spent")


func test_build_menu_disables_unaffordable_towers() -> void:
	_level.call("_on_build_pad_selected", (_level.get("build_pads") as Node).get_child(0))
	var menu := _level.get("_build_menu") as BuildMenu
	assert_true(menu.is_affordable(MACHINE_GUN))
	(_level.get("_wallet") as Wallet).spend(_credits() - _cost(MACHINE_GUN) + 1)
	assert_false(menu.is_affordable(MACHINE_GUN), "open menu updates when credits change")


func test_killing_an_enemy_pays_its_bounty() -> void:
	_level.call("set_paused", false)
	await wait_seconds(SPAWN_WAIT_SECONDS)
	var enemy := (_level.get("enemies_container") as Node).get_child(0) as PathEnemy
	var before: int = _credits()
	enemy.apply_damage(1000000.0)
	assert_gt(enemy.bounty, 0)
	assert_eq(_credits(), before + enemy.bounty)


func test_credits_do_not_carry_over_to_the_next_level_load() -> void:
	(_level.get("_wallet") as Wallet).earn(5000)
	var reloaded: Node = _load_level()
	assert_eq(_credits(reloaded), int(_definition["starting_credits"]))
