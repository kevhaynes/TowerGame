extends GutTest


func _json_file_count(directory_path: String) -> int:
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(directory_path):
		if file_name.ends_with(".json"):
			count += 1
	return count


func test_loads_every_tower_definition_with_its_path() -> void:
	var towers: Array[Dictionary] = DefinitionCatalog.load_directory(
		DefinitionCatalog.TOWERS_DIRECTORY
	)
	assert_eq(towers.size(), _json_file_count(DefinitionCatalog.TOWERS_DIRECTORY))
	for tower: Dictionary in towers:
		var path: String = str(tower[DefinitionCatalog.DEFINITION_PATH_KEY])
		assert_eq(path.get_file().get_basename(), str(tower["id"]))


func test_loads_every_enemy_definition() -> void:
	var enemies: Array[Dictionary] = DefinitionCatalog.load_directory(
		DefinitionCatalog.ENEMIES_DIRECTORY
	)
	assert_eq(enemies.size(), _json_file_count(DefinitionCatalog.ENEMIES_DIRECTORY))


func test_load_enemy_by_id() -> void:
	assert_eq(str(DefinitionCatalog.load_enemy("scout")["id"]), "scout")
