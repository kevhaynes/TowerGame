extends GutTest

var _ramp: LaserRamp


func before_each() -> void:
	_ramp = LaserRamp.new(10.0, 0.5, 3.0)


func test_multiplier_starts_at_one_and_grows_linearly() -> void:
	assert_almost_eq(_ramp.get_multiplier(), 1.0, 0.0001)
	assert_almost_eq(_ramp.multiplier_at(2.0), 2.0, 0.0001)


func test_multiplier_caps_at_max() -> void:
	assert_almost_eq(_ramp.multiplier_at(4.0), 3.0, 0.0001)
	assert_almost_eq(_ramp.multiplier_at(60.0), 3.0, 0.0001)


func test_advance_integrates_damage_over_the_ramp() -> void:
	# Integral of 10 * (1 + 0.5t) from 0 to 1 is 12.5.
	assert_almost_eq(_ramp.advance(1.0), 12.5, 0.0001)
	assert_almost_eq(_ramp.advance(1.0), 17.5, 0.0001)
	assert_almost_eq(_ramp.time_on_target, 2.0, 0.0001)


func test_advance_crossing_the_cap_uses_capped_rate_afterwards() -> void:
	# 0..4s ramps (integral 8), 4..5s at 3x: total 11 * base 10.
	assert_almost_eq(_ramp.advance(5.0), 110.0, 0.0001)
	assert_almost_eq(_ramp.advance(1.0), 30.0, 0.0001)


func test_damage_is_frame_rate_independent() -> void:
	var stepped_damage: float = 0.0
	for _step: int in range(300):
		stepped_damage += _ramp.advance(1.0 / 60.0)
	var single_step := LaserRamp.new(10.0, 0.5, 3.0)
	assert_almost_eq(stepped_damage, single_step.advance(5.0), 0.001)


func test_reset_returns_to_base_damage() -> void:
	_ramp.advance(3.0)
	_ramp.reset()
	assert_almost_eq(_ramp.get_multiplier(), 1.0, 0.0001)
	assert_almost_eq(_ramp.get_progress(), 0.0, 0.0001)


func test_progress_reaches_one_when_fully_ramped() -> void:
	_ramp.advance(2.0)
	assert_almost_eq(_ramp.get_progress(), 0.5, 0.0001)
	_ramp.advance(10.0)
	assert_almost_eq(_ramp.get_progress(), 1.0, 0.0001)


func test_non_positive_delta_deals_no_damage() -> void:
	assert_eq(_ramp.advance(0.0), 0.0)
	assert_eq(_ramp.advance(-1.0), 0.0)
	assert_eq(_ramp.time_on_target, 0.0)
