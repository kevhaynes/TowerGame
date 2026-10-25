extends BaseTower
class_name PhaseDisruptorTower

## Pulses the first enemy out of phase: it takes damage and becomes PHASED,
## taking bonus damage from every source but ignoring slows while it lasts.

const PULSE_COLOR: Color = Color(0.8, 0.5, 1.0, 0.9)
const PULSE_WIDTH: float = 6.0
const PULSE_LIFETIME: float = 0.18

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _phase_duration: float = 0.0
var _phased_damage_bonus: float = 0.0
var _pulse_end: Vector2
var _pulse_time: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_phase_duration = stats.positive("phase_duration")
	_phased_damage_bonus = stats.positive("phased_damage_bonus")


func _process(delta: float) -> void:
	if _pulse_time > 0.0:
		_pulse_time -= delta
		queue_redraw()
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		disrupt(target)
		start_cooldown(_fire_rate)


func disrupt(target: PathEnemy) -> void:
	_pulse_end = target.global_position
	_pulse_time = PULSE_LIFETIME
	deal_damage(target, _damage)
	target.apply_status(StatusEffect.phased(_phased_damage_bonus, _phase_duration))
	queue_redraw()


func _draw() -> void:
	if _pulse_time > 0.0:
		var alpha: float = _pulse_time / PULSE_LIFETIME
		draw_line(Vector2.ZERO, to_local(_pulse_end), Color(PULSE_COLOR, alpha), PULSE_WIDTH)
