extends BaseTower
class_name EmpPylonTower

## Periodic pulse around the pylon. Every enemy in range loses its shield
## points and its SHIELDED trait, then takes damage; MECHANICAL enemies are
## also stunned. Organic targets suffer only the (trait-reduced) damage.

const PULSE_COLOR: Color = Color(0.5, 0.75, 1.0, 0.9)
const STUNNABLE_TRAIT: String = "MECHANICAL"
const STRIPPED_TRAIT: String = "SHIELDED"

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _stun_duration: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_stun_duration = stats.positive("stun_duration")


func _process(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if find_first_target() == null:
		return
	pulse()
	start_cooldown(_fire_rate)


## Returns the enemies caught in the pulse.
func pulse() -> Array[PathEnemy]:
	var hit: Array[PathEnemy] = enemies_within(global_position, attack_range)
	for enemy: PathEnemy in hit:
		if enemy.traits.has(STUNNABLE_TRAIT):
			enemy.apply_status(StatusEffect.stun(_stun_duration))
		enemy.strip_shield()
		deal_damage(enemy, _damage)
		if is_instance_valid(enemy):
			enemy.strip_trait(STRIPPED_TRAIT)
	spawn_blast(global_position, attack_range, PULSE_COLOR)
	return hit
