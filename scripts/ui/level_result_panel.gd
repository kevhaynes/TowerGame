extends CanvasLayer
class_name LevelResultPanel

signal next_level_requested
signal retry_requested
signal level_select_requested
signal research_requested

const PANEL_LAYER: int = 10
const COMPLETE_COLOR: Color = Color(0.65, 0.96, 0.82)
const FAILED_COLOR: Color = Color(1.0, 0.55, 0.42)
const BUTTON_SIZE: Vector2 = Vector2(240, 84)
const STAR_SIZE: float = 84.0
const STAR_SPACING: float = 24.0
const HEALTH_TEXT: String = "Base health %d / %d."
const RESEARCH_STARS_TEXT: String = "%d stars to spend on research."
const RESEARCH_HIGHLIGHT_COLOR: Color = Color(1, 0.83, 0.42)

var _title: Label
var _stars: StarRating
var _message: Label
var _next_button: Button
var _research_button: Button
var _research_stars: Label


func _ready() -> void:
	layer = PANEL_LAYER
	_build_panel()


func show_complete(has_next_level: bool, stars: int, health: float, max_health: float) -> void:
	_title.text = "LEVEL COMPLETE"
	_title.add_theme_color_override("font_color", COMPLETE_COLOR)
	_stars.stars = stars
	_stars.visible = true
	var health_text: String = HEALTH_TEXT % [ceili(health), ceili(max_health)]
	if has_next_level:
		_message.text = "%s The next level is now unlocked." % health_text
	else:
		_message.text = "%s You have cleared every level." % health_text
	_next_button.visible = has_next_level
	visible = true


func show_failed() -> void:
	_title.text = "LEVEL FAILED"
	_title.add_theme_color_override("font_color", FAILED_COLOR)
	_stars.visible = false
	_message.text = "Too many enemies reached the exit and the base has fallen."
	_next_button.visible = false
	visible = true


## Shows how many stars the player can spend, highlighting RESEARCH when any.
func set_research_stars(available_stars: int) -> void:
	_research_stars.text = RESEARCH_STARS_TEXT % available_stars
	_research_stars.visible = available_stars > 0
	if available_stars > 0:
		_research_button.add_theme_color_override("font_color", RESEARCH_HIGHLIGHT_COLOR)
	else:
		_research_button.remove_theme_color_override("font_color")


func get_shown_stars() -> int:
	return _stars.stars if _stars.visible else 0


func _build_panel() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
	panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 36)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 27)
	margin.add_child(layout)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 51)
	layout.add_child(_title)

	_stars = StarRating.new()
	_stars.star_size = STAR_SIZE
	_stars.spacing = STAR_SPACING
	layout.add_child(_stars)

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color(0.69, 0.78, 0.77))
	layout.add_child(_message)

	_research_stars = Label.new()
	_research_stars.name = "ResearchStars"
	_research_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_research_stars.add_theme_color_override("font_color", RESEARCH_HIGHLIGHT_COLOR)
	_research_stars.visible = false
	layout.add_child(_research_stars)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	layout.add_child(buttons)

	_next_button = _add_button(buttons, "NEXT LEVEL", next_level_requested)
	_add_button(buttons, "RETRY", retry_requested)
	_add_button(buttons, "LEVELS", level_select_requested)
	_research_button = _add_button(buttons, "RESEARCH", research_requested)
	_research_button.name = "ResearchButton"

	visible = false


func _add_button(container: HBoxContainer, text: String, pressed_signal: Signal) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(pressed_signal.emit)
	container.add_child(button)
	return button


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.09, 0.105, 0.97)
	style.border_color = Color(0.28, 0.58, 0.51, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	return style
