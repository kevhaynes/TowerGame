extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_heavy_slug_against_armour() -> void:
	var tower := _fx.tower("mass_driver", Vector2(150, 150))
	var heavy := _fx.enemy(225, ["ARMOURED"], {"armour": 3})
	tower._process(0.0)
	var expected: float = 70.0 * TraitAffinity.STRONG_MULTIPLIER * CombatMath.armour_multiplier(3)
	assert_almost_eq(_fx.damage_taken(heavy), expected, 0.001)
