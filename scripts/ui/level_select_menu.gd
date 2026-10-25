extends Control
class_name LevelSelectMenu

const BUTTON_SIZE: Vector2 = Vector2(360, 210)
const GRID_COLUMNS: int = 4
const BACKGROUND_COLOR: Color = Color(0.075, 0.118, 0.137, 1)
const TITLE_COLOR: Color = Color(0.65, 0.96, 0.82)
const COMPLETE_COLOR: Color = Color(0.38, 0.92, 0.5)
const LOCKED_COLOR: Color = Color(0.5, 0.56, 0.56)
const TOTAL_STARS_COLOR: Color = Color(1, 0.83, 0.42)
const TOTAL_STARS_TEXT: String = "STARS %d / %d"
const BUTTON_STAR_SIZE: float = 42.0
## Gap between a level button's star row and its bottom edge.
const BUTTON_STAR_MARGIN: float = 21.0

var _levels: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_levels = LevelCatalog.load_levels()
	_build_menu()


func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 48)
	center.add_child(layout)

	var title := Label.new()
	title.text = "SELECT LEVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	layout.add_child(title)

	var total_stars := Label.new()
	total_stars.name = "TotalStars"
	total_stars.text = (
		TOTAL_STARS_TEXT
		% [SaveManager.progress.get_total_stars(), _levels.size() * LevelStars.MAX_STARS]
	)
	total_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_stars.add_theme_font_size_override("font_size", 36)
	total_stars.add_theme_color_override("font_color", TOTAL_STARS_COLOR)
	layout.add_child(total_stars)
	_add_back_button()

	if _levels.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No levels available."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(empty_label)
		return

	var grid := GridContainer.new()
	grid.columns = mini(GRID_COLUMNS, _levels.size())
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	layout.add_child(grid)

	var ordered_ids: Array[String] = LevelCatalog.get_ordered_ids(_levels)
	var progress: LevelProgress = SaveManager.progress
	for level: Dictionary in _levels:
		var level_id: String = str(level["id"])
		var unlocked: bool = progress.is_unlocked(ordered_ids, level_id)
		grid.add_child(
			_create_level_button(
				str(level["display_name"]), level_id, unlocked, progress.get_stars(level_id)
			)
		)


## [param stars] is the level's best star rating, 0 when not yet completed.
func _create_level_button(
	display_name: String, level_id: String, unlocked: bool, stars: int
) -> Button:
	var button := Button.new()
	button.name = "%sButton" % level_id.to_pascal_case()
	button.custom_minimum_size = BUTTON_SIZE
	button.disabled = not unlocked
	button.add_theme_font_size_override("font_size", 36)

	var status: String = ""
	if not unlocked:
		status = "LOCKED"
		button.add_theme_color_override("font_disabled_color", LOCKED_COLOR)
	elif stars > 0:
		button.add_theme_color_override("font_color", COMPLETE_COLOR)
		button.add_child(_create_button_stars(stars))
	button.text = display_name if status.is_empty() else "%s\n%s" % [display_name, status]

	if unlocked:
		button.pressed.connect(_on_level_pressed.bind(level_id))
	return button


func _create_button_stars(stars: int) -> StarRating:
	var rating := StarRating.new()
	rating.name = "Stars"
	rating.stars = stars
	rating.star_size = BUTTON_STAR_SIZE
	rating.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	rating.offset_top = -(BUTTON_STAR_SIZE + BUTTON_STAR_MARGIN)
	rating.offset_bottom = -BUTTON_STAR_MARGIN
	return rating


## Top-left, outside the centred layout, like the other menus.
func _add_back_button() -> void:
	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "BACK"
	back_button.custom_minimum_size = MenuWidgets.BACK_BUTTON_SIZE
	back_button.position = Vector2(MenuWidgets.PAGE_MARGIN, MenuWidgets.PAGE_MARGIN)
	back_button.add_theme_font_size_override("font_size", MenuWidgets.SUBTITLE_FONT_SIZE)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MenuWidgets.MAIN_MENU_SCENE)


func _on_level_pressed(level_id: String) -> void:
	var level: Dictionary = LevelCatalog.find_level(_levels, level_id)
	GameState.current_level_id = level_id
	get_tree().change_scene_to_file(str(level["scene"]))
