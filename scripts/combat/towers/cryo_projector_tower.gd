extends BaseTower
class_name CryoProjectorTower

## Sprays liquid-nitrogen mist on the first enemy: everything within
## spray_radius of it takes light damage, is slowed and becomes BRITTLE (the
## next direct hit from any tower deals bonus damage).

const MIST_COLOR: Color = Color(0.7, 0.92, 1.0, 0.8)

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _spray_radius: float = 0.0
var _slow_fraction: float = 0.0
var _slow_duration: float = 0.0
var _brittle_bonus: float = 0.0
var _brittle_duration: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_spray_radius = stats.positive("spray_radius")
	_slow_fraction = stats.fraction("slow_fraction")
	_slow_duration = stats.positive("slow_duration")
	_brittle_bonus = stats.positive("brittle_bonus")
	_brittle_duration = stats.positive("brittle_duration")


func _process(delta: float) -> void:
	var can_fire: bool = tick_cooldown(delta)
	var target := find_first_target()
	if target == null:
		return
	aim_at(target.global_position)
	if can_fire:
		spray(target.global_position)
		start_cooldown(_fire_rate)


## Mists every enemy around [param point]. The damage lands before BRITTLE is
## applied so the spray never consumes its own bonus. Returns the enemies hit.
func spray(point: Vector2) -> Array[PathEnemy]:
	var hit: Array[PathEnemy] = enemies_within(point, _spray_radius)
	for enemy: PathEnemy in hit:
		deal_damage(enemy, _damage, false)
		enemy.apply_status(StatusEffect.slow(_slow_fraction, _slow_duration))
		enemy.apply_status(StatusEffect.brittle(_brittle_bonus, _brittle_duration))
	spawn_blast(point, _spray_radius, MIST_COLOR)
	return hit
