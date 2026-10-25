extends Control
class_name ResearchMenu

## The research tree on the left; the selected tower's details and its
## RESEARCH button on the right. BACK returns to GameState.research_return_scene.

const STARS_TEXT: String = "%d STARS TO SPEND"
const DETAIL_WIDTH: float = 460.0
const RESEARCH_BUTTON_SIZE: Vector2 = Vector2(0, 96)
const RESEARCH_TEXT: String = "RESEARCH  -  %s"
const CATEGORY_TEXT: String = "%s  -  TIER %d"
const REQUIRES_TEXT: String = "REQUIRES: %s"
const STATUS_TEXTS: Dictionary = {
	ResearchTree.Status.UNLOCKED: "Unlocked: available to build in every level.",
	ResearchTree.Status.AVAILABLE: "Ready to research.",
	ResearchTree.Status.NEEDS_STARS: "Not enough stars. Earn more by completing levels.",
	ResearchTree.Status.NEEDS_PREREQUISITES: "Research the required towers first.",
}

var _tree: ResearchTree
var _definitions: Dictionary = {}
var _tree_view: ResearchTreeView
var _subtitle: Label
var _detail: VBoxContainer
var _research_button: Button
var _selected: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tree = ResearchTree.load_tree()
	for definition: Dictionary in DefinitionCatalog.load_directory(
		DefinitionCatalog.TOWERS_DIRECTORY
	):
		_definitions[str(definition["id"])] = definition

	var page: Dictionary = MenuWidgets.build_header_page(self, "RESEARCH", _on_back_pressed)
	_subtitle = page["subtitle"] as Label

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", MenuWidgets.CARD_SEPARATION)
	(page["layout"] as VBoxContainer).add_child(body)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	_tree_view = ResearchTreeView.new()
	_tree_view.name = "TreeView"
	_tree_view.setup(_tree, _definitions)
	_tree_view.tower_selected.connect(select_tower)
	scroll.add_child(_tree_view)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(detail_scroll)

	_detail = VBoxContainer.new()
	_detail.name = "Detail"
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", MenuWidgets.CARD_SEPARATION / 2)
	detail_scroll.add_child(_detail)

	_refresh()
	select_tower(_pick_initial_selection())


func select_tower(tower_id: String) -> void:
	_selected = tower_id
	_tree_view.select(tower_id)
	_show_detail()


## Researches the selected tower if possible. Returns true when it was.
func research_selected() -> bool:
	if not SaveManager.research_tower(_tree, _selected):
		return false
	_refresh()
	_show_detail()
	return true


func _refresh() -> void:
	var available: int = SaveManager.get_available_stars(_tree)
	_subtitle.text = STARS_TEXT % available
	_tree_view.refresh(SaveManager.research, available)


## The first tower ready to research, else the first one only short of stars,
## else the first tower in the tree.
func _pick_initial_selection() -> String:
	var ids: Array[String] = _tree.get_tower_ids()
	for wanted: ResearchTree.Status in [
		ResearchTree.Status.AVAILABLE, ResearchTree.Status.NEEDS_STARS
	]:
		for tower_id: String in ids:
			if _tree_view.get_status(tower_id) == wanted:
				return tower_id
	return ids[0] if not ids.is_empty() else ""


func _show_detail() -> void:
	for child: Node in _detail.get_children():
		child.queue_free()
	_research_button = null
	if not _definitions.has(_selected) or not _tree.has_tower(_selected):
		return

	var category: Dictionary = _tree.get_category(str(_tree.get_node_data(_selected)["category"]))
	_detail.add_child(
		MenuWidgets.create_label(
			CATEGORY_TEXT % [str(category["display_name"]).to_upper(), _tree.get_tier(_selected)],
			MenuWidgets.CARD_TEXT_FONT_SIZE,
			Color.html(str(category["color"]))
		)
	)

	var definition: Dictionary = _definitions[_selected]
	var card := MenuWidgets.create_card(definition, MenuWidgets.tower_card_lines(definition))
	card.custom_minimum_size = Vector2.ZERO
	_detail.add_child(card)

	var requirements: Array[String] = _tree.get_requirements(_selected)
	if not requirements.is_empty():
		var names: PackedStringArray = []
		var all_met: bool = true
		for required: String in requirements:
			names.append(str(_definitions.get(required, {}).get("display_name", required)))
			all_met = all_met and _tree.is_unlocked(required, SaveManager.research)
		var requires := MenuWidgets.create_label(
			REQUIRES_TEXT % ", ".join(names),
			MenuWidgets.CARD_TEXT_FONT_SIZE,
			MenuWidgets.STRONG_COLOR if all_met else MenuWidgets.WEAK_COLOR
		)
		requires.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(requires)

	var status: ResearchTree.Status = _tree_view.get_status(_selected)
	var status_label := MenuWidgets.create_label(
		STATUS_TEXTS[status], MenuWidgets.CARD_TEXT_FONT_SIZE, MenuWidgets.TEXT_COLOR
	)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(status_label)

	if status == ResearchTree.Status.UNLOCKED:
		return
	_research_button = Button.new()
	_research_button.name = "ResearchButton"
	_research_button.text = RESEARCH_TEXT % ResearchTreeView.format_cost(_tree.get_cost(_selected))
	_research_button.custom_minimum_size = RESEARCH_BUTTON_SIZE
	_research_button.disabled = status != ResearchTree.Status.AVAILABLE
	_research_button.add_theme_font_size_override("font_size", MenuWidgets.SUBTITLE_FONT_SIZE)
	if status == ResearchTree.Status.AVAILABLE:
		_research_button.add_theme_color_override("font_color", MenuWidgets.HIGHLIGHT_COLOR)
	_research_button.pressed.connect(research_selected)
	_detail.add_child(_research_button)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(GameState.research_return_scene)
