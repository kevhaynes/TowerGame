extends GutTest

const STRAIGHT_PATH: PackedVector2Array = [Vector2(100, 300), Vector2(1100, 300)]


func test_well_placed_pad_has_no_problems() -> void:
	var pads: PackedVector2Array = [Vector2(500, 450)]
	assert_eq(LevelLayout.validate(STRAIGHT_PATH, pads).size(), 0)


func test_pad_too_close_to_the_road() -> void:
	var pads: PackedVector2Array = [Vector2(500, 360)]
	assert_eq(LevelLayout.validate(STRAIGHT_PATH, pads).size(), 1)


func test_overlapping_pads_are_both_reported() -> void:
	var pads: PackedVector2Array = [Vector2(500, 450), Vector2(540, 450)]
	assert_eq(LevelLayout.validate(STRAIGHT_PATH, pads).size(), 2)


func test_pad_off_screen_or_under_the_hud_button() -> void:
	var right_edge: float = LevelLayout.viewport_size().x - 10.0
	var pads: PackedVector2Array = [Vector2(right_edge, 500), Vector2(100, 100)]
	var problems: PackedStringArray = LevelLayout.validate(STRAIGHT_PATH, pads)
	assert_eq(problems.size(), 2)
	assert_string_contains(problems[0], "off screen")
	assert_string_contains(problems[1], "HUD buttons")


func test_path_needs_two_points() -> void:
	var single: PackedVector2Array = [Vector2(100, 300)]
	assert_eq(LevelLayout.validate(single, []).size(), 1)


func test_distance_to_path_measures_closest_segment() -> void:
	var path: PackedVector2Array = [Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)]
	assert_almost_eq(LevelLayout.distance_to_path(Vector2(50, 30), path), 30.0, 0.001)
	assert_almost_eq(LevelLayout.distance_to_path(Vector2(130, 60), path), 30.0, 0.001)


func test_world_curve_applies_the_path_node_transform() -> void:
	var root: Node2D = autofree(Node2D.new())
	var path := Path2D.new()
	path.position = Vector2(10, 20)
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(5, 0))
	path.curve.add_point(Vector2(100, 0))
	root.add_child(path)
	var world: Curve2D = LevelLayout.world_curve(path, root)
	assert_eq(world.get_point_position(0), Vector2(10, 20))
	assert_eq(world.get_point_position(1), Vector2(110, 20))
	assert_eq(world.get_point_out(0), Vector2(5, 0), "handles keep their direction")


func test_shipped_level_scenes_have_valid_layouts() -> void:
	for level: Dictionary in LevelCatalog.load_levels():
		var scene: PackedScene = load(str(level["scene"]))
		assert_not_null(scene, "%s scene loads" % level["id"])
		if scene == null:
			continue
		var root: Node = scene.instantiate()
		var problems: PackedStringArray = LevelLayout.validate_level(root)
		assert_eq(problems.size(), 0, "%s: %s" % [level["id"], "; ".join(problems)])
		assert_gt(LevelLayout.pad_positions(root).size(), 0, "%s has build pads" % level["id"])
		root.free()
