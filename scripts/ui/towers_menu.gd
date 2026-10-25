extends Control
class_name TowersMenu

## Lists the unlocked towers (researched or starting ones), with a RESEARCH
## button that opens the research tree to unlock more.

const UNLOCKED_TEXT: String = "%d / %d UNLOCKED"
const RESEARCH_HINT_TEXT: String = "%d STARS TO SPEND  -  research unlocks stronger towers"
const RESEARCH_BUTTON_SIZE: Vector2 = Vector2(270, 90)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page: Dictionary = MenuWidgets.build_page(self, "TOWERS", _on_back_pressed)
	var grid := page["grid"] as GridContainer
	var tree := ResearchTree.load_tree()
	var available_stars: int = SaveManager.get_available_stars(tree)

	var research_button := Button.new()
	research_button.name = "ResearchButton"
	research_button.text = "RESEARCH"
	research_button.custom_minimum_size = RESEARCH_BUTTON_SIZE
	research_button.add_theme_font_size_override("font_size", MenuWidgets.SUBTITLE_FONT_SIZE)
	if available_stars > 0:
		research_button.add_theme_color_override("font_color", MenuWidgets.HIGHLIGHT_COLOR)
	research_button.pressed.connect(_on_research_pressed)
	(page["header"] as HBoxContainer).add_child(research_button)

	var hint := MenuWidgets.create_label(
		RESEARCH_HINT_TEXT % available_stars,
		MenuWidgets.CARD_TEXT_FONT_SIZE,
		MenuWidgets.TEXT_COLOR
	)
	hint.name = "ResearchLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var layout := page["layout"] as VBoxContainer
	layout.add_child(hint)
	layout.move_child(hint, 1)

	var definitions: Array[Dictionary] = DefinitionCatalog.load_directory(
		DefinitionCatalog.TOWERS_DIRECTORY
	)
	var unlocked: int = 0
	for definition: Dictionary in definitions:
		if not tree.is_unlocked(str(definition.get("id", "")), SaveManager.research):
			continue
		grid.add_child(
			MenuWidgets.create_card(definition, MenuWidgets.tower_card_lines(definition))
		)
		unlocked += 1
	(page["subtitle"] as Label).text = UNLOCKED_TEXT % [unlocked, definitions.size()]


func _on_research_pressed() -> void:
	GameState.research_return_scene = MenuWidgets.TOWERS_SCENE
	get_tree().change_scene_to_file(MenuWidgets.RESEARCH_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MenuWidgets.MAIN_MENU_SCENE)
