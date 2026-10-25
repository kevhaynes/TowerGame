extends RefCounted
class_name CombatFixture

## Test helper: a straight path along the x axis from (0, 0) to (PATH_LENGTH, 0),
## enemies placed by path distance (so an enemy at distance d sits at (d, 0)),
## and towers built from their shipped JSON with projectiles landing instantly.

const PATH_LENGTH: float = 1500.0
const ENEMY_HEALTH: float = 1000.0
const ENEMY_SPEED: float = 75.0
const TOWERS_PATH: String = "res://data/towers/%s.json"

var curve: Curve2D

var _test: GutTest
var _enemies: Array[PathEnemy] = []


func _init(test: GutTest) -> void:
	_test = test
	curve = Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(PATH_LENGTH, 0))


func enemy(
	path_distance: float, traits: Array = [], stat_overrides: Dictionary = {}
) -> PathEnemy:
	var spawned := PathEnemy.new()
	_test.add_child_autofree(spawned)
	var stats: Dictionary = {"health": ENEMY_HEALTH, "move_speed": ENEMY_SPEED}
	stats.merge(stat_overrides, true)
	_test.assert_true(spawned.configure({"stats": stats, "traits": traits}, curve))
	spawned.set_path_distance(path_distance)
	spawned.previous_path_distance = path_distance
	_enemies.append(spawned)
	return spawned


func definition(tower_id: String, stat_overrides: Dictionary = {}) -> Dictionary:
	var loaded: Dictionary = LevelCatalog.read_json_object(TOWERS_PATH % tower_id)
	(loaded["stats"] as Dictionary).merge(stat_overrides, true)
	return loaded


## Builds the tower from data/towers/<tower_id>.json and places it at [param at].
func tower(tower_id: String, at: Vector2, stat_overrides: Dictionary = {}) -> BaseTower:
	var tower_definition: Dictionary = definition(tower_id, stat_overrides)
	var behaviour: Script = load(str(tower_definition["behaviour"]))
	var built: BaseTower = behaviour.new()
	built.path_curve = curve
	_test.assert_true(built.configure(tower_definition, null), "configure %s" % tower_id)
	_test.add_child_autofree(built)
	built.global_position = at
	return built


func damage_taken(target: PathEnemy) -> float:
	return ENEMY_HEALTH - target.health


## Call from after_each: stops freed-later enemies leaking into the next test.
func cleanup() -> void:
	for spawned: PathEnemy in _enemies:
		if is_instance_valid(spawned) and spawned.is_in_group(PathEnemy.ENEMY_GROUP):
			spawned.remove_from_group(PathEnemy.ENEMY_GROUP)
