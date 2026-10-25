extends BaseTower
class_name RailgunEmplacementTower

## Slow-firing hypervelocity slug that pierces every enemy on a straight line
## from the emplacement through its target, out to full range.

const TRACER_COLOR: Color = Color(0.6, 0.95, 1.0, 1.0)
const TRACER_WIDTH: float = 7.5
const TRACER_LIFETIME: float = 0.25

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _line_half_width: float = 0.0
var _tracer_end: Vector2
var _tracer_time: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_line_half_width = stats.positive("line_half_width")


func _process(delta: float) -> void:
	if _tracer_time > 0.0:
		_tracer_time -= delta
		queue_redraw()
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		fire_at(target.global_position)
		start_cooldown(_fire_rate)


## Fires through [param point]. Returns every enemy hit.
func fire_at(point: Vector2) -> Array[PathEnemy]:
	var direction: Vector2 = (point - global_position).normalized()
	var hit: Array[PathEnemy] = TowerTargeting.enemies_on_line(
		get_enemies(), global_position, direction, attack_range, _line_half_width
	)
	for enemy: PathEnemy in hit:
		deal_damage(enemy, _damage)
	_tracer_end = global_position + direction * attack_range
	_tracer_time = TRACER_LIFETIME
	queue_redraw()
	return hit


func _draw() -> void:
	if _tracer_time <= 0.0:
		return
	var alpha: float = _tracer_time / TRACER_LIFETIME
	draw_line(
		Vector2.ZERO, to_local(_tracer_end), Color(TRACER_COLOR, alpha), TRACER_WIDTH * alpha
	)
