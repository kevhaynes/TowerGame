extends RefCounted
class_name StatusEffect

## One status effect instance on an enemy. Build them with the static
## constructors so each type's fields are used consistently:
## [br]- SLOW: [member magnitude] is the fraction of speed removed (0.5 = half speed).
## [br]- STUN, STASIS: no magnitude; the enemy cannot move.
## [br]- BRITTLE: [member magnitude] is the bonus fraction on the next direct hit.
## [br]- ARMOUR_SHRED: [member magnitude] is armour removed, stacking up to [member cap].
## [br]- DOT: [member magnitude] is damage per second; [member source] identifies the tower type.
## [br]- PHASED: [member magnitude] is the bonus fraction of all damage taken.
## [br]- MASS_INCREASE: [member magnitude] is the slow fraction, [member damage_per_second] the DoT.

enum Type { SLOW, STUN, BRITTLE, ARMOUR_SHRED, DOT, PHASED, STASIS, MASS_INCREASE }

var type: Type
var magnitude: float = 0.0
var damage_per_second: float = 0.0
var cap: float = 0.0
var duration: float = 0.0
var source: String = ""
## Nanite infections: how many more times this DoT may spread to a neighbour.
var spread_generations: int = 0


static func slow(fraction: float, seconds: float) -> StatusEffect:
	return _make(Type.SLOW, fraction, seconds)


static func stun(seconds: float) -> StatusEffect:
	return _make(Type.STUN, 0.0, seconds)


static func stasis(seconds: float) -> StatusEffect:
	return _make(Type.STASIS, 0.0, seconds)


static func brittle(bonus: float, seconds: float) -> StatusEffect:
	return _make(Type.BRITTLE, bonus, seconds)


static func phased(bonus: float, seconds: float) -> StatusEffect:
	return _make(Type.PHASED, bonus, seconds)


static func armour_shred(points: float, max_points: float, seconds: float) -> StatusEffect:
	var effect := _make(Type.ARMOUR_SHRED, points, seconds)
	effect.cap = max_points
	return effect


static func dot(dps: float, seconds: float, source_id: String) -> StatusEffect:
	var effect := _make(Type.DOT, dps, seconds)
	effect.damage_per_second = dps
	effect.source = source_id
	return effect


static func mass_increase(slow_fraction: float, dps: float, seconds: float) -> StatusEffect:
	var effect := _make(Type.MASS_INCREASE, slow_fraction, seconds)
	effect.damage_per_second = dps
	return effect


static func _make(effect_type: Type, effect_magnitude: float, seconds: float) -> StatusEffect:
	var effect := StatusEffect.new()
	effect.type = effect_type
	effect.magnitude = effect_magnitude
	effect.duration = seconds
	return effect


func duplicate_effect() -> StatusEffect:
	var copy := StatusEffect.new()
	copy.type = type
	copy.magnitude = magnitude
	copy.damage_per_second = damage_per_second
	copy.cap = cap
	copy.duration = duration
	copy.source = source
	copy.spread_generations = spread_generations
	return copy
