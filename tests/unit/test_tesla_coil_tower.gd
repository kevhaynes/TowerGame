extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_chain_hops_to_nearest_and_falls_off() -> void:
	var tower := _fx.tower("tesla_coil", Vector2(150, 150)) as TeslaCoilTower
	var behind := _fx.enemy(150)
	var first := _fx.enemy(300)
	var second := _fx.enemy(435)
	var third := _fx.enemy(585)
	var unreachable := _fx.enemy(900)
	tower._process(0.0)
	assert_almost_eq(_fx.damage_taken(first), 14.0, 0.001)
	assert_almost_eq(_fx.damage_taken(second), 10.5, 0.001)
	assert_almost_eq(_fx.damage_taken(third), 7.875, 0.001)
	assert_eq(_fx.damage_taken(behind), 0.0, "nearest hop from 300 is 435, then 585")
	assert_eq(_fx.damage_taken(unreachable), 0.0)


func test_chain_is_capped_by_chain_count() -> void:
	var tower := _fx.tower("tesla_coil", Vector2(150, 150)) as TeslaCoilTower
	for index: int in 6:
		_fx.enemy(150 + index * 75.0)
	var first := tower.find_first_target()
	assert_eq(tower.zap(first).size(), 4)
