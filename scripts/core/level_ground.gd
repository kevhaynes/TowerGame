@tool
extends Node2D
class_name LevelGround

## Draws the level's ground and grid across the level_size set on the level's
## root, so a level larger than the screen is covered edge to edge. In the
## editor it also outlines the level, in red when level_size breaks a
## LevelLayout rule.

const GROUND_COLOR: Color = Color(0.075, 0.118, 0.137, 1)
const GRID_COLOR: Color = Color(0.14, 0.21, 0.22, 0.42)
const GRID_WIDTH: float = 1.0
const GRID_SPACING: Vector2 = Vector2(480, 360)
const OUTLINE_COLOR: Color = Color(0.37, 0.7, 0.63, 0.8)
const OUTLINE_WIDTH: float = 6.0
const WARNING_COLOR: Color = Color(1.0, 0.2, 0.2, 0.95)

var _drawn_size: Vector2


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	# Editor only: follow edits to the root's level_size.
	if LevelLayout.level_size_of(get_parent()) != _drawn_size:
		queue_redraw()


func _draw() -> void:
	var size: Vector2 = LevelLayout.level_size_of(get_parent())
	_drawn_size = size
	draw_rect(Rect2(Vector2.ZERO, size), GROUND_COLOR)
	var x: float = GRID_SPACING.x
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_COLOR, GRID_WIDTH, true)
		x += GRID_SPACING.x
	var y: float = GRID_SPACING.y
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR, GRID_WIDTH, true)
		y += GRID_SPACING.y
	if Engine.is_editor_hint():
		var is_valid: bool = LevelLayout.level_size_problems(size).is_empty()
		var outline: Color = OUTLINE_COLOR if is_valid else WARNING_COLOR
		draw_rect(Rect2(Vector2.ZERO, size), outline, false, OUTLINE_WIDTH)
