extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_fires_at_first_enemy_and_respects_cooldown() -> void:
	var tower := _fx.tower("machine_gun", Vector2(150, 150))
	var back := _fx.enemy(75)
	var front := _fx.enemy(225)
	tower._process(0.0)
	assert_almost_eq(_fx.damage_taken(front), 6.0, 0.001)
	assert_eq(_fx.damage_taken(back), 0.0)
	tower._process(0.1)
	assert_almost_eq(_fx.damage_taken(front), 6.0, 0.001, "still cooling down")
	tower._process(0.2)
	assert_almost_eq(_fx.damage_taken(front), 12.0, 0.001)


func test_trait_affinity() -> void:
	var tower := _fx.tower("machine_gun", Vector2(150, 150))
	var mechanical := _fx.enemy(150, ["MECHANICAL"])
	tower._process(0.0)
	assert_almost_eq(_fx.damage_taken(mechanical), 6.0 * TraitAffinity.STRONG_MULTIPLIER, 0.001)
