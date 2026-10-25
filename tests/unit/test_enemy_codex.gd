extends GutTest


func test_new_codex_has_no_encounters() -> void:
	var codex := EnemyCodex.new()
	assert_eq(codex.get_encountered_count(), 0)
	assert_false(codex.has_encountered("scout"))


func test_record_encounter_reports_only_new_enemies() -> void:
	var codex := EnemyCodex.new()
	assert_true(codex.record_encounter("scout"), "first encounter")
	assert_false(codex.record_encounter("scout"), "repeat encounter")
	assert_false(codex.record_encounter(""), "empty id")
	assert_true(codex.has_encountered("scout"))
	assert_eq(codex.get_encountered_count(), 1)


func test_round_trips_through_json() -> void:
	var codex := EnemyCodex.new()
	codex.record_encounter("scout")
	codex.record_encounter("heavy")
	var parsed: Variant = JSON.parse_string(JSON.stringify(codex.to_array()))
	var restored := EnemyCodex.from_array(parsed)
	assert_true(restored.has_encountered("scout"))
	assert_true(restored.has_encountered("heavy"))
	assert_eq(restored.get_encountered_count(), 2)


func test_from_array_ignores_invalid_entries() -> void:
	var restored := EnemyCodex.from_array(["scout", 7, "", "scout"])
	assert_eq(restored.to_array(), ["scout"] as Array[String])


func test_from_array_handles_malformed_data() -> void:
	assert_eq(EnemyCodex.from_array({"scout": true}).get_encountered_count(), 0)
	assert_push_warning("is not a list")
