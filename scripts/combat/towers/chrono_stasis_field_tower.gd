extends BaseTower
class_name ChronoStasisFieldTower

## Periodically freezes every enemy in range in STASIS. Damage they take while
## frozen is stored and released all at once when the stasis ends.

const FIELD_COLOR: Color = Color(0.6, 0.95, 1.0, 0.9)

var _fire_rate: float = 0.0
var _stasis_duration: float = 0.0


func _read_stats(stats: StatReader) -> void:
	_fire_rate = stats.positive("fire_rate")
	_stasis_duration = stats.positive("stasis_duration")


func _process(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if find_first_target() == null:
		return
	freeze()
	start_cooldown(_fire_rate)


## Returns the enemies frozen.
func freeze() -> Array[PathEnemy]:
	var frozen: Array[PathEnemy] = enemies_within(global_position, attack_range)
	for enemy: PathEnemy in frozen:
		enemy.apply_status(StatusEffect.stasis(_stasis_duration))
	spawn_blast(global_position, attack_range, FIELD_COLOR)
	return frozen
