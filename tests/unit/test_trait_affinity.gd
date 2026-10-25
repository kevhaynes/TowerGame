extends GutTest

var _strong: Array[String] = ["ARMOURED"]
var _weak: Array[String] = ["SHIELDED"]


func test_neutral_target_takes_base_damage() -> void:
	var target_traits: Array[String] = ["ORGANIC"]
	assert_eq(TraitAffinity.get_multiplier(_strong, _weak, target_traits), 1.0)


func test_strong_and_weak_multipliers() -> void:
	var armoured: Array[String] = ["MECHANICAL", "ARMOURED"]
	var shielded: Array[String] = ["SHIELDED"]
	var both: Array[String] = ["ARMOURED", "SHIELDED"]
	assert_almost_eq(
		TraitAffinity.get_multiplier(_strong, _weak, armoured),
		TraitAffinity.STRONG_MULTIPLIER,
		0.0001
	)
	assert_almost_eq(
		TraitAffinity.get_multiplier(_strong, _weak, shielded),
		TraitAffinity.WEAK_MULTIPLIER,
		0.0001
	)
	assert_almost_eq(
		TraitAffinity.get_multiplier(_strong, _weak, both),
		TraitAffinity.STRONG_MULTIPLIER * TraitAffinity.WEAK_MULTIPLIER,
		0.0001
	)


func test_reads_valid_trait_list() -> void:
	var output: Array[String] = []
	var definition: Dictionary = {"strong_against_trait": ["ARMOURED", "BOSS"]}
	assert_true(TraitAffinity.read_trait_list(definition, "strong_against_trait", output))
	assert_eq(output, ["ARMOURED", "BOSS"] as Array[String])


func test_missing_trait_list_reads_as_empty() -> void:
	var output: Array[String] = ["STALE"]
	assert_true(TraitAffinity.read_trait_list({}, "weak_against_trait", output))
	assert_eq(output.size(), 0)


func test_rejects_too_many_traits() -> void:
	var output: Array[String] = []
	var definition: Dictionary = {"traits": ["ARMOURED", "BOSS", "FLYING"]}
	assert_false(TraitAffinity.read_trait_list(definition, "traits", output))
	assert_push_error("at most")


func test_rejects_unknown_and_duplicate_traits() -> void:
	var output: Array[String] = []
	assert_false(TraitAffinity.read_trait_list({"traits": ["SQUISHY"]}, "traits", output))
	assert_push_error("unknown trait")
	assert_false(TraitAffinity.read_trait_list({"traits": [7]}, "traits", output))
	assert_push_error("unknown trait")
	assert_false(TraitAffinity.read_trait_list({"traits": ["BOSS", "BOSS"]}, "traits", output))
	assert_push_error("duplicate")
