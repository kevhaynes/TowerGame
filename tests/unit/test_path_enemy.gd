extends GutTest

const DEFINITION: Dictionary = {"stats": {"health": 10, "move_speed": 100.0}, "traits": []}

var _enemy: PathEnemy


func before_each() -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100, 0))
	_enemy = PathEnemy.new()
	add_child_autofree(_enemy)
	assert_true(_enemy.configure(DEFINITION, curve))
	watch_signals(_enemy)


func test_lethal_damage_emits_killed_once() -> void:
	_enemy.apply_damage(10.0)
	_enemy.apply_damage(10.0)
	assert_signal_emit_count(_enemy, "killed", 1)
	assert_signal_not_emitted(_enemy, "escaped")
	assert_false(_enemy.is_in_group("enemies"))


func test_reaching_path_end_emits_escaped() -> void:
	_enemy._process(2.0)
	assert_signal_emit_count(_enemy, "escaped", 1)
	assert_false(_enemy.is_in_group("enemies"))


func test_escaped_enemy_ignores_later_damage() -> void:
	_enemy._process(2.0)
	_enemy.apply_damage(10.0)
	assert_signal_not_emitted(_enemy, "killed")


func _armoured_enemy(armour: float, traits: Array = []) -> PathEnemy:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(1000, 0))
	var enemy := PathEnemy.new()
	add_child_autofree(enemy)
	var definition: Dictionary = {
		"stats": {"health": 100, "move_speed": 100.0, "armour": armour}, "traits": traits
	}
	assert_true(enemy.configure(definition, curve))
	return enemy


func test_armour_reduces_damage() -> void:
	var enemy := _armoured_enemy(3.0)
	enemy.apply_damage(10.0)
	assert_almost_eq(enemy.health, 93.0, 0.0001)


func test_armour_shred_lowers_effective_armour() -> void:
	var enemy := _armoured_enemy(3.0)
	enemy.apply_status(StatusEffect.armour_shred(2.0, 3.0, 5.0))
	enemy.apply_damage(10.0)
	assert_almost_eq(enemy.health, 91.0, 0.0001)


func test_brittle_boosts_next_direct_hit_only() -> void:
	var enemy := _armoured_enemy(0.0)
	enemy.apply_status(StatusEffect.brittle(0.5, 3.0))
	enemy.apply_damage(2.0, false)
	enemy.apply_damage(10.0)
	enemy.apply_damage(10.0)
	assert_almost_eq(enemy.health, 100.0 - 2.0 - 15.0 - 10.0, 0.0001)


func test_slow_reduces_movement() -> void:
	var enemy := _armoured_enemy(0.0)
	enemy.apply_status(StatusEffect.slow(0.5, 5.0))
	enemy._process(1.0)
	assert_almost_eq(enemy.path_distance, 50.0, 0.0001)
	assert_almost_eq(enemy.previous_path_distance, 0.0, 0.0001)


func test_damage_over_time_ticks_in_process() -> void:
	var enemy := _armoured_enemy(0.0)
	enemy.apply_status(StatusEffect.dot(5.0, 4.0, "test"))
	enemy._process(1.0)
	assert_almost_eq(enemy.health, 95.0, 0.0001)


func test_stasis_freezes_and_releases_stored_damage() -> void:
	var enemy := _armoured_enemy(0.0)
	enemy.apply_status(StatusEffect.stasis(2.0))
	enemy.apply_damage(30.0)
	enemy._process(1.0)
	assert_eq(enemy.health, 100.0, "damage is stored during stasis")
	assert_eq(enemy.path_distance, 0.0, "frozen enemies do not move")
	enemy.push_along_path(-50.0)
	enemy._process(1.0)
	assert_almost_eq(enemy.health, 70.0, 0.0001, "stored damage released on expiry")


func test_push_along_path_clamps_and_halves_for_bosses() -> void:
	var enemy := _armoured_enemy(0.0)
	enemy.set_path_distance(100.0)
	enemy.push_along_path(-60.0)
	assert_almost_eq(enemy.path_distance, 40.0, 0.0001)
	enemy.push_along_path(-500.0)
	assert_eq(enemy.path_distance, 0.0)
	var boss := _armoured_enemy(0.0, ["BOSS"])
	boss.set_path_distance(100.0)
	boss.push_along_path(-60.0)
	assert_almost_eq(boss.path_distance, 70.0, 0.0001)


func test_predict_position_follows_path_at_current_speed() -> void:
	var enemy := _armoured_enemy(0.0)
	enemy.set_path_distance(100.0)
	assert_almost_eq(enemy.predict_position(1.5).x, 250.0, 0.001)
	enemy.apply_status(StatusEffect.stun(5.0))
	assert_almost_eq(enemy.predict_position(1.5).x, 100.0, 0.001)


func test_strip_trait() -> void:
	var enemy := _armoured_enemy(0.0, ["SHIELDED", "MECHANICAL"])
	assert_true(enemy.strip_trait("SHIELDED"))
	assert_false(enemy.strip_trait("SHIELDED"))
	assert_eq(enemy.traits, ["MECHANICAL"] as Array[String])


func test_enemy_is_inactive_until_spawned() -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100, 0))
	var enemy := PathEnemy.new()
	add_child_autofree(enemy)
	assert_true(enemy.configure(DEFINITION, curve, 2.0))
	assert_false(enemy.is_active())
	enemy._process(1.99)
	assert_false(enemy.is_active())
	enemy._process(0.02)
	assert_true(enemy.is_active())


func _corner_enemy() -> PathEnemy:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100, 0))
	curve.add_point(Vector2(100, 100))
	var enemy := PathEnemy.new()
	add_child_autofree(enemy)
	assert_true(enemy.configure(DEFINITION, curve))
	return enemy


func test_faces_along_the_path() -> void:
	var enemy := _corner_enemy()
	assert_almost_eq(enemy.rotation, 0.0, 0.01, "starts facing along the first leg")
	enemy._process(1.5)
	assert_almost_eq(enemy.rotation, PI / 2.0, 0.01, "turned onto the second leg")


func test_turns_smoothly_rather_than_snapping() -> void:
	var enemy := _corner_enemy()
	enemy.set_path_distance(150.0)
	enemy._process(0.01)
	assert_between(enemy.rotation, 0.01, PI / 2.0 - 0.01)


func test_health_bar_stays_upright_above_the_enemy() -> void:
	var enemy := _corner_enemy()
	enemy._process(1.5)
	var bar := enemy.get_node("HealthBar") as Node2D
	assert_almost_eq(bar.global_rotation, 0.0, 0.001)
	var offset: Vector2 = bar.global_position - enemy.global_position
	assert_almost_eq(offset.x, 0.0, 0.01)
	assert_almost_eq(offset.y, PathEnemy.HEALTH_BAR_OFFSET, 0.01)


func test_reads_bounty_and_rejects_negative_bounty() -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100, 0))
	var rich := PathEnemy.new()
	add_child_autofree(rich)
	var definition: Dictionary = {"stats": {"health": 10, "move_speed": 1.0, "bounty": 18}}
	assert_true(rich.configure(definition, curve))
	assert_eq(rich.bounty, 18)
	var bad := PathEnemy.new()
	add_child_autofree(bad)
	var negative: Dictionary = {"stats": {"health": 10, "move_speed": 1.0, "bounty": -1}}
	assert_false(bad.configure(negative, curve))
	assert_push_error("bounty")


func _shielded_enemy(shield: float, armour: float = 0.0) -> PathEnemy:
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(1000, 0))
	var enemy := PathEnemy.new()
	add_child_autofree(enemy)
	var stats: Dictionary = {
		"health": 100, "move_speed": 100.0, "armour": armour, "shield": shield
	}
	assert_true(enemy.configure({"stats": stats}, curve))
	return enemy


func test_shield_absorbs_damage_before_health() -> void:
	var enemy := _shielded_enemy(20.0)
	enemy.apply_damage(15.0)
	assert_almost_eq(enemy.shield, 5.0, 0.0001)
	assert_eq(enemy.health, 100.0)
	enemy.apply_damage(15.0)
	assert_eq(enemy.shield, 0.0)
	assert_almost_eq(enemy.health, 90.0, 0.0001, "overflow reaches health")


func test_armour_only_reduces_damage_that_gets_past_the_shield() -> void:
	var enemy := _shielded_enemy(20.0, 3.0)
	enemy.apply_damage(30.0)
	assert_eq(enemy.shield, 0.0, "shield takes the full 20")
	assert_almost_eq(enemy.health, 100.0 - 10.0 * 0.7, 0.0001, "armour cuts the other 10")


func test_strip_shield() -> void:
	var enemy := _shielded_enemy(40.0)
	assert_eq(enemy.strip_shield(), 40.0)
	assert_eq(enemy.shield, 0.0)
	enemy.apply_damage(10.0)
	assert_almost_eq(enemy.health, 90.0, 0.0001)


func test_shield_defaults_to_zero_and_rejects_negative() -> void:
	var enemy := _armoured_enemy(0.0)
	assert_eq(enemy.shield, 0.0)
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100, 0))
	var bad := PathEnemy.new()
	add_child_autofree(bad)
	assert_false(bad.configure({"stats": {"health": 10, "move_speed": 1.0, "shield": -5}}, curve))
	assert_push_error("shield")


func test_stasis_damage_is_released_through_the_shield() -> void:
	var enemy := _shielded_enemy(20.0)
	enemy.apply_status(StatusEffect.stasis(1.0))
	enemy.apply_damage(30.0)
	assert_eq(enemy.shield, 20.0, "stored, not applied, during stasis")
	enemy._process(1.0)
	assert_eq(enemy.shield, 0.0)
	assert_almost_eq(enemy.health, 90.0, 0.0001)
