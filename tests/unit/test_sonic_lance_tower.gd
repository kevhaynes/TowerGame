extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_knocks_target_back_along_path() -> void:
	var tower := _fx.tower("sonic_lance", Vector2(150, 150))
	var target := _fx.enemy(300)
	tower._process(0.0)
	assert_almost_eq(target.path_distance, 210.0, 0.01)
	assert_almost_eq(target.position.x, 210.0, 0.01)
	assert_almost_eq(_fx.damage_taken(target), 6.0, 0.001)


func test_bosses_are_knocked_back_half_as_far() -> void:
	var tower := _fx.tower("sonic_lance", Vector2(150, 150))
	var boss := _fx.enemy(300, ["BOSS"])
	tower._process(0.0)
	assert_almost_eq(boss.path_distance, 255.0, 0.01)
