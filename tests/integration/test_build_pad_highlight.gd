extends GutTest

## The selected build pad is highlighted while the build menu is open for it,
## so the player can see where the tower will go.

const MACHINE_GUN: String = "res://data/towers/machine_gun.json"
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0
const PLENTY_OF_CREDITS: int = 100000

var _save_state: SaveStateFixture
var _level: Node


func before_each() -> void:
	_save_state = SaveStateFixture.new()
	_save_state.unlock_all_towers()
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	_level = add_child_autofree(load(str(first_level["scene"])).instantiate())
	_level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
	(_level.get("_wallet") as Wallet).earn(PLENTY_OF_CREDITS)


func after_each() -> void:
	_save_state.restore()


func _pad(index: int) -> BuildPad:
	return (_level.get("build_pads") as Node).get_child(index) as BuildPad


func _menu() -> BuildMenu:
	return _level.get("_build_menu") as BuildMenu


func _build_on(pad: BuildPad) -> void:
	pad.selected.emit(pad)
	_menu().get_button(MACHINE_GUN).pressed.emit()
	_menu().get_button(MACHINE_GUN).pressed.emit()


func test_pads_start_unhighlighted() -> void:
	for pad: Node in (_level.get("build_pads") as Node).get_children():
		assert_false((pad as BuildPad).is_highlighted)


func test_selecting_a_pad_highlights_it() -> void:
	var face_color: Color = _pad(0).face.color
	_pad(0).selected.emit(_pad(0))
	assert_true(_pad(0).is_highlighted)
	assert_true(_pad(0).highlight.visible)
	assert_ne(_pad(0).face.color, face_color, "the face brightens")


func test_selecting_another_pad_moves_the_highlight() -> void:
	_pad(0).selected.emit(_pad(0))
	_pad(1).selected.emit(_pad(1))
	assert_false(_pad(0).is_highlighted)
	assert_true(_pad(1).is_highlighted)


func test_closing_the_menu_clears_the_highlight() -> void:
	var face_color: Color = _pad(0).face.color
	_pad(0).selected.emit(_pad(0))
	_menu().close()
	assert_false(_pad(0).is_highlighted)
	assert_false(_pad(0).highlight.visible)
	assert_eq(_pad(0).face.color, face_color, "the face goes back to normal")


func test_building_clears_the_highlight() -> void:
	_build_on(_pad(0))
	assert_true(_pad(0).is_occupied)
	assert_false(_pad(0).is_highlighted)


func test_tapping_a_built_tower_clears_the_highlight() -> void:
	_build_on(_pad(0))
	_pad(1).selected.emit(_pad(1))
	_pad(0).selected.emit(_pad(0))
	assert_false(_pad(1).is_highlighted)
	assert_false(_pad(0).is_highlighted, "built pads are not highlighted")


func test_selling_leaves_the_pad_unhighlighted() -> void:
	_build_on(_pad(0))
	_level.call("sell_tower", _pad(0))
	assert_false(_pad(0).is_occupied)
	assert_false(_pad(0).is_highlighted)
