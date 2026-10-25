extends RefCounted
class_name LevelCatalog

## Loads the level definitions in data/levels. Each one names the level, its
## place in the sequence, its starting credits and health, its enemy waves (see
## WaveSpawner) and the scene that holds its layout (path and build pads,
## authored in the editor).

const LEVELS_DIRECTORY: String = "res://data/levels"
const SCENE_EXTENSION: String = ".tscn"


static func load_levels(directory_path: String = LEVELS_DIRECTORY) -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error(
			"Could not open level definitions directory: %s"
			% error_string(DirAccess.get_open_error())
		)
		return levels

	for file_name: String in directory.get_files():
		if not file_name.ends_with(".json"):
			continue
		var definition_path: String = "%s/%s" % [directory_path, file_name]
		var definition: Dictionary = read_json_object(definition_path)
		if definition.is_empty():
			continue
		var errors: PackedStringArray = validate(definition)
		if errors.is_empty() and not ResourceLoader.exists(str(definition["scene"])):
			errors.append("scene %s does not exist" % definition["scene"])
		if not errors.is_empty():
			push_error("Invalid level definition %s: %s" % [definition_path, "; ".join(errors)])
			continue
		definition["_definition_path"] = definition_path
		levels.append(definition)

	levels.sort_custom(_compare_order)
	if levels.is_empty():
		push_warning("No valid level definitions were found in %s." % directory_path)
	return levels


static func read_json_object(definition_path: String) -> Dictionary:
	if not FileAccess.file_exists(definition_path):
		push_error("Definition file does not exist: %s" % definition_path)
		return {}

	var file: FileAccess = FileAccess.open(definition_path, FileAccess.READ)
	if file == null:
		push_error(
			"Could not open definition file %s: %s"
			% [definition_path, error_string(FileAccess.get_open_error())]
		)
		return {}

	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"Could not parse definition file %s at line %d: %s"
			% [definition_path, parser.get_error_line(), parser.get_error_message()]
		)
		return {}
	if not parser.data is Dictionary:
		push_error("Definition must contain a JSON object: %s" % definition_path)
		return {}
	return parser.data


static func validate(definition: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for field: String in ["id", "display_name"]:
		var value: Variant = definition.get(field)
		if not value is String or (value as String).is_empty():
			errors.append("%s must be a non-empty string" % field)

	var order: Variant = definition.get("order")
	if not _is_number(order) or float(order) < 1.0:
		errors.append("order must be a number of at least 1")

	var scene: Variant = definition.get("scene")
	if not scene is String or not (scene as String).ends_with(SCENE_EXTENSION):
		errors.append("scene must be a res:// path to a %s file" % SCENE_EXTENSION)

	var credits: Variant = definition.get("starting_credits")
	if not _is_number(credits) or float(credits) < 0.0 or not is_equal_approx(
		float(credits), roundf(float(credits))
	):
		errors.append("starting_credits must be a whole number of at least 0")

	var health: Variant = definition.get("health")
	if not _is_number(health) or float(health) < 1.0 or not is_equal_approx(
		float(health), roundf(float(health))
	):
		errors.append("health must be a whole number of at least 1")

	var waves: Variant = definition.get("waves")
	if not waves is Array or (waves as Array).is_empty():
		errors.append("waves must be a non-empty list")
		return errors
	for index: int in (waves as Array).size():
		var wave: Variant = waves[index]
		var spawns: Variant = wave.get("spawns") if wave is Dictionary else null
		if not spawns is Array or (spawns as Array).is_empty():
			errors.append("wave %d must have a non-empty spawns list" % (index + 1))
			continue
		for group_index: int in (spawns as Array).size():
			var group_error: String = _get_group_error(spawns[group_index])
			if not group_error.is_empty():
				errors.append(
					"wave %d, group %d: %s" % [index + 1, group_index + 1, group_error]
				)
	return errors


## An empty string for a valid spawn group (see WaveSpawner), else what is wrong.
static func _get_group_error(group: Variant) -> String:
	if not group is Dictionary:
		return "must be an object"
	var enemy: Variant = group.get(WaveSpawner.ENEMY_KEY)
	if not enemy is String or (enemy as String).is_empty():
		return "needs an enemy id"
	if group.has(WaveSpawner.COUNT_KEY):
		var count: Variant = group.get(WaveSpawner.COUNT_KEY)
		if not _is_number(count) or float(count) < 1.0 or not is_equal_approx(
			float(count), roundf(float(count))
		):
			return "count must be a whole number of at least 1"
	for key: String in [WaveSpawner.DELAY_KEY, WaveSpawner.INTERVAL_KEY]:
		if group.has(key) and (not _is_number(group.get(key)) or float(group.get(key)) < 0.0):
			return "%s must be a number of at least 0" % key
	if WaveSpawner.get_count(group) > 1 and not group.has(WaveSpawner.INTERVAL_KEY):
		return "a group of more than one enemy needs a spawn_interval"
	return ""


static func get_ordered_ids(levels: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for level: Dictionary in levels:
		ids.append(str(level["id"]))
	return ids


static func find_level(levels: Array[Dictionary], level_id: String) -> Dictionary:
	for level: Dictionary in levels:
		if str(level["id"]) == level_id:
			return level
	return {}


static func find_level_by_scene(levels: Array[Dictionary], scene_path: String) -> Dictionary:
	for level: Dictionary in levels:
		if str(level["scene"]) == scene_path:
			return level
	return {}


static func get_next_level_id(levels: Array[Dictionary], level_id: String) -> String:
	var ids: Array[String] = get_ordered_ids(levels)
	var index: int = ids.find(level_id)
	if index < 0 or index + 1 >= ids.size():
		return ""
	return ids[index + 1]


static func _compare_order(a: Dictionary, b: Dictionary) -> bool:
	return float(a["order"]) < float(b["order"])


static func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]
