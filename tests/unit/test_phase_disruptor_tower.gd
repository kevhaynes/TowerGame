extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_phased_enemy_takes_bonus_damage_and_ignores_slows() -> void:
	var tower := _fx.tower("phase_disruptor", Vector2(150, 150))
	var target := _fx.enemy(225)
	tower._process(0.0)
	assert_almost_eq(_fx.damage_taken(target), 10.0, 0.001)
	assert_true(target.statuses.has(StatusEffect.Type.PHASED))

	target.apply_damage(10.0)
	assert_almost_eq(_fx.damage_taken(target), 10.0 + 13.5, 0.001)
	target.apply_status(StatusEffect.slow(0.5, 2.0))
	assert_eq(target.statuses.get_speed_multiplier(), 1.0)
