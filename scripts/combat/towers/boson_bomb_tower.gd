extends SplashShellTower
class_name BosonBombTower

## Splash shell that also increases the mass of everything caught in it:
## MASS_INCREASE slows the enemy and deals damage over time.

const MASS_BLAST_COLOR: Color = Color(0.7, 0.45, 1.0, 0.9)

var _mass_slow: float = 0.0
var _mass_dps: float = 0.0
var _mass_duration: float = 0.0


func _read_stats(stats: StatReader) -> void:
	super(stats)
	_mass_slow = stats.fraction("mass_slow")
	_mass_dps = stats.positive("mass_dps")
	_mass_duration = stats.positive("mass_duration")


func detonate(target: PathEnemy, point: Vector2) -> Array[PathEnemy]:
	var hit: Array[PathEnemy] = super(target, point)
	for enemy: PathEnemy in hit:
		if is_instance_valid(enemy):
			enemy.apply_status(StatusEffect.mass_increase(_mass_slow, _mass_dps, _mass_duration))
	return hit


func _get_blast_color() -> Color:
	return MASS_BLAST_COLOR
