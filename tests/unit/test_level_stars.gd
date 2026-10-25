extends GutTest


func test_full_health_earns_three_stars() -> void:
	assert_eq(LevelStars.for_health(20.0, 20.0), 3)


func test_any_damage_drops_to_two_stars() -> void:
	assert_eq(LevelStars.for_health(19.0, 20.0), 2)


func test_exactly_half_health_earns_two_stars() -> void:
	assert_eq(LevelStars.for_health(10.0, 20.0), 2)


func test_below_half_health_earns_one_star() -> void:
	assert_eq(LevelStars.for_health(9.0, 20.0), 1)
	assert_eq(LevelStars.for_health(0.5, 20.0), 1)


func test_no_health_earns_no_stars() -> void:
	assert_eq(LevelStars.for_health(0.0, 20.0), 0)
	assert_eq(LevelStars.for_health(-3.0, 20.0), 0)
	assert_eq(LevelStars.for_health(5.0, 0.0), 0)
