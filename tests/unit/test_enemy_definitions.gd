extends GutTest

## Validates every enemy definition in data/enemies.

const ENEMIES_DIRECTORY: String = "res://data/enemies"
const POSITIVE_STATS: Array[String] = ["health", "move_speed"]
const NON_NEGATIVE_STATS: Array[String] = ["armour", "shield", "bounty", "base_damage"]


func _load_definitions() -> Dictionary:
	var definitions: Dictionary = {}
	for file_name: String in DirAccess.get_files_at(ENEMIES_DIRECTORY):
		if file_name.ends_with(".json"):
			var path: String = "%s/%s" % [ENEMIES_DIRECTORY, file_name]
			definitions[file_name.get_basename()] = LevelCatalog.read_json_object(path)
	return definitions


func test_at_least_one_enemy_is_defined() -> void:
	assert_gt(_load_definitions().size(), 0)


func test_required_fields_and_sprite() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var definition: Dictionary = definitions[file_id]
		assert_eq(definition.get("id"), file_id, "%s id must match its filename" % file_id)
		for field: String in ["display_name", "description", "sprite"]:
			var value: Variant = definition.get(field)
			assert_true(
				value is String and not (value as String).is_empty(),
				"%s needs a non-empty string %s" % [file_id, field]
			)
		var sprite_path: String = str(definition.get("sprite", ""))
		assert_true(
			ResourceLoader.exists(sprite_path) and ResourceLoader.load(sprite_path) is Texture2D,
			"%s sprite must load as a texture" % file_id
		)


func test_every_stat_is_present_and_in_range() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var stats: Variant = definitions[file_id].get("stats")
		assert_true(stats is Dictionary, "%s stats must be an object" % file_id)
		if not stats is Dictionary:
			continue
		for stat: String in POSITIVE_STATS + NON_NEGATIVE_STATS:
			var value: Variant = stats.get(stat)
			assert_true(
				typeof(value) in [TYPE_INT, TYPE_FLOAT], "%s needs a numeric %s" % [file_id, stat]
			)
			if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
				var minimum_ok: bool = (
					float(value) > 0.0 if stat in POSITIVE_STATS else float(value) >= 0.0
				)
				assert_true(minimum_ok, "%s has an out-of-range %s" % [file_id, stat])


func test_traits_are_valid() -> void:
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var traits: Variant = definitions[file_id].get("traits")
		assert_true(traits is Array, "%s traits must be an array" % file_id)
		if traits is Array:
			for trait_value: Variant in traits:
				assert_true(
					TraitAffinity.VALID_TRAITS.has(trait_value),
					"%s has unknown trait %s" % [file_id, trait_value]
				)


func test_shipped_enemies_configure() -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100, 0))
	var definitions: Dictionary = _load_definitions()
	for file_id: String in definitions:
		var enemy := PathEnemy.new()
		add_child_autofree(enemy)
		assert_true(enemy.configure(definitions[file_id], curve), "%s configures" % file_id)


## Enemies designed so the starting Machine Gun is not the answer: it is never
## strong against them, and at least one tier-1 research tower is.
const TIER_ONE_COUNTER_ENEMIES: Array[String] = ["wasp", "brute", "aegis", "skitter"]
const STARTING_TOWER: String = "machine_gun"
const TOWER_PATH: String = "res://data/towers/%s.json"


func _trait_multiplier(tower_id: String, enemy_traits: Array[String]) -> float:
	var tower: Dictionary = LevelCatalog.read_json_object(TOWER_PATH % tower_id)
	var strong: Array[String] = []
	var weak: Array[String] = []
	TraitAffinity.read_trait_list(tower, "strong_against_trait", strong)
	TraitAffinity.read_trait_list(tower, "weak_against_trait", weak)
	return TraitAffinity.get_multiplier(strong, weak, enemy_traits)


func test_new_enemies_are_countered_by_tier_one_towers() -> void:
	var tree := ResearchTree.load_tree()
	var definitions: Dictionary = _load_definitions()
	for enemy_id: String in TIER_ONE_COUNTER_ENEMIES:
		assert_true(definitions.has(enemy_id), "%s is defined" % enemy_id)
		var enemy_traits: Array[String] = []
		enemy_traits.assign(definitions.get(enemy_id, {}).get("traits", []))
		assert_lte(
			_trait_multiplier(STARTING_TOWER, enemy_traits), 1.0, "%s: gun not strong" % enemy_id
		)
		var countered: bool = false
		for tower_id: String in tree.get_tower_ids():
			if tree.get_tier(tower_id) == 1 and _trait_multiplier(tower_id, enemy_traits) > 1.0:
				countered = true
		assert_true(countered, "%s has a tier-1 counter" % enemy_id)


func test_enemy_roles() -> void:
	var definitions: Dictionary = _load_definitions()
	assert_has(definitions["wasp"]["traits"], "FLYING")
	assert_has(definitions["brute"]["traits"], "ORGANIC")
	assert_gt(float(definitions["aegis"]["stats"]["shield"]), 0.0)
	assert_has(definitions["aegis"]["traits"], "SHIELDED")
	var swarm: Dictionary = definitions["skitter"]["stats"]
	for enemy_id: String in definitions:
		if enemy_id == "skitter":
			continue
		var stats: Dictionary = definitions[enemy_id]["stats"]
		assert_gt(float(swarm["move_speed"]), float(stats["move_speed"]), "swarm is fastest")
		assert_lt(float(swarm["health"]), float(stats["health"]), "swarm is weakest")
