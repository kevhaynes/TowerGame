extends GutTest

## The main, enemies and towers menus, and recording enemy encounters in a
## level. SaveStateFixture keeps the player's real progress and save untouched.
## Navigation buttons are not pressed, since changing scene would replace the
## test runner.

const MainMenuScene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const EnemiesMenuScene: PackedScene = preload("res://scenes/ui/enemies_menu.tscn")
const TowersMenuScene: PackedScene = preload("res://scenes/ui/towers_menu.tscn")
const LevelSelectScene: PackedScene = preload("res://scenes/ui/level_select.tscn")

var _save_state: SaveStateFixture


func before_each() -> void:
	_save_state = SaveStateFixture.new()


func after_each() -> void:
	_save_state.restore()


func _cards(menu: Node) -> Array[Node]:
	return menu.find_child("Cards", true, false).get_children()


func test_main_menu_has_its_buttons() -> void:
	var menu: Node = add_child_autofree(MainMenuScene.instantiate())
	for button_name: String in ["PlayButton", "EnemiesButton", "TowersButton"]:
		var button := menu.find_child(button_name, true, false) as Button
		assert_not_null(button, button_name)
		assert_true(button.pressed.get_connections().size() > 0, "%s is wired" % button_name)


func test_reset_stars_sets_stars_to_zero_and_saves() -> void:
	SaveManager.progress.record_completion("level_01", 3)
	SaveManager.progress.record_completion("level_02", 2)
	SaveManager.research.record_research("mass_driver")
	var menu: Node = add_child_autofree(MainMenuScene.instantiate())
	var total := menu.find_child("TotalStars", true, false) as Label
	assert_eq(total.text, "4 STARS TO SPEND", "5 earned, 1 spent on the mass driver")
	assert_not_null(menu.find_child("ResetStarsButton", true, false), "shown in debug builds")

	(menu.find_child("ResetStarsDialog", true, false) as ConfirmationDialog).confirmed.emit()
	assert_eq(SaveManager.progress.get_total_stars(), 0)
	assert_false(SaveManager.research.has_researched("mass_driver"), "research is cleared")
	assert_eq(total.text, "0 STARS TO SPEND")
	SaveManager.load_game()
	assert_eq(SaveManager.progress.get_total_stars(), 0, "the reset was saved")


func test_add_stars_grants_debug_stars_and_saves() -> void:
	var menu: Node = add_child_autofree(MainMenuScene.instantiate())
	(menu.find_child("AddStarsButton", true, false) as Button).pressed.emit()
	var total := menu.find_child("TotalStars", true, false) as Label
	assert_eq(total.text, "%d STARS TO SPEND" % MainMenu.DEBUG_STAR_GRANT)
	SaveManager.load_game()
	assert_eq(SaveManager.research.bonus_stars, MainMenu.DEBUG_STAR_GRANT, "saved")


func test_reset_stars_keeps_encountered_enemies() -> void:
	SaveManager.record_enemy_encounter("scout")
	SaveManager.reset_stars()
	SaveManager.load_game()
	assert_true(SaveManager.codex.has_encountered("scout"))


func test_enemies_menu_lists_only_encountered_enemies() -> void:
	SaveManager.record_enemy_encounter("scout")
	var menu: Node = add_child_autofree(EnemiesMenuScene.instantiate())
	var cards: Array[Node] = _cards(menu)
	assert_eq(cards.size(), 1)
	assert_eq(cards[0].name, &"ScoutCard")
	assert_null(menu.find_child("EmptyLabel", true, false))


func test_enemies_menu_with_no_encounters_shows_empty_message() -> void:
	var menu: Node = add_child_autofree(EnemiesMenuScene.instantiate())
	assert_eq(_cards(menu).size(), 0)
	assert_not_null(menu.find_child("EmptyLabel", true, false))


func test_towers_menu_lists_only_unlocked_towers() -> void:
	SaveManager.research.record_research("laser_turret")
	var menu: Node = add_child_autofree(TowersMenuScene.instantiate())
	var names: Array[StringName] = []
	for card: Node in _cards(menu):
		names.append(card.name)
	assert_eq(names, [&"LaserTurretCard", &"MachineGunCard"] as Array[StringName])
	assert_not_null(menu.find_child("ResearchButton", true, false))


func test_level_select_has_back_button() -> void:
	var menu: Node = add_child_autofree(LevelSelectScene.instantiate())
	assert_not_null(menu.find_child("BackButton", true, false))


func test_spawned_enemies_are_recorded_as_encountered() -> void:
	var first_level: Dictionary = LevelCatalog.load_levels()[0]
	var first_enemy: String = str(first_level["waves"][0]["spawns"][0]["enemy"])
	var level: Node = add_child_autofree(load(str(first_level["scene"])).instantiate())
	level.call("_spawn_enemy", first_enemy)
	assert_true(SaveManager.codex.has_encountered(first_enemy))
