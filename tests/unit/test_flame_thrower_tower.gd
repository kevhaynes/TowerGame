extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_cone_burns_enemies_in_front_only() -> void:
	var tower := _fx.tower("flame_thrower", Vector2(150, 90))
	var target := _fx.enemy(255)
	var in_cone := _fx.enemy(225)
	var beside := _fx.enemy(150)
	tower._process(1.0)
	assert_almost_eq(_fx.damage_taken(target), 18.0, 0.001)
	assert_almost_eq(_fx.damage_taken(in_cone), 18.0, 0.001)
	assert_eq(_fx.damage_taken(beside), 0.0, "outside the 40 degree cone")
	assert_not_null(target.statuses.get_effect(StatusEffect.Type.DOT, "flame_thrower"))


func test_strong_against_organic_weak_against_mechanical() -> void:
	var tower := _fx.tower("flame_thrower", Vector2(150, 90))
	var organic := _fx.enemy(225, ["ORGANIC"])
	var machine := _fx.enemy(225, ["MECHANICAL"])
	tower._process(1.0)
	assert_almost_eq(_fx.damage_taken(organic), 18.0 * TraitAffinity.STRONG_MULTIPLIER, 0.001)
	assert_almost_eq(_fx.damage_taken(machine), 18.0 * TraitAffinity.WEAK_MULTIPLIER, 0.001)


func test_burn_lingers_after_leaving_the_cone() -> void:
	var tower := _fx.tower("flame_thrower", Vector2(150, 90))
	var target := _fx.enemy(225)
	tower._process(0.5)
	var after_flame: float = _fx.damage_taken(target)
	target._process(1.0)
	assert_almost_eq(_fx.damage_taken(target), after_flame + 4.0, 0.001)
