extends Sprite2D
class_name PathEnemy

signal killed(enemy: PathEnemy)
signal escaped(enemy: PathEnemy)

const ENEMY_GROUP: StringName = &"enemies"
const HEALTH_BAR_SCRIPT: Script = preload("res://scripts/combat/enemy_health_bar.gd")
const BOSS_TRAIT: String = "BOSS"
const DEFAULT_BASE_DAMAGE: float = 1.0
const HEALTH_BAR_OFFSET: float = -63.0
## How quickly the enemy turns to follow the path (exponential smoothing per
## second), so it eases round corners instead of snapping at each path point.
const TURN_RATE: float = 12.0

const STASIS_TINT: Color = Color(0.7, 0.95, 1.0)
const STUN_TINT: Color = Color(1.0, 0.95, 0.45)
const PHASED_TINT: Color = Color(0.85, 0.55, 1.0, 0.6)
const SLOW_TINT: Color = Color(0.55, 0.75, 1.0)
const DOT_TINT: Color = Color(1.0, 0.7, 0.45)

var path_distance: float = 0.0
## Path distance at the start of the current frame, before this frame's move.
var previous_path_distance: float = 0.0
var health: float = 0.0
var armour: float = 0.0
## Shield points absorb damage before health and are not reduced by armour.
## EMP pulses strip them to 0; they do not regenerate.
var shield: float = 0.0
## Damage this enemy does when it escapes or pushes against a barrier.
var base_damage: float = DEFAULT_BASE_DAMAGE
## Credits the player earns for killing this enemy.
var bounty: int = 0
var traits: Array[String] = []
var statuses: StatusEffects = StatusEffects.new()

var _max_health: float = 0.0
var _max_shield: float = 0.0
var _health_bar: Node2D
var _move_speed: float = 0.0
var _path_curve: Curve2D
var _path_length: float = 0.0
var _spawn_delay: float = 0.0
var _is_configured: bool = false
var _is_resolved: bool = false


func configure(
	definition: Dictionary, path_curve: Curve2D, spawn_delay_seconds: float = 0.0
) -> bool:
	var stats: Variant = definition.get("stats", {})
	if not stats is Dictionary:
		push_error("Enemy definition stats must be a JSON object.")
		return false

	var health_value: Variant = stats.get("health")
	var speed_value: Variant = stats.get("move_speed")
	var armour_value: Variant = stats.get("armour", 0.0)
	var shield_value: Variant = stats.get("shield", 0.0)
	var base_damage_value: Variant = stats.get("base_damage", DEFAULT_BASE_DAMAGE)
	var bounty_value: Variant = stats.get("bounty", 0)
	var traits_value: Variant = definition.get("traits", [])
	if not traits_value is Array:
		push_error("Enemy definition traits must be a JSON array.")
		return false
	if not _is_number(health_value) or not _is_number(speed_value):
		push_error("Enemy definition requires numeric health and move_speed stats.")
		return false
	if float(health_value) <= 0.0 or float(speed_value) <= 0.0:
		push_error("Enemy health and move_speed must be positive.")
		return false
	if not _is_number(armour_value) or float(armour_value) < 0.0:
		push_error("Enemy armour must be a number of at least 0.")
		return false
	if not _is_number(shield_value) or float(shield_value) < 0.0:
		push_error("Enemy shield must be a number of at least 0.")
		return false
	if not _is_number(base_damage_value) or float(base_damage_value) < 0.0:
		push_error("Enemy base_damage must be a number of at least 0.")
		return false
	if not _is_number(bounty_value) or float(bounty_value) < 0.0:
		push_error("Enemy bounty must be a number of at least 0.")
		return false
	if path_curve.get_baked_length() <= 0.0:
		push_error("Enemy cannot follow an empty or zero-length path.")
		return false

	health = float(health_value)
	_max_health = health
	armour = float(armour_value)
	shield = float(shield_value)
	_max_shield = shield
	base_damage = float(base_damage_value)
	bounty = int(bounty_value)
	traits.clear()
	for trait_value: Variant in traits_value:
		if not trait_value is String:
			push_error("Enemy definition traits must contain only strings.")
			return false
		traits.append(trait_value)
	_move_speed = float(speed_value)
	_path_curve = path_curve
	_path_length = path_curve.get_baked_length()
	_spawn_delay = maxf(spawn_delay_seconds, 0.0)
	position = _path_curve.sample_baked(path_distance)
	_health_bar = HEALTH_BAR_SCRIPT.new()
	_health_bar.name = "HealthBar"
	add_child(_health_bar)
	_health_bar.call("set_health_ratio", 1.0)
	_update_shield_bar()
	face_path(1.0)
	visible = _spawn_delay <= 0.0
	_is_configured = true
	add_to_group(ENEMY_GROUP)
	return true


func _process(delta: float) -> void:
	if not _is_configured or _is_resolved:
		return

	if _spawn_delay > 0.0:
		_spawn_delay = maxf(_spawn_delay - delta, 0.0)
		if _spawn_delay > 0.0:
			return
		visible = true

	previous_path_distance = path_distance
	var damage_over_time: float = statuses.advance(delta)
	var speed: float = _move_speed * statuses.get_speed_multiplier()
	set_path_distance(path_distance + speed * delta)
	face_path(1.0 - exp(-TURN_RATE * delta))
	_update_tint()

	if damage_over_time > 0.0:
		apply_damage(damage_over_time, false)
	var released: float = statuses.take_released_damage()
	if released > 0.0:
		_absorb_damage(released)
	if _is_resolved:
		return

	if path_distance >= _path_length:
		_resolve()
		escaped.emit(self)


## Applies [param amount] damage, scaled by PHASED and (for direct hits)
## BRITTLE. The shield absorbs it first; what gets through is reduced by armour
## and taken from health. Damage-over-time and continuous beams pass
## [param is_direct_hit] false so they do not consume BRITTLE. During STASIS
## the damage is stored and released through the shield and armour later.
func apply_damage(amount: float, is_direct_hit: bool = true) -> void:
	if amount <= 0.0 or health <= 0.0 or _is_resolved:
		return

	var scaled: float = amount * statuses.get_damage_taken_multiplier()
	if is_direct_hit:
		scaled *= 1.0 + statuses.consume_brittle_bonus()
	if statuses.is_in_stasis():
		statuses.store_damage(scaled)
		return
	_absorb_damage(scaled)


## Removes the whole shield (EMP). Returns the shield points lost.
func strip_shield() -> float:
	var lost: float = shield
	shield = 0.0
	_update_shield_bar()
	return lost


func apply_status(effect: StatusEffect) -> void:
	if _is_resolved:
		return
	statuses.apply(effect, is_boss())
	_update_tint()


## True once the spawn delay has passed and until the enemy is killed or escapes.
func is_active() -> bool:
	return _is_configured and not _is_resolved and _spawn_delay <= 0.0


func is_boss() -> bool:
	return traits.has(BOSS_TRAIT)


## Removes a trait (e.g. an EMP stripping SHIELDED). Returns true if it was present.
func strip_trait(trait_name: String) -> bool:
	if not traits.has(trait_name):
		return false
	traits.erase(trait_name)
	return true


func get_move_speed() -> float:
	return _move_speed


func get_path_length() -> float:
	return _path_length


## Pushes the enemy along its path: negative is backwards (knockback). Bosses
## move [constant StatusEffects.BOSS_CONTROL_FACTOR] as far; enemies in stasis
## do not move.
func push_along_path(distance: float) -> void:
	if not is_active() or statuses.is_in_stasis():
		return
	if is_boss():
		distance *= StatusEffects.BOSS_CONTROL_FACTOR
	set_path_distance(path_distance + distance)


## Turns toward the path direction at the current distance: [param weight] 1
## snaps, smaller values ease. Sprites face +x. Keeps the health bar upright.
func face_path(weight: float) -> void:
	var heading: float = get_path_heading(path_distance)
	rotation = lerp_angle(rotation, heading, clampf(weight, 0.0, 1.0))
	_health_bar.rotation = -rotation
	_health_bar.position = Vector2(0.0, HEALTH_BAR_OFFSET).rotated(-rotation)


## Direction of travel (radians) at [param distance] along the path.
func get_path_heading(distance: float) -> float:
	var clamped: float = clampf(distance, 0.0, _path_length)
	return _path_curve.sample_baked_with_rotation(clamped).get_rotation()


func set_path_distance(distance: float) -> void:
	path_distance = clampf(distance, 0.0, _path_length)
	position = _path_curve.sample_baked(path_distance)


## Global position of the point [param distance] along this enemy's path.
func get_path_point(distance: float) -> Vector2:
	var local_point: Vector2 = _path_curve.sample_baked(clampf(distance, 0.0, _path_length))
	var parent := get_parent() as Node2D
	return parent.to_global(local_point) if parent != null else local_point


## Where the enemy will be after [param seconds] at its current speed.
func predict_position(seconds: float) -> Vector2:
	var speed: float = _move_speed * statuses.get_speed_multiplier()
	return get_path_point(path_distance + speed * maxf(seconds, 0.0))


## Runs scaled damage through the shield, then armour, then health.
func _absorb_damage(amount: float) -> void:
	var absorbed: float = minf(shield, amount)
	if absorbed > 0.0:
		shield -= absorbed
		_update_shield_bar()
	var through: float = amount - absorbed
	if through <= 0.0:
		return
	var effective_armour: float = maxf(armour - statuses.get_armour_shred(), 0.0)
	_take_damage(through * CombatMath.armour_multiplier(effective_armour))


func _update_shield_bar() -> void:
	var ratio: float = shield / _max_shield if _max_shield > 0.0 else 0.0
	_health_bar.call("set_shield_ratio", ratio)


func _take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0 or _is_resolved:
		return
	health = maxf(health - amount, 0.0)
	_health_bar.call("set_health_ratio", health / _max_health)
	if health <= 0.0:
		_resolve()
		killed.emit(self)


func _update_tint() -> void:
	var tint: Color = Color.WHITE
	if statuses.is_in_stasis():
		tint = STASIS_TINT
	elif statuses.has(StatusEffect.Type.STUN):
		tint = STUN_TINT
	elif statuses.has(StatusEffect.Type.PHASED):
		tint = PHASED_TINT
	elif statuses.get_speed_multiplier() < 1.0:
		tint = SLOW_TINT
	elif statuses.has(StatusEffect.Type.DOT):
		tint = DOT_TINT
	self_modulate = tint


## Removes the enemy from targeting immediately so a hit landing later in the
## same frame cannot count it twice.
func _resolve() -> void:
	_is_resolved = true
	remove_from_group(ENEMY_GROUP)
	queue_free()


func _is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]
