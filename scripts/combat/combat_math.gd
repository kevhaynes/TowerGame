extends RefCounted
class_name CombatMath

## Pure combat formulas shared by towers and enemies.

const ARMOUR_REDUCTION_PER_POINT: float = 0.1
const MAX_ARMOUR_REDUCTION: float = 0.75
## Path distance either side of an enemy used to find which way a graviton
## well pulls it.
const GRAVITON_PROBE_DISTANCE: float = 12.0
## Ignore pulls smaller than this so enemies settle at the well instead of jittering.
const GRAVITON_DEAD_ZONE: float = 0.75


## Damage multiplier for an enemy with [param armour] effective armour points.
static func armour_multiplier(armour: float) -> float:
	return 1.0 - clampf(armour * ARMOUR_REDUCTION_PER_POINT, 0.0, MAX_ARMOUR_REDUCTION)


## Splash multiplier at [param distance] from the blast centre: 1 at the centre,
## falling linearly to [param edge_factor] at [param radius], 0 outside.
static func splash_falloff(distance: float, radius: float, edge_factor: float) -> float:
	if radius <= 0.0 or distance > radius:
		return 0.0
	return lerpf(1.0, edge_factor, distance / radius)


## Damage of the [param hop_index]th target in a chain (0 = first target).
static func chain_damage(base_damage: float, falloff: float, hop_index: int) -> float:
	return base_damage * pow(falloff, hop_index)


## Which way along the path a graviton well pulls an enemy: +1 forward, -1
## back, 0 when it is already at the closest point. Arguments are distances
## from the well to the enemy's path position, one probe ahead and one behind.
static func graviton_direction(here: float, ahead: float, behind: float) -> int:
	var closest: float = minf(ahead, behind)
	if here - closest < GRAVITON_DEAD_ZONE:
		return 0
	return 1 if ahead <= behind else -1


## Moves [param from] toward [param goal] by at most [param step], then keeps
## the result inside the circle at [param centre] with [param radius].
static func step_within_zone(
	from: Vector2, goal: Vector2, step: float, centre: Vector2, radius: float
) -> Vector2:
	var moved: Vector2 = from.move_toward(goal, step)
	var offset: Vector2 = moved - centre
	if offset.length() > radius:
		moved = centre + offset.normalized() * radius
	return moved
