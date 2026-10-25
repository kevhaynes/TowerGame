extends RefCounted
class_name LevelProgress

## Completed levels and the best star rating earned on each.

const LEVEL_STARS_KEY: String = "level_stars"

var _level_stars: Dictionary[String, int] = {}


static func from_dict(data: Dictionary) -> LevelProgress:
	var progress := LevelProgress.new()
	var level_stars: Variant = data.get(LEVEL_STARS_KEY, {})
	if not level_stars is Dictionary:
		push_warning("Saved %s is not an object; ignoring it." % LEVEL_STARS_KEY)
		return progress
	for level_id: Variant in level_stars:
		var stars: Variant = level_stars[level_id]
		if not level_id is String or (level_id as String).is_empty():
			continue
		if not typeof(stars) in [TYPE_INT, TYPE_FLOAT] or int(stars) < 1:
			continue
		progress.record_completion(level_id, int(stars))
	return progress


func to_dict() -> Dictionary:
	return {LEVEL_STARS_KEY: _level_stars.duplicate()}


func is_completed(level_id: String) -> bool:
	return _level_stars.has(level_id)


## Best stars earned on the level, or 0 if it has not been completed.
func get_stars(level_id: String) -> int:
	return _level_stars.get(level_id, 0)


## Sum of the best stars of every completed level.
func get_total_stars() -> int:
	var total: int = 0
	for stars: int in _level_stars.values():
		total += stars
	return total


## Records a completion with [param stars] (clamped to 1..MAX_STARS, since
## completing always earns a star). Returns true when the level was not
## completed before or this beats its best stars.
func record_completion(level_id: String, stars: int) -> bool:
	var clamped: int = clampi(stars, 1, LevelStars.MAX_STARS)
	if clamped <= get_stars(level_id):
		return false
	_level_stars[level_id] = clamped
	return true


## The first level is always unlocked; every other level unlocks once the one
## before it in `ordered_level_ids` has been completed.
func is_unlocked(ordered_level_ids: Array[String], level_id: String) -> bool:
	var index: int = ordered_level_ids.find(level_id)
	if index < 0:
		return false
	if index == 0:
		return true
	return is_completed(ordered_level_ids[index - 1])
