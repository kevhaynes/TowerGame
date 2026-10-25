extends Node2D
class_name RangeIndicator

## Shows a tower's attack range: a filled ring out to its range, any
## minimum-range blind spot, and the stretches of the enemy path it can hit
## drawn over the road.

const FILL_COLOR: Color = Color(0.65, 0.96, 0.82, 0.1)
const OUTLINE_COLOR: Color = Color(0.65, 0.96, 0.82, 0.75)
const BLIND_SPOT_COLOR: Color = Color(1.0, 0.39, 0.35, 0.12)
const BLIND_SPOT_OUTLINE_COLOR: Color = Color(1.0, 0.39, 0.35, 0.7)
const PATH_HIGHLIGHT_COLOR: Color = Color(1, 0.83, 0.42, 0.55)
const OUTLINE_WIDTH: float = 3.0
const PATH_HIGHLIGHT_WIDTH: float = 18.0
const CIRCLE_POINTS: int = 96

var attack_range: float = 0.0
var min_range: float = 0.0
## In-range stretches of the path, in this node's local coordinates.
var _segments: Array[PackedVector2Array] = []


## [param path_points] are the enemy path's baked points in global
## coordinates. Call after positioning the indicator.
func show_range(
	range_value: float, min_range_value: float, path_points: PackedVector2Array
) -> void:
	attack_range = range_value
	min_range = min_range_value
	_segments.clear()
	for segment: PackedVector2Array in path_segments_in_range(
		path_points, global_position, min_range, attack_range
	):
		var local_points := PackedVector2Array()
		for point: Vector2 in segment:
			local_points.append(to_local(point))
		_segments.append(local_points)
	visible = true
	queue_redraw()


## The runs of consecutive [param points] whose distance from [param centre]
## lies within [param min_distance]..[param max_distance]. Runs of a single
## point are dropped.
static func path_segments_in_range(
	points: PackedVector2Array, centre: Vector2, min_distance: float, max_distance: float
) -> Array[PackedVector2Array]:
	var segments: Array[PackedVector2Array] = []
	var current := PackedVector2Array()
	for point: Vector2 in points:
		var distance: float = centre.distance_to(point)
		if distance >= min_distance and distance <= max_distance:
			current.append(point)
			continue
		if current.size() > 1:
			segments.append(current)
		current = PackedVector2Array()
	if current.size() > 1:
		segments.append(current)
	return segments


func get_segment_count() -> int:
	return _segments.size()


func _draw() -> void:
	if attack_range <= 0.0:
		return
	draw_circle(Vector2.ZERO, attack_range, FILL_COLOR)
	draw_arc(
		Vector2.ZERO, attack_range, 0.0, TAU, CIRCLE_POINTS, OUTLINE_COLOR, OUTLINE_WIDTH, true
	)
	if min_range > 0.0:
		draw_circle(Vector2.ZERO, min_range, BLIND_SPOT_COLOR)
		draw_arc(
			Vector2.ZERO,
			min_range,
			0.0,
			TAU,
			CIRCLE_POINTS,
			BLIND_SPOT_OUTLINE_COLOR,
			OUTLINE_WIDTH,
			true
		)
	for segment: PackedVector2Array in _segments:
		draw_polyline(segment, PATH_HIGHLIGHT_COLOR, PATH_HIGHLIGHT_WIDTH, true)
