extends GutTest

var _fx: CombatFixture


func before_each() -> void:
	_fx = CombatFixture.new(self)


func after_each() -> void:
	_fx.cleanup()


func test_buffs_adjacent_towers_while_active() -> void:
	var relay := _fx.tower("overcharge_relay", Vector2(0, 150)) as OverchargeRelayTower
	var near := _fx.tower("machine_gun", Vector2(150, 150))
	var far := _fx.tower("machine_gun", Vector2(600, 150))
	relay._process(0.1)
	assert_almost_eq(near.get_damage_multiplier(), 1.25, 0.0001)
	assert_almost_eq(near.get_fire_rate_multiplier(), 1.25, 0.0001)
	assert_eq(far.get_damage_multiplier(), 1.0)


func test_buff_clears_while_overheated() -> void:
	var relay := _fx.tower("overcharge_relay", Vector2(0, 150)) as OverchargeRelayTower
	var near := _fx.tower("machine_gun", Vector2(150, 150))
	relay._process(8.5)
	assert_false(relay.is_active())
	assert_eq(near.get_damage_multiplier(), 1.0)


func test_relays_do_not_stack_or_buff_each_other() -> void:
	var relay := _fx.tower("overcharge_relay", Vector2(0, 150)) as OverchargeRelayTower
	var other := _fx.tower("overcharge_relay", Vector2(75, 150)) as OverchargeRelayTower
	var near := _fx.tower("machine_gun", Vector2(150, 150))
	relay._process(0.1)
	other._process(0.1)
	assert_almost_eq(near.get_damage_multiplier(), 1.25, 0.0001)
	assert_eq(other.get_damage_multiplier(), 1.0)


func test_buffed_tower_deals_more_damage() -> void:
	var relay := _fx.tower("overcharge_relay", Vector2(0, 150)) as OverchargeRelayTower
	var gun := _fx.tower("machine_gun", Vector2(150, 150))
	var target := _fx.enemy(225)
	relay._process(0.1)
	gun._process(0.0)
	assert_almost_eq(_fx.damage_taken(target), 6.0 * 1.25, 0.001)


func test_removing_a_relay_clears_its_buffs() -> void:
	var relay := _fx.tower("overcharge_relay", Vector2(0, 150)) as OverchargeRelayTower
	var near := _fx.tower("machine_gun", Vector2(150, 150))
	relay._process(0.1)
	relay.get_parent().remove_child(relay)
	relay.free()
	assert_eq(near.get_damage_multiplier(), 1.0)
	assert_eq(near.get_fire_rate_multiplier(), 1.0)
