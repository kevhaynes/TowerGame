extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_deploys_drones_that_engage_enemies_in_the_zone() -> void:
	var tower := _fx.tower("drone_bay", Vector2(150, 150)) as DroneBayTower
	var target := _fx.enemy(150)
	tower._process(0.0)
	assert_eq(tower.get_drones().size(), 2)
	assert_almost_eq(_fx.damage_taken(target), 10.0, 0.001, "both drones fire")


func test_drones_stay_inside_the_patrol_zone() -> void:
	var tower := _fx.tower("drone_bay", Vector2(150, 150)) as DroneBayTower
	_fx.enemy(285)
	for _i: int in 60:
		tower._process(0.1)
	for drone: CombatDrone in tower.get_drones():
		assert_lte(drone.global_position.distance_to(tower.global_position), 210.01)


func test_drones_ignore_enemies_outside_the_zone() -> void:
	var tower := _fx.tower("drone_bay", Vector2(150, 150)) as DroneBayTower
	var far := _fx.enemy(900)
	for _i: int in 20:
		tower._process(0.1)
	assert_eq(_fx.damage_taken(far), 0.0)
