extends GutTest


func test_cycles_between_active_and_overheated() -> void:
	var cycle := OverchargeCycle.new(8.0, 4.0)
	assert_true(cycle.is_active())
	cycle.advance(7.9)
	assert_true(cycle.is_active())
	cycle.advance(0.2)
	assert_false(cycle.is_active())
	cycle.advance(4.0)
	assert_true(cycle.is_active(), "back on after the cooldown")


func test_phase_progress() -> void:
	var cycle := OverchargeCycle.new(8.0, 4.0)
	cycle.advance(4.0)
	assert_almost_eq(cycle.get_phase_progress(), 0.5, 0.0001)
	cycle.advance(6.0)
	assert_almost_eq(cycle.get_phase_progress(), 0.5, 0.0001)
