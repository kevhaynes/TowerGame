extends RefCounted
class_name ResearchTree

## The tower research tree from data/progression/research_tree.json. Each node
## unlocks one tower for a star cost once every tower in its "requires" list is
## unlocked. Starting nodes are unlocked from the beginning. Stars to spend are
## the stars earned on levels (plus debug bonus stars) minus the cost of
## everything researched, so retuning a cost re-prices past research too.

enum Status { UNLOCKED, AVAILABLE, NEEDS_STARS, NEEDS_PREREQUISITES }

const TREE_PATH: String = "res://data/progression/research_tree.json"

var categories: Array[Dictionary] = []
## Nodes by tower id, in file order.
var _nodes: Dictionary[String, Dictionary] = {}


## An empty tree (no towers unlocked) when the file is missing or invalid.
static func load_tree(path: String = TREE_PATH) -> ResearchTree:
	var data: Dictionary = LevelCatalog.read_json_object(path)
	var errors: PackedStringArray = validate(data)
	if not errors.is_empty():
		push_error("Invalid research tree %s: %s" % [path, "; ".join(errors)])
		return ResearchTree.new()
	return from_dict(data)


## [param data] must already pass validate().
static func from_dict(data: Dictionary) -> ResearchTree:
	var tree := ResearchTree.new()
	for category: Dictionary in data["categories"]:
		tree.categories.append(category)
	for node: Dictionary in data["nodes"]:
		tree._nodes[str(node["tower"])] = node
	return tree


static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var category_list: Variant = data.get("categories")
	var category_ids: Array[String] = []
	if not category_list is Array or (category_list as Array).is_empty():
		errors.append("categories must be a non-empty list")
	else:
		for category: Variant in category_list:
			if not category is Dictionary or not _is_text(category.get("id")):
				errors.append("each category needs a string id")
				continue
			var category_id: String = category["id"]
			if category_ids.has(category_id):
				errors.append("category %s is listed twice" % category_id)
			category_ids.append(category_id)
			if not _is_text(category.get("display_name")):
				errors.append("category %s needs a display_name" % category_id)
			var color: Variant = category.get("color")
			if not color is String or not Color.html_is_valid(color):
				errors.append("category %s needs an HTML color" % category_id)

	var nodes: Variant = data.get("nodes")
	if not nodes is Array or (nodes as Array).is_empty():
		errors.append("nodes must be a non-empty list")
		return errors

	var tiers: Dictionary[String, int] = {}
	for node: Variant in nodes:
		if not node is Dictionary or not _is_text(node.get("tower")):
			errors.append("each node needs a string tower id")
			continue
		var tower_id: String = node["tower"]
		if tiers.has(tower_id):
			errors.append("%s is listed twice" % tower_id)
		var tier: Variant = node.get("tier")
		tiers[tower_id] = int(tier) if _is_whole(tier) else -1
		if not category_ids.has(str(node.get("category"))):
			errors.append("%s has an unknown category" % tower_id)
		if not _is_whole(tier) or int(tier) < 0:
			errors.append("%s needs a whole tier of at least 0" % tower_id)
		if not _is_whole(node.get("cost")) or int(node.get("cost")) < 0:
			errors.append("%s needs a whole cost of at least 0" % tower_id)
		if not node.get("requires") is Array:
			errors.append("%s needs a requires list" % tower_id)

	var has_starting: bool = false
	for node: Variant in nodes:
		if not node is Dictionary or not node.get("requires") is Array:
			continue
		var tower_id: String = str(node.get("tower"))
		var requires: Array = node["requires"]
		var starting: bool = node.get("starting", false) == true
		has_starting = has_starting or starting
		if starting and (requires.size() > 0 or int(node.get("cost", 0)) != 0):
			errors.append("starting tower %s must be free with no requirements" % tower_id)
		if not starting and (requires.is_empty() or int(node.get("cost", 0)) < 1):
			errors.append("%s must cost at least 1 star and require a tower" % tower_id)
		for required: Variant in requires:
			if not required is String or not tiers.has(required):
				errors.append("%s requires unknown tower %s" % [tower_id, required])
			elif tiers[required] >= tiers.get(tower_id, 0):
				errors.append("%s requires %s from the same or a later tier" % [tower_id, required])
	if not has_starting:
		errors.append("at least one node must be starting")
	return errors


func has_tower(tower_id: String) -> bool:
	return _nodes.has(tower_id)


## Tower ids in file order.
func get_tower_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_nodes.keys())
	return ids


func get_node_data(tower_id: String) -> Dictionary:
	return _nodes.get(tower_id, {})


func get_category(category_id: String) -> Dictionary:
	for category: Dictionary in categories:
		if str(category["id"]) == category_id:
			return category
	return {}


func get_cost(tower_id: String) -> int:
	return int(get_node_data(tower_id).get("cost", 0))


func get_tier(tower_id: String) -> int:
	return int(get_node_data(tower_id).get("tier", 0))


func get_requirements(tower_id: String) -> Array[String]:
	var requirements: Array[String] = []
	for required: Variant in get_node_data(tower_id).get("requires", []):
		requirements.append(str(required))
	return requirements


func is_starting(tower_id: String) -> bool:
	return get_node_data(tower_id).get("starting", false) == true


func get_max_tier() -> int:
	var max_tier: int = 0
	for tower_id: String in _nodes:
		max_tier = maxi(max_tier, get_tier(tower_id))
	return max_tier


## Towers not in the tree are never unlocked.
func is_unlocked(tower_id: String, research: ResearchProgress) -> bool:
	if not _nodes.has(tower_id):
		return false
	return is_starting(tower_id) or research.has_researched(tower_id)


func get_status(tower_id: String, research: ResearchProgress, available_stars: int) -> Status:
	if is_unlocked(tower_id, research):
		return Status.UNLOCKED
	if not _nodes.has(tower_id):
		return Status.NEEDS_PREREQUISITES
	for required: String in get_requirements(tower_id):
		if not is_unlocked(required, research):
			return Status.NEEDS_PREREQUISITES
	if available_stars < get_cost(tower_id):
		return Status.NEEDS_STARS
	return Status.AVAILABLE


## Stars spent on research. Researched ids no longer in the tree cost nothing.
func get_spent_stars(research: ResearchProgress) -> int:
	var spent: int = 0
	for tower_id: String in research.get_researched_ids():
		if _nodes.has(tower_id) and not is_starting(tower_id):
			spent += get_cost(tower_id)
	return spent


## Never negative, even if costs were raised after research was bought.
func get_available_stars(earned_stars: int, research: ResearchProgress) -> int:
	return maxi(0, earned_stars + research.bonus_stars - get_spent_stars(research))


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).is_empty()


static func _is_whole(value: Variant) -> bool:
	return (
		typeof(value) in [TYPE_INT, TYPE_FLOAT]
		and is_equal_approx(float(value), roundf(float(value)))
	)
