@tool
extends Path2D
class_name CurvePathRenderer

@export var line_color: Color = Color.WHITE:
	set(value):
		line_color = value
		queue_redraw()
@export_range(0.1, 100.0, 0.1) var line_width: float = 1.0
@export var antialiased: bool = true


func _draw() -> void:
	if curve == null:
		return

	var baked_points: PackedVector2Array = curve.get_baked_points()
	if baked_points.size() < 2:
		return

	draw_polyline(baked_points, line_color, line_width, antialiased)
