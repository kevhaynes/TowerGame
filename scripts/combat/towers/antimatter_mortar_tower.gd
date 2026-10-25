extends BaseTower
class_name AntimatterMortarTower

## Long-range artillery with a minimum-range blind spot. Leads its target:
## the shell is aimed where the enemy will be after shell_flight_time and
## lands there whether or not the enemy is, with a huge splash.

const BLAST_COLOR: Color = Color(0.95, 0.4, 1.0, 1.0)

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _min_range: float = 0.0
var _splash_radius: float = 0.0
var _splash_edge_factor: float = 0.0
var _shell_flight_time: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_min_range = stats.non_negative("min_range")
	_splash_radius = stats.positive("splash_radius")
	_splash_edge_factor = stats.fraction("splash_edge_factor")
	_shell_flight_time = stats.positive("shell_flight_time")


func _process(delta: float) -> void:
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target(_min_range)
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		fire_at(target)
		start_cooldown(_fire_rate)


func fire_at(target: PathEnemy) -> Vector2:
	var landing: Vector2 = target.predict_position(_shell_flight_time)
	var speed: float = global_position.distance_to(landing) / _shell_flight_time
	launch_projectile(null, landing, maxf(speed, 1.0), detonate)
	return landing


func detonate(_target: PathEnemy, point: Vector2) -> Array[PathEnemy]:
	spawn_blast(point, _splash_radius, BLAST_COLOR)
	return deal_splash(point, _splash_radius, _damage, _splash_edge_factor)
