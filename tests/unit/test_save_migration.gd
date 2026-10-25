extends GutTest

## Save data migration. Only the static migrate() is exercised, so the
## player's real save file is never touched.

const SaveManagerScript: GDScript = preload("res://scripts/core/save_manager.gd")


func _levels(save_data: Dictionary) -> Dictionary:
	return save_data[SaveManagerScript.LEVELS_KEY]


func test_version_1_completed_levels_become_three_stars() -> void:
	# Version 1 only completed a level when no enemy escaped, i.e. at full health.
	var v1: Dictionary = {"save_version": 1, "levels": {"completed_levels": ["level_01"]}}
	var migrated: Dictionary = SaveManagerScript.migrate(v1)
	assert_eq(migrated[SaveManagerScript.VERSION_KEY], SaveManagerScript.SAVE_VERSION)
	var progress := LevelProgress.from_dict(_levels(migrated))
	assert_eq(progress.get_stars("level_01"), LevelStars.MAX_STARS)
	assert_false(progress.is_completed("level_02"))
	assert_false(_levels(migrated).has("completed_levels"), "old key is dropped")


func test_version_1_ignores_invalid_completed_entries() -> void:
	var v1: Dictionary = {"save_version": 1, "levels": {"completed_levels": ["level_01", 7, ""]}}
	var progress := LevelProgress.from_dict(_levels(SaveManagerScript.migrate(v1)))
	assert_eq(progress.get_total_stars(), LevelStars.MAX_STARS)


func test_save_without_version_is_treated_as_version_1() -> void:
	var unversioned: Dictionary = {"levels": {"completed_levels": ["level_01"]}}
	var progress := LevelProgress.from_dict(_levels(SaveManagerScript.migrate(unversioned)))
	assert_true(progress.is_completed("level_01"))


func test_current_version_is_unchanged() -> void:
	var current: Dictionary = {
		"save_version": SaveManagerScript.SAVE_VERSION,
		"levels": {LevelProgress.LEVEL_STARS_KEY: {"level_01": 2}},
	}
	var progress := LevelProgress.from_dict(_levels(SaveManagerScript.migrate(current)))
	assert_eq(progress.get_stars("level_01"), 2)


func test_migrate_does_not_modify_its_input() -> void:
	var v1: Dictionary = {"save_version": 1, "levels": {"completed_levels": ["level_01"]}}
	SaveManagerScript.migrate(v1)
	assert_eq(v1["save_version"], 1)
	assert_true(_levels(v1).has("completed_levels"))


func test_version_2_gains_an_empty_encountered_enemy_list() -> void:
	var v2: Dictionary = {
		"save_version": 2, "levels": {LevelProgress.LEVEL_STARS_KEY: {"level_01": 2}}
	}
	var migrated: Dictionary = SaveManagerScript.migrate(v2)
	assert_eq(migrated[SaveManagerScript.VERSION_KEY], SaveManagerScript.SAVE_VERSION)
	assert_eq(migrated[SaveManagerScript.ENCOUNTERED_ENEMIES_KEY], [])
	assert_eq(LevelProgress.from_dict(_levels(migrated)).get_stars("level_01"), 2)


func test_current_version_keeps_encountered_enemies() -> void:
	var current: Dictionary = {
		"save_version": SaveManagerScript.SAVE_VERSION,
		"levels": {},
		SaveManagerScript.ENCOUNTERED_ENEMIES_KEY: ["scout"],
	}
	var migrated: Dictionary = SaveManagerScript.migrate(current)
	var codex := EnemyCodex.from_array(migrated[SaveManagerScript.ENCOUNTERED_ENEMIES_KEY])
	assert_true(codex.has_encountered("scout"))


func test_version_3_gains_empty_research() -> void:
	var v3: Dictionary = {"save_version": 3, "levels": {}, "encountered_enemies": ["scout"]}
	var migrated: Dictionary = SaveManagerScript.migrate(v3)
	assert_eq(migrated[SaveManagerScript.VERSION_KEY], SaveManagerScript.SAVE_VERSION)
	var research := ResearchProgress.from_dict(migrated[SaveManagerScript.RESEARCH_KEY])
	assert_eq(research.get_researched_ids().size(), 0)
	assert_eq(research.bonus_stars, 0)
	assert_eq(migrated[SaveManagerScript.ENCOUNTERED_ENEMIES_KEY], ["scout"])


func test_current_version_keeps_research() -> void:
	var current: Dictionary = {
		"save_version": SaveManagerScript.SAVE_VERSION,
		"levels": {},
		SaveManagerScript.RESEARCH_KEY: {ResearchProgress.RESEARCHED_KEY: ["laser_turret"]},
	}
	var migrated: Dictionary = SaveManagerScript.migrate(current)
	var research := ResearchProgress.from_dict(migrated[SaveManagerScript.RESEARCH_KEY])
	assert_true(research.has_researched("laser_turret"))
