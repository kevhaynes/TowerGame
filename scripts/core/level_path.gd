@tool
extends Path2D
class_name LevelPath

## The level's enemy route. Draw it in the editor with the Path2D tools (add,
## move and curve points); it renders as the road with ENTRY and EXIT markers
## at its ends, in the editor and in game. In the editor, build pads that break
## a LevelLayout rule are ringed in red.

const SHOULDER_COLOR: Color = Color(0.055, 0.09, 0.105, 1)
const SHOULDER_WIDTH: float = 123.0
const ROAD_COLOR: Color = Color(0.28, 0.36, 0.36, 1)
const ROAD_WIDTH: float = 102.0
const HIGHLIGHT_COLOR: Color = Color(0.55, 0.67, 0.62, 0.72)
const HIGHLIGHT_WIDTH: float = 4.5

## Arrow pointing along the direction of travel.
const MARKER_POLYGON: PackedVector2Array = [Vector2(15, 0), Vector2(-15, -18), Vector2(-15, 18)]
const MARKER_OFFSET: float = 36.0
const LABEL_OFFSET: Vector2 = Vector2(-33, -42)
const LABEL_BELOW_OFFSET: Vector2 = Vector2(-33, 66)
const LABEL_FLIP_MARGIN: float = 90.0
const LABEL_FONT_SIZE: int = 22
const ENTRY_COLOR: Color = Color(0.35, 0.9, 0.75, 1)
const ENTRY_LABEL_COLOR: Color = Color(0.55, 0.9, 0.79, 1)
const EXIT_COLOR: Color = Color(1, 0.55, 0.34, 1)
const EXIT_LABEL_COLOR: Color = Color(1, 0.61, 0.42, 1)

const WARNING_COLOR: Color = Color(1.0, 0.2, 0.2, 0.95)
const WARNING_RADIUS: float = 63.0
const WARNING_WIDTH: float = 6.0


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	# Editor only: keep the road and pad warnings in step with edits.
	queue_redraw()


func _draw() -> void:
	if curve == null or curve.point_count < 2:
		return
	var points: PackedVector2Array = curve.get_baked_points()
	if points.size() < 2:
		return
	draw_polyline(points, SHOULDER_COLOR, SHOULDER_WIDTH, true)
	draw_polyline(points, ROAD_COLOR, ROAD_WIDTH, true)
	draw_polyline(points, HIGHLIGHT_COLOR, HIGHLIGHT_WIDTH, true)

	var last: int = points.size() - 1
	var entry_direction: Vector2 = (points[1] - points[0]).normalized()
	var exit_direction: Vector2 = (points[last] - points[last - 1]).normalized()
	_draw_marker(
		points[0] - entry_direction * MARKER_OFFSET,
		entry_direction,
		"ENTRY",
		ENTRY_COLOR,
		ENTRY_LABEL_COLOR
	)
	_draw_marker(
		points[last] + exit_direction * MARKER_OFFSET,
		exit_direction,
		"EXIT",
		EXIT_COLOR,
		EXIT_LABEL_COLOR
	)

	if Engine.is_editor_hint():
		_draw_pad_warnings(points)


func _draw_marker(
	centre: Vector2, direction: Vector2, text: String, color: Color, label_color: Color
) -> void:
	var arrow := Transform2D(direction.angle(), centre) * MARKER_POLYGON
	draw_colored_polygon(arrow, color)
	var global_y: float = (global_transform * centre).y
	var offset: Vector2 = LABEL_BELOW_OFFSET if global_y < LABEL_FLIP_MARGIN else LABEL_OFFSET
	draw_string(
		ThemeDB.fallback_font,
		centre + offset,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		LABEL_FONT_SIZE,
		label_color
	)


func _draw_pad_warnings(points: PackedVector2Array) -> void:
	var pads_parent: Node = get_parent().get_node_or_null(LevelLayout.PADS_NODE)
	if pads_parent == null:
		return
	var pads: Array[Node2D] = []
	var pad_positions: PackedVector2Array = []
	for child: Node in pads_parent.get_children():
		if child is Node2D:
			pads.append(child as Node2D)
			pad_positions.append((child as Node2D).global_position)
	var global_points: PackedVector2Array = global_transform * points
	for index: int in pads.size():
		if not LevelLayout.pad_problems(index, pad_positions, global_points).is_empty():
			draw_arc(
				to_local(pad_positions[index]),
				WARNING_RADIUS,
				0.0,
				TAU,
				32,
				WARNING_COLOR,
				WARNING_WIDTH
			)
