extends RefCounted
class_name LaserRamp

## Damage ramp for a beam held on one target. The damage multiplier grows
## linearly from 1 by [member ramp_rate] per second, capped at
## [member max_multiplier], and returns to 1 on [method reset].

var base_dps: float
var ramp_rate: float
var max_multiplier: float
var time_on_target: float = 0.0


func _init(base_dps_value: float, ramp_rate_value: float, max_multiplier_value: float) -> void:
	base_dps = base_dps_value
	ramp_rate = ramp_rate_value
	max_multiplier = max_multiplier_value


func get_multiplier() -> float:
	return multiplier_at(time_on_target)


func multiplier_at(seconds: float) -> float:
	return minf(1.0 + ramp_rate * seconds, max_multiplier)


## How far the ramp has climbed, from 0 (base damage) to 1 (fully ramped).
func get_progress() -> float:
	if max_multiplier <= 1.0:
		return 1.0
	return (get_multiplier() - 1.0) / (max_multiplier - 1.0)


## Returns the damage dealt over the next [param delta] seconds and advances the
## ramp. The multiplier is integrated exactly, so damage is frame-rate independent.
func advance(delta: float) -> float:
	if delta <= 0.0:
		return 0.0
	var start: float = time_on_target
	time_on_target += delta
	return base_dps * (_multiplier_integral(time_on_target) - _multiplier_integral(start))


func reset() -> void:
	time_on_target = 0.0


## Integral of the multiplier from 0 to [param seconds].
func _multiplier_integral(seconds: float) -> float:
	if ramp_rate <= 0.0:
		return seconds
	var cap_time: float = maxf((max_multiplier - 1.0) / ramp_rate, 0.0)
	if seconds <= cap_time:
		return seconds + 0.5 * ramp_rate * seconds * seconds
	return (
		cap_time
		+ 0.5 * ramp_rate * cap_time * cap_time
		+ max_multiplier * (seconds - cap_time)
	)
