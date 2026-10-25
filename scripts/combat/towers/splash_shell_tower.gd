extends BaseTower
class_name SplashShellTower

## Fires a projectile at the first enemy that bursts in a splash on impact,
## dealing full damage at the centre and splash_edge_factor at the edge.
## Used directly by the Plasma Cannon and Flak Battery; the Boson Bomb extends it.

const BLAST_COLOR: Color = Color(1.0, 0.6, 0.25, 0.9)

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _projectile_speed: float = 0.0
var _splash_radius: float = 0.0
var _splash_edge_factor: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_projectile_speed = stats.positive("projectile_speed")
	_splash_radius = stats.positive("splash_radius")
	_splash_edge_factor = stats.fraction("splash_edge_factor")


func _process(delta: float) -> void:
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if not can_fire:
		return
	launch_projectile(target, target.global_position, _projectile_speed, detonate)
	start_cooldown(_fire_rate)


## Splash at [param point]. Returns the enemies caught in the blast.
func detonate(_target: PathEnemy, point: Vector2) -> Array[PathEnemy]:
	spawn_blast(point, _splash_radius, _get_blast_color())
	return deal_splash(point, _splash_radius, _damage, _splash_edge_factor)


func _get_blast_color() -> Color:
	return BLAST_COLOR
