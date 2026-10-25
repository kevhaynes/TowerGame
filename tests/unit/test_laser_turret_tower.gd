extends GutTest

const DEFINITION_PATH: String = "res://data/towers/laser_turret.json"
const ENEMY_HEALTH: float = 1000.0
const TOWER_STATS: Dictionary = {
	"base_dps": 10.0,
	"ramp_rate": 0.5,
	"max_ramp_multiplier": 3.0,
	"range": 200.0,
}

var _curve: Curve2D
var _enemies: Array[PathEnemy] = []


func before_each() -> void:
	_curve = Curve2D.new()
	_curve.add_point(Vector2.ZERO)
	_curve.add_point(Vector2(1000, 0))
	_enemies.clear()


func after_each() -> void:
	for enemy: PathEnemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_in_group(PathEnemy.ENEMY_GROUP):
			enemy.remove_from_group(PathEnemy.ENEMY_GROUP)


func _definition(stats_override: Dictionary = {}) -> Dictionary:
	var stats: Dictionary = TOWER_STATS.duplicate()
	stats.merge(stats_override, true)
	return {
		"strong_against_trait": ["ARMOURED"],
		"weak_against_trait": ["SHIELDED"],
		"stats": stats,
	}


func _add_tower() -> LaserTurretTower:
	var tower := LaserTurretTower.new()
	assert_true(tower.configure(_definition(), null))
	add_child_autofree(tower)
	return tower


func _add_enemy(at: Vector2, path_distance: float, traits: Array = []) -> PathEnemy:
	var enemy := PathEnemy.new()
	add_child_autofree(enemy)
	var definition: Dictionary = {
		"stats": {"health": ENEMY_HEALTH, "move_speed": 1.0}, "traits": traits
	}
	assert_true(enemy.configure(definition, _curve))
	enemy.position = at
	enemy.path_distance = path_distance
	_enemies.append(enemy)
	return enemy


func _damage_taken(enemy: PathEnemy) -> float:
	return ENEMY_HEALTH - enemy.health


func test_configures_from_shipped_definition() -> void:
	var definition: Dictionary = LevelCatalog.read_json_object(DEFINITION_PATH)
	var tower: LaserTurretTower = autofree(LaserTurretTower.new())
	assert_true(tower.configure(definition, null))


func test_rejects_missing_non_numeric_or_non_positive_stats() -> void:
	var tower: LaserTurretTower = autofree(LaserTurretTower.new())
	var missing: Dictionary = _definition()
	(missing["stats"] as Dictionary).erase("base_dps")
	assert_false(tower.configure(missing, null))
	assert_false(tower.configure(_definition({"ramp_rate": "fast"}), null))
	assert_false(tower.configure(_definition({"range": -1.0}), null))
	assert_push_error_count(3)


func test_rejects_max_multiplier_below_one() -> void:
	var tower: LaserTurretTower = autofree(LaserTurretTower.new())
	assert_false(tower.configure(_definition({"max_ramp_multiplier": 0.5}), null))
	assert_push_error("max_ramp_multiplier")


func test_rejects_bad_trait_list() -> void:
	var tower: LaserTurretTower = autofree(LaserTurretTower.new())
	var definition: Dictionary = _definition()
	definition["weak_against_trait"] = ["SQUISHY"]
	assert_false(tower.configure(definition, null))
	assert_push_error("unknown trait")


func test_targets_first_enemy_in_range() -> void:
	var tower := _add_tower()
	_add_enemy(Vector2(100, 0), 10.0)
	var leader := _add_enemy(Vector2(0, 100), 30.0)
	_add_enemy(Vector2(600, 0), 90.0)
	tower._process(0.1)
	assert_eq(tower.get_target(), leader)


func test_keeps_lock_when_another_enemy_overtakes() -> void:
	var tower := _add_tower()
	var locked := _add_enemy(Vector2(100, 0), 30.0)
	var overtaker := _add_enemy(Vector2(0, 100), 10.0)
	tower._process(0.1)
	overtaker.path_distance = 50.0
	tower._process(0.1)
	assert_eq(tower.get_target(), locked)


func test_damage_ramps_on_same_target() -> void:
	var tower := _add_tower()
	var enemy := _add_enemy(Vector2(100, 0), 10.0, ["ORGANIC"])
	tower._process(1.0)
	assert_almost_eq(_damage_taken(enemy), 12.5, 0.001)
	tower._process(1.0)
	assert_almost_eq(_damage_taken(enemy), 30.0, 0.001)


func test_strong_trait_takes_bonus_damage() -> void:
	var tower := _add_tower()
	var enemy := _add_enemy(Vector2(100, 0), 10.0, ["MECHANICAL", "ARMOURED"])
	tower._process(1.0)
	assert_almost_eq(_damage_taken(enemy), 12.5 * TraitAffinity.STRONG_MULTIPLIER, 0.001)


func test_weak_trait_takes_reduced_damage() -> void:
	var tower := _add_tower()
	var enemy := _add_enemy(Vector2(100, 0), 10.0, ["SHIELDED"])
	tower._process(1.0)
	assert_almost_eq(_damage_taken(enemy), 12.5 * TraitAffinity.WEAK_MULTIPLIER, 0.001)


func test_ramp_resets_when_target_leaves_range() -> void:
	var tower := _add_tower()
	var first := _add_enemy(Vector2(100, 0), 30.0)
	var second := _add_enemy(Vector2(0, 100), 10.0)
	tower._process(3.0)
	first.position = Vector2(600, 0)
	tower._process(1.0)
	assert_eq(tower.get_target(), second)
	assert_almost_eq(_damage_taken(second), 12.5, 0.001)


func test_retargets_after_kill_at_base_damage() -> void:
	var tower := _add_tower()
	var doomed := _add_enemy(Vector2(100, 0), 30.0)
	var next := _add_enemy(Vector2(0, 100), 10.0)
	tower._process(2.0)
	doomed.apply_damage(ENEMY_HEALTH)
	tower._process(1.0)
	assert_eq(tower.get_target(), next)
	assert_almost_eq(_damage_taken(next), 12.5, 0.001)


func test_idle_without_enemies_in_range() -> void:
	var tower := _add_tower()
	var far := _add_enemy(Vector2(600, 0), 10.0)
	tower._process(1.0)
	assert_null(tower.get_target())
	assert_eq(_damage_taken(far), 0.0)
