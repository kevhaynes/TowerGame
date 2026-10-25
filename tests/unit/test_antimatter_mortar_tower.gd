extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_blind_spot_ignores_close_enemies() -> void:
	var tower := _fx.tower("antimatter_mortar", Vector2(0, 150))
	_fx.enemy(75)
	var far := _fx.enemy(450)
	assert_eq(tower.find_first_target(210.0), far)


func test_shell_leads_the_target() -> void:
	var tower := _fx.tower("antimatter_mortar", Vector2(0, 150)) as AntimatterMortarTower
	var target := _fx.enemy(450)
	var waiting := _fx.enemy(562.5)
	var landing := tower.fire_at(target)
	var lead: float = CombatFixture.ENEMY_SPEED * 1.5
	assert_almost_eq(landing.x, 450.0 + lead, 0.01)
	assert_almost_eq(_fx.damage_taken(waiting), 150.0, 0.001)
	var falloff: float = CombatMath.splash_falloff(lead, 165.0, 0.4)
	assert_almost_eq(_fx.damage_taken(target), 150.0 * falloff, 0.001)
