extends Control
class_name ResearchTreeView

## Draws the research tree: one horizontal band per category (as many lanes as
## its busiest tier needs), one column per tier, a button per tower and a
## connector from each requirement. Tapping a tower emits tower_selected.

signal tower_selected(tower_id: String)

const LABEL_WIDTH: float = 160.0
const NODE_SIZE: Vector2 = Vector2(204, 108)
const COLUMN_PITCH: float = 232.0
const LANE_PITCH: float = 122.0
const ICON_SIZE: Vector2 = Vector2(44, 44)
const NAME_FONT_SIZE: int = 18
const COST_FONT_SIZE: int = 18
const CATEGORY_FONT_SIZE: int = 24
const CONNECTOR_WIDTH: float = 4.0
const CONNECTOR_POINTS: int = 16
const LOCKED_CONNECTOR_COLOR: Color = Color(0.3, 0.37, 0.38, 0.8)
const LOCKED_BORDER_COLOR: Color = Color(0.3, 0.37, 0.38)
const BAND_COLOR: Color = Color(1, 1, 1, 0.03)
const SELECTED_COLOR: Color = Color(1, 1, 1, 0.9)
const SELECTED_WIDTH: float = 4.0
const SELECTED_MARGIN: float = 7.0
## How far an unlocked node's background moves from the card colour to its
## category colour.
const UNLOCKED_TINT: float = 0.3
const NEEDS_PREREQUISITES_MODULATE: Color = Color(1, 1, 1, 0.45)
const UNLOCKED_TEXT: String = "UNLOCKED"
const STARS_TEXT: String = "%d STAR"
const STARS_PLURAL_TEXT: String = "%d STARS"

var _tree: ResearchTree
var _definitions: Dictionary = {}
## Per tower id: { "button": Button, "cost": Label, "rect": Rect2 }.
var _nodes: Dictionary = {}
## Per category id: Rect2 of its band.
var _bands: Dictionary = {}
var _statuses: Dictionary = {}
var _selected: String = ""


## [param definitions] maps tower id to its data/towers definition.
func setup(tree: ResearchTree, definitions: Dictionary) -> void:
	_tree = tree
	_definitions = definitions
	_build()


## Restyles every node for the current research and stars to spend.
func refresh(research: ResearchProgress, available_stars: int) -> void:
	for tower_id: String in _nodes:
		_statuses[tower_id] = _tree.get_status(tower_id, research, available_stars)
		_style_node(tower_id)
	queue_redraw()


func select(tower_id: String) -> void:
	_selected = tower_id
	queue_redraw()


func get_status(tower_id: String) -> ResearchTree.Status:
	return _statuses.get(tower_id, ResearchTree.Status.NEEDS_PREREQUISITES)


func _build() -> void:
	var lane_top: float = 0.0
	for category: Dictionary in _tree.categories:
		var category_id: String = str(category["id"])
		var lanes_by_tier: Dictionary = {}
		for tower_id: String in _tree.get_tower_ids():
			if str(_tree.get_node_data(tower_id)["category"]) != category_id:
				continue
			var tier: int = _tree.get_tier(tower_id)
			var lane: int = int(lanes_by_tier.get(tier, 0))
			lanes_by_tier[tier] = lane + 1
			var node_position := Vector2(
				LABEL_WIDTH + tier * COLUMN_PITCH,
				lane_top + lane * LANE_PITCH + (LANE_PITCH - NODE_SIZE.y) / 2.0
			)
			_add_node(tower_id, Rect2(node_position, NODE_SIZE))
		var lane_count: int = 1
		for count: int in lanes_by_tier.values():
			lane_count = maxi(lane_count, count)
		var band := Rect2(0, lane_top, 0, lane_count * LANE_PITCH)
		_bands[category_id] = band
		_add_category_label(category, band)
		lane_top += band.size.y

	custom_minimum_size = Vector2(
		LABEL_WIDTH + (_tree.get_max_tier() + 1) * COLUMN_PITCH, lane_top
	)


func _add_category_label(category: Dictionary, band: Rect2) -> void:
	var label := MenuWidgets.create_label(
		str(category["display_name"]).to_upper(),
		CATEGORY_FONT_SIZE,
		Color.html(str(category["color"]))
	)
	label.name = "%sLabel" % str(category["id"]).to_pascal_case()
	label.position = band.position
	label.size = Vector2(LABEL_WIDTH, band.size.y)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)


func _add_node(tower_id: String, rect: Rect2) -> void:
	var definition: Dictionary = _definitions.get(tower_id, {})
	var button := Button.new()
	button.name = "%sNode" % tower_id.to_pascal_case()
	button.position = rect.position
	button.size = rect.size
	button.pressed.connect(_on_node_pressed.bind(tower_id))
	add_child(button)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon := TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if definition.has("sprite"):
		icon.texture = ResourceLoader.load(str(definition["sprite"])) as Texture2D
	content.add_child(icon)

	var name_label := MenuWidgets.create_label(
		str(definition.get("display_name", tower_id)), NAME_FONT_SIZE, MenuWidgets.TITLE_COLOR
	)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	var cost_label := MenuWidgets.create_label("", COST_FONT_SIZE, MenuWidgets.TEXT_COLOR)
	cost_label.name = "Cost"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(cost_label)

	_nodes[tower_id] = {"button": button, "cost": cost_label, "rect": rect}


func _style_node(tower_id: String) -> void:
	var node: Dictionary = _nodes[tower_id]
	var button := node["button"] as Button
	var cost_label := node["cost"] as Label
	var category_color: Color = _category_color(tower_id)
	var status: ResearchTree.Status = get_status(tower_id)

	var style := StyleBoxFlat.new()
	style.bg_color = MenuWidgets.CARD_COLOR
	style.set_corner_radius_all(12)
	style.set_border_width_all(3)
	style.border_color = category_color
	button.modulate = Color.WHITE
	cost_label.text = format_cost(_tree.get_cost(tower_id))
	cost_label.add_theme_color_override("font_color", MenuWidgets.TEXT_COLOR)
	match status:
		ResearchTree.Status.UNLOCKED:
			style.bg_color = MenuWidgets.CARD_COLOR.lerp(category_color, UNLOCKED_TINT)
			cost_label.text = UNLOCKED_TEXT
			cost_label.add_theme_color_override("font_color", category_color)
		ResearchTree.Status.AVAILABLE:
			style.border_color = MenuWidgets.HIGHLIGHT_COLOR
			style.set_border_width_all(5)
			cost_label.add_theme_color_override("font_color", MenuWidgets.HIGHLIGHT_COLOR)
		ResearchTree.Status.NEEDS_STARS:
			style.border_color = category_color.darkened(0.4)
		ResearchTree.Status.NEEDS_PREREQUISITES:
			style.border_color = LOCKED_BORDER_COLOR
			button.modulate = NEEDS_PREREQUISITES_MODULATE

	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, style)


static func format_cost(cost: int) -> String:
	return (STARS_TEXT if cost == 1 else STARS_PLURAL_TEXT) % cost


func _category_color(tower_id: String) -> Color:
	var category: Dictionary = _tree.get_category(str(_tree.get_node_data(tower_id)["category"]))
	return Color.html(str(category.get("color", "#ffffff")))


func _draw() -> void:
	var index: int = 0
	for category_id: String in _bands:
		if index % 2 == 0:
			var band: Rect2 = _bands[category_id]
			draw_rect(Rect2(band.position, Vector2(size.x, band.size.y)), BAND_COLOR)
		index += 1

	for tower_id: String in _nodes:
		var to_rect: Rect2 = _nodes[tower_id]["rect"]
		for required: String in _tree.get_requirements(tower_id):
			if not _nodes.has(required):
				continue
			var from_rect: Rect2 = _nodes[required]["rect"]
			var lit: bool = get_status(required) == ResearchTree.Status.UNLOCKED
			_draw_connector(
				Vector2(from_rect.end.x, from_rect.get_center().y),
				Vector2(to_rect.position.x, to_rect.get_center().y),
				_category_color(tower_id) if lit else LOCKED_CONNECTOR_COLOR
			)

	if _nodes.has(_selected):
		var selected_rect: Rect2 = (_nodes[_selected]["rect"] as Rect2).grow(SELECTED_MARGIN)
		draw_rect(selected_rect, SELECTED_COLOR, false, SELECTED_WIDTH)


## A horizontal S-curve, so links between bands stay readable.
func _draw_connector(from: Vector2, to: Vector2, color: Color) -> void:
	var handle: float = (to.x - from.x) / 2.0
	var points := PackedVector2Array()
	for step: int in CONNECTOR_POINTS + 1:
		var t: float = float(step) / CONNECTOR_POINTS
		points.append(
			from.bezier_interpolate(
				from + Vector2(handle, 0), to - Vector2(handle, 0), to, t
			)
		)
	draw_polyline(points, color, CONNECTOR_WIDTH, true)


func _on_node_pressed(tower_id: String) -> void:
	select(tower_id)
	tower_selected.emit(tower_id)
