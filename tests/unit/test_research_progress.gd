extends GutTest


func test_record_research_reports_only_new_towers() -> void:
	var research := ResearchProgress.new()
	assert_true(research.record_research("laser_turret"))
	assert_false(research.record_research("laser_turret"))
	assert_false(research.record_research(""))
	assert_true(research.has_researched("laser_turret"))


func test_round_trips_through_json() -> void:
	var research := ResearchProgress.new()
	research.record_research("laser_turret")
	research.bonus_stars = 10
	var parsed: Variant = JSON.parse_string(JSON.stringify(research.to_dict()))
	var restored := ResearchProgress.from_dict(parsed)
	assert_true(restored.has_researched("laser_turret"))
	assert_eq(restored.bonus_stars, 10)


func test_from_dict_ignores_invalid_entries() -> void:
	var restored := ResearchProgress.from_dict(
		{
			ResearchProgress.RESEARCHED_KEY: ["laser_turret", 7, ""],
			ResearchProgress.BONUS_STARS_KEY: -5,
		}
	)
	assert_eq(restored.get_researched_ids(), ["laser_turret"] as Array[String])
	assert_eq(restored.bonus_stars, 0)


func test_from_dict_handles_malformed_data() -> void:
	assert_eq(ResearchProgress.from_dict(["laser_turret"]).get_researched_ids().size(), 0)
	assert_push_warning("is not an object")
