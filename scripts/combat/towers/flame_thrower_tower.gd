extends BaseTower
class_name FlameThrowerTower

## Close-range flame cone aimed at the first enemy: continuous damage to
## everything inside the cone, plus a burning DOT that lingers after.

const BURN_SOURCE: String = "flame_thrower"
const FLAME_COLOR: Color = Color(1.0, 0.5, 0.15, 0.55)
const FLAME_CORE_COLOR: Color = Color(1.0, 0.85, 0.4, 0.6)
const FLAME_CORE_RATIO: float = 0.6
const FLICKER: float = 0.08
const CONE_SEGMENTS: int = 6

var _damage_per_second: float = 0.0
var _cone_half_angle: float = 0.0
var _burn_dps: float = 0.0
var _burn_duration: float = 0.0
var _is_firing: bool = false


func _read_stats(stats: StatReader) -> void:
	_damage_per_second = stats.positive("damage_per_second")
	_cone_half_angle = deg_to_rad(stats.positive("cone_angle")) * 0.5
	_burn_dps = stats.positive("burn_dps")
	_burn_duration = stats.positive("burn_duration")


func _process(delta: float) -> void:
	var target := find_first_target()
	var was_firing: bool = _is_firing
	_is_firing = target != null
	if _is_firing:
		aim_at(target.global_position)
		burn(delta)
	if _is_firing or was_firing:
		queue_redraw()


## Burns every enemy in the cone along the tower's current facing. Returns them.
func burn(delta: float) -> Array[PathEnemy]:
	var hit: Array[PathEnemy] = TowerTargeting.enemies_in_cone(
		get_enemies(), global_position, global_rotation, _cone_half_angle, attack_range
	)
	for enemy: PathEnemy in hit:
		deal_damage(enemy, _damage_per_second * delta, false)
		enemy.apply_status(StatusEffect.dot(_burn_dps, _burn_duration, BURN_SOURCE))
	return hit


func _draw() -> void:
	if not _is_firing:
		return
	var reach: float = attack_range * (1.0 + randf_range(-FLICKER, FLICKER))
	_draw_cone(reach, FLAME_COLOR)
	_draw_cone(reach * FLAME_CORE_RATIO, FLAME_CORE_COLOR)


func _draw_cone(reach: float, colour: Color) -> void:
	var points: PackedVector2Array = [Vector2.ZERO]
	for step: int in CONE_SEGMENTS + 1:
		var angle: float = lerpf(
			-_cone_half_angle, _cone_half_angle, float(step) / CONE_SEGMENTS
		)
		points.append(Vector2.RIGHT.rotated(angle) * reach)
	draw_colored_polygon(points, colour)
