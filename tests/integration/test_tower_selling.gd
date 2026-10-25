extends GutTest

## Selling towers in a real level: tapping a built tower opens its panel, and
## selling refunds 70% of its price to the level's wallet and frees the pad
## for another tower.

const MACHINE_GUN: String = "res://data/towers/machine_gun.json"
const LASER_TURRET: String = "res://data/towers/laser_turret.json"
const DRONE_BAY: String = "res://data/towers/drone_bay.json"
const TOWERS_DIRECTORY: String = "res://data/towers"
const RUN_SECONDS: float = 0.5
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0
const PLENTY_OF_CREDITS: int = 1000000

var _save_state: SaveStateFixture
var _level: Node
var _pad: BuildPad


func before_each() -> void:
	_save_state = SaveStateFixture.new()
	_save_state.unlock_all_towers()
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	_level = add_child_autofree(load(str(first_level["scene"])).instantiate())
	_level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
	_pad = _pads()[0] as BuildPad


func after_each() -> void:
	_save_state.restore()


func _pads() -> Array[Node]:
	return (_level.get("build_pads") as Node).get_children()


func _build(pad: BuildPad, tower_path: String) -> void:
	pad.selected.emit(pad)
	_level.call("_on_tower_selected", tower_path)


func _credits() -> int:
	return int(_level.call("get_credits"))


func _cost(tower_path: String) -> int:
	return int(LevelCatalog.read_json_object(tower_path)["stats"]["cost"])


func _towers() -> Node:
	return _level.get("towers_container") as Node


func _panel() -> TowerPanel:
	return _level.get("_tower_panel") as TowerPanel


func _sell_by_tapping(pad: BuildPad) -> void:
	pad.selected.emit(pad)
	_panel().get_sell_button().pressed.emit()


func test_tapping_a_built_tower_opens_its_panel_with_the_refund() -> void:
	_build(_pad, MACHINE_GUN)
	_pad.selected.emit(_pad)
	assert_true(_panel().visible)
	assert_eq(_panel().get_refund(), Wallet.sell_refund(_cost(MACHINE_GUN)))
	assert_string_contains(
		_panel().get_sell_button().text, "%d CR" % Wallet.sell_refund(_cost(MACHINE_GUN))
	)
	_pad.selected.emit(_pad)
	assert_false(_panel().visible, "tapping the tower again closes the panel")


func test_selling_refunds_seventy_percent_to_the_wallet() -> void:
	_build(_pad, LASER_TURRET)
	var before: int = _credits()
	_sell_by_tapping(_pad)
	assert_eq(_credits(), before + Wallet.sell_refund(_cost(LASER_TURRET)))
	var label := _level.get("credits_label") as Label
	assert_eq(label.text, "%d CR" % _credits())


func test_selling_frees_the_pad() -> void:
	_build(_pad, MACHINE_GUN)
	_sell_by_tapping(_pad)
	await wait_process_frames(1)
	assert_false(_pad.is_occupied)
	assert_eq(_towers().get_child_count(), 0, "tower removed")
	assert_false(_panel().visible)
	assert_false((_level.get("_range_indicator") as RangeIndicator).visible)
	_pad.selected.emit(_pad)
	assert_true((_level.get("_build_menu") as BuildMenu).visible, "pad builds again")


func test_refunded_credits_can_be_spent_again() -> void:
	(_level.get("_wallet") as Wallet).spend(_credits() - _cost(LASER_TURRET))
	_build(_pad, LASER_TURRET)
	assert_eq(_credits(), 0)
	_sell_by_tapping(_pad)
	assert_eq(_credits(), Wallet.sell_refund(_cost(LASER_TURRET)))
	_build(_pad, MACHINE_GUN)
	assert_true(_pad.is_occupied, "refund buys a new tower on the freed pad")
	assert_eq(
		_credits(), Wallet.sell_refund(_cost(LASER_TURRET)) - _cost(MACHINE_GUN)
	)


func test_selling_a_drone_bay_removes_its_drones() -> void:
	(_level.get("_wallet") as Wallet).earn(PLENTY_OF_CREDITS)
	_build(_pad, DRONE_BAY)
	_level.call("set_paused", false)
	await wait_process_frames(2)
	var projectiles := _level.get("projectile_container") as Node
	assert_gt(projectiles.get_child_count(), 0, "drones deployed")
	_sell_by_tapping(_pad)
	await wait_process_frames(2)
	for child: Node in projectiles.get_children():
		assert_false(child is CombatDrone, "no drones left behind")


func test_every_tower_can_be_sold_mid_combat() -> void:
	(_level.get("_wallet") as Wallet).earn(PLENTY_OF_CREDITS)
	var paths: Array[String] = []
	for file_name: String in DirAccess.get_files_at(TOWERS_DIRECTORY):
		if file_name.ends_with(".json"):
			paths.append("%s/%s" % [TOWERS_DIRECTORY, file_name])
	var pads: Array[Node] = _pads()
	_level.call("set_paused", false)
	var index: int = 0
	while index < paths.size():
		var batch: int = mini(pads.size(), paths.size() - index)
		for offset: int in batch:
			_build(pads[offset] as BuildPad, paths[index + offset])
		await wait_seconds(RUN_SECONDS)
		for offset: int in batch:
			var before: int = _credits()
			_sell_by_tapping(pads[offset] as BuildPad)
			assert_eq(
				_credits(),
				before + Wallet.sell_refund(_cost(paths[index + offset])),
				"sold %s" % paths[index + offset]
			)
			assert_false((pads[offset] as BuildPad).is_occupied)
		await wait_seconds(RUN_SECONDS)
		index += batch
	assert_eq(_towers().get_child_count(), 0)
