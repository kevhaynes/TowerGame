extends RefCounted
class_name ResearchProgress

## The towers the player has researched, and debug bonus stars (granted by the
## main menu's debug button) that add to the stars earned on levels.

const RESEARCHED_KEY: String = "researched"
const BONUS_STARS_KEY: String = "bonus_stars"

var bonus_stars: int = 0
var _researched: Array[String] = []


static func from_dict(data: Variant) -> ResearchProgress:
	var research := ResearchProgress.new()
	if not data is Dictionary:
		push_warning("Saved research is not an object; ignoring it.")
		return research
	var researched: Variant = data.get(RESEARCHED_KEY, [])
	if researched is Array:
		for tower_id: Variant in researched:
			if tower_id is String:
				research.record_research(tower_id)
	var bonus: Variant = data.get(BONUS_STARS_KEY, 0)
	if typeof(bonus) in [TYPE_INT, TYPE_FLOAT]:
		research.bonus_stars = maxi(0, int(bonus))
	return research


func to_dict() -> Dictionary:
	return {RESEARCHED_KEY: _researched.duplicate(), BONUS_STARS_KEY: bonus_stars}


func has_researched(tower_id: String) -> bool:
	return _researched.has(tower_id)


func get_researched_ids() -> Array[String]:
	return _researched.duplicate()


## Returns true when [param tower_id] was not researched before. Does not
## check cost or requirements; see ResearchTree.get_status().
func record_research(tower_id: String) -> bool:
	if tower_id.is_empty() or _researched.has(tower_id):
		return false
	_researched.append(tower_id)
	return true
