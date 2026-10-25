extends GutTest


func test_format_stat_drops_trailing_zero_from_whole_numbers() -> void:
	var stats: Dictionary = {"health": 160.0, "speed": 82.5, "count": 3, "type": "KINETIC"}
	assert_eq(MenuWidgets.format_stat(stats, "health"), "160")
	assert_eq(MenuWidgets.format_stat(stats, "speed"), "82.5")
	assert_eq(MenuWidgets.format_stat(stats, "count"), "3")
	assert_eq(MenuWidgets.format_stat(stats, "type"), "KINETIC")
	assert_eq(MenuWidgets.format_stat(stats, "missing"), "?")


func test_format_names_capitalises_enum_names() -> void:
	assert_eq(MenuWidgets.format_names(["MECHANICAL", "ARMOUR_SHRED"]), "Mechanical, Armour Shred")
	assert_eq(MenuWidgets.format_names("not a list"), "")
