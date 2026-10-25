extends Sprite2D
class_name BaseTower

## Shared plumbing for every tower behaviour script. A tower JSON names its
## behaviour script in "behaviour"; level.gd sets that script on a Sprite2D,
## assigns [member path_curve] and calls [method configure].
## [br]Subclasses override [method _read_stats] (read every stat through the
## StatReader) and optionally [method _on_configured].

const TOWER_GROUP: StringName = &"towers"

## The level's enemy path, in the same coordinate space as the towers.
var path_curve: Curve2D
var attack_range: float = 0.0
var display_name: String = ""

var _strong_against_traits: Array[String] = []
var _weak_against_traits: Array[String] = []
var _projectile_container: Node2D
var _projectile_texture: Texture2D
var _cooldown: float = 0.0
## Overcharge buffs by source relay instance id: [damage_bonus, fire_rate_bonus].
var _buffs: Dictionary = {}


func configure(definition: Dictionary, projectile_container: Node2D) -> bool:
	display_name = str(definition.get("display_name", definition.get("id", "Tower")))
	var stats: Variant = definition.get("stats", {})
	if not stats is Dictionary:
		push_error("%s definition stats must be a JSON object." % display_name)
		return false
	if not TraitAffinity.read_trait_list(
		definition, "strong_against_trait", _strong_against_traits
	):
		return false
	if not TraitAffinity.read_trait_list(definition, "weak_against_trait", _weak_against_traits):
		return false
	if definition.has("projectile_sprite"):
		var sprite_path: String = str(definition["projectile_sprite"])
		if not ResourceLoader.exists(sprite_path):
			push_error("%s projectile_sprite does not exist: %s" % [display_name, sprite_path])
			return false
		_projectile_texture = ResourceLoader.load(sprite_path) as Texture2D

	var reader := StatReader.new(stats, display_name)
	attack_range = reader.positive("range")
	_read_stats(reader)
	if not reader.is_valid():
		return false

	_projectile_container = projectile_container
	add_to_group(TOWER_GROUP)
	_on_configured()
	return true


func _read_stats(_stats: StatReader) -> void:
	pass


func _on_configured() -> void:
	pass


## Overcharge Relays call this every frame they are active, and clear_buff when not.
func set_buff(source_id: int, damage_bonus: float, fire_rate_bonus: float) -> void:
	_buffs[source_id] = [damage_bonus, fire_rate_bonus]


func clear_buff(source_id: int) -> void:
	_buffs.erase(source_id)


## Buffs from several relays do not stack: the strongest applies.
func get_damage_multiplier() -> float:
	return 1.0 + _strongest_buff(0)


func get_fire_rate_multiplier() -> float:
	return 1.0 + _strongest_buff(1)


func get_enemies() -> Array[Node]:
	if not is_inside_tree():
		return []
	return get_tree().get_nodes_in_group(PathEnemy.ENEMY_GROUP)


func find_first_target(min_range: float = 0.0) -> PathEnemy:
	return TowerTargeting.find_first(get_enemies(), global_position, attack_range, min_range)


func enemies_within(centre: Vector2, radius: float) -> Array[PathEnemy]:
	return TowerTargeting.enemies_within(get_enemies(), centre, radius)


## Damages [param enemy] with this tower's trait affinity and buffs applied.
func deal_damage(enemy: PathEnemy, amount: float, is_direct_hit: bool = true) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var affinity: float = TraitAffinity.get_multiplier(
		_strong_against_traits, _weak_against_traits, enemy.traits
	)
	enemy.apply_damage(amount * affinity * get_damage_multiplier(), is_direct_hit)


## Damages every enemy within [param radius] of [param centre], scaled by
## distance from 1 at the centre to [param edge_factor] at the edge. Returns
## the enemies hit.
func deal_splash(
	centre: Vector2, radius: float, amount: float, edge_factor: float
) -> Array[PathEnemy]:
	var hit: Array[PathEnemy] = enemies_within(centre, radius)
	for enemy: PathEnemy in hit:
		var falloff: float = CombatMath.splash_falloff(
			centre.distance_to(enemy.global_position), radius, edge_factor
		)
		deal_damage(enemy, amount * falloff)
	return hit


func aim_at(point: Vector2) -> void:
	rotation = (point - global_position).angle()


## Counts the shot cooldown down (faster when overcharged). Returns true when
## the tower may fire.
func tick_cooldown(delta: float) -> bool:
	_cooldown = maxf(_cooldown - delta * get_fire_rate_multiplier(), 0.0)
	return _cooldown <= 0.0


func start_cooldown(fire_rate: float) -> void:
	_cooldown = 1.0 / fire_rate


## Launches a projectile toward [param target] (homing) or, when target is
## null, toward [param destination]. [param on_impact] receives
## (target: PathEnemy or null, point: Vector2).
func launch_projectile(
	target: PathEnemy, destination: Vector2, speed: float, on_impact: Callable
) -> void:
	if _projectile_container == null or not is_instance_valid(_projectile_container):
		on_impact.call(target, destination)
		return
	var projectile := TowerProjectile.new()
	_projectile_container.add_child(projectile)
	projectile.launch(_projectile_texture, global_position, target, destination, speed, on_impact)


func spawn_blast(centre: Vector2, radius: float, colour: Color) -> void:
	if _projectile_container == null or not is_instance_valid(_projectile_container):
		return
	var blast := BlastEffect.new()
	_projectile_container.add_child(blast)
	blast.global_position = centre
	blast.setup(radius, colour)


func _strongest_buff(index: int) -> float:
	var strongest: float = 0.0
	for buff: Array in _buffs.values():
		strongest = maxf(strongest, float(buff[index]))
	return strongest
