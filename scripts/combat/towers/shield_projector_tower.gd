extends BaseTower
class_name ShieldProjectorTower

## Projects an energy barrier across the road at the path point closest to
## the projector (if that point is in range). Enemies reaching the barrier are
## held there and drain its HP by base_damage x barrier_drain_per_base_damage
## per second each. A broken barrier recharges after recharge_time.

const BARRIER_COLOR: Color = Color(0.4, 0.85, 1.0, 0.9)
const BARRIER_DOWN_COLOR: Color = Color(0.4, 0.85, 1.0, 0.15)
const BARRIER_LENGTH: float = 126.0
const BARRIER_WIDTH: float = 10.5
const MIN_BARRIER_ALPHA: float = 0.3
## Runs after enemies have moved so it can catch any that crossed this frame.
const AFTER_ENEMIES_PRIORITY: int = 10
## How close an enemy must be to the barrier to count as pushing against it.
const HOLD_TOLERANCE: float = 0.75

var _barrier_hp: float = 0.0
var _drain_per_base_damage: float = 0.0
var _recharge_time: float = 0.0
var _hp: float = 0.0
var _recharge_timer: float = 0.0
var _barrier_distance: float = -1.0
var _is_located: bool = false


func _read_stats(stats: StatReader) -> void:
	_barrier_hp = stats.positive("barrier_hp")
	_drain_per_base_damage = stats.positive("barrier_drain_per_base_damage")
	_recharge_time = stats.positive("recharge_time")


func _on_configured() -> void:
	_hp = _barrier_hp
	process_priority = AFTER_ENEMIES_PRIORITY


func is_barrier_up() -> bool:
	return _barrier_distance >= 0.0 and _hp > 0.0


func get_barrier_hp() -> float:
	return _hp


## Path distance of the barrier, or -1 when the path is out of range.
func get_barrier_distance() -> float:
	_locate_barrier()
	return _barrier_distance


func _process(delta: float) -> void:
	_locate_barrier()
	if _barrier_distance < 0.0:
		return
	if _hp <= 0.0:
		_recharge_timer -= delta
		if _recharge_timer <= 0.0:
			_hp = _barrier_hp
		queue_redraw()
		return
	hold_enemies(delta)
	queue_redraw()


## Stops enemies at the barrier and lets them drain it.
func hold_enemies(delta: float) -> void:
	for enemy: PathEnemy in enemies_within(global_position, INF):
		var crossed: bool = (
			enemy.previous_path_distance <= _barrier_distance
			and enemy.path_distance > _barrier_distance
		)
		if crossed:
			enemy.set_path_distance(_barrier_distance)
		if absf(enemy.path_distance - _barrier_distance) <= HOLD_TOLERANCE:
			_hp -= enemy.base_damage * _drain_per_base_damage * delta
	if _hp <= 0.0:
		_hp = 0.0
		_recharge_timer = _recharge_time


func _locate_barrier() -> void:
	if _is_located or path_curve == null or not is_inside_tree():
		return
	_is_located = true
	var closest_distance: float = path_curve.get_closest_offset(global_position)
	if global_position.distance_to(path_curve.sample_baked(closest_distance)) <= attack_range:
		_barrier_distance = closest_distance
	else:
		push_warning("%s has no path within range; its barrier is inactive." % display_name)


func _draw() -> void:
	if _barrier_distance < 0.0:
		return
	var centre: Vector2 = path_curve.sample_baked(_barrier_distance)
	var ahead: Vector2 = path_curve.sample_baked(_barrier_distance + 1.0)
	var across: Vector2 = (ahead - centre).orthogonal().normalized() * BARRIER_LENGTH * 0.5
	var colour: Color = BARRIER_DOWN_COLOR
	if _hp > 0.0:
		colour = Color(BARRIER_COLOR, lerpf(MIN_BARRIER_ALPHA, 1.0, _hp / _barrier_hp))
	draw_line(to_local(centre - across), to_local(centre + across), colour, BARRIER_WIDTH)
