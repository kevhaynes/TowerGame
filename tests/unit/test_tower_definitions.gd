extends GutTest

## Validates every tower definition in data/towers.

const TOWERS_DIRECTORY: String = "res://data/towers"
const SCHEMA_VERSION: int = 1
const DAMAGE_TYPES: Array[String] = ["KINETIC", "ENERGY", "EXPLOSIVE", "THERMAL", "CRYO", "EMP"]
const UPGRADE_BRANCH_COUNT: int = 2
const UPGRADE_TIER_COUNT: int = 3
## Stats used by the shop and data rather than by tower behaviours.
const UNVALIDATED_STATS: Array[String] = ["cost", "damage_type", "targeting_mode"]


func _load_definitions() -> Dictionary:
	var definitions: Dictionary = {}
	var directory: DirAccess = DirAccess.open(TOWERS_DIRECTORY)
	assert_not_null(directory, "Could not open %s" % TOWERS_DIRECTORY)
	if directory == null:
		return definitions
	for file_name: String in directory.get_files():
		if file_name.ends_with(".json"):
			var path: String = "%s/%s" % [TOWERS_DIRECTORY, file_name]
			definitions[file_name.get_basename()] = LevelCatalog.read_json_object(path)
	return definitions


func test_at_least_one_tower_is_defined() -> void:
	assert_gt(_load_definitions().size(), 0)


func test_required_fields() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var definition: Dictionary = definitions[file_id]
		assert_false(definition.is_empty(), "%s must be a JSON object" % file_id)
		assert_eq(definition.get("schema_version"), float(SCHEMA_VERSION), file_id)
		assert_eq(definition.get("id"), file_id, "%s id must match its filename" % file_id)
		for field: String in ["display_name", "description", "sprite"]:
			var value: Variant = definition.get(field)
			assert_true(
				value is String and not (value as String).is_empty(),
				"%s needs a non-empty string %s" % [file_id, field]
			)


func test_sprite_loads_as_texture() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var sprite_path: String = str(definitions[file_id].get("sprite", ""))
		assert_true(ResourceLoader.exists(sprite_path), "%s sprite missing" % file_id)
		if ResourceLoader.exists(sprite_path):
			assert_true(ResourceLoader.load(sprite_path) is Texture2D, file_id)


func test_traits_are_valid() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var definition: Dictionary = definitions[file_id]
		for property: String in ["strong_against_trait", "weak_against_trait"]:
			var output: Array[String] = []
			assert_true(
				TraitAffinity.read_trait_list(definition, property, output),
				"%s has an invalid %s" % [file_id, property]
			)


func test_stats_have_cost_and_damage_type() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var stats: Variant = definitions[file_id].get("stats")
		assert_true(stats is Dictionary, "%s stats must be an object" % file_id)
		if not stats is Dictionary:
			continue
		var cost: Variant = stats.get("cost")
		assert_true(
			typeof(cost) in [TYPE_INT, TYPE_FLOAT] and float(cost) >= 0.0,
			"%s needs a non-negative cost" % file_id
		)
		assert_true(
			DAMAGE_TYPES.has(stats.get("damage_type")),
			"%s has an unknown damage_type" % file_id
		)


func test_upgrade_tree_shape() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var branches: Variant = definitions[file_id].get("upgrade_branches")
		assert_true(branches is Array, "%s upgrade_branches must be an array" % file_id)
		if not branches is Array or (branches as Array).is_empty():
			continue
		assert_eq((branches as Array).size(), UPGRADE_BRANCH_COUNT, file_id)
		for branch: Variant in branches:
			var tiers: Variant = branch.get("tiers") if branch is Dictionary else null
			assert_true(
				tiers is Array and (tiers as Array).size() == UPGRADE_TIER_COUNT,
				"%s branches need %d tiers" % [file_id, UPGRADE_TIER_COUNT]
			)


func test_behaviour_script_configures_from_shipped_definition() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var definition: Dictionary = definitions[file_id]
		var behaviour_path: String = str(definition.get("behaviour", ""))
		assert_true(ResourceLoader.exists(behaviour_path), "%s behaviour missing" % file_id)
		if not ResourceLoader.exists(behaviour_path):
			continue
		var tower: Variant = autofree((load(behaviour_path) as Script).new())
		assert_true(tower is BaseTower, "%s behaviour must extend BaseTower" % file_id)
		if tower is BaseTower:
			assert_true((tower as BaseTower).configure(definition, null), file_id)


func test_projectile_sprites_load_as_textures() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		if not definitions[file_id].has("projectile_sprite"):
			continue
		var sprite_path: String = str(definitions[file_id]["projectile_sprite"])
		assert_true(ResourceLoader.exists(sprite_path), "%s projectile sprite missing" % file_id)
		if ResourceLoader.exists(sprite_path):
			assert_true(ResourceLoader.load(sprite_path) is Texture2D, file_id)


## Every numeric stat must be read and validated by the behaviour: removing
## any one of them must make configure() fail with a single error.
func test_every_numeric_stat_is_required_by_its_behaviour() -> void:
	var definitions: Dictionary = _load_definitions()
	var expected_errors: int = 0
	for file_id: String in definitions:
		var definition: Dictionary = definitions[file_id]
		var behaviour: Script = load(str(definition.get("behaviour", ""))) as Script
		if behaviour == null:
			continue
		for stat: String in (definition["stats"] as Dictionary).keys():
			if stat in UNVALIDATED_STATS:
				continue
			var trimmed: Dictionary = definition.duplicate(true)
			(trimmed["stats"] as Dictionary).erase(stat)
			var tower: BaseTower = autofree(behaviour.new())
			assert_false(tower.configure(trimmed, null), "%s accepts missing %s" % [file_id, stat])
			expected_errors += 1
	assert_push_error_count(expected_errors)
