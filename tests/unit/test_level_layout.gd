extends GutTest

const STRAIGHT_PATH: PackedVector2Array = [Vector2(100, 300), Vector2(1100, 300)]
const LARGE_LEVEL: Vector2 = Vector2(3840, 2160)


func _screen() -> Vector2:
	return LevelLayout.viewport_size()


func test_well_placed_pad_has_no_problems() -> void:
	var pads: PackedVector2Array = [Vector2(500, 450)]
	assert_eq(LevelLayout.validate(STRAIGHT_PATH, pads, _screen()).size(), 0)


func test_pad_too_close_to_the_road() -> void:
	var pads: PackedVector2Array = [Vector2(500, 360)]
	assert_eq(LevelLayout.validate(STRAIGHT_PATH, pads, _screen()).size(), 1)


func test_overlapping_pads_are_both_reported() -> void:
	var pads: PackedVector2Array = [Vector2(500, 450), Vector2(540, 450)]
	assert_eq(LevelLayout.validate(STRAIGHT_PATH, pads, _screen()).size(), 2)


func test_pad_outside_the_level_or_under_the_hud_button() -> void:
	var right_edge: float = _screen().x - 10.0
	var pads: PackedVector2Array = [Vector2(right_edge, 500), Vector2(100, 100)]
	var problems: PackedStringArray = LevelLayout.validate(STRAIGHT_PATH, pads, _screen())
	assert_eq(problems.size(), 2)
	assert_string_contains(problems[0], "outside the level")
	assert_string_contains(problems[1], "HUD buttons")


func test_pads_beyond_the_screen_are_fine_in_a_larger_level() -> void:
	var pads: PackedVector2Array = [Vector2(3000, 1800)]
	var path: PackedVector2Array = [Vector2(100, 1600), Vector2(3700, 1600)]
	assert_eq(LevelLayout.validate(path, pads, LARGE_LEVEL).size(), 0)
	var edge: PackedVector2Array = [Vector2(3800, 1800)]
	assert_string_contains(
		LevelLayout.validate(path, edge, LARGE_LEVEL)[0], "outside the level"
	)


func test_level_size_fills_the_screen_and_respects_the_maximum() -> void:
	assert_eq(LevelLayout.level_size_problems(_screen()).size(), 0)
	assert_eq(LevelLayout.level_size_problems(Vector2(LevelLayout.MAX_LEVEL_SIZE)).size(), 0)
	assert_eq(LevelLayout.MAX_LEVEL_SIZE, Vector2i(3840, 2160))
	var small: PackedStringArray = LevelLayout.level_size_problems(_screen() - Vector2(1, 0))
	assert_eq(small.size(), 1)
	assert_string_contains(small[0], "smaller than the screen")
	var too_wide := Vector2(LevelLayout.MAX_LEVEL_SIZE) + Vector2(1, 0)
	var large: PackedStringArray = LevelLayout.level_size_problems(too_wide)
	assert_eq(large.size(), 1)
	assert_string_contains(large[0], "larger than the maximum")
	var too_tall := Vector2(LevelLayout.MAX_LEVEL_SIZE) + Vector2(0, 1)
	assert_eq(LevelLayout.level_size_problems(too_tall).size(), 1)


func test_level_size_is_read_from_the_level_root() -> void:
	var scene: PackedScene = load(str(LevelCatalog.load_levels()[0]["scene"]))
	var root: Node = scene.instantiate()
	assert_eq(LevelLayout.level_size_of(root), Vector2(LevelLayout.DEFAULT_LEVEL_SIZE))
	root.set("level_size", Vector2i(2880, 1620))
	assert_eq(LevelLayout.level_size_of(root), Vector2(2880, 1620))
	root.free()
	assert_eq(LevelLayout.level_size_of(null), _screen(), "no root: one screen")


func test_path_needs_two_points() -> void:
	var single: PackedVector2Array = [Vector2(100, 300)]
	assert_eq(LevelLayout.validate(single, [], _screen()).size(), 1)


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
