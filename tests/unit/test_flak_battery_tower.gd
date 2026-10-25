extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_flak_shell_splashes_and_favours_flyers() -> void:
	var tower := _fx.tower("flak_battery", Vector2(150, 150)) as SplashShellTower
	var flyer := _fx.enemy(300, ["FLYING"])
	var armoured := _fx.enemy(300, ["ARMOURED"])
	tower.detonate(null, Vector2(300, 0))
	assert_almost_eq(_fx.damage_taken(flyer), 9.0 * TraitAffinity.STRONG_MULTIPLIER, 0.001)
	assert_almost_eq(_fx.damage_taken(armoured), 9.0 * TraitAffinity.WEAK_MULTIPLIER, 0.001)
