extends GutTest

const Outcome := LevelOutcomeTracker.Outcome
const MAX_HEALTH: float = 10.0


func _started(enemy_count: int, max_health: float = MAX_HEALTH) -> LevelOutcomeTracker:
	var tracker := LevelOutcomeTracker.new()
	tracker.start(enemy_count, max_health)
	return tracker


func test_in_progress_until_every_enemy_is_resolved() -> void:
	var tracker := _started(2)
	assert_eq(tracker.get_outcome(), Outcome.IN_PROGRESS)
	assert_eq(tracker.record_kill(), Outcome.IN_PROGRESS)
	assert_eq(tracker.get_remaining(), 1)


func test_complete_when_all_enemies_are_killed() -> void:
	var tracker := _started(2)
	tracker.record_kill()
	assert_eq(tracker.record_kill(), Outcome.COMPLETE)
	assert_eq(tracker.get_stars(), 3)


func test_escape_costs_health_but_level_can_still_complete() -> void:
	var tracker := _started(2)
	assert_eq(tracker.record_escape(4.0), Outcome.IN_PROGRESS)
	assert_eq(tracker.get_health(), 6.0)
	assert_eq(tracker.record_kill(), Outcome.COMPLETE)
	assert_eq(tracker.get_stars(), 2)


func test_finishing_below_half_health_earns_one_star() -> void:
	var tracker := _started(2)
	tracker.record_escape(6.0)
	assert_eq(tracker.record_kill(), Outcome.COMPLETE)
	assert_eq(tracker.get_stars(), 1)


func test_fails_as_soon_as_health_runs_out() -> void:
	var tracker := _started(5)
	assert_eq(tracker.record_escape(7.0), Outcome.IN_PROGRESS)
	assert_eq(tracker.record_escape(7.0), Outcome.FAILED)
	assert_eq(tracker.get_health(), 0.0, "health does not go negative")
	assert_eq(tracker.get_remaining(), 3)
	assert_eq(tracker.get_stars(), 0)


func test_harmless_escape_keeps_full_health() -> void:
	var tracker := _started(1)
	assert_eq(tracker.record_escape(0.0), Outcome.COMPLETE)
	assert_eq(tracker.get_stars(), 3)


func test_health_changed_is_emitted_on_damage() -> void:
	var tracker := _started(2)
	watch_signals(tracker)
	tracker.record_escape(3.0)
	assert_signal_emitted_with_parameters(tracker, "health_changed", [7.0, MAX_HEALTH])
	tracker.record_escape(0.0)
	assert_signal_emit_count(tracker, "health_changed", 1, "no signal without damage")


func test_extra_events_do_not_go_negative_or_change_result() -> void:
	var tracker := _started(1)
	tracker.record_kill()
	assert_eq(tracker.record_escape(5.0), Outcome.COMPLETE)
	assert_eq(tracker.record_kill(), Outcome.COMPLETE)
	assert_eq(tracker.get_remaining(), 0)
	assert_eq(tracker.get_health(), MAX_HEALTH)


func test_events_after_failure_change_nothing() -> void:
	var tracker := _started(3)
	tracker.record_escape(MAX_HEALTH)
	assert_eq(tracker.record_kill(), Outcome.FAILED)
	assert_eq(tracker.record_kill(), Outcome.FAILED)
	assert_eq(tracker.get_remaining(), 2)


func test_start_resets_previous_state() -> void:
	var tracker := _started(1)
	tracker.record_escape(MAX_HEALTH)
	tracker.start(1, MAX_HEALTH)
	assert_eq(tracker.get_health(), MAX_HEALTH)
	assert_eq(tracker.record_kill(), Outcome.COMPLETE)
