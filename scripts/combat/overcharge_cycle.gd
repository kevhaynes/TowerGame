extends RefCounted
class_name OverchargeCycle

## The Overcharge Relay's duty cycle: active for active_duration, then
## overheated (no buff) for cooldown_duration, repeating. Starts active.

var active_duration: float
var cooldown_duration: float
var _time: float = 0.0


func _init(active_seconds: float, cooldown_seconds: float) -> void:
	active_duration = active_seconds
	cooldown_duration = cooldown_seconds


func advance(delta: float) -> void:
	_time = fmod(_time + maxf(delta, 0.0), active_duration + cooldown_duration)


func is_active() -> bool:
	return _time < active_duration


## 0..1 progress through the current phase (active or overheated).
func get_phase_progress() -> float:
	if is_active():
		return _time / active_duration
	return (_time - active_duration) / cooldown_duration
