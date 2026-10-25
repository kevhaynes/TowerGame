extends BaseTower
class_name SwarmMissilePodTower

## Launches a salvo of homing micro-missiles, each at a different target
## (furthest along the path first); with fewer targets than missiles, the
## extra missiles wrap round onto the same targets.

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _missiles_per_salvo: int = 0
var _projectile_speed: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_missiles_per_salvo = stats.whole_number("missiles_per_salvo", 1)
	_projectile_speed = stats.positive("projectile_speed")


func _process(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if not pick_salvo_targets().is_empty():
		fire_salvo()
		start_cooldown(_fire_rate)


func pick_salvo_targets() -> Array[PathEnemy]:
	var ordered: Array[PathEnemy] = TowerTargeting.find_ordered(
		get_enemies(), global_position, attack_range
	)
	var targets: Array[PathEnemy] = []
	if ordered.is_empty():
		return targets
	for index: int in _missiles_per_salvo:
		targets.append(ordered[index % ordered.size()])
	return targets


func fire_salvo() -> void:
	var targets: Array[PathEnemy] = pick_salvo_targets()
	if targets.is_empty():
		return
	aim_at(targets[0].global_position)
	for target: PathEnemy in targets:
		launch_projectile(target, target.global_position, _projectile_speed, _on_missile_impact)


func _on_missile_impact(target: PathEnemy, _point: Vector2) -> void:
	if target != null:
		deal_damage(target, _damage)
