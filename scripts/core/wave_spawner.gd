extends RefCounted
class_name WaveSpawner

## Runs a level's waves. Each wave is { "spawns": [group, ...] } and each group
## is { "enemy": id, "count": n, "spawn_interval": seconds, "spawn_delay":
## seconds }: n enemies of one type, spawn_interval apart. A group's
## spawn_delay is the wait before its first enemy, counted from the previous
## group's last enemy (or, for a wave's first group, from the start of the
## wave). count defaults to 1; a missing spawn_delay or spawn_interval is 0.
## Wave 1 starts with the first advance (when the player presses PLAY); each
## later wave starts once every enemy of the previous wave has been killed or
## has escaped.

const SPAWNS_KEY: String = "spawns"
const ENEMY_KEY: String = "enemy"
const DELAY_KEY: String = "spawn_delay"
const COUNT_KEY: String = "count"
const INTERVAL_KEY: String = "spawn_interval"
## Tolerance so a spawn due exactly at the end of a frame is not pushed to the
## next one by floating-point error.
const TIMING_TOLERANCE: float = 0.000001

var _waves: Array[Array] = []
var _wave_index: int = 0
var _spawn_index: int = 0
var _timer: float = 0.0
var _alive: int = 0
var _is_finished: bool = false


## [param waves] must already be validated (LevelCatalog.validate). Waves with
## no spawns are skipped.
func _init(waves: Array) -> void:
	for wave: Variant in waves:
		var spawns: Array[Dictionary] = []
		for group: Variant in (wave as Dictionary).get(SPAWNS_KEY, []):
			spawns.append_array(expand_group(group as Dictionary))
		if not spawns.is_empty():
			_waves.append(spawns)
	_is_finished = _waves.is_empty()
	if not _is_finished:
		_timer = get_delay(_current_wave()[0])


## The group's enemies as single spawns, each with its delay after the one
## before: the group's spawn_delay for the first, spawn_interval for the rest.
static func expand_group(group: Dictionary) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	var interval: float = float(group.get(INTERVAL_KEY, 0.0))
	for index: int in get_count(group):
		spawns.append(
			{ENEMY_KEY: group[ENEMY_KEY], DELAY_KEY: get_delay(group) if index == 0 else interval}
		)
	return spawns


static func get_count(group: Dictionary) -> int:
	return int(group.get(COUNT_KEY, 1))


static func get_delay(spawn: Dictionary) -> float:
	return float(spawn.get(DELAY_KEY, 0.0))


## Advances time by [param delta] seconds and returns the enemy ids to spawn
## now, in order. Returns nothing while waiting for a wave to be cleared.
func advance(delta: float) -> Array[String]:
	var spawned: Array[String] = []
	if _is_finished or _is_wave_spawned():
		return spawned
	_timer -= delta
	while _timer <= TIMING_TOLERANCE and not _is_wave_spawned():
		spawned.append(str(_current_wave()[_spawn_index][ENEMY_KEY]))
		_alive += 1
		_spawn_index += 1
		if not _is_wave_spawned():
			_timer += get_delay(_current_wave()[_spawn_index])
	return spawned


## Call when a spawned enemy is killed or escapes. Starts the next wave once
## the current one has fully spawned and none of its enemies remain.
func notify_enemy_resolved() -> void:
	_alive = maxi(_alive - 1, 0)
	if _alive == 0 and _is_wave_spawned():
		_start_next_wave()


## 1-based number of the wave in progress (or the last wave once finished).
func get_wave_number() -> int:
	return mini(_wave_index + 1, get_wave_count())


func get_wave_count() -> int:
	return _waves.size()


func get_total_spawn_count() -> int:
	var total: int = 0
	for wave: Array in _waves:
		total += wave.size()
	return total


## True once the last wave has been cleared.
func is_finished() -> bool:
	return _is_finished


func _start_next_wave() -> void:
	if _wave_index + 1 >= _waves.size():
		_is_finished = true
		return
	_wave_index += 1
	_spawn_index = 0
	_timer = get_delay(_current_wave()[0])


func _current_wave() -> Array:
	return _waves[_wave_index]


func _is_wave_spawned() -> bool:
	return _spawn_index >= _current_wave().size()
