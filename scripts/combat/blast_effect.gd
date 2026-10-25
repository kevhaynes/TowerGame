extends Node2D
class_name BlastEffect

## A short expanding, fading ring that marks an explosion or pulse.

const LIFETIME: float = 0.35
const START_SCALE: float = 0.3
const RING_WIDTH: float = 6.0
const FILL_ALPHA: float = 0.25

var _radius: float = 0.0
var _colour: Color = Color.WHITE
var _age: float = 0.0


func setup(radius: float, colour: Color) -> void:
	_radius = radius
	_colour = colour
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		set_process(false)
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(_age / LIFETIME, 0.0, 1.0)
	var radius: float = _radius * lerpf(START_SCALE, 1.0, progress)
	var fade: float = 1.0 - progress
	var fill: Color = Color(_colour, _colour.a * FILL_ALPHA * fade)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(_colour, _colour.a * fade), RING_WIDTH)
