extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func _cross_barrier(enemy: PathEnemy, from: float, to: float) -> void:
	enemy.previous_path_distance = from
	enemy.set_path_distance(to)


func test_barrier_sits_at_closest_path_point() -> void:
	var tower := _fx.tower("shield_projector", Vector2(750, 150)) as ShieldProjectorTower
	assert_almost_eq(tower.get_barrier_distance(), 750.0, 0.75)


func test_barrier_holds_enemies_and_is_drained() -> void:
	var tower := _fx.tower("shield_projector", Vector2(750, 150)) as ShieldProjectorTower
	tower.get_barrier_distance()
	var enemy := _fx.enemy(735)
	_cross_barrier(enemy, 735.0, 765.0)
	tower.hold_enemies(1.0)
	assert_almost_eq(enemy.path_distance, tower.get_barrier_distance(), 0.01)
	assert_almost_eq(tower.get_barrier_hp(), 110.0, 0.001)


func test_heavier_enemies_drain_faster() -> void:
	var tower := _fx.tower("shield_projector", Vector2(750, 150)) as ShieldProjectorTower
	var barrier: float = tower.get_barrier_distance()
	var heavy := _fx.enemy(barrier, [], {"base_damage": 2})
	tower.hold_enemies(1.0)
	assert_almost_eq(tower.get_barrier_hp(), 100.0, 0.001)
	assert_almost_eq(heavy.path_distance, barrier, 0.01)


func test_broken_barrier_lets_enemies_through_then_recharges() -> void:
	var tower := _fx.tower("shield_projector", Vector2(750, 150)) as ShieldProjectorTower
	var barrier: float = tower.get_barrier_distance()
	_fx.enemy(barrier)
	tower.hold_enemies(12.5)
	assert_false(tower.is_barrier_up())

	var runner := _fx.enemy(735)
	_cross_barrier(runner, 735.0, 765.0)
	tower._process(1.0)
	assert_almost_eq(runner.path_distance, 765.0, 0.01, "not held while down")
	tower._process(5.5)
	assert_true(tower.is_barrier_up())
	assert_almost_eq(tower.get_barrier_hp(), 120.0, 0.001)


func test_inactive_when_path_out_of_range() -> void:
	var tower := _fx.tower("shield_projector", Vector2(750, 600)) as ShieldProjectorTower
	assert_eq(tower.get_barrier_distance(), -1.0)
	assert_false(tower.is_barrier_up())
