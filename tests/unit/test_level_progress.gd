extends GutTest

const LEVEL_IDS: Array[String] = ["level_01", "level_02", "level_03"]


func test_first_level_is_unlocked_with_no_progress() -> void:
	var progress := LevelProgress.new()
	assert_true(progress.is_unlocked(LEVEL_IDS, "level_01"))
	assert_false(progress.is_unlocked(LEVEL_IDS, "level_02"))
	assert_false(progress.is_unlocked(LEVEL_IDS, "level_03"))


func test_completing_a_level_unlocks_only_the_next_level() -> void:
	var progress := LevelProgress.new()
	progress.record_completion("level_01", 1)
	assert_true(progress.is_unlocked(LEVEL_IDS, "level_02"))
	assert_false(progress.is_unlocked(LEVEL_IDS, "level_03"))


func test_unknown_level_is_locked() -> void:
	var progress := LevelProgress.new()
	assert_false(progress.is_unlocked(LEVEL_IDS, "missing_level"))


func test_record_completion_keeps_the_best_stars() -> void:
	var progress := LevelProgress.new()
	assert_true(progress.record_completion("level_01", 2), "first completion")
	assert_false(progress.record_completion("level_01", 1), "worse run")
	assert_false(progress.record_completion("level_01", 2), "equal run")
	assert_eq(progress.get_stars("level_01"), 2)
	assert_true(progress.record_completion("level_01", 3), "better run")
	assert_eq(progress.get_stars("level_01"), 3)


func test_record_completion_clamps_stars() -> void:
	var progress := LevelProgress.new()
	progress.record_completion("level_01", 0)
	assert_true(progress.is_completed("level_01"))
	assert_eq(progress.get_stars("level_01"), 1, "completing always earns a star")
	progress.record_completion("level_02", 99)
	assert_eq(progress.get_stars("level_02"), LevelStars.MAX_STARS)


func test_total_stars_sums_the_best_of_each_level() -> void:
	var progress := LevelProgress.new()
	assert_eq(progress.get_total_stars(), 0)
	progress.record_completion("level_01", 2)
	progress.record_completion("level_01", 3)
	progress.record_completion("level_02", 1)
	assert_eq(progress.get_total_stars(), 4)


func test_uncompleted_level_has_no_stars() -> void:
	var progress := LevelProgress.new()
	assert_false(progress.is_completed("level_01"))
	assert_eq(progress.get_stars("level_01"), 0)


func test_round_trips_through_dictionary() -> void:
	var progress := LevelProgress.new()
	progress.record_completion("level_01", 2)
	var restored := LevelProgress.from_dict(progress.to_dict())
	assert_true(restored.is_completed("level_01"))
	assert_eq(restored.get_stars("level_01"), 2)
	assert_false(restored.is_completed("level_02"))


func test_round_trips_through_json() -> void:
	var progress := LevelProgress.new()
	progress.record_completion("level_01", 3)
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(progress.to_dict()))
	assert_eq(LevelProgress.from_dict(parsed).get_stars("level_01"), 3)


func test_from_dict_ignores_invalid_entries() -> void:
	var restored := LevelProgress.from_dict(
		{
			LevelProgress.LEVEL_STARS_KEY:
			{"level_01": 2.0, "level_02": "three", "": 3, "level_03": 0, "level_04": 7}
		}
	)
	assert_eq(restored.get_stars("level_01"), 2)
	assert_false(restored.is_completed("level_02"))
	assert_false(restored.is_completed(""))
	assert_false(restored.is_completed("level_03"), "a completed level has at least a star")
	assert_eq(restored.get_stars("level_04"), LevelStars.MAX_STARS)


func test_from_dict_handles_missing_or_malformed_data() -> void:
	assert_false(LevelProgress.from_dict({}).is_completed("level_01"))
	var malformed := LevelProgress.from_dict({LevelProgress.LEVEL_STARS_KEY: ["level_01"]})
	assert_false(malformed.is_completed("level_01"))
	assert_push_warning("is not an object")
