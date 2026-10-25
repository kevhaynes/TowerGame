extends Node2D
class_name EnemyHealthBar

const BAR_WIDTH: float = 72.0
const BAR_HEIGHT: float = 10.5
const BORDER_WIDTH: float = 1.5
const GREEN: Color = Color(0.18, 0.88, 0.35)
const YELLOW: Color = Color(1.0, 0.83, 0.18)
const RED: Color = Color(0.95, 0.17, 0.16)
const BACKGROUND: Color = Color(0.035, 0.055, 0.06, 0.9)
const BORDER: Color = Color(0.72, 0.82, 0.76, 0.9)
const SHIELD_COLOR: Color = Color(0.35, 0.72, 1.0)
const SHIELD_HEIGHT: float = 6.0
const SHIELD_GAP: float = 3.0

var _health_ratio: float = 1.0
var _shield_ratio: float = 0.0


func set_health_ratio(ratio: float) -> void:
	_health_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


## Shield remaining, 0 to 1. The shield bar shows above the health bar while
## any shield is left.
func set_shield_ratio(ratio: float) -> void:
	_shield_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var bar_rect := Rect2(-BAR_WIDTH * 0.5, 0.0, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(bar_rect.grow(BORDER_WIDTH), BORDER)
	draw_rect(bar_rect, BACKGROUND)

	if _health_ratio > 0.0:
		var fill_rect := Rect2(
			bar_rect.position,
			Vector2(BAR_WIDTH * _health_ratio, BAR_HEIGHT)
		)
		draw_rect(fill_rect, _get_health_color())

	if _shield_ratio > 0.0:
		var shield_rect := Rect2(
			-BAR_WIDTH * 0.5, -SHIELD_HEIGHT - SHIELD_GAP, BAR_WIDTH, SHIELD_HEIGHT
		)
		draw_rect(shield_rect.grow(BORDER_WIDTH), BORDER)
		draw_rect(shield_rect, BACKGROUND)
		draw_rect(
			Rect2(shield_rect.position, Vector2(BAR_WIDTH * _shield_ratio, SHIELD_HEIGHT)),
			SHIELD_COLOR
		)


func _get_health_color() -> Color:
	if _health_ratio >= 0.5:
		return YELLOW.lerp(GREEN, (_health_ratio - 0.5) / 0.5)
	if _health_ratio >= 0.1:
		return RED.lerp(YELLOW, (_health_ratio - 0.1) / 0.4)
	return RED
