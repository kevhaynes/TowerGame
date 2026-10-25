extends CanvasLayer
class_name BuildMenu

## Building takes two taps on the same tower: the first previews it
## (tower_previewed), the second builds it (tower_selected).
signal tower_previewed(definition_path: String)
signal tower_selected(definition_path: String)
## Emitted whenever the menu closes, including after a tower is chosen.
signal closed

const COST_TEXT: String = "%d CR"
const CONFIRM_COST_TEXT: String = "%d CR - TAP TO BUILD"
const PREVIEW_BORDER_COLOR: Color = Color(1, 0.83, 0.42)
const PREVIEW_BORDER_WIDTH: int = 4
const BUTTON_MIN_HEIGHT: float = 123.0
## Space kept above and below a tower button's contents when it grows to fit.
const BUTTON_VERTICAL_PADDING: float = 18.0
const COST_COLOR: Color = Color(0.69, 0.78, 0.77)
const UNAFFORDABLE_COST_COLOR: Color = Color(1.0, 0.39, 0.35)
const UNAFFORDABLE_MODULATE: Color = Color(1, 1, 1, 0.45)

var _tower_list: VBoxContainer
## One entry per tower button: { "button": Button, "cost": int, "cost_label": Label,
## "path": String }.
var _entries: Array[Dictionary] = []
## The tower shown on the pad awaiting a second tap, or "" when none.
var _previewing_path: String = ""


func _ready() -> void:
	_build_panel()


## Lists [param tower_definitions], disabling any costing more than [param credits].
func show_for_pad(tower_definitions: Array[Dictionary], credits: int) -> void:
	for child: Node in _tower_list.get_children():
		child.queue_free()
	_entries.clear()
	_previewing_path = ""

	if tower_definitions.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No towers available."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tower_list.add_child(empty_label)
	else:
		for definition: Dictionary in tower_definitions:
			var tower_name: String = str(definition.get("display_name", "Unnamed Tower"))
			var stats: Variant = definition.get("stats", {})

			var button := Button.new()
			button.custom_minimum_size = Vector2(0, BUTTON_MIN_HEIGHT)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var sprite_path: Variant = definition.get("sprite")
			if not sprite_path is String or not ResourceLoader.exists(sprite_path):
				push_error("Tower definition has no available sprite: %s" % str(sprite_path))
				continue
			var sprite: Resource = ResourceLoader.load(sprite_path)
			if not sprite is Texture2D:
				push_error("Tower sprite is not a texture: %s" % str(sprite_path))
				continue

			var row := HBoxContainer.new()
			row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			row.add_theme_constant_override("separation", 21)
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(row)
			# The row is not laid out by the button, so grow the button to fit
			# it (long names and two lines of trait tags).
			row.minimum_size_changed.connect(_fit_button_to_row.bind(button, row))

			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(87, 87)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = sprite as Texture2D
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)

			var details := VBoxContainer.new()
			details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			details.alignment = BoxContainer.ALIGNMENT_CENTER
			details.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(details)

			var name_label := Label.new()
			name_label.text = tower_name
			name_label.add_theme_font_size_override("font_size", 27)
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			details.add_child(name_label)

			_add_trait_tags(details, definition)

			var cost: int = 0
			if stats is Dictionary:
				cost = int((stats as Dictionary).get("cost", 0))
			var cost_label := Label.new()
			cost_label.text = COST_TEXT % cost
			cost_label.add_theme_font_size_override("font_size", 21)
			cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			details.add_child(cost_label)

			var definition_path: String = str(definition.get("_definition_path", ""))
			if definition_path.is_empty():
				push_error("Tower menu received a definition without its data path.")
				continue
			button.pressed.connect(_on_tower_pressed.bind(definition_path))
			_tower_list.add_child(button)
			_entries.append(
				{
					"button": button,
					"cost": cost,
					"cost_label": cost_label,
					"path": definition_path,
				}
			)

	set_credits(credits)
	visible = true


## Enables only the towers the player can afford with [param credits].
func set_credits(credits: int) -> void:
	for entry: Dictionary in _entries:
		var button := entry["button"] as Button
		if not is_instance_valid(button):
			continue
		var affordable: bool = int(entry["cost"]) <= credits
		button.disabled = not affordable
		button.modulate = Color.WHITE if affordable else UNAFFORDABLE_MODULATE
		(entry["cost_label"] as Label).add_theme_color_override(
			"font_color", COST_COLOR if affordable else UNAFFORDABLE_COST_COLOR
		)


## True when the listed tower at [param definition_path] is enabled.
func is_affordable(definition_path: String) -> bool:
	for entry: Dictionary in _entries:
		var button := entry["button"] as Button
		if is_instance_valid(button) and str(entry["path"]) == definition_path:
			return not button.disabled
	return false


func _add_trait_tags(details: VBoxContainer, definition: Dictionary) -> void:
	var tags: HFlowContainer = HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 12)
	tags.add_theme_constant_override("v_separation", 3)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var has_tags: bool = false
	has_tags = _add_trait_tag(
		tags, definition.get("strong_against_trait", []), "STRONG", Color(0.38, 0.92, 0.5)
	)
	has_tags = (
		_add_trait_tag(
			tags, definition.get("weak_against_trait", []), "WEAK", Color(1.0, 0.39, 0.35)
		)
		or has_tags
	)
	if has_tags:
		details.add_child(tags)
	else:
		tags.free()


func _add_trait_tag(
	container: HFlowContainer, traits_value: Variant, label_prefix: String, color: Color
) -> bool:
	if not traits_value is Array:
		push_error("%s tower traits must be a JSON array." % label_prefix.to_lower())
		return false
	if traits_value.is_empty():
		return false

	var trait_names: PackedStringArray = []
	for trait_value: Variant in traits_value:
		if not trait_value is String:
			push_error("%s tower traits must contain only strings." % label_prefix.to_lower())
			return false
		trait_names.append(str(trait_value).replace("_", " ").to_lower().capitalize())

	var tag := Label.new()
	tag.text = "%s: %s" % [label_prefix, ", ".join(trait_names)]
	tag.add_theme_font_size_override("font_size", 18)
	tag.add_theme_color_override("font_color", color)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(tag)
	return true


func _fit_button_to_row(button: Button, row: Control) -> void:
	var height: float = row.get_combined_minimum_size().y + BUTTON_VERTICAL_PADDING
	button.custom_minimum_size.y = maxf(BUTTON_MIN_HEIGHT, height)


## The listed tower's button, or null.
func get_button(definition_path: String) -> Button:
	for entry: Dictionary in _entries:
		if str(entry["path"]) == definition_path and is_instance_valid(entry["button"]):
			return entry["button"] as Button
	return null


func get_previewing_path() -> String:
	return _previewing_path


func close() -> void:
	visible = false
	_previewing_path = ""
	closed.emit()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -465.0
	panel.offset_top = 30.0
	panel.offset_right = -30.0
	panel.offset_bottom = -30.0
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

	var title := Label.new()
	title.text = "BUILD TOWER"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 33)
	title.add_theme_color_override("font_color", Color(0.65, 0.96, 0.82))
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(114, 78)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var subtitle := Label.new()
	subtitle.text = "Choose a tower for this build pad"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color(0.69, 0.78, 0.77))
	layout.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	_tower_list = VBoxContainer.new()
	_tower_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tower_list.add_theme_constant_override("separation", 15)
	scroll.add_child(_tower_list)

	visible = false


func _on_tower_pressed(definition_path: String) -> void:
	if definition_path == _previewing_path:
		tower_selected.emit(definition_path)
		close()
		return
	_previewing_path = definition_path
	_update_preview_highlight()
	tower_previewed.emit(definition_path)


## Outlines the previewed tower's button and asks for the second tap.
func _update_preview_highlight() -> void:
	for entry: Dictionary in _entries:
		var button := entry["button"] as Button
		if not is_instance_valid(button):
			continue
		var previewing: bool = str(entry["path"]) == _previewing_path
		var cost_text: String = CONFIRM_COST_TEXT if previewing else COST_TEXT
		(entry["cost_label"] as Label).text = cost_text % int(entry["cost"])
		if previewing:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.14, 0.15)
			style.border_color = PREVIEW_BORDER_COLOR
			style.set_border_width_all(PREVIEW_BORDER_WIDTH)
			style.set_corner_radius_all(9)
			for state: String in ["normal", "hover", "pressed", "focus"]:
				button.add_theme_stylebox_override(state, style)
		else:
			for state: String in ["normal", "hover", "pressed", "focus"]:
				button.remove_theme_stylebox_override(state)


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
