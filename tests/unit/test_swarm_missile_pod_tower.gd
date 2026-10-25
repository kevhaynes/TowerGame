extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_missiles_spread_over_separate_targets() -> void:
	var tower := _fx.tower("swarm_missile_pod", Vector2(450, 150))
	var enemies: Array[PathEnemy] = []
	for distance: float in [150, 300, 450, 600, 750]:
		enemies.append(_fx.enemy(distance))
	tower._process(0.0)
	assert_eq(_fx.damage_taken(enemies[0]), 0.0, "rearmost of five gets no missile")
	for index: int in range(1, 5):
		assert_almost_eq(_fx.damage_taken(enemies[index]), 12.0, 0.001)


func test_extra_missiles_wrap_onto_fewer_targets() -> void:
	var tower := _fx.tower("swarm_missile_pod", Vector2(150, 150))
	var first := _fx.enemy(300)
	var second := _fx.enemy(150)
	tower._process(0.0)
	assert_almost_eq(_fx.damage_taken(first), 24.0, 0.001)
	assert_almost_eq(_fx.damage_taken(second), 24.0, 0.001)
