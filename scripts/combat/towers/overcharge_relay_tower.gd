extends BaseTower
class_name OverchargeRelayTower

## Support: while active, every other tower within range (except other
## relays) gets bonus damage and fire rate. It then overheats and gives no
## buff for cooldown_duration. Buffs from several relays do not stack.

const ACTIVE_COLOR: Color = Color(1.0, 0.8, 0.3, 0.35)
const OVERHEAT_COLOR: Color = Color(1.0, 0.25, 0.15, 0.35)
const RING_WIDTH: float = 4.5

var _damage_bonus: float = 0.0
var _fire_rate_bonus: float = 0.0
var _active_duration: float = 0.0
var _cooldown_duration: float = 0.0
var _cycle: OverchargeCycle


func _read_stats(stats: StatReader) -> void:
	_damage_bonus = stats.positive("damage_bonus")
	_fire_rate_bonus = stats.positive("fire_rate_bonus")
	_active_duration = stats.positive("active_duration")
	_cooldown_duration = stats.positive("cooldown_duration")


func _on_configured() -> void:
	_cycle = OverchargeCycle.new(_active_duration, _cooldown_duration)


func is_active() -> bool:
	return _cycle != null and _cycle.is_active()


func _process(delta: float) -> void:
	_cycle.advance(delta)
	update_buffs()
	queue_redraw()


func update_buffs() -> void:
	var source_id: int = get_instance_id()
	for node: Node in get_tree().get_nodes_in_group(TOWER_GROUP):
		if node == self or node is OverchargeRelayTower or not node is BaseTower:
			continue
		var tower := node as BaseTower
		var in_range: bool = (
			global_position.distance_to(tower.global_position) <= attack_range
		)
		if in_range and is_active():
			tower.set_buff(source_id, _damage_bonus, _fire_rate_bonus)
		else:
			tower.clear_buff(source_id)


func _draw() -> void:
	var colour: Color = ACTIVE_COLOR if is_active() else OVERHEAT_COLOR
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, colour, RING_WIDTH)
