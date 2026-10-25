extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_freezes_enemies_in_range_and_releases_stored_damage() -> void:
	var tower := _fx.tower("chrono_stasis_field", Vector2(150, 150))
	var frozen := _fx.enemy(225)
	var far := _fx.enemy(900)
	tower._process(0.0)
	assert_true(frozen.statuses.is_in_stasis())
	assert_false(far.statuses.is_in_stasis())

	frozen.apply_damage(50.0)
	frozen._process(1.0)
	assert_eq(_fx.damage_taken(frozen), 0.0, "damage held during stasis")
	assert_eq(frozen.path_distance, 225.0, "frozen in place")
	frozen._process(2.1)
	assert_almost_eq(_fx.damage_taken(frozen), 50.0, 0.001, "released on expiry")


func test_bosses_are_frozen_for_half_as_long() -> void:
	var tower := _fx.tower("chrono_stasis_field", Vector2(150, 150))
	var boss := _fx.enemy(225, ["BOSS"])
	tower._process(0.0)
	boss._process(1.6)
	assert_false(boss.statuses.is_in_stasis())
