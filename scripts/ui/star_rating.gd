extends Control
class_name StarRating

## A centred row of LevelStars.MAX_STARS stars with the first `stars` filled.
## Drawn as polygons so it doesn't depend on the font having a star glyph.

const STAR_POINTS: int = 5
const INNER_RADIUS_RATIO: float = 0.45
const FILLED_COLOR: Color = Color(1, 0.83, 0.42)
const EMPTY_COLOR: Color = Color(0.22, 0.29, 0.3)

@export var stars: int = 0:
	set(value):
		stars = clampi(value, 0, LevelStars.MAX_STARS)
		queue_redraw()
@export var star_size: float = 48.0:
	set(value):
		star_size = maxf(value, 0.0)
		update_minimum_size()
		queue_redraw()
@export var spacing: float = 12.0:
	set(value):
		spacing = maxf(value, 0.0)
		update_minimum_size()
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	var count: int = LevelStars.MAX_STARS
	return Vector2(count * star_size + (count - 1) * spacing, star_size)


func _draw() -> void:
	var row_width: float = _get_minimum_size().x
	var left: float = (size.x - row_width) / 2.0
	for index: int in LevelStars.MAX_STARS:
		var center := Vector2(left + star_size * (index + 0.5) + spacing * index, size.y / 2.0)
		var color: Color = FILLED_COLOR if index < stars else EMPTY_COLOR
		draw_colored_polygon(_star_polygon(center, star_size / 2.0), color)


func _star_polygon(center: Vector2, outer_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var inner_radius: float = outer_radius * INNER_RADIUS_RATIO
	for index: int in STAR_POINTS * 2:
		var radius: float = outer_radius if index % 2 == 0 else inner_radius
		var angle: float = -PI / 2.0 + PI * index / STAR_POINTS
		points.append(center + Vector2.from_angle(angle) * radius)
	return points
