extends BaseTower
class_name MachineGunTower

## Cheap single-target kinetic DPS: fires homing bullets at the first enemy.

var _damage_per_shot: float = 0.0
var _fire_rate: float = 0.0
var _projectile_speed: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage_per_shot = stats.positive("damage_per_shot")
	_fire_rate = stats.positive("fire_rate")
	_projectile_speed = stats.positive("projectile_speed")


func _process(delta: float) -> void:
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if not can_fire:
		return
	launch_projectile(target, target.global_position, _projectile_speed, _on_bullet_impact)
	start_cooldown(_fire_rate)


func _on_bullet_impact(target: PathEnemy, _point: Vector2) -> void:
	if target != null:
		deal_damage(target, _damage_per_shot)
