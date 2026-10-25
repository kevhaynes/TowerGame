extends BaseTower
class_name TeslaCoilTower

## Chain lightning: zaps the first enemy, then jumps to the nearest unhit
## enemy within chain_range, losing chain_falloff of its damage per hop.

const ARC_COLOR: Color = Color(0.55, 0.85, 1.0, 0.95)
const ARC_WIDTH: float = 4.5
const ARC_SEGMENTS: int = 6
const ARC_JITTER: float = 13.5
const ARC_LIFETIME: float = 0.15

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _chain_count: int = 0
var _chain_range: float = 0.0
var _chain_falloff: float = 0.0
var _arc_points: PackedVector2Array = []
var _arc_time: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_chain_count = stats.whole_number("chain_count", 1)
	_chain_range = stats.positive("chain_range")
	_chain_falloff = stats.fraction("chain_falloff")


func _process(delta: float) -> void:
	_fade_arc(delta)
	if not tick_cooldown(delta):
		return
	var target := find_first_target()
	if target == null:
		return
	zap(target)
	start_cooldown(_fire_rate)


## Damages the chain starting at [param first]. Returns the enemies hit, in order.
func zap(first: PathEnemy) -> Array[PathEnemy]:
	var chain: Array[PathEnemy] = TowerTargeting.build_chain(
		first, get_enemies(), _chain_count, _chain_range
	)
	_arc_points = [global_position]
	for index: int in chain.size():
		_arc_points.append(chain[index].global_position)
		deal_damage(chain[index], CombatMath.chain_damage(_damage, _chain_falloff, index))
	_arc_time = ARC_LIFETIME
	queue_redraw()
	return chain


func _fade_arc(delta: float) -> void:
	if _arc_time <= 0.0:
		return
	_arc_time -= delta
	if _arc_time <= 0.0:
		_arc_points.clear()
	queue_redraw()


func _draw() -> void:
	for index: int in range(_arc_points.size() - 1):
		var start: Vector2 = to_local(_arc_points[index])
		var end: Vector2 = to_local(_arc_points[index + 1])
		var previous: Vector2 = start
		for step: int in range(1, ARC_SEGMENTS + 1):
			var point: Vector2 = start.lerp(end, float(step) / ARC_SEGMENTS)
			if step < ARC_SEGMENTS:
				point += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * ARC_JITTER
			draw_line(previous, point, ARC_COLOR, ARC_WIDTH)
			previous = point
