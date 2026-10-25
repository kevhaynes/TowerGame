extends Node2D
class_name TowerProjectile

## A projectile that homes on a target, or flies to a fixed point when it has
## none. If a homing target dies mid-flight the projectile carries on to its
## last known position, so splash shells still land.

const ARRIVAL_DISTANCE: float = 12.0

var _target: PathEnemy
var _destination: Vector2
var _speed: float = 0.0
var _on_impact: Callable


func launch(
	texture: Texture2D,
	start: Vector2,
	target: PathEnemy,
	destination: Vector2,
	speed: float,
	on_impact: Callable
) -> void:
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		add_child(sprite)
	global_position = start
	_target = target
	_destination = target.global_position if target != null else destination
	_speed = speed
	_on_impact = on_impact


func _process(delta: float) -> void:
	if _is_target_alive():
		_destination = _target.global_position
	else:
		_target = null

	var to_destination: Vector2 = _destination - global_position
	var travel: float = _speed * delta
	if to_destination.length() <= maxf(travel, ARRIVAL_DISTANCE):
		global_position = _destination
		var hit_target: PathEnemy = _target if _is_target_alive() else null
		if _on_impact.is_valid():
			_on_impact.call(hit_target, _destination)
		queue_free()
		set_process(false)
		return

	var direction: Vector2 = to_destination.normalized()
	global_position += direction * travel
	rotation = direction.angle()


func _is_target_alive() -> bool:
	return is_instance_valid(_target) and _target.health > 0.0 and _target.is_active()
