extends GutTest


func test_armour_reduces_ten_percent_per_point_up_to_cap() -> void:
	assert_almost_eq(CombatMath.armour_multiplier(0.0), 1.0, 0.0001)
	assert_almost_eq(CombatMath.armour_multiplier(3.0), 0.7, 0.0001)
	assert_almost_eq(CombatMath.armour_multiplier(20.0), 0.25, 0.0001)
	assert_almost_eq(CombatMath.armour_multiplier(-2.0), 1.0, 0.0001)


func test_splash_falloff() -> void:
	assert_almost_eq(CombatMath.splash_falloff(0.0, 70.0, 0.5), 1.0, 0.0001)
	assert_almost_eq(CombatMath.splash_falloff(35.0, 70.0, 0.5), 0.75, 0.0001)
	assert_almost_eq(CombatMath.splash_falloff(70.0, 70.0, 0.5), 0.5, 0.0001)
	assert_eq(CombatMath.splash_falloff(71.0, 70.0, 0.5), 0.0)


func test_chain_damage_falls_off_per_hop() -> void:
	assert_almost_eq(CombatMath.chain_damage(14.0, 0.75, 0), 14.0, 0.0001)
	assert_almost_eq(CombatMath.chain_damage(14.0, 0.75, 2), 7.875, 0.0001)


func test_graviton_direction() -> void:
	assert_eq(CombatMath.graviton_direction(100.0, 95.0, 105.0), 1)
	assert_eq(CombatMath.graviton_direction(100.0, 105.0, 95.0), -1)
	assert_eq(CombatMath.graviton_direction(100.0, 100.2, 100.3), 0)


func test_step_within_zone_moves_and_clamps() -> void:
	var moved := CombatMath.step_within_zone(Vector2.ZERO, Vector2(100, 0), 10.0, Vector2.ZERO, 50)
	assert_eq(moved, Vector2(10, 0))
	var clamped := CombatMath.step_within_zone(
		Vector2(45, 0), Vector2(100, 0), 20.0, Vector2.ZERO, 50
	)
	assert_almost_eq(clamped.x, 50.0, 0.0001)
