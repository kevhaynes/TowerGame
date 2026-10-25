extends GutTest


func _line(from_x: int, to_x: int, step: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for x: int in range(from_x, to_x + 1, step):
		points.append(Vector2(x, 0))
	return points


func test_keeps_only_points_within_range() -> void:
	var segments: Array[PackedVector2Array] = RangeIndicator.path_segments_in_range(
		_line(-500, 500, 10), Vector2.ZERO, 0.0, 100.0
	)
	assert_eq(segments.size(), 1)
	assert_eq(segments[0][0], Vector2(-100, 0))
	assert_eq(segments[0][segments[0].size() - 1], Vector2(100, 0))


func test_blind_spot_splits_the_path() -> void:
	var segments: Array[PackedVector2Array] = RangeIndicator.path_segments_in_range(
		_line(-500, 500, 10), Vector2.ZERO, 50.0, 100.0
	)
	assert_eq(segments.size(), 2, "the stretch inside the blind spot is left out")
	assert_eq(segments[0][segments[0].size() - 1], Vector2(-50, 0))
	assert_eq(segments[1][0], Vector2(50, 0))


func test_path_out_of_range_has_no_segments() -> void:
	var segments: Array[PackedVector2Array] = RangeIndicator.path_segments_in_range(
		_line(-500, 500, 10), Vector2(0, 400), 0.0, 100.0
	)
	assert_eq(segments.size(), 0)


func test_single_points_are_dropped() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(500, 0), Vector2(1000, 0)])
	assert_eq(RangeIndicator.path_segments_in_range(points, Vector2.ZERO, 0, 100).size(), 0)
