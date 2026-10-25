extends RefCounted
class_name MenuWidgets

## Shared building blocks for the full-screen menus: background, page header
## with a back button, and the definition cards on the enemies and towers pages.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/ui/level_select.tscn"
const ENEMIES_SCENE: String = "res://scenes/ui/enemies_menu.tscn"
const TOWERS_SCENE: String = "res://scenes/ui/towers_menu.tscn"
const RESEARCH_SCENE: String = "res://scenes/ui/research_menu.tscn"
const BACKGROUND_COLOR: Color = Color(0.075, 0.118, 0.137, 1)
const TITLE_COLOR: Color = Color(0.65, 0.96, 0.82)
const TEXT_COLOR: Color = Color(0.69, 0.78, 0.77)
const HIGHLIGHT_COLOR: Color = Color(1, 0.83, 0.42)
const STRONG_COLOR: Color = Color(0.38, 0.92, 0.5)
const WEAK_COLOR: Color = Color(1.0, 0.39, 0.35)
const CARD_COLOR: Color = Color(0.055, 0.09, 0.105, 0.97)
const CARD_BORDER_COLOR: Color = Color(0.28, 0.58, 0.51, 0.9)
const PAGE_MARGIN: int = 48
const BACK_BUTTON_SIZE: Vector2 = Vector2(180, 90)
const CARD_SIZE: Vector2 = Vector2(870, 0)
const CARD_ICON_SIZE: Vector2 = Vector2(120, 120)
const CARD_COLUMNS: int = 2
const CARD_SEPARATION: int = 30
const TITLE_FONT_SIZE: int = 60
const SUBTITLE_FONT_SIZE: int = 36
const CARD_NAME_FONT_SIZE: int = 33
const CARD_TEXT_FONT_SIZE: int = 24
const TOWER_DETAILS_TEXT: String = "%s DAMAGE   COST %s CR   RANGE %s"


static func add_background(parent: Control) -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(background)


static func create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## A full-screen page: a header row with a BACK button (wired to
## [param on_back]), [param title] and a subtitle, above a scrolling card grid.
## Returns { "subtitle": Label, "grid": GridContainer, "layout": VBoxContainer }.
static func build_page(parent: Control, title: String, on_back: Callable) -> Dictionary:
	var page: Dictionary = build_header_page(parent, title, on_back)
	var layout := page["layout"] as VBoxContainer

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var grid := GridContainer.new()
	grid.name = "Cards"
	grid.columns = CARD_COLUMNS
	grid.add_theme_constant_override("h_separation", CARD_SEPARATION)
	grid.add_theme_constant_override("v_separation", CARD_SEPARATION)
	center.add_child(grid)

	page["grid"] = grid
	return page


## A full-screen page with only the header row; the caller adds the body to
## the returned layout. Returns { "subtitle": Label, "header": HBoxContainer,
## "layout": VBoxContainer }.
static func build_header_page(parent: Control, title: String, on_back: Callable) -> Dictionary:
	add_background(parent)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, PAGE_MARGIN)
	parent.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", CARD_SEPARATION)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", CARD_SEPARATION)
	layout.add_child(header)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "BACK"
	back_button.custom_minimum_size = BACK_BUTTON_SIZE
	back_button.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	back_button.pressed.connect(on_back)
	header.add_child(back_button)

	var title_label := create_label(title, TITLE_FONT_SIZE, TITLE_COLOR)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var subtitle := create_label("", SUBTITLE_FONT_SIZE, HIGHLIGHT_COLOR)
	subtitle.name = "Subtitle"
	header.add_child(subtitle)

	return {"subtitle": subtitle, "header": header, "layout": layout}


## A card showing a definition's sprite, name and description, followed by
## [param lines]: each { "text": String, "color": Color }.
static func create_card(definition: Dictionary, lines: Array[Dictionary]) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "%sCard" % str(definition.get("id", "")).to_pascal_case()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", _create_card_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CARD_SEPARATION)
	card.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = CARD_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon.texture = ResourceLoader.load(str(definition["sprite"])) as Texture2D
	row.add_child(icon)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)

	details.add_child(
		create_label(str(definition["display_name"]), CARD_NAME_FONT_SIZE, TITLE_COLOR)
	)
	var description := create_label(
		str(definition.get("description", "")), CARD_TEXT_FONT_SIZE, TEXT_COLOR
	)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)
	for line: Dictionary in lines:
		var label := create_label(str(line["text"]), CARD_TEXT_FONT_SIZE, line["color"])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(label)
	return card


## Card lines for a tower: damage type, cost and range, then the traits it is
## strong and weak against.
static func tower_card_lines(definition: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var stats: Variant = definition.get("stats", {})
	if stats is Dictionary:
		lines.append(
			{
				"text":
				(
					TOWER_DETAILS_TEXT
					% [
						format_stat(stats, "damage_type"),
						format_stat(stats, "cost"),
						format_stat(stats, "range"),
					]
				),
				"color": HIGHLIGHT_COLOR,
			}
		)
	var strong: String = format_names(definition.get("strong_against_trait", []))
	if not strong.is_empty():
		lines.append({"text": "STRONG: %s" % strong, "color": STRONG_COLOR})
	var weak: String = format_names(definition.get("weak_against_trait", []))
	if not weak.is_empty():
		lines.append({"text": "WEAK: %s" % weak, "color": WEAK_COLOR})
	return lines


## "ARMOURED" -> "Armoured"; joins a JSON list of enum names for display.
static func format_names(values: Variant) -> String:
	var names: PackedStringArray = []
	if values is Array:
		for value: Variant in values:
			names.append(str(value).replace("_", " ").to_lower().capitalize())
	return ", ".join(names)


## JSON numbers parse as floats; shows whole numbers without the ".0".
## A missing stat shows as "?".
static func format_stat(stats: Dictionary, key: String) -> String:
	var value: Variant = stats.get(key)
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		var number: float = float(value)
		return str(int(number)) if is_equal_approx(number, roundf(number)) else str(number)
	return "?" if value == null else str(value)


static func _create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.border_color = CARD_BORDER_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	return style
