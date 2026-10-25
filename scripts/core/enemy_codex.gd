extends RefCounted
class_name EnemyCodex

## The enemy types the player has encountered (seen spawn in a level), listed
## on the enemies menu.

var _encountered: Array[String] = []


static func from_array(data: Variant) -> EnemyCodex:
	var codex := EnemyCodex.new()
	if not data is Array:
		push_warning("Saved encountered enemies is not a list; ignoring it.")
		return codex
	for enemy_id: Variant in data:
		if enemy_id is String:
			codex.record_encounter(enemy_id)
	return codex


func to_array() -> Array[String]:
	return _encountered.duplicate()


## Returns true when [param enemy_id] had not been encountered before.
func record_encounter(enemy_id: String) -> bool:
	if enemy_id.is_empty() or _encountered.has(enemy_id):
		return false
	_encountered.append(enemy_id)
	return true


func has_encountered(enemy_id: String) -> bool:
	return _encountered.has(enemy_id)


func get_encountered_count() -> int:
	return _encountered.size()
