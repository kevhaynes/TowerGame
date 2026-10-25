extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_slug_pierces_everything_on_the_line() -> void:
	var tower := _fx.tower("railgun_emplacement", Vector2(-150, 0)) as RailgunEmplacementTower
	var on_line: Array[PathEnemy] = [_fx.enemy(75), _fx.enemy(225), _fx.enemy(375)]
	var beyond_range := _fx.enemy(600)
	var off_line := _fx.enemy(150)
	off_line.position = Vector2(150, 75)
	var hit := tower.fire_at(Vector2(150, 0))
	assert_eq(hit.size(), 3)
	for enemy: PathEnemy in on_line:
		assert_almost_eq(_fx.damage_taken(enemy), 90.0, 0.001)
	assert_eq(_fx.damage_taken(beyond_range), 0.0)
	assert_eq(_fx.damage_taken(off_line), 0.0)
