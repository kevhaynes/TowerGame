extends RefCounted
class_name StatReader

## Reads numeric stats from a tower definition's "stats" object, collecting
## every problem so [method is_valid] can report them in a single push_error.

var _stats: Dictionary
var _owner_name: String
var _problems: PackedStringArray = []


func _init(stats: Dictionary, owner_name: String) -> void:
	_stats = stats
	_owner_name = owner_name


func positive(key: String) -> float:
	return _read(key, func(value: float) -> bool: return value > 0.0, "a positive number")


func non_negative(key: String) -> float:
	return _read(key, func(value: float) -> bool: return value >= 0.0, "a number of at least 0")


## A fraction in (0, 1].
func fraction(key: String) -> float:
	return _read(
		key,
		func(value: float) -> bool: return value > 0.0 and value <= 1.0,
		"a number above 0 and at most 1"
	)


func at_least(key: String, minimum: float) -> float:
	return _read(
		key,
		func(value: float) -> bool: return value >= minimum,
		"a number of at least %s" % minimum
	)


func whole_number(key: String, minimum: int) -> int:
	var is_whole := func(number: float) -> bool: return is_equal_approx(number, roundf(number))
	var value: float = _read(
		key,
		func(number: float) -> bool: return number >= minimum and is_whole.call(number),
		"a whole number of at least %d" % minimum
	)
	return int(roundf(value))


## Pushes one error listing every problem found so far. Returns true if there were none.
func is_valid() -> bool:
	if _problems.is_empty():
		return true
	push_error("%s definition has invalid stats: %s" % [_owner_name, "; ".join(_problems)])
	_problems.clear()
	return false


func _read(key: String, is_allowed: Callable, requirement: String) -> float:
	var value: Variant = _stats.get(key)
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_allowed.call(float(value)):
		_problems.append("%s must be %s" % [key, requirement])
		return 0.0
	return float(value)
