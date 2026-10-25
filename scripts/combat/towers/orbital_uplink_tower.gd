extends BaseTower
class_name OrbitalUplinkTower

## Paints the first enemy and calls down a kinetic strike after strike_delay.
## The strike follows the painted enemy while it lives, then lands on its last
## known position, hitting everything within strike_radius.

const RETICLE_COLOR: Color = Color(1.0, 0.3, 0.25, 0.9)
const RETICLE_WIDTH: float = 3.0
const RETICLE_MIN_RADIUS: float = 12.0
const PAINT_WIDTH: float = 1.5
const PAINT_COLOR: Color = Color(1.0, 0.3, 0.25, 0.5)
const STRIKE_COLOR: Color = Color(1.0, 0.85, 0.5, 1.0)

var _damage: float = 0.0
var _fire_rate: float = 0.0
var _strike_delay: float = 0.0
var _strike_radius: float = 0.0
var _splash_edge_factor: float = 0.0
## Pending strikes: { "target": PathEnemy or null, "point": Vector2, "time": float }.
var _strikes: Array[Dictionary] = []


func _read_stats(stats: StatReader) -> void:
	_damage = stats.positive("damage")
	_fire_rate = stats.positive("fire_rate")
	_strike_delay = stats.positive("strike_delay")
	_strike_radius = stats.positive("strike_radius")
	_splash_edge_factor = stats.fraction("splash_edge_factor")


func _process(delta: float) -> void:
	advance_strikes(delta)
	if not tick_cooldown(delta):
		return
	var target := find_first_target()
	if target == null:
		return
	paint(target)
	start_cooldown(_fire_rate)


func paint(target: PathEnemy) -> void:
	aim_at(target.global_position)
	_strikes.append({"target": target, "point": target.global_position, "time": _strike_delay})


func get_pending_strike_count() -> int:
	return _strikes.size()


func advance_strikes(delta: float) -> void:
	var pending: Array[Dictionary] = []
	for strike: Dictionary in _strikes:
		var target: Variant = strike["target"]
		if is_instance_valid(target) and (target as PathEnemy).is_active():
			strike["point"] = (target as PathEnemy).global_position
		else:
			strike["target"] = null
		strike["time"] = float(strike["time"]) - delta
		if float(strike["time"]) <= 0.0:
			spawn_blast(strike["point"], _strike_radius, STRIKE_COLOR)
			deal_splash(strike["point"], _strike_radius, _damage, _splash_edge_factor)
		else:
			pending.append(strike)
	_strikes = pending
	queue_redraw()


func _draw() -> void:
	for strike: Dictionary in _strikes:
		var point: Vector2 = to_local(strike["point"])
		var progress: float = 1.0 - float(strike["time"]) / _strike_delay
		draw_line(Vector2.ZERO, point, PAINT_COLOR, PAINT_WIDTH)
		draw_arc(
			point,
			lerpf(_strike_radius, RETICLE_MIN_RADIUS, progress),
			0.0,
			TAU,
			32,
			RETICLE_COLOR,
			RETICLE_WIDTH
		)
