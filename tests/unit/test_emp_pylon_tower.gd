extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_pulse_stuns_mechanical_and_strips_shields() -> void:
	var tower := _fx.tower("emp_pylon", Vector2(150, 150)) as EmpPylonTower
	var machine := _fx.enemy(150, ["MECHANICAL", "SHIELDED"])
	var organic := _fx.enemy(225, ["ORGANIC"])
	var far := _fx.enemy(600, ["MECHANICAL"])
	tower.pulse()
	assert_true(machine.statuses.has(StatusEffect.Type.STUN))
	assert_false(machine.traits.has("SHIELDED"))
	assert_almost_eq(_fx.damage_taken(machine), 5.0 * TraitAffinity.STRONG_MULTIPLIER, 0.001)
	assert_false(organic.statuses.has(StatusEffect.Type.STUN))
	assert_almost_eq(_fx.damage_taken(organic), 5.0 * TraitAffinity.WEAK_MULTIPLIER, 0.001)
	assert_false(far.statuses.has(StatusEffect.Type.STUN))


func test_pulses_only_when_an_enemy_is_in_range() -> void:
	var tower := _fx.tower("emp_pylon", Vector2(150, 150))
	var far := _fx.enemy(900)
	tower._process(0.0)
	assert_eq(_fx.damage_taken(far), 0.0)


func test_pulse_strips_shield_points_before_its_damage() -> void:
	var tower := _fx.tower("emp_pylon", Vector2(150, 150)) as EmpPylonTower
	var shielded := _fx.enemy(150, [], {"shield": 50})
	tower.pulse()
	assert_eq(shielded.shield, 0.0)
	assert_almost_eq(_fx.damage_taken(shielded), 5.0, 0.001, "pulse damage hits health")
