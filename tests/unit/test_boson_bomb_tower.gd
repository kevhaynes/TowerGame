extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_blast_applies_mass_increase() -> void:
	var tower := _fx.tower("boson_bomb", Vector2(150, 150)) as BosonBombTower
	var caught := _fx.enemy(330)
	var outside := _fx.enemy(600)
	tower.detonate(null, Vector2(300, 0))
	assert_almost_eq(_fx.damage_taken(caught), 8.0, 0.001)
	assert_true(caught.statuses.has(StatusEffect.Type.MASS_INCREASE))
	assert_almost_eq(caught.statuses.get_speed_multiplier(), 0.6, 0.001)
	assert_false(outside.statuses.has(StatusEffect.Type.MASS_INCREASE))


func test_mass_increase_deals_damage_over_time() -> void:
	var tower := _fx.tower("boson_bomb", Vector2(150, 150)) as BosonBombTower
	var caught := _fx.enemy(300)
	tower.detonate(null, Vector2(300, 0))
	caught._process(1.0)
	assert_almost_eq(_fx.damage_taken(caught), 8.0 + 6.0, 0.001)
