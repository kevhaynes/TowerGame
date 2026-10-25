extends GutTest


func test_reads_valid_stats() -> void:
	var reader := StatReader.new(
		{"a": 2, "b": 0.0, "c": 0.5, "d": 3, "e": 1.5}, "Test"
	)
	assert_eq(reader.positive("a"), 2.0)
	assert_eq(reader.non_negative("b"), 0.0)
	assert_eq(reader.fraction("c"), 0.5)
	assert_eq(reader.whole_number("d", 1), 3)
	assert_eq(reader.at_least("e", 1.0), 1.5)
	assert_true(reader.is_valid())


func test_collects_every_problem_into_one_error() -> void:
	var reader := StatReader.new({"a": -1, "c": 1.5, "d": 2.5, "e": "x"}, "Test")
	reader.positive("a")
	reader.fraction("c")
	reader.whole_number("d", 1)
	reader.at_least("e", 1.0)
	reader.positive("missing")
	assert_false(reader.is_valid())
	assert_push_error_count(1)


func test_error_names_the_bad_stat() -> void:
	var reader := StatReader.new({}, "Test Tower")
	reader.positive("splash_radius")
	assert_false(reader.is_valid())
	assert_push_error("splash_radius")
