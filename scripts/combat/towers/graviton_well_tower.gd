extends BaseTower
class_name GravitonWellTower

## A singularity that pulls every enemy in range along the path toward the
## point of the path closest to the well, bunching them up for splash towers.
## Enemies before that point are drawn forward, enemies past it dragged back.

const FIELD_COLOR: Color = Color(0.6, 0.4, 1.0, 0.35)
const FIELD_RINGS: int = 3
const FIELD_SPIN_SPEED: float = 1.5
const FIELD_RING_WIDTH: float = 3.0

var _damage_per_second: float = 0.0
var _pull_speed: float = 0.0
var _spin: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage_per_second = stats.non_negative("damage_per_second")
	_pull_speed = stats.positive("pull_speed")


func _process(delta: float) -> void:
	_spin = fmod(_spin + delta * FIELD_SPIN_SPEED, 1.0)
	queue_redraw()
	pull(delta)


func pull(delta: float) -> void:
	for enemy: PathEnemy in enemies_within(global_position, attack_range):
		var direction: int = get_pull_direction(enemy)
		if direction != 0:
			enemy.push_along_path(direction * _pull_speed * delta)
		if _damage_per_second > 0.0:
			deal_damage(enemy, _damage_per_second * delta, false)


## +1 to pull the enemy forward along its path, -1 back, 0 when it is at the
## path point closest to the well.
func get_pull_direction(enemy: PathEnemy) -> int:
	var probe: float = CombatMath.GRAVITON_PROBE_DISTANCE
	return CombatMath.graviton_direction(
		global_position.distance_to(enemy.global_position),
		global_position.distance_to(enemy.get_path_point(enemy.path_distance + probe)),
		global_position.distance_to(enemy.get_path_point(enemy.path_distance - probe))
	)


func _draw() -> void:
	for ring: int in FIELD_RINGS:
		var phase: float = fmod(float(ring) / FIELD_RINGS + 1.0 - _spin, 1.0)
		draw_arc(
			Vector2.ZERO,
			attack_range * phase,
			0.0,
			TAU,
			48,
			Color(FIELD_COLOR, FIELD_COLOR.a * phase),
			FIELD_RING_WIDTH
		)
