extends RefCounted
class_name StatusEffects

## The active status effects on one enemy, and their stacking rules:
## [br]- SLOW, STUN, STASIS, BRITTLE, PHASED, MASS_INCREASE: one instance per type;
##   the strongest magnitude wins and the longest remaining duration is kept.
## [br]- DOT: one instance per source; different sources add together.
## [br]- ARMOUR_SHRED: magnitudes add up to the effect's cap; the duration refreshes.
## [br]Bosses take crowd-control effects for [constant BOSS_CONTROL_FACTOR] of the duration.
## While PHASED, slows (including the MASS_INCREASE slow) are ignored.
## Damage taken during STASIS is stored and released when the stasis ends.

const BOSS_CONTROL_FACTOR: float = 0.5
const CONTROL_TYPES: Array[StatusEffect.Type] = [
	StatusEffect.Type.SLOW,
	StatusEffect.Type.STUN,
	StatusEffect.Type.STASIS,
	StatusEffect.Type.MASS_INCREASE,
]

var _effects: Array[StatusEffect] = []
var _stored_damage: float = 0.0
var _released_damage: float = 0.0


func apply(effect: StatusEffect, is_boss: bool = false) -> void:
	if effect == null or effect.duration <= 0.0:
		return
	var incoming := effect.duplicate_effect()
	if is_boss and CONTROL_TYPES.has(incoming.type):
		incoming.duration *= BOSS_CONTROL_FACTOR

	var existing := get_effect(incoming.type, incoming.source)
	if existing == null:
		if incoming.type == StatusEffect.Type.ARMOUR_SHRED:
			incoming.magnitude = minf(incoming.magnitude, incoming.cap)
		_effects.append(incoming)
		return

	existing.duration = maxf(existing.duration, incoming.duration)
	existing.spread_generations = maxi(existing.spread_generations, incoming.spread_generations)
	if incoming.type == StatusEffect.Type.ARMOUR_SHRED:
		existing.cap = maxf(existing.cap, incoming.cap)
		existing.magnitude = minf(existing.magnitude + incoming.magnitude, existing.cap)
	else:
		existing.magnitude = maxf(existing.magnitude, incoming.magnitude)
		existing.damage_per_second = maxf(
			existing.damage_per_second, incoming.damage_per_second
		)


## Ticks every effect by [param delta] seconds, removes expired effects and
## returns the damage-over-time dealt during the tick.
func advance(delta: float) -> float:
	if delta <= 0.0:
		return 0.0
	var damage: float = 0.0
	var remaining: Array[StatusEffect] = []
	for effect: StatusEffect in _effects:
		damage += effect.damage_per_second * minf(delta, effect.duration)
		effect.duration -= delta
		if effect.duration > 0.0:
			remaining.append(effect)
		elif effect.type == StatusEffect.Type.STASIS:
			_released_damage += _stored_damage
			_stored_damage = 0.0
	_effects = remaining
	return damage


func get_effect(effect_type: StatusEffect.Type, source: String = "") -> StatusEffect:
	for effect: StatusEffect in _effects:
		if effect.type == effect_type and effect.source == source:
			return effect
	return null


func has(effect_type: StatusEffect.Type) -> bool:
	for effect: StatusEffect in _effects:
		if effect.type == effect_type:
			return true
	return false


func get_effects() -> Array[StatusEffect]:
	return _effects


func is_in_stasis() -> bool:
	return has(StatusEffect.Type.STASIS)


func is_immobilised() -> bool:
	return is_in_stasis() or has(StatusEffect.Type.STUN)


func get_speed_multiplier() -> float:
	if is_immobilised():
		return 0.0
	if has(StatusEffect.Type.PHASED):
		return 1.0
	var slow: float = 0.0
	for effect: StatusEffect in _effects:
		if effect.type in [StatusEffect.Type.SLOW, StatusEffect.Type.MASS_INCREASE]:
			slow = maxf(slow, effect.magnitude)
	return clampf(1.0 - slow, 0.0, 1.0)


func get_armour_shred() -> float:
	var shred := get_effect(StatusEffect.Type.ARMOUR_SHRED)
	return shred.magnitude if shred != null else 0.0


## Multiplier on all damage taken (PHASED).
func get_damage_taken_multiplier() -> float:
	var phased := get_effect(StatusEffect.Type.PHASED)
	return 1.0 + (phased.magnitude if phased != null else 0.0)


## Returns the BRITTLE bonus fraction and removes it: it applies to one hit only.
func consume_brittle_bonus() -> float:
	var brittle := get_effect(StatusEffect.Type.BRITTLE)
	if brittle == null:
		return 0.0
	_effects.erase(brittle)
	return brittle.magnitude


func store_damage(amount: float) -> void:
	_stored_damage += maxf(amount, 0.0)


func get_stored_damage() -> float:
	return _stored_damage


## Returns damage released by an expired stasis since the last call.
func take_released_damage() -> float:
	var released: float = _released_damage
	_released_damage = 0.0
	return released
