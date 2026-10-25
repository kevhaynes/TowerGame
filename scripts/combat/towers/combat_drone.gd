extends Node2D
class_name CombatDrone

## One autonomous drone from a Drone Bay. It flies toward its assigned target
## (staying inside the bay's patrol zone), fires instant shots when in range,
## and circles the bay when it has nothing to engage.

const TRACER_COLOR: Color = Color(1.0, 0.9, 0.5, 0.9)
const TRACER_WIDTH: float = 3.0
const TRACER_LIFETIME: float = 0.08
## Drones close to this fraction of their weapon range before stopping.
const ENGAGE_DISTANCE_RATIO: float = 0.7
const IDLE_ORBIT_RATIO: float = 0.4
const IDLE_ORBIT_SPEED: float = 1.2

var damage: float = 0.0
var fire_rate: float = 0.0
var weapon_range: float = 0.0
var speed: float = 0.0
var orbit_phase: float = 0.0

var _bay: BaseTower
var _cooldown: float = 0.0
var _tracer_end: Vector2
var _tracer_time: float = 0.0


func setup(bay: BaseTower, texture: Texture2D, phase: float) -> void:
	_bay = bay
	orbit_phase = phase
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		add_child(sprite)


## Moves and fires for one frame against [param target] (may be null).
func step(delta: float, target: PathEnemy) -> void:
	var centre: Vector2 = _bay.global_position
	var zone: float = _bay.attack_range
	_cooldown = maxf(_cooldown - delta * _bay.get_fire_rate_multiplier(), 0.0)
	_tracer_time = maxf(_tracer_time - delta, 0.0)

	var goal: Vector2
	if target == null:
		orbit_phase = fmod(orbit_phase + delta * IDLE_ORBIT_SPEED, TAU)
		goal = centre + Vector2.RIGHT.rotated(orbit_phase) * zone * IDLE_ORBIT_RATIO
	else:
		var to_drone: Vector2 = global_position - target.global_position
		var standoff: float = weapon_range * ENGAGE_DISTANCE_RATIO
		goal = target.global_position + to_drone.limit_length(standoff)
		if to_drone.length() < standoff:
			goal = global_position
	global_position = CombatMath.step_within_zone(
		global_position, goal, speed * delta, centre, zone
	)

	if target != null:
		rotation = (target.global_position - global_position).angle()
		if (
			_cooldown <= 0.0
			and global_position.distance_to(target.global_position) <= weapon_range
		):
			_bay.deal_damage(target, damage)
			_cooldown = 1.0 / fire_rate
			_tracer_end = target.global_position
			_tracer_time = TRACER_LIFETIME
	queue_redraw()


func _draw() -> void:
	if _tracer_time > 0.0:
		draw_line(Vector2.ZERO, to_local(_tracer_end), TRACER_COLOR, TRACER_WIDTH)
