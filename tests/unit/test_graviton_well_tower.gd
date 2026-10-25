extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_pulls_enemies_toward_the_closest_path_point() -> void:
	var tower := _fx.tower("graviton_well", Vector2(750, 150)) as GravitonWellTower
	var before := _fx.enemy(600)
	var after := _fx.enemy(900)
	var centred := _fx.enemy(750)
	tower.pull(1.0)
	assert_almost_eq(before.path_distance, 660.0, 0.01, "drawn forward")
	assert_almost_eq(after.path_distance, 840.0, 0.01, "dragged back")
	assert_almost_eq(centred.path_distance, 750.0, 0.01, "already at the well")
	assert_almost_eq(_fx.damage_taken(before), 2.0, 0.001)


func test_bosses_resist_the_pull() -> void:
	var tower := _fx.tower("graviton_well", Vector2(750, 150)) as GravitonWellTower
	var boss := _fx.enemy(600, ["BOSS"])
	tower.pull(1.0)
	assert_almost_eq(boss.path_distance, 630.0, 0.01)


func test_ignores_enemies_out_of_range() -> void:
	var tower := _fx.tower("graviton_well", Vector2(750, 150)) as GravitonWellTower
	var far := _fx.enemy(150)
	tower.pull(1.0)
	assert_eq(far.path_distance, 150.0)
