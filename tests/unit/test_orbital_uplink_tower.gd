extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_strike_lands_after_delay_on_the_painted_target() -> void:
	var tower := _fx.tower("orbital_uplink", Vector2(150, 150)) as OrbitalUplinkTower
	var target := _fx.enemy(300)
	var neighbour := _fx.enemy(300)
	tower.paint(target)
	tower.advance_strikes(1.0)
	assert_eq(_fx.damage_taken(target), 0.0, "still incoming")
	target.set_path_distance(382.5)
	tower.advance_strikes(0.6)
	assert_eq(tower.get_pending_strike_count(), 0)
	assert_almost_eq(_fx.damage_taken(target), 120.0, 0.001, "followed the target")
	var falloff: float = CombatMath.splash_falloff(82.5, 135.0, 0.7)
	assert_almost_eq(_fx.damage_taken(neighbour), 120.0 * falloff, 0.001)


func test_strike_lands_on_last_known_position_if_target_dies() -> void:
	var tower := _fx.tower("orbital_uplink", Vector2(150, 150)) as OrbitalUplinkTower
	var target := _fx.enemy(300)
	var bystander := _fx.enemy(315)
	tower.paint(target)
	target.apply_damage(CombatFixture.ENEMY_HEALTH)
	tower.advance_strikes(2.0)
	assert_gt(_fx.damage_taken(bystander), 0.0)
