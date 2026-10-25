extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_spray_slows_and_makes_brittle() -> void:
	var tower := _fx.tower("cryo_projector", Vector2(300, 150)) as CryoProjectorTower
	var misted: Array[PathEnemy] = [_fx.enemy(300), _fx.enemy(345)]
	var outside := _fx.enemy(450)
	tower.spray(Vector2(300, 0))
	for enemy: PathEnemy in misted:
		assert_almost_eq(_fx.damage_taken(enemy), 3.0, 0.001)
		assert_almost_eq(enemy.statuses.get_speed_multiplier(), 0.5, 0.001)
		assert_true(enemy.statuses.has(StatusEffect.Type.BRITTLE))
	assert_eq(_fx.damage_taken(outside), 0.0)


func test_brittle_survives_further_sprays_and_boosts_next_hit() -> void:
	var tower := _fx.tower("cryo_projector", Vector2(300, 150)) as CryoProjectorTower
	var target := _fx.enemy(300)
	tower.spray(Vector2(300, 0))
	tower.spray(Vector2(300, 0))
	assert_true(target.statuses.has(StatusEffect.Type.BRITTLE))
	target.apply_damage(10.0)
	assert_almost_eq(_fx.damage_taken(target), 6.0 + 15.0, 0.001)
