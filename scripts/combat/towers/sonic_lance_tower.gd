extends BaseTower
class_name SonicLanceTower

## Focused acoustic beam: damages the first enemy and knocks it back along the
## path by knockback_distance (half for bosses), buying time.

const BEAM_COLOR: Color = Color(0.75, 1.0, 0.9, 0.85)
const BEAM_WIDTH: float = 9.0
const BEAM_LIFETIME: float = 0.2

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _knockback_distance: float = 0.0
var _beam_end: Vector2
var _beam_time: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_knockback_distance = stats.positive("knockback_distance")


func _process(delta: float) -> void:
	if _beam_time > 0.0:
		_beam_time -= delta
		queue_redraw()
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		blast(target)
		start_cooldown(_fire_rate)


func blast(target: PathEnemy) -> void:
	_beam_end = target.global_position
	_beam_time = BEAM_LIFETIME
	deal_damage(target, _damage)
	target.push_along_path(-_knockback_distance)
	queue_redraw()


func _draw() -> void:
	if _beam_time > 0.0:
		var alpha: float = _beam_time / BEAM_LIFETIME
		draw_line(Vector2.ZERO, to_local(_beam_end), Color(BEAM_COLOR, alpha), BEAM_WIDTH)
