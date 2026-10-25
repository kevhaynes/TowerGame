extends RefCounted
class_name DefinitionCatalog

## Loads tower and enemy JSON definitions. A definition is only returned when
## it has a string display_name and a sprite that loads as a texture.

const TOWERS_DIRECTORY: String = "res://data/towers"
const ENEMIES_DIRECTORY: String = "res://data/enemies"
const ENEMY_DEFINITION_PATH: String = "res://data/enemies/%s.json"
## Key added to each loaded definition holding the file it came from.
const DEFINITION_PATH_KEY: String = "_definition_path"


## Every valid definition in [param directory_path], ordered by file name.
static func load_directory(directory_path: String) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error(
			"Could not open definitions directory %s: %s"
			% [directory_path, error_string(DirAccess.get_open_error())]
		)
		return definitions

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()
	for file_name: String in file_names:
		if not file_name.ends_with(".json"):
			continue
		var definition_path: String = "%s/%s" % [directory_path, file_name]
		var definition: Dictionary = read_definition(definition_path)
		if definition.is_empty():
			continue
		definition[DEFINITION_PATH_KEY] = definition_path
		definitions.append(definition)

	if definitions.is_empty():
		push_warning("No valid definitions were found in %s." % directory_path)
	return definitions


static func load_enemy(enemy_id: String) -> Dictionary:
	return read_definition(ENEMY_DEFINITION_PATH % enemy_id)


static func read_definition(definition_path: String) -> Dictionary:
	var definition: Dictionary = LevelCatalog.read_json_object(definition_path)
	if definition.is_empty():
		return {}

	if not definition.has("display_name") or not definition["display_name"] is String:
		push_error("Definition is missing its string display_name: %s" % definition_path)
		return {}
	if not definition.has("sprite") or not definition["sprite"] is String:
		push_error("Definition is missing its string sprite path: %s" % definition_path)
		return {}

	var sprite_path: String = definition["sprite"]
	if not ResourceLoader.exists(sprite_path):
		push_error("Definition sprite does not exist: %s" % sprite_path)
		return {}
	var sprite_resource: Resource = ResourceLoader.load(sprite_path)
	if not sprite_resource is Texture2D:
		push_error("Definition sprite is not a texture: %s" % sprite_path)
		return {}

	return definition
