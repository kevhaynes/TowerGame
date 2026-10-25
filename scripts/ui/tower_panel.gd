extends CanvasLayer
class_name TowerPanel

## Opens when the player taps a built tower: names it and offers to sell it
## for its refund. Upgrades will join it here.
signal sell_requested
## Emitted whenever the panel closes, including after selling.
signal closed

const SELL_TEXT: String = "SELL  +%d CR"
const SELL_COLOR: Color = Color(1, 0.83, 0.42)
const BUTTON_MIN_HEIGHT: float = 96.0

var _title: Label
var _sell_button: Button
var _refund: int = 0


func _ready() -> void:
	_build_panel()


## Shows [param tower_name] with a sell button paying [param refund] credits.
func show_for_tower(tower_name: String, refund: int) -> void:
	_title.text = tower_name.to_upper()
	_refund = refund
	_sell_button.text = SELL_TEXT % refund
	visible = true


func get_refund() -> int:
	return _refund


func get_sell_button() -> Button:
	return _sell_button


func close() -> void:
	visible = false
	closed.emit()


func _on_sell_pressed() -> void:
	sell_requested.emit()
	close()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -465.0
	panel.offset_top = 30.0
	panel.offset_right = -30.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _create_panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 27)
	margin.add_theme_constant_override("margin_top", 27)
	margin.add_theme_constant_override("margin_right", 27)
	margin.add_theme_constant_override("margin_bottom", 27)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 21)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 33)
	_title.add_theme_color_override("font_color", Color(0.65, 0.96, 0.82))
	header.add_child(_title)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(114, 78)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	_sell_button = Button.new()
	_sell_button.custom_minimum_size = Vector2(0, BUTTON_MIN_HEIGHT)
	_sell_button.add_theme_font_size_override("font_size", 30)
	_sell_button.add_theme_color_override("font_color", SELL_COLOR)
	_sell_button.pressed.connect(_on_sell_pressed)
	layout.add_child(_sell_button)

	visible = false


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.09, 0.105, 0.97)
	style.border_color = Color(0.28, 0.58, 0.51, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 15
	style.content_margin_top = 15
	style.content_margin_right = 15
	style.content_margin_bottom = 15
	return style
