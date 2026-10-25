extends GutTest

var _statuses: StatusEffects


func before_each() -> void:
	_statuses = StatusEffects.new()


func test_slow_strongest_wins_and_duration_refreshes() -> void:
	_statuses.apply(StatusEffect.slow(0.3, 5.0))
	_statuses.apply(StatusEffect.slow(0.5, 1.0))
	assert_almost_eq(_statuses.get_speed_multiplier(), 0.5, 0.0001)
	_statuses.advance(4.0)
	assert_almost_eq(_statuses.get_speed_multiplier(), 0.5, 0.0001, "kept longest duration")
	_statuses.advance(1.5)
	assert_almost_eq(_statuses.get_speed_multiplier(), 1.0, 0.0001)


func test_stun_and_stasis_stop_movement() -> void:
	_statuses.apply(StatusEffect.stun(1.0))
	assert_eq(_statuses.get_speed_multiplier(), 0.0)
	_statuses.advance(1.0)
	_statuses.apply(StatusEffect.stasis(1.0))
	assert_eq(_statuses.get_speed_multiplier(), 0.0)


func test_mass_increase_slows_and_deals_damage_over_time() -> void:
	_statuses.apply(StatusEffect.mass_increase(0.4, 6.0, 3.0))
	assert_almost_eq(_statuses.get_speed_multiplier(), 0.6, 0.0001)
	assert_almost_eq(_statuses.advance(1.0), 6.0, 0.0001)


func test_dots_from_different_sources_add_and_same_source_refreshes() -> void:
	_statuses.apply(StatusEffect.dot(5.0, 2.0, "a"))
	_statuses.apply(StatusEffect.dot(5.0, 2.0, "a"))
	_statuses.apply(StatusEffect.dot(4.0, 2.0, "b"))
	assert_almost_eq(_statuses.advance(1.0), 9.0, 0.0001)


func test_dot_deals_only_its_remaining_duration() -> void:
	_statuses.apply(StatusEffect.dot(10.0, 0.5, "a"))
	assert_almost_eq(_statuses.advance(1.0), 5.0, 0.0001)
	assert_false(_statuses.has(StatusEffect.Type.DOT))


func test_armour_shred_stacks_to_cap() -> void:
	for _i: int in 5:
		_statuses.apply(StatusEffect.armour_shred(1.0, 3.0, 6.0))
	assert_eq(_statuses.get_armour_shred(), 3.0)


func test_brittle_is_consumed_by_one_hit() -> void:
	_statuses.apply(StatusEffect.brittle(0.5, 3.0))
	assert_eq(_statuses.consume_brittle_bonus(), 0.5)
	assert_eq(_statuses.consume_brittle_bonus(), 0.0)


func test_phased_ignores_slows_and_increases_damage_taken() -> void:
	_statuses.apply(StatusEffect.slow(0.5, 5.0))
	_statuses.apply(StatusEffect.mass_increase(0.4, 0.0, 5.0))
	_statuses.apply(StatusEffect.phased(0.35, 2.0))
	assert_eq(_statuses.get_speed_multiplier(), 1.0)
	assert_almost_eq(_statuses.get_damage_taken_multiplier(), 1.35, 0.0001)
	_statuses.advance(2.5)
	assert_almost_eq(_statuses.get_speed_multiplier(), 0.5, 0.0001, "slow resumes after phase")


func test_stasis_releases_stored_damage_on_expiry() -> void:
	_statuses.apply(StatusEffect.stasis(2.0))
	_statuses.store_damage(40.0)
	_statuses.advance(1.0)
	assert_eq(_statuses.take_released_damage(), 0.0)
	_statuses.advance(1.5)
	assert_eq(_statuses.take_released_damage(), 40.0)
	assert_eq(_statuses.take_released_damage(), 0.0)


func test_bosses_take_half_duration_crowd_control() -> void:
	_statuses.apply(StatusEffect.stun(2.0), true)
	_statuses.apply(StatusEffect.dot(1.0, 2.0, "a"), true)
	_statuses.advance(1.1)
	assert_false(_statuses.has(StatusEffect.Type.STUN))
	assert_true(_statuses.has(StatusEffect.Type.DOT), "DoT is not crowd control")


func test_zero_duration_effects_are_ignored() -> void:
	_statuses.apply(StatusEffect.slow(0.5, 0.0))
	assert_eq(_statuses.get_effects().size(), 0)
