extends BaseTower
class_name LaserTurretTower

## Continuous energy beam. Locks onto one target until it dies or leaves range;
## damage ramps up the longer the beam stays on the same target.

const BEAM_COLOR: Color = Color(1.0, 0.27, 0.32, 0.8)
const BEAM_CORE_COLOR: Color = Color(1.0, 0.9, 0.88, 1.0)
const BEAM_MIN_WIDTH: float = 4.5
const BEAM_MAX_WIDTH: float = 12.0
const BEAM_CORE_WIDTH_RATIO: float = 0.35

var _ramp: LaserRamp
var _base_dps: float = 0.0
var _ramp_rate: float = 0.0
var _max_multiplier: float = 0.0
var _target: PathEnemy
var _is_beam_drawn: bool = false


func _read_stats(stats: StatReader) -> void:
	_base_dps = stats.positive("base_dps")
	_ramp_rate = stats.positive("ramp_rate")
	_max_multiplier = stats.at_least("max_ramp_multiplier", 1.0)


func _on_configured() -> void:
	_ramp = LaserRamp.new(_base_dps, _ramp_rate, _max_multiplier)


func get_target() -> PathEnemy:
	return _target if is_instance_valid(_target) else null


func _process(delta: float) -> void:
	if _ramp == null:
		return

	if not _has_valid_target():
		_target = find_first_target()
		_ramp.reset()

	if _target == null:
		if _is_beam_drawn:
			_is_beam_drawn = false
			queue_redraw()
		return

	aim_at(_target.global_position)
	deal_damage(_target, _ramp.advance(delta), false)
	_is_beam_drawn = true
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_target):
		return
	var beam_end: Vector2 = to_local(_target.global_position)
	var width: float = lerpf(BEAM_MIN_WIDTH, BEAM_MAX_WIDTH, _ramp.get_progress())
	draw_line(Vector2.ZERO, beam_end, BEAM_COLOR, width)
	draw_line(Vector2.ZERO, beam_end, BEAM_CORE_COLOR, width * BEAM_CORE_WIDTH_RATIO)


func _has_valid_target() -> bool:
	if not is_instance_valid(_target):
		_target = null
		return false
	return TowerTargeting.is_valid_target(_target, global_position, attack_range)
