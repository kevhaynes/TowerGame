extends BaseTower
class_name DroneBayTower

## Deploys drone_count autonomous drones that patrol the bay's range (its
## patrol zone) and engage enemies inside it independently: drone i takes the
## i-th enemy furthest along the path, wrapping when there are fewer enemies.

var _drone_count: int = 0
var _drone_damage: float = 0.0
var _drone_fire_rate: float = 0.0
var _drone_range: float = 0.0
var _drone_speed: float = 0.0
var _drones: Array[CombatDrone] = []


func _read_stats(stats: StatReader) -> void:
	_drone_count = stats.whole_number("drone_count", 1)
	_drone_damage = stats.positive("drone_damage")
	_drone_fire_rate = stats.positive("drone_fire_rate")
	_drone_range = stats.positive("drone_range")
	_drone_speed = stats.positive("drone_speed")


func get_drones() -> Array[CombatDrone]:
	return _drones


func _process(delta: float) -> void:
	if _drones.is_empty():
		_deploy_drones()
	var targets: Array[PathEnemy] = TowerTargeting.find_ordered(
		get_enemies(), global_position, attack_range
	)
	for index: int in _drones.size():
		var target: PathEnemy = null
		if not targets.is_empty():
			target = targets[index % targets.size()]
		_drones[index].step(delta, target)


func _deploy_drones() -> void:
	var container: Node = self
	if is_instance_valid(_projectile_container):
		container = _projectile_container
	for index: int in _drone_count:
		var drone := CombatDrone.new()
		drone.damage = _drone_damage
		drone.fire_rate = _drone_fire_rate
		drone.weapon_range = _drone_range
		drone.speed = _drone_speed
		drone.setup(self, _projectile_texture, TAU * index / _drone_count)
		container.add_child(drone)
		drone.global_position = global_position
		_drones.append(drone)
