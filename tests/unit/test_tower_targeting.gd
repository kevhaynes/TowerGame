extends GutTest

const ENEMY_DEFINITION: Dictionary = {"stats": {"health": 10, "move_speed": 1.0}, "traits": []}
const RANGE: float = 100.0

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


func _add_enemy(at: Vector2, path_distance: float) -> PathEnemy:
	var enemy := PathEnemy.new()
	add_child_autofree(enemy)
	assert_true(enemy.configure(ENEMY_DEFINITION, _curve))
	enemy.position = at
	enemy.path_distance = path_distance
	_enemies.append(enemy)
	return enemy


func _candidates() -> Array[Node]:
	var nodes: Array[Node] = []
	nodes.assign(_enemies)
	return nodes


func test_picks_enemy_furthest_along_path() -> void:
	_add_enemy(Vector2(50, 0), 10.0)
	var leader := _add_enemy(Vector2(0, 50), 40.0)
	assert_eq(TowerTargeting.find_first(_candidates(), Vector2.ZERO, RANGE), leader)


func test_ignores_out_of_range_enemies() -> void:
	var near := _add_enemy(Vector2(60, 0), 5.0)
	_add_enemy(Vector2(500, 0), 90.0)
	assert_eq(TowerTargeting.find_first(_candidates(), Vector2.ZERO, RANGE), near)


func test_range_edge_is_inclusive() -> void:
	var edge := _add_enemy(Vector2(RANGE, 0), 1.0)
	assert_true(TowerTargeting.is_valid_target(edge, Vector2.ZERO, RANGE))


func test_ignores_dead_enemies() -> void:
	var dead := _add_enemy(Vector2(10, 0), 90.0)
	var alive := _add_enemy(Vector2(20, 0), 5.0)
	dead.apply_damage(100.0)
	assert_false(TowerTargeting.is_valid_target(dead, Vector2.ZERO, RANGE))
	assert_eq(TowerTargeting.find_first(_candidates(), Vector2.ZERO, RANGE), alive)


func test_returns_null_without_targets() -> void:
	_add_enemy(Vector2(500, 0), 1.0)
	assert_null(TowerTargeting.find_first(_candidates(), Vector2.ZERO, RANGE))


func test_find_ordered_sorts_by_path_progress() -> void:
	var middle := _add_enemy(Vector2(10, 0), 20.0)
	var front := _add_enemy(Vector2(20, 0), 30.0)
	var back := _add_enemy(Vector2(30, 0), 10.0)
	var ordered := TowerTargeting.find_ordered(_candidates(), Vector2.ZERO, RANGE)
	assert_eq(ordered, [front, middle, back] as Array[PathEnemy])


func test_min_range_creates_blind_spot() -> void:
	_add_enemy(Vector2(10, 0), 90.0)
	var far := _add_enemy(Vector2(80, 0), 5.0)
	assert_eq(TowerTargeting.find_first(_candidates(), Vector2.ZERO, RANGE, 50.0), far)


func test_ignores_enemies_still_waiting_to_spawn() -> void:
	var waiting := PathEnemy.new()
	add_child_autofree(waiting)
	assert_true(waiting.configure(ENEMY_DEFINITION, _curve, 5.0))
	_enemies.append(waiting)
	assert_null(TowerTargeting.find_first(_candidates(), Vector2.ZERO, RANGE))


func test_enemies_on_line() -> void:
	var on_line := _add_enemy(Vector2(50, 5), 1.0)
	_add_enemy(Vector2(50, 40), 1.0)
	_add_enemy(Vector2(-20, 0), 1.0)
	var hit := TowerTargeting.enemies_on_line(_candidates(), Vector2.ZERO, Vector2.RIGHT, 100, 10)
	assert_eq(hit, [on_line] as Array[PathEnemy])


func test_enemies_in_cone() -> void:
	var ahead := _add_enemy(Vector2(50, 10), 1.0)
	_add_enemy(Vector2(0, 50), 1.0)
	var hit := TowerTargeting.enemies_in_cone(
		_candidates(), Vector2.ZERO, 0.0, deg_to_rad(20.0), RANGE
	)
	assert_eq(hit, [ahead] as Array[PathEnemy])


func test_build_chain_jumps_to_nearest_unhit() -> void:
	var first := _add_enemy(Vector2(0, 0), 1.0)
	var second := _add_enemy(Vector2(40, 0), 1.0)
	var third := _add_enemy(Vector2(90, 0), 1.0)
	_add_enemy(Vector2(300, 0), 1.0)
	var chain := TowerTargeting.build_chain(first, _candidates(), 4, 60.0)
	assert_eq(chain, [first, second, third] as Array[PathEnemy])
