extends RefCounted
class_name LevelOutcomeTracker

## Tracks a level's remaining enemies and health. Each escaping enemy costs
## health equal to its base_damage.

signal health_changed(health: float, max_health: float)

enum Outcome { IN_PROGRESS, COMPLETE, FAILED }

var _remaining: int = 0
var _health: float = 0.0
var _max_health: float = 0.0


func start(enemy_count: int, max_health: float) -> void:
	_remaining = maxi(enemy_count, 0)
	_max_health = maxf(max_health, 0.0)
	_health = _max_health
	health_changed.emit(_health, _max_health)


func record_kill() -> Outcome:
	if get_outcome() == Outcome.IN_PROGRESS:
		_remaining -= 1
	return get_outcome()


func record_escape(damage: float) -> Outcome:
	if get_outcome() != Outcome.IN_PROGRESS:
		return get_outcome()
	_remaining -= 1
	if damage > 0.0:
		_health = maxf(_health - damage, 0.0)
		health_changed.emit(_health, _max_health)
	return get_outcome()


## The level fails as soon as health runs out, and is complete once every
## enemy has been killed or has escaped with health left.
func get_outcome() -> Outcome:
	if _health <= 0.0:
		return Outcome.FAILED
	if _remaining > 0:
		return Outcome.IN_PROGRESS
	return Outcome.COMPLETE


func get_remaining() -> int:
	return _remaining


func get_health() -> float:
	return _health


func get_max_health() -> float:
	return _max_health


func get_stars() -> int:
	return LevelStars.for_health(_health, _max_health)
