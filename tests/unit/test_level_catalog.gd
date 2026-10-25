extends GutTest

const ENEMIES_DIRECTORY: String = "res://data/enemies/%s.json"


func _valid_definition() -> Dictionary:
	return {
		"id": "test_level",
		"display_name": "Test Level",
		"order": 1,
		"scene": "res://scenes/levels/test_level.tscn",
		"starting_credits": 300,
		"health": 20,
		"waves": [
			{"spawns": [{"enemy": "scout", "spawn_delay": 0.0}, {"enemy": "heavy"}]},
			{"spawns": [{"enemy": "scout", "spawn_delay": 2.0}]},
		],
	}


func test_valid_definition_has_no_errors() -> void:
	assert_eq(LevelCatalog.validate(_valid_definition()).size(), 0)


func test_rejects_missing_or_non_scene_path() -> void:
	var definition := _valid_definition()
	definition.erase("scene")
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["scene"] = "res://data/levels/level_01.json"
	assert_gt(LevelCatalog.validate(definition).size(), 0)


func test_rejects_missing_or_empty_waves() -> void:
	var definition := _valid_definition()
	definition.erase("waves")
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["waves"] = []
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["waves"] = [{"spawns": []}]
	assert_gt(LevelCatalog.validate(definition).size(), 0)


func test_rejects_bad_spawns() -> void:
	var definition := _valid_definition()
	definition["waves"] = [{"spawns": [{"enemy": "scout", "spawn_delay": -1.0}]}]
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["waves"] = [{"spawns": [{"spawn_delay": 1.0}]}]
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["waves"] = [{"spawns": [{"enemy": "scout", "spawn_delay": "soon"}]}]
	assert_gt(LevelCatalog.validate(definition).size(), 0)


func test_accepts_spawn_groups() -> void:
	var definition := _valid_definition()
	definition["waves"] = [
		{
			"spawns":
			[
				{"enemy": "scout", "count": 5, "spawn_interval": 0.8},
				{"enemy": "heavy", "count": 6, "spawn_delay": 2.0, "spawn_interval": 1.5},
			]
		}
	]
	assert_eq(LevelCatalog.validate(definition), PackedStringArray())


func test_rejects_bad_spawn_groups() -> void:
	var cases: Dictionary = {
		"count must be a whole number": {"enemy": "scout", "count": 0, "spawn_interval": 1},
		"count must be": {"enemy": "scout", "count": 2.5, "spawn_interval": 1},
		"spawn_interval must be a number of at least 0":
		{"enemy": "scout", "count": 2, "spawn_interval": -1},
		"needs a spawn_interval": {"enemy": "scout", "count": 3},
	}
	for expected: String in cases:
		var definition := _valid_definition()
		definition["waves"] = [{"spawns": [cases[expected]]}]
		var errors: String = "; ".join(LevelCatalog.validate(definition))
		assert_string_contains(errors, expected)
		assert_string_contains(errors, "wave 1, group 1")


func test_rejects_missing_negative_or_fractional_starting_credits() -> void:
	var definition := _valid_definition()
	definition.erase("starting_credits")
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["starting_credits"] = -1
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["starting_credits"] = 12.5
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["starting_credits"] = 0
	assert_eq(LevelCatalog.validate(definition).size(), 0)


func test_rejects_missing_non_positive_or_fractional_health() -> void:
	var definition := _valid_definition()
	definition.erase("health")
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["health"] = 0
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["health"] = 7.5
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["health"] = "lots"
	assert_gt(LevelCatalog.validate(definition).size(), 0)
	definition["health"] = 1
	assert_eq(LevelCatalog.validate(definition).size(), 0)


func test_rejects_missing_id_and_order() -> void:
	var definition := _valid_definition()
	definition.erase("id")
	definition["order"] = 0
	assert_eq(LevelCatalog.validate(definition).size(), 2)


func test_next_level_follows_order() -> void:
	var levels: Array[Dictionary] = [{"id": "a", "order": 1}, {"id": "b", "order": 2}]
	assert_eq(LevelCatalog.get_next_level_id(levels, "a"), "b")
	assert_eq(LevelCatalog.get_next_level_id(levels, "b"), "")
	assert_eq(LevelCatalog.get_next_level_id(levels, "missing"), "")


func test_find_level_by_scene() -> void:
	var levels: Array[Dictionary] = [
		{"id": "a", "scene": "res://a.tscn"}, {"id": "b", "scene": "res://b.tscn"}
	]
	assert_eq(LevelCatalog.find_level_by_scene(levels, "res://b.tscn")["id"], "b")
	assert_true(LevelCatalog.find_level_by_scene(levels, "res://c.tscn").is_empty())


func test_shipped_levels_load_in_order_with_unique_ids_and_orders() -> void:
	var levels: Array[Dictionary] = LevelCatalog.load_levels()
	assert_gte(levels.size(), 2)
	var ids: Array[String] = LevelCatalog.get_ordered_ids(levels)
	assert_eq(ids[0], "level_01")
	assert_eq(ids[1], "level_02")
	var orders: Array[float] = []
	var scenes: Array[String] = []
	for level: Dictionary in levels:
		assert_eq(ids.count(str(level["id"])), 1, "Level id %s must be unique" % level["id"])
		assert_false(float(level["order"]) in orders, "%s repeats an order" % level["id"])
		assert_false(str(level["scene"]) in scenes, "%s reuses a scene" % level["id"])
		orders.append(float(level["order"]))
		scenes.append(str(level["scene"]))


func test_shipped_level_spawns_reference_existing_enemies() -> void:
	for level: Dictionary in LevelCatalog.load_levels():
		for wave: Dictionary in level["waves"]:
			for spawn: Dictionary in wave["spawns"]:
				var enemy_path: String = ENEMIES_DIRECTORY % spawn["enemy"]
				assert_true(
					FileAccess.file_exists(enemy_path),
					"%s spawns unknown enemy %s" % [level["id"], spawn["enemy"]]
				)
