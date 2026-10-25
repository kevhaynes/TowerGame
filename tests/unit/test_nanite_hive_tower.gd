extends GutTest

const SOURCE: String = NaniteHiveTower.NANITE_SOURCE

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func _is_infected(enemy: PathEnemy) -> bool:
	return enemy.statuses.get_effect(StatusEffect.Type.DOT, SOURCE) != null


func test_cloud_applies_dot_and_shred() -> void:
	var tower := _fx.tower("nanite_hive", Vector2(150, 150))
	var target := _fx.enemy(225, [], {"armour": 3})
	tower._process(0.0)
	assert_true(_is_infected(target))
	assert_eq(target.statuses.get_armour_shred(), 1.0)
	target._process(1.0)
	assert_almost_eq(
		_fx.damage_taken(target), 5.0 * CombatMath.armour_multiplier(2.0), 0.001
	)


func test_shred_stacks_to_its_cap() -> void:
	var tower := _fx.tower("nanite_hive", Vector2(150, 150)) as NaniteHiveTower
	var target := _fx.enemy(225)
	for _i: int in 5:
		tower.infect(target, 0)
	assert_eq(target.statuses.get_armour_shred(), 3.0)


func test_infection_spreads_one_ring_per_interval_for_its_generations() -> void:
	var tower := _fx.tower("nanite_hive", Vector2(150, 150)) as NaniteHiveTower
	var patient_zero := _fx.enemy(150)
	var neighbour := _fx.enemy(255)
	var next := _fx.enemy(360)
	var last := _fx.enemy(465)
	var far := _fx.enemy(900)
	tower.infect(patient_zero, 2)

	assert_eq(tower.spread_infections(), 1)
	assert_true(_is_infected(neighbour))
	assert_false(_is_infected(next), "spreads one ring per interval")
	assert_eq(tower.spread_infections(), 1)
	assert_true(_is_infected(next))
	assert_eq(tower.spread_infections(), 0, "generations are used up")
	assert_false(_is_infected(last))
	assert_false(_is_infected(far))
