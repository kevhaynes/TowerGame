extends BaseTower
class_name NaniteHiveTower

## Releases nanite clouds on the first enemy: a DOT plus stacking
## ARMOUR_SHRED. Every spread_interval, each infected enemy that still has
## spread generations infects every uninfected enemy within spread_radius
## (with one generation fewer) and then stops spreading.

const NANITE_SOURCE: String = "nanite_hive"
const CLOUD_COLOR: Color = Color(0.55, 1.0, 0.55, 0.8)
const CLOUD_RADIUS: float = 36.0

var _fire_rate: float = 0.0
var _projectile_speed: float = 0.0
var _dot_dps: float = 0.0
var _dot_duration: float = 0.0
var _shred_per_application: float = 0.0
var _shred_max: float = 0.0
var _shred_duration: float = 0.0
var _spread_radius: float = 0.0
var _spread_generations: int = 0
var _spread_interval: float = 0.0
var _spread_timer: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_fire_rate = stats.positive("fire_rate")
	_projectile_speed = stats.positive("projectile_speed")
	_dot_dps = stats.positive("dot_dps")
	_dot_duration = stats.positive("dot_duration")
	_shred_per_application = stats.positive("shred_per_application")
	_shred_max = stats.positive("shred_max")
	_shred_duration = stats.positive("shred_duration")
	_spread_radius = stats.positive("spread_radius")
	_spread_generations = stats.whole_number("spread_generations", 0)
	_spread_interval = stats.positive("spread_interval")


func _process(delta: float) -> void:
	_spread_timer += delta
	if _spread_timer >= _spread_interval:
		_spread_timer = 0.0
		spread_infections()

	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		launch_projectile(target, target.global_position, _projectile_speed, _on_cloud_impact)
		start_cooldown(_fire_rate)


func infect(enemy: PathEnemy, generations: int) -> void:
	var infection := StatusEffect.dot(_dot_dps, _dot_duration, NANITE_SOURCE)
	infection.spread_generations = generations
	enemy.apply_status(infection)
	enemy.apply_status(
		StatusEffect.armour_shred(_shred_per_application, _shred_max, _shred_duration)
	)


## Spreads each carrier's infection to uninfected neighbours. Returns how many
## enemies were newly infected.
func spread_infections() -> int:
	var enemies: Array[PathEnemy] = enemies_within(global_position, INF)
	var carriers: Array[StatusEffect] = []
	var carrier_enemies: Array[PathEnemy] = []
	for enemy: PathEnemy in enemies:
		var infection := enemy.statuses.get_effect(StatusEffect.Type.DOT, NANITE_SOURCE)
		if infection != null and infection.spread_generations > 0:
			carriers.append(infection)
			carrier_enemies.append(enemy)

	var newly_infected: int = 0
	for index: int in carriers.size():
		var generations: int = carriers[index].spread_generations - 1
		carriers[index].spread_generations = 0
		var origin: Vector2 = carrier_enemies[index].global_position
		for neighbour: PathEnemy in enemies_within(origin, _spread_radius):
			if neighbour.statuses.get_effect(StatusEffect.Type.DOT, NANITE_SOURCE) == null:
				infect(neighbour, generations)
				newly_infected += 1
	return newly_infected


func _on_cloud_impact(target: PathEnemy, point: Vector2) -> void:
	spawn_blast(point, CLOUD_RADIUS, CLOUD_COLOR)
	if target != null:
		infect(target, _spread_generations)
