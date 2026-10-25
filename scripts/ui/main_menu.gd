extends Control
class_name MainMenu

## Startup menu: PLAY (level select), ENEMIES, TOWERS, and in debug builds
## RESET STARS and ADD STARS buttons for testing.

const TITLE_TEXT: String = "TOWERS"
const TOTAL_STARS_TEXT: String = "%d STARS TO SPEND"
const BUTTON_SIZE: Vector2 = Vector2(540, 120)
const BUTTON_FONT_SIZE: int = 42
const TITLE_FONT_SIZE: int = 96
const DEBUG_BUTTON_SIZE: Vector2 = Vector2(270, 84)
const DEBUG_FONT_SIZE: int = 27
## Stars the debug ADD STARS button grants, for testing research.
const DEBUG_STAR_GRANT: int = 10
const RESET_CONFIRM_TEXT: String = (
	"Reset all stars to 0?\n"
	+ "This also clears all research and locks every level except the first."
)

var _total_stars: Label
var _reset_dialog: ConfirmationDialog
var _research_tree: ResearchTree


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_research_tree = ResearchTree.load_tree()
	_build_menu()


func _build_menu() -> void:
	MenuWidgets.add_background(self)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", MenuWidgets.CARD_SEPARATION)
	center.add_child(layout)

	var title := MenuWidgets.create_label(TITLE_TEXT, TITLE_FONT_SIZE, MenuWidgets.TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	_total_stars = MenuWidgets.create_label(
		"", MenuWidgets.SUBTITLE_FONT_SIZE, MenuWidgets.HIGHLIGHT_COLOR
	)
	_total_stars.name = "TotalStars"
	_total_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_total_stars)
	_update_total_stars()

	layout.add_child(_create_button("PlayButton", "PLAY", MenuWidgets.LEVEL_SELECT_SCENE))
	layout.add_child(_create_button("EnemiesButton", "ENEMIES", MenuWidgets.ENEMIES_SCENE))
	layout.add_child(_create_button("TowersButton", "TOWERS", MenuWidgets.TOWERS_SCENE))

	if OS.is_debug_build():
		_add_debug_buttons()


func _create_button(button_name: String, text: String, scene_path: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.pressed.connect(_change_scene.bind(scene_path))
	return button


## Bottom-left, away from the main buttons. RESET STARS asks first.
func _add_debug_buttons() -> void:
	var row := HBoxContainer.new()
	row.name = "DebugButtons"
	row.add_theme_constant_override("separation", MenuWidgets.CARD_SEPARATION)
	row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	row.offset_left = MenuWidgets.PAGE_MARGIN
	row.offset_top = -(DEBUG_BUTTON_SIZE.y + MenuWidgets.PAGE_MARGIN)
	row.offset_bottom = -MenuWidgets.PAGE_MARGIN
	add_child(row)

	var reset_button := _create_debug_button("ResetStarsButton", "RESET STARS")
	row.add_child(reset_button)
	var add_button := _create_debug_button("AddStarsButton", "ADD %d STARS" % DEBUG_STAR_GRANT)
	add_button.pressed.connect(_on_add_stars_pressed)
	row.add_child(add_button)

	_reset_dialog = ConfirmationDialog.new()
	_reset_dialog.name = "ResetStarsDialog"
	_reset_dialog.title = "RESET STARS"
	_reset_dialog.dialog_text = RESET_CONFIRM_TEXT
	_reset_dialog.ok_button_text = "RESET"
	_reset_dialog.confirmed.connect(_on_reset_stars_confirmed)
	add_child(_reset_dialog)
	reset_button.pressed.connect(_reset_dialog.popup_centered)


func _create_debug_button(button_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = DEBUG_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", DEBUG_FONT_SIZE)
	button.add_theme_color_override("font_color", MenuWidgets.WEAK_COLOR)
	return button


func _on_reset_stars_confirmed() -> void:
	SaveManager.reset_stars()
	_update_total_stars()


func _on_add_stars_pressed() -> void:
	SaveManager.add_debug_stars(DEBUG_STAR_GRANT)
	_update_total_stars()


func _update_total_stars() -> void:
	_total_stars.text = TOTAL_STARS_TEXT % SaveManager.get_available_stars(_research_tree)


func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
