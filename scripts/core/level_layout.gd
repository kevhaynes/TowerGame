@tool
extends RefCounted
class_name LevelLayout

## Layout rules and coordinate helpers for level scenes. A level scene has a
## "Path" (Path2D) holding the enemy route, a "BuildPads" node whose children
## are BuildPad instances, and a level_size on its root (the area the camera
## scrolls over). Used by the level at runtime, by LevelPath's
## editor warnings and by the tests, so all of them apply the same rules.

const PATH_NODE: NodePath = ^"Path"
const PADS_NODE: NodePath = ^"BuildPads"
## Shoulder half-width (123 / 2) plus build pad face radius (51), so a pad never
## overlaps the drawn road.
const MIN_PAD_CLEARANCE: float = 112.5
## Two pad tap radii (57), so touch targets never overlap.
const MIN_PAD_SPACING: float = 114.0
## One pad tap radius, so the whole pad is inside the level.
const PAD_EDGE_MARGIN: float = 57.0
## The root property holding a level's size in pixels.
const LEVEL_SIZE_PROPERTY: StringName = &"level_size"
## One screen at the project viewport size.
const DEFAULT_LEVEL_SIZE: Vector2i = Vector2i(3840, 2160)
## The largest level_size a level may use. May change after playtesting.
const MAX_LEVEL_SIZE: Vector2i = Vector2i(3840, 2160)
## The HUD buttons and credits readout in scenes/game/level.tscn, grown by a
## pad tap radius.
const HUD_BUTTON_ZONE: Rect2 = Rect2(-27, -27, 774, 192)


static func viewport_size() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)


## The size of the level rooted at [param level_root] (its level_size), or
## one screen when it has none.
static func level_size_of(level_root: Node) -> Vector2:
	if level_root != null:
		var size: Variant = level_root.get(LEVEL_SIZE_PROPERTY)
		if size is Vector2i:
			return Vector2(size as Vector2i)
	return viewport_size()


## Problems with a level_size: it must fill the screen and be no larger than
## MAX_LEVEL_SIZE. Empty when it is valid.
static func level_size_problems(size: Vector2) -> PackedStringArray:
	var problems: PackedStringArray = []
	var screen: Vector2 = viewport_size()
	if size.x < screen.x or size.y < screen.y:
		problems.append("level_size %s is smaller than the screen %s" % [size, screen])
	if size.x > MAX_LEVEL_SIZE.x or size.y > MAX_LEVEL_SIZE.y:
		problems.append("level_size %s is larger than the maximum %s" % [size, MAX_LEVEL_SIZE])
	return problems


## Problems with a layout whose path points and pad centres share one
## coordinate space (the level root's), in a level of [param level_size].
## Empty when the layout is valid.
static func validate(
	path_points: PackedVector2Array, pads: PackedVector2Array, level_size: Vector2
) -> PackedStringArray:
	var errors: PackedStringArray = level_size_problems(level_size)
	if path_points.size() < 2:
		errors.append("the path needs at least two points")
		return errors
	for index: int in pads.size():
		for problem: String in pad_problems(index, pads, path_points, level_size):
			errors.append("build pad %d at %s %s" % [index, pads[index], problem])
	return errors


## Problems with the pad at [param index]; empty when it is placed well.
static func pad_problems(
	index: int, pads: PackedVector2Array, path_points: PackedVector2Array, level_size: Vector2
) -> PackedStringArray:
	var problems: PackedStringArray = []
	var pad: Vector2 = pads[index]
	var clearance: float = distance_to_path(pad, path_points)
	if clearance < MIN_PAD_CLEARANCE:
		problems.append(
			"is %d px from the road (needs %d)" % [roundi(clearance), MIN_PAD_CLEARANCE]
		)
	for other: int in pads.size():
		if other != index and pad.distance_to(pads[other]) < MIN_PAD_SPACING:
			problems.append("overlaps build pad %d" % other)
	var bounds := Rect2(Vector2.ZERO, level_size).grow(-PAD_EDGE_MARGIN)
	if not bounds.has_point(pad):
		problems.append("is partly outside the level")
	if HUD_BUTTON_ZONE.has_point(pad):
		problems.append("is under the HUD buttons")
	return problems


static func distance_to_path(point: Vector2, path_points: PackedVector2Array) -> float:
	var closest_distance: float = INF
	for index: int in range(path_points.size() - 1):
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			point, path_points[index], path_points[index + 1]
		)
		closest_distance = minf(closest_distance, point.distance_to(closest))
	return closest_distance


## Transform from [param node]'s local space to [param root]'s. Works outside
## the scene tree, so tests can inspect an instantiated level without adding it.
static func transform_to(node: Node, root: Node) -> Transform2D:
	var result := Transform2D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node2D:
			result = (current as Node2D).transform * result
		current = current.get_parent()
	return result


## The path's curve in [param root]'s coordinate space, so enemies and towers
## (children of root-level containers) can use it directly.
static func world_curve(path: Path2D, root: Node) -> Curve2D:
	var source: Curve2D = path.curve
	var to_root: Transform2D = transform_to(path, root)
	var result := Curve2D.new()
	result.bake_interval = source.bake_interval
	for index: int in source.point_count:
		result.add_point(
			to_root * source.get_point_position(index),
			to_root.basis_xform(source.get_point_in(index)),
			to_root.basis_xform(source.get_point_out(index))
		)
	return result


static func pad_positions(level_root: Node) -> PackedVector2Array:
	var positions: PackedVector2Array = []
	var pads: Node = level_root.get_node_or_null(PADS_NODE)
	if pads == null:
		return positions
	for pad: Node in pads.get_children():
		if pad is BuildPad:
			positions.append(transform_to(pad, level_root).origin)
	return positions


## Validates a level scene instance (it need not be in the scene tree).
static func validate_level(level_root: Node) -> PackedStringArray:
	var path := level_root.get_node_or_null(PATH_NODE) as Path2D
	if path == null or path.curve == null:
		return PackedStringArray(["the level has no Path with a curve"])
	var points: PackedVector2Array = world_curve(path, level_root).get_baked_points()
	return validate(points, pad_positions(level_root), level_size_of(level_root))
