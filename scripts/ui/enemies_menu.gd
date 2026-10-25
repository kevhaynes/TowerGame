extends Control
class_name EnemiesMenu

## Lists the enemy types the player has encountered, from SaveManager.codex.

const ENCOUNTERED_TEXT: String = "%d / %d ENCOUNTERED"
const EMPTY_TEXT: String = "No enemies encountered yet. Play a level to scan hostiles."
const TRAITS_TEXT: String = "TRAITS: %s"
const STATS_TEXT: String = "HEALTH %s   ARMOUR %s   SHIELD %s   SPEED %s"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page: Dictionary = MenuWidgets.build_page(self, "ENEMIES", _on_back_pressed)
	var grid := page["grid"] as GridContainer

	var definitions: Array[Dictionary] = DefinitionCatalog.load_directory(
		DefinitionCatalog.ENEMIES_DIRECTORY
	)
	var shown: int = 0
	for definition: Dictionary in definitions:
		if not SaveManager.codex.has_encountered(str(definition.get("id", ""))):
			continue
		grid.add_child(MenuWidgets.create_card(definition, _card_lines(definition)))
		shown += 1
	(page["subtitle"] as Label).text = ENCOUNTERED_TEXT % [shown, definitions.size()]

	if shown == 0:
		var empty := MenuWidgets.create_label(
			EMPTY_TEXT, MenuWidgets.SUBTITLE_FONT_SIZE, MenuWidgets.TEXT_COLOR
		)
		empty.name = "EmptyLabel"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		(page["layout"] as VBoxContainer).add_child(empty)
		(page["layout"] as VBoxContainer).move_child(empty, 1)


func _card_lines(definition: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var traits: String = MenuWidgets.format_names(definition.get("traits", []))
	if not traits.is_empty():
		lines.append({"text": TRAITS_TEXT % traits, "color": MenuWidgets.HIGHLIGHT_COLOR})
	var stats: Variant = definition.get("stats", {})
	if stats is Dictionary:
		lines.append(
			{
				"text":
				(
					STATS_TEXT
					% [
						MenuWidgets.format_stat(stats, "health"),
						MenuWidgets.format_stat(stats, "armour"),
						MenuWidgets.format_stat(stats, "shield"),
						MenuWidgets.format_stat(stats, "move_speed"),
					]
				),
				"color": MenuWidgets.TEXT_COLOR,
			}
		)
	return lines


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MenuWidgets.MAIN_MENU_SCENE)
