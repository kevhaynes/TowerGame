extends RefCounted
class_name TowerTargeting

## Target selection shared by towers. Callers must pass live instances; check
## is_instance_valid() first for a reference that may have been freed.


static func is_valid_target(enemy: PathEnemy, origin: Vector2, attack_range: float) -> bool:
	return (
		_is_alive(enemy)
		and origin.distance_squared_to(enemy.global_position) <= attack_range * attack_range
	)


## Returns the living enemy in range that is furthest along the path, or null.
## Enemies closer than [param min_range] are ignored (mortar blind spot).
static func find_first(
	candidates: Array[Node], origin: Vector2, attack_range: float, min_range: float = 0.0
) -> PathEnemy:
	var ordered: Array[PathEnemy] = find_ordered(candidates, origin, attack_range, min_range)
	return ordered[0] if not ordered.is_empty() else null


## Living enemies in range, furthest along the path first.
static func find_ordered(
	candidates: Array[Node], origin: Vector2, attack_range: float, min_range: float = 0.0
) -> Array[PathEnemy]:
	var found: Array[PathEnemy] = []
	var min_squared: float = min_range * min_range
	for enemy: PathEnemy in _alive(candidates):
		if not is_valid_target(enemy, origin, attack_range):
			continue
		if origin.distance_squared_to(enemy.global_position) < min_squared:
			continue
		found.append(enemy)
	found.sort_custom(_is_further_along)
	return found


static func enemies_within(
	candidates: Array[Node], centre: Vector2, radius: float
) -> Array[PathEnemy]:
	var found: Array[PathEnemy] = []
	for enemy: PathEnemy in _alive(candidates):
		if centre.distance_squared_to(enemy.global_position) <= radius * radius:
			found.append(enemy)
	return found


## Enemies within [param half_width] of the segment from [param origin] along
## [param direction] (normalised) for [param length].
static func enemies_on_line(
	candidates: Array[Node], origin: Vector2, direction: Vector2, length: float, half_width: float
) -> Array[PathEnemy]:
	var found: Array[PathEnemy] = []
	for enemy: PathEnemy in _alive(candidates):
		var offset: Vector2 = enemy.global_position - origin
		var along: float = offset.dot(direction)
		if along < 0.0 or along > length:
			continue
		if absf(offset.cross(direction)) <= half_width:
			found.append(enemy)
	return found


## Enemies within [param attack_range] and [param half_angle] radians of [param facing].
static func enemies_in_cone(
	candidates: Array[Node], origin: Vector2, facing: float, half_angle: float, attack_range: float
) -> Array[PathEnemy]:
	var found: Array[PathEnemy] = []
	for enemy: PathEnemy in _alive(candidates):
		var offset: Vector2 = enemy.global_position - origin
		if offset.length_squared() > attack_range * attack_range:
			continue
		if offset.is_zero_approx() or absf(angle_difference(facing, offset.angle())) <= half_angle:
			found.append(enemy)
	return found


## Builds a lightning chain: starts at [param first] and repeatedly jumps to the
## nearest enemy not yet hit within [param hop_range], up to [param max_targets].
static func build_chain(
	first: PathEnemy, candidates: Array[Node], max_targets: int, hop_range: float
) -> Array[PathEnemy]:
	var chain: Array[PathEnemy] = [first]
	var pool: Array[PathEnemy] = _alive(candidates)
	pool.erase(first)
	while chain.size() < max_targets:
		var last: PathEnemy = chain[chain.size() - 1]
		var next: PathEnemy
		var best: float = hop_range * hop_range
		for enemy: PathEnemy in pool:
			var distance: float = last.global_position.distance_squared_to(enemy.global_position)
			if distance <= best:
				best = distance
				next = enemy
		if next == null:
			break
		chain.append(next)
		pool.erase(next)
	return chain


static func _is_further_along(a: PathEnemy, b: PathEnemy) -> bool:
	return a.path_distance > b.path_distance


static func _alive(candidates: Array[Node]) -> Array[PathEnemy]:
	var alive: Array[PathEnemy] = []
	for candidate: Node in candidates:
		if candidate is PathEnemy and _is_alive(candidate as PathEnemy):
			alive.append(candidate as PathEnemy)
	return alive


static func _is_alive(enemy: PathEnemy) -> bool:
	return (
		enemy != null
		and enemy.health > 0.0
		and enemy.is_active()
		and enemy.is_in_group(PathEnemy.ENEMY_GROUP)
	)
