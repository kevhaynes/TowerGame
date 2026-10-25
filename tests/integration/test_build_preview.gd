extends GutTest

## Two-tap building in a real level: the first tap on a tower previews it on
## the pad at half opacity with its range, the second builds it. Tapping a
## built tower toggles its range.

const MACHINE_GUN: String = "res://data/towers/machine_gun.json"
const LASER_TURRET: String = "res://data/towers/laser_turret.json"
const MORTAR: String = "res://data/towers/antimatter_mortar.json"
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0
const PLENTY_OF_CREDITS: int = 100000

var _save_state: SaveStateFixture
var _level: Node
var _pad: BuildPad


func before_each() -> void:
	_save_state = SaveStateFixture.new()
	_save_state.unlock_all_towers()
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	_level = add_child_autofree(load(str(first_level["scene"])).instantiate())
	_level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
	(_level.get("_wallet") as Wallet).earn(PLENTY_OF_CREDITS)
	_pad = (_level.get("build_pads") as Node).get_child(0) as BuildPad
	_pad.selected.emit(_pad)


func after_each() -> void:
	_save_state.restore()


func _menu() -> BuildMenu:
	return _level.get("_build_menu") as BuildMenu


func _tap(tower_path: String) -> void:
	_menu().get_button(tower_path).pressed.emit()


func _preview() -> Sprite2D:
	return _level.get("_build_preview") as Sprite2D


func _indicator() -> RangeIndicator:
	return _level.get("_range_indicator") as RangeIndicator


func _tower_count() -> int:
	return (_level.get("towers_container") as Node).get_child_count()


func _range_of(tower_path: String) -> float:
	return float(LevelCatalog.read_json_object(tower_path)["stats"]["range"])


func test_first_tap_previews_without_building() -> void:
	var credits: int = int(_level.call("get_credits"))
	_tap(MACHINE_GUN)
	assert_eq(_tower_count(), 0, "nothing built yet")
	assert_eq(int(_level.call("get_credits")), credits, "nothing spent yet")
	assert_true(_preview().visible)
	assert_almost_eq(_preview().modulate.a, 0.5, 0.001, "half opacity")
	assert_eq(_preview().global_position, _pad.global_position)
	assert_true(_indicator().visible)
	assert_eq(_indicator().attack_range, _range_of(MACHINE_GUN))
	assert_gt(_indicator().get_segment_count(), 0, "the pad's stretch of road is shown")
	assert_true(_menu().visible, "menu stays open for the second tap")
	assert_eq(_menu().get_previewing_path(), MACHINE_GUN)


func test_second_tap_on_the_same_tower_builds_it() -> void:
	_tap(MACHINE_GUN)
	_tap(MACHINE_GUN)
	assert_eq(_tower_count(), 1)
	assert_false(_preview().visible)
	assert_false(_indicator().visible)
	assert_false(_menu().visible)


func test_tapping_another_tower_switches_the_preview() -> void:
	_tap(MACHINE_GUN)
	_tap(LASER_TURRET)
	assert_eq(_tower_count(), 0)
	assert_eq(_menu().get_previewing_path(), LASER_TURRET)
	assert_eq(_indicator().attack_range, _range_of(LASER_TURRET))
	_tap(LASER_TURRET)
	assert_eq(_tower_count(), 1)


func test_closing_the_menu_clears_the_preview() -> void:
	_tap(MACHINE_GUN)
	_menu().close()
	assert_false(_preview().visible)
	assert_false(_indicator().visible)
	assert_eq(_tower_count(), 0)


func test_min_range_blind_spot_is_shown() -> void:
	_tap(MORTAR)
	var stats: Dictionary = LevelCatalog.read_json_object(MORTAR)["stats"]
	assert_eq(_indicator().min_range, float(stats["min_range"]))


func test_tapping_a_built_tower_toggles_its_range() -> void:
	_tap(MACHINE_GUN)
	_tap(MACHINE_GUN)
	_pad.selected.emit(_pad)
	assert_true(_indicator().visible)
	assert_eq(_indicator().global_position, _pad.global_position)
	assert_eq(_indicator().attack_range, _range_of(MACHINE_GUN))
	assert_false(_menu().visible, "a built pad does not open the build menu")
	_pad.selected.emit(_pad)
	assert_false(_indicator().visible)
