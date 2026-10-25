extends GutTest

## Research in the real menus and levels: spending stars on the research
## screen, levels only offering unlocked towers, and the result panel's
## RESEARCH button. SaveStateFixture keeps the player's real save untouched.

const ResearchMenuScene: PackedScene = preload("res://scenes/ui/research_menu.tscn")
const MACHINE_GUN: String = "res://data/towers/machine_gun.json"
const LASER_TURRET: String = "res://data/towers/laser_turret.json"
## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0

var _save_state: SaveStateFixture


func before_each() -> void:
	_save_state = SaveStateFixture.new()


func after_each() -> void:
	_save_state.restore()


func _research_menu() -> ResearchMenu:
	return add_child_autofree(ResearchMenuScene.instantiate()) as ResearchMenu


func _level() -> Node:
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	var level: Node = add_child_autofree(load(str(first_level["scene"])).instantiate())
	level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
	return level


func test_research_menu_shows_every_tower_in_the_tree() -> void:
	var menu := _research_menu()
	for tower_id: String in ResearchTree.load_tree().get_tower_ids():
		assert_not_null(menu.find_child("%sNode" % tower_id.to_pascal_case(), true, false))


func test_researching_spends_stars_and_saves() -> void:
	SaveManager.progress.record_completion("level_01", 3)
	var menu := _research_menu()
	menu.select_tower("laser_turret")
	var button := menu.find_child("ResearchButton", true, false) as Button
	assert_false(button.disabled)
	button.pressed.emit()
	assert_true(SaveManager.research.has_researched("laser_turret"))
	assert_eq((menu.find_child("Subtitle", true, false) as Label).text, "2 STARS TO SPEND")
	SaveManager.load_game()
	assert_true(SaveManager.research.has_researched("laser_turret"), "research was saved")


func test_cannot_research_without_stars_or_requirements() -> void:
	var menu := _research_menu()
	menu.select_tower("laser_turret")
	assert_true((menu.find_child("ResearchButton", true, false) as Button).disabled, "no stars")
	assert_false(menu.research_selected())

	SaveManager.add_debug_stars(99)
	menu.select_tower("tesla_coil")
	assert_false(menu.research_selected(), "laser turret not researched")
	assert_false(SaveManager.research.has_researched("tesla_coil"))


func test_initial_selection_is_researchable_when_stars_are_available() -> void:
	SaveManager.add_debug_stars(1)
	var menu := _research_menu()
	var button := menu.find_child("ResearchButton", true, false) as Button
	assert_not_null(button)
	assert_false(button.disabled)


func test_level_build_menu_lists_only_unlocked_towers() -> void:
	SaveManager.research.record_research("laser_turret")
	var level: Node = _level()
	level.call("_on_build_pad_selected", (level.get("build_pads") as Node).get_child(0))
	var menu := level.get("_build_menu") as BuildMenu
	assert_true(menu.is_affordable(MACHINE_GUN))
	assert_true(menu.is_affordable(LASER_TURRET))
	assert_false(menu.is_affordable("res://data/towers/tesla_coil.json"), "not listed")


func test_level_rejects_locked_towers() -> void:
	var level: Node = _level()
	level.call("_on_build_pad_selected", (level.get("build_pads") as Node).get_child(0))
	level.call("_on_tower_selected", LASER_TURRET)
	assert_push_warning("has not been researched")
	assert_eq((level.get("towers_container") as Node).get_child_count(), 0)


func test_level_connects_the_result_panel_research_button() -> void:
	var panel := _level().get("_result_panel") as LevelResultPanel
	assert_gt(panel.research_requested.get_connections().size(), 0)


## A standalone panel, since pressing RESEARCH in a level changes scene.
func test_result_panel_has_research_button_and_stars() -> void:
	var panel := LevelResultPanel.new()
	add_child_autofree(panel)
	var button := panel.find_child("ResearchButton", true, false) as Button
	assert_not_null(button)
	watch_signals(panel)
	button.pressed.emit()
	assert_signal_emitted(panel, "research_requested")

	panel.show_complete(true, 3, 10.0, 10.0)
	panel.set_research_stars(3)
	var stars_label := panel.find_child("ResearchStars", true, false) as Label
	assert_true(stars_label.visible)
	assert_string_contains(stars_label.text, "3 stars")
	panel.set_research_stars(0)
	assert_false(stars_label.visible)
