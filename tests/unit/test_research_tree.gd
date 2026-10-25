extends GutTest

## ResearchTree rules against a small hand-written tree, plus validation of the
## shipped data/progression/research_tree.json.

const TOWERS_DIRECTORY: String = "res://data/towers"

var _tree: ResearchTree


func _tree_data() -> Dictionary:
	return {
		"categories":
		[
			{"id": "PHYSICAL", "display_name": "Physical", "color": "#ffffff"},
			{"id": "STATUS", "display_name": "Status", "color": "#00ff00"},
		],
		"nodes":
		[
			_node("gun", "PHYSICAL", 0, 0, [], true),
			_node("cannon", "PHYSICAL", 1, 1, ["gun"]),
			_node("cryo", "STATUS", 1, 2, ["gun"]),
			_node("stasis", "STATUS", 2, 3, ["cannon", "cryo"]),
		],
	}


func _node(
	tower: String, category: String, tier: int, cost: int, requires: Array, starting: bool = false
) -> Dictionary:
	return {
		"tower": tower,
		"category": category,
		"tier": tier,
		"cost": cost,
		"requires": requires,
		"starting": starting,
	}


func before_each() -> void:
	var data: Dictionary = _tree_data()
	assert_eq(ResearchTree.validate(data), PackedStringArray(), "fixture tree is valid")
	_tree = ResearchTree.from_dict(data)


func _research(ids: Array[String], bonus: int = 0) -> ResearchProgress:
	var research := ResearchProgress.new()
	for tower_id: String in ids:
		research.record_research(tower_id)
	research.bonus_stars = bonus
	return research


func test_only_starting_towers_are_unlocked_at_first() -> void:
	var research := ResearchProgress.new()
	assert_true(_tree.is_unlocked("gun", research))
	assert_false(_tree.is_unlocked("cannon", research))
	assert_false(_tree.is_unlocked("not_in_tree", research))


func test_status_follows_requirements_and_stars() -> void:
	var research := ResearchProgress.new()
	assert_eq(_tree.get_status("gun", research, 0), ResearchTree.Status.UNLOCKED)
	assert_eq(_tree.get_status("cannon", research, 1), ResearchTree.Status.AVAILABLE)
	assert_eq(_tree.get_status("cryo", research, 1), ResearchTree.Status.NEEDS_STARS)
	assert_eq(
		_tree.get_status("stasis", research, 99), ResearchTree.Status.NEEDS_PREREQUISITES
	)


func test_multiple_requirements_all_need_unlocking() -> void:
	assert_eq(
		_tree.get_status("stasis", _research(["cannon"]), 99),
		ResearchTree.Status.NEEDS_PREREQUISITES,
		"cryo still missing"
	)
	assert_eq(
		_tree.get_status("stasis", _research(["cannon", "cryo"]), 99),
		ResearchTree.Status.AVAILABLE
	)


func test_branches_are_independent_choices() -> void:
	var research := _research(["cryo"])
	assert_true(_tree.is_unlocked("cryo", research))
	assert_eq(_tree.get_status("cannon", research, 1), ResearchTree.Status.AVAILABLE)


func test_available_stars_subtract_research_and_add_bonus() -> void:
	assert_eq(_tree.get_available_stars(5, ResearchProgress.new()), 5)
	assert_eq(_tree.get_spent_stars(_research(["cannon", "cryo"])), 3)
	assert_eq(_tree.get_available_stars(5, _research(["cannon", "cryo"])), 2)
	assert_eq(_tree.get_available_stars(0, _research(["cannon"], 10)), 9)


func test_available_stars_are_never_negative() -> void:
	assert_eq(_tree.get_available_stars(0, _research(["cannon", "cryo", "stasis"])), 0)


func test_unknown_research_costs_nothing() -> void:
	assert_eq(_tree.get_spent_stars(_research(["removed_tower", "gun"])), 0)


func test_validate_rejects_broken_trees() -> void:
	var data: Dictionary = _tree_data()
	data["nodes"][1]["requires"] = ["missing"]
	data["nodes"][2]["requires"] = ["stasis"]
	data["nodes"][3]["category"] = "NOPE"
	var errors: String = "; ".join(ResearchTree.validate(data))
	assert_string_contains(errors, "cannon requires unknown tower missing")
	assert_string_contains(errors, "cryo requires stasis from the same or a later tier")
	assert_string_contains(errors, "stasis has an unknown category")


func test_validate_needs_a_free_starting_tower() -> void:
	var data: Dictionary = _tree_data()
	data["nodes"][0]["starting"] = false
	var errors: String = "; ".join(ResearchTree.validate(data))
	assert_string_contains(errors, "at least one node must be starting")
	assert_string_contains(errors, "gun must cost at least 1 star")


func test_shipped_tree_is_valid() -> void:
	var data: Dictionary = LevelCatalog.read_json_object(ResearchTree.TREE_PATH)
	assert_eq(ResearchTree.validate(data), PackedStringArray())


func test_shipped_tree_covers_every_tower_exactly() -> void:
	var tree := ResearchTree.load_tree()
	var tower_ids: Array[String] = []
	for file_name: String in DirAccess.get_files_at(TOWERS_DIRECTORY):
		if file_name.ends_with(".json"):
			tower_ids.append(file_name.get_basename())
	for tower_id: String in tower_ids:
		assert_true(tree.has_tower(tower_id), "%s is in the research tree" % tower_id)
	for tower_id: String in tree.get_tower_ids():
		assert_true(tower_ids.has(tower_id), "%s in the tree is a real tower" % tower_id)


func test_shipped_tree_branches() -> void:
	var tree := ResearchTree.load_tree()
	var unlocked_by_start: int = 0
	for tower_id: String in tree.get_tower_ids():
		var requirements: Array[String] = tree.get_requirements(tower_id)
		if requirements.size() == 1 and tree.is_starting(requirements[0]):
			unlocked_by_start += 1
	assert_gt(unlocked_by_start, 1, "the first research is a choice")
