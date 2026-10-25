extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_splash_falls_off_to_edge_factor() -> void:
	var tower := _fx.tower("plasma_cannon", Vector2(150, 150)) as SplashShellTower
	var centre := _fx.enemy(300)
	var mid := _fx.enemy(352.5)
	var outside := _fx.enemy(450)
	tower.detonate(null, Vector2(300, 0))
	assert_almost_eq(_fx.damage_taken(centre), 20.0, 0.001)
	assert_almost_eq(_fx.damage_taken(mid), 15.0, 0.001)
	assert_eq(_fx.damage_taken(outside), 0.0)


func test_fires_at_first_enemy() -> void:
	var tower := _fx.tower("plasma_cannon", Vector2(150, 150))
	var target := _fx.enemy(225)
	tower._process(0.0)
	assert_almost_eq(_fx.damage_taken(target), 20.0, 0.001)
