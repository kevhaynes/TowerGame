extends RefCounted
class_name TraitAffinity

## Damage multipliers a tower applies when its target has a trait the tower is
## strong or weak against, plus parsing of the trait lists in tower JSON.

const STRONG_MULTIPLIER: float = 1.2
const WEAK_MULTIPLIER: float = 0.8
const MAX_TRAITS_PER_LIST: int = 2
const VALID_TRAITS: Array[String] = [
	"ARMOURED", "SHIELDED", "MECHANICAL", "ORGANIC", "FLYING", "BOSS"
]


static func get_multiplier(
	strong_traits: Array[String], weak_traits: Array[String], target_traits: Array[String]
) -> float:
	var multiplier: float = 1.0
	if has_matching_trait(strong_traits, target_traits):
		multiplier *= STRONG_MULTIPLIER
	if has_matching_trait(weak_traits, target_traits):
		multiplier *= WEAK_MULTIPLIER
	return multiplier


static func has_matching_trait(
	affinity_traits: Array[String], target_traits: Array[String]
) -> bool:
	for affinity_trait: String in affinity_traits:
		if target_traits.has(affinity_trait):
			return true
	return false


## Reads a strong/weak trait list from a tower definition into [param output].
## Returns false (after reporting the problem) if the list is malformed.
static func read_trait_list(
	definition: Dictionary, property_name: String, output: Array[String]
) -> bool:
	output.clear()
	var trait_list: Variant = definition.get(property_name, [])
	if not trait_list is Array or trait_list.size() > MAX_TRAITS_PER_LIST:
		push_error(
			"%s must be a JSON array containing at most %d traits."
			% [property_name, MAX_TRAITS_PER_LIST]
		)
		return false

	for trait_value: Variant in trait_list:
		if not trait_value is String or not VALID_TRAITS.has(trait_value):
			push_error("%s contains an unknown trait: %s" % [property_name, str(trait_value)])
			return false
		if output.has(trait_value):
			push_error("%s must not contain duplicate traits." % property_name)
			return false
		output.append(trait_value)
	return true
